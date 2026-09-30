import SwiftUI
import ARKit
import SceneKit
import PaketlotseCore

/// Zustand der Vermessung, geteilt zwischen AR-Ansicht (schreibt Treffer) und SwiftUI-Oberfläche.
@MainActor
@Observable
final class MeasureSession {
    var measurement = BoxMeasurement()
    /// Punkt in der Welt, auf den das Fadenkreuz gerade zeigt.
    var currentHit: SIMD3<Float>?
    var trackingHint: String?
    var errorMessage: String?

    var canAddPoint: Bool { currentHit != nil && !measurement.isComplete }

    var previewCm: Double? {
        currentHit.flatMap { measurement.previewCm(to: $0) }
    }

    func addPoint() {
        guard let hit = currentHit, !measurement.isComplete else { return }
        measurement.add(hit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func undo() {
        measurement.undo()
    }

    func reset() {
        measurement.reset()
    }
}

/// ARKit-Kameraansicht (SceneKit) mit Mittelpunkt-Raycast, Messpunkten und Vorschau-Linie.
/// Auf LiDAR-Geräten wird Scene Depth aktiviert – Raycasts werden dadurch deutlich genauer.
struct ARMeasureView: UIViewRepresentable {
    let model: MeasureSession
    /// Explizit übergeben, damit `updateUIView` bei jeder Änderung der Punkte läuft.
    let points: [SIMD3<Float>]

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.automaticallyUpdatesLighting = true
        view.rendersContinuously = true
        view.session.delegate = context.coordinator
        view.scene.rootNode.addChildNode(context.coordinator.pointsNode)
        view.scene.rootNode.addChildNode(context.coordinator.previewLine)
        context.coordinator.sceneView = view

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        return view
    }

    func updateUIView(_ view: ARSCNView, context: Context) {
        context.coordinator.syncPoints(points)
    }

    static func dismantleUIView(_ view: ARSCNView, coordinator: Coordinator) {
        view.session.pause()
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        let model: MeasureSession
        weak var sceneView: ARSCNView?

        let pointsNode = SCNNode()
        let previewLine: SCNNode = {
            let node = SCNNode(geometry: SCNCylinder(radius: 0.0015, height: 0.01))
            node.geometry?.firstMaterial = Coordinator.material(.white)
            node.isHidden = true
            return node
        }()

        private var renderedPoints: [SIMD3<Float>] = []

        init(model: MeasureSession) {
            self.model = model
        }

        // MARK: ARSessionDelegate (läuft auf dem Main Thread, da keine eigene delegateQueue gesetzt ist)

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let trackingState = frame.camera.trackingState
            MainActor.assumeIsolated {
                handleFrame(trackingState: trackingState)
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            let message: String
            if let arError = error as? ARError, arError.code == .cameraUnauthorized {
                message = "Paketlotse braucht Zugriff auf die Kamera. Du kannst ihn in den Einstellungen erlauben."
            } else {
                message = "Die Kamera-Vermessung konnte nicht gestartet werden."
            }
            MainActor.assumeIsolated {
                model.errorMessage = message
            }
        }

        // MARK: Frame-Verarbeitung

        @MainActor
        private func handleFrame(trackingState: ARCamera.TrackingState) {
            guard let view = sceneView else { return }

            let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            var hit: SIMD3<Float>?
            if let query = view.raycastQuery(from: center, allowing: .estimatedPlane, alignment: .any),
               let result = view.session.raycast(query).first {
                let translation = result.worldTransform.columns.3
                hit = SIMD3(translation.x, translation.y, translation.z)
            }

            // Nur bei spürbarer Änderung (> 1 mm) veröffentlichen, um SwiftUI nicht 60× pro Sekunde neu zu zeichnen.
            if Self.hasMeaningfulChange(from: model.currentHit, to: hit) {
                model.currentHit = hit
            }
            let hint = Self.hint(for: trackingState)
            if model.trackingHint != hint {
                model.trackingHint = hint
            }
            updatePreview(hit: hit)
        }

        @MainActor
        func syncPoints(_ points: [SIMD3<Float>]) {
            guard points != renderedPoints else { return }
            renderedPoints = points
            pointsNode.childNodes.forEach { $0.removeFromParentNode() }

            for (index, point) in points.enumerated() {
                pointsNode.addChildNode(Self.sphere(at: point))
                if index == 1 || index == 2 {
                    pointsNode.addChildNode(Self.line(from: points[index - 1], to: point, color: .white))
                }
            }
            // Höhe: senkrechte Linie vom Boden zum Deckel-Punkt.
            if points.count == 4, let floor = model.measurement.floorLevel {
                let top = points[3]
                pointsNode.addChildNode(Self.line(from: SIMD3(top.x, floor, top.z), to: top, color: .white))
            }
        }

        @MainActor
        private func updatePreview(hit: SIMD3<Float>?) {
            let measurement = model.measurement
            guard let hit, let start = Self.previewStart(for: measurement, hit: hit) else {
                previewLine.isHidden = true
                return
            }
            Self.place(previewLine, from: start, to: hit)
            previewLine.isHidden = false
        }

        // MARK: Geometrie-Helfer

        private static func previewStart(for measurement: BoxMeasurement, hit: SIMD3<Float>) -> SIMD3<Float>? {
            switch measurement.currentStep {
            case .secondCorner, .thirdCorner:
                return measurement.points.last
            case .top:
                return measurement.floorLevel.map { SIMD3(hit.x, $0, hit.z) }
            case .firstCorner, nil:
                return nil
            }
        }

        private static func hasMeaningfulChange(from old: SIMD3<Float>?, to new: SIMD3<Float>?) -> Bool {
            switch (old, new) {
            case (nil, nil): return false
            case let (old?, new?): return simd_distance(old, new) > 0.001
            default: return true
            }
        }

        private static func material(_ color: UIColor) -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.lightingModel = .constant
            return material
        }

        private static func sphere(at point: SIMD3<Float>) -> SCNNode {
            let sphere = SCNSphere(radius: 0.005)
            sphere.firstMaterial = material(UIColor(red: 0.95, green: 0.66, blue: 0.23, alpha: 1))
            let node = SCNNode(geometry: sphere)
            node.simdPosition = point
            return node
        }

        private static func line(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor) -> SCNNode {
            let node = SCNNode(geometry: SCNCylinder(radius: 0.0015, height: 0.01))
            node.geometry?.firstMaterial = material(color)
            place(node, from: start, to: end)
            return node
        }

        /// Richtet einen Zylinder (Achse = lokales +y) zwischen zwei Punkten aus.
        private static func place(_ node: SCNNode, from start: SIMD3<Float>, to end: SIMD3<Float>) {
            let direction = end - start
            let length = simd_length(direction)
            (node.geometry as? SCNCylinder)?.height = CGFloat(max(length, 0.0001))
            node.simdPosition = (start + end) / 2
            if length > 0.0001 {
                node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: direction / length)
            }
        }

        private static func hint(for state: ARCamera.TrackingState) -> String? {
            switch state {
            case .normal:
                return nil
            case .notAvailable:
                return "Kamera startet …"
            case .limited(let reason):
                switch reason {
                case .initializing: return "Bewege das iPhone langsam hin und her."
                case .excessiveMotion: return "Etwas langsamer bewegen."
                case .insufficientFeatures: return "Mehr Licht oder eine strukturierte Fläche nötig."
                case .relocalizing: return "Orientierung wird wiederhergestellt …"
                @unknown default: return "Bewege das iPhone langsam."
                }
            }
        }
    }
}
