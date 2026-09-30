import SwiftUI
import SceneKit
import PaketlotseCore

/// Anleitung vor jedem Messschritt: 3D-Karton, an dem die zu messende Strecke animiert gezeigt wird.
struct MeasureTutorialSheet: View {
    let dimension: BoxMeasurement.Dimension
    let onStart: () -> Void

    /// Global für alle drei Schritte: „Nicht erneut anzeigen“.
    @AppStorage(MeasureTutorialSheet.disabledKey) private var isDisabled = false

    static let disabledKey = "measureTutorialDisabled"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Schritt \(dimension.number) von 3")
                    .font(.lotse(13, .bold))
                    .foregroundStyle(Theme.accent)
                Text("\(dimension.title) messen")
                    .font(.lotse(24, .bold))
                    .foregroundStyle(Theme.textPrimary)
            }

            MeasureTutorialAnimation(dimension: dimension)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityLabel("Animation: \(dimension.title) am Karton messen")

            Text(dimension.tutorialText)
                .font(.lotse(15))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $isDisabled) {
                Text("Nicht erneut anzeigen")
                    .font(.lotse(14, .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .toggleStyle(CheckboxToggleStyle())

            Button("Verstanden, \(dimension.title.lowercased()) messen", action: onStart)
                .buttonStyle(PrimaryButtonStyle())

            Text("Über das ? oben kannst du diese Anleitung jederzeit wieder öffnen.")
                .font(.lotse(11))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
        }
        .padding(24)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

/// Quadratische Checkbox mit Haken.
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundStyle(configuration.isOn ? Theme.primary : Theme.textSecondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}

// MARK: - 3D-Animation

struct MeasureTutorialAnimation: View {
    let dimension: BoxMeasurement.Dimension

    var body: some View {
        // `.id`: Beim Wechsel des Schritts entsteht eine neue Szene, die Animation beginnt von vorn.
        MeasureTutorialSceneView(dimension: dimension)
            .id(dimension)
            .allowsHitTesting(false)
    }
}

private struct MeasureTutorialSceneView: View {
    let dimension: BoxMeasurement.Dimension
    /// Szene nur einmal bauen – sonst würde jede Neuzeichnung die Animation neu starten.
    @State private var scene: SCNScene?

    var body: some View {
        ZStack {
            Color(uiColor: MeasureTutorialScene.backgroundColor)
            if let scene {
                SceneView(
                    scene: scene,
                    pointOfView: scene.rootNode.childNode(withName: MeasureTutorialScene.cameraName, recursively: false),
                    options: [.autoenablesDefaultLighting]
                )
            }
        }
        .onAppear {
            if scene == nil { scene = MeasureTutorialScene.make(for: dimension) }
        }
    }
}

enum MeasureTutorialScene {
    static let cameraName = "tutorialCamera"
    static let backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 0.96, alpha: 1)
    // Karton 40 × 25 × 30 cm (x = Länge, y = Höhe, z = Breite), Mittelpunkt im Ursprung.
    private static let size = SIMD3<Float>(0.40, 0.25, 0.30)
    private static let cardboard = UIColor(red: 0.80, green: 0.62, blue: 0.43, alpha: 1)
    private static let tape = UIColor(red: 0.95, green: 0.66, blue: 0.23, alpha: 1)
    private static let highlight = UIColor(red: 0.12, green: 0.43, blue: 0.55, alpha: 1)

    static func make(for dimension: BoxMeasurement.Dimension) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = backgroundColor

        let pivot = SCNNode()
        scene.rootNode.addChildNode(pivot)
        pivot.addChildNode(box())
        pivot.addChildNode(floor())

        let (start, end) = edge(for: dimension)
        pivot.addChildNode(measurement(from: start, to: end))

        // Leichtes Hin- und Herdrehen, damit der Karton räumlich wirkt.
        let swing = SCNAction.sequence([
            .rotateBy(x: 0, y: 0.35, z: 0, duration: 2.5),
            .rotateBy(x: 0, y: -0.35, z: 0, duration: 2.5),
        ])
        swing.timingMode = .easeInEaseOut
        pivot.runAction(.repeatForever(swing))

        let camera = SCNNode()
        camera.name = cameraName
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 38
        camera.simdPosition = SIMD3(0.62, 0.48, 0.78)
        camera.simdLook(at: SIMD3(0, -0.02, 0))
        scene.rootNode.addChildNode(camera)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 450
        scene.rootNode.addChildNode(ambient)

        return scene
    }

    /// Start- und Endpunkt der hervorgehobenen Kante.
    private static func edge(for dimension: BoxMeasurement.Dimension) -> (SIMD3<Float>, SIMD3<Float>) {
        let h = size / 2
        switch dimension {
        case .length:  // vordere untere Kante entlang x
            return (SIMD3(-h.x, -h.y, h.z), SIMD3(h.x, -h.y, h.z))
        case .width:   // rechte untere Kante entlang z
            return (SIMD3(h.x, -h.y, h.z), SIMD3(h.x, -h.y, -h.z))
        case .height:  // vordere rechte senkrechte Kante
            return (SIMD3(h.x, -h.y, h.z), SIMD3(h.x, h.y, h.z))
        }
    }

    private static func box() -> SCNNode {
        let geometry = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z), chamferRadius: 0.004)
        geometry.firstMaterial = material(cardboard, lit: true)
        let node = SCNNode(geometry: geometry)

        // Klebeband oben und vorne
        let topTape = SCNNode(geometry: SCNBox(width: 0.06, height: 0.002, length: CGFloat(size.z) + 0.002, chamferRadius: 0))
        topTape.geometry?.firstMaterial = material(tape, lit: true)
        topTape.simdPosition = SIMD3(0, size.y / 2 + 0.001, 0)
        node.addChildNode(topTape)

        let frontTape = SCNNode(geometry: SCNBox(width: 0.06, height: 0.08, length: 0.002, chamferRadius: 0))
        frontTape.geometry?.firstMaterial = material(tape, lit: true)
        frontTape.simdPosition = SIMD3(0, size.y / 2 - 0.04, size.z / 2 + 0.001)
        node.addChildNode(frontTape)
        return node
    }

    private static func floor() -> SCNNode {
        let plane = SCNPlane(width: 1.2, height: 1.2)
        plane.cornerRadius = 0.6
        plane.firstMaterial = material(UIColor.black.withAlphaComponent(0.06), lit: false)
        let node = SCNNode(geometry: plane)
        node.eulerAngles.x = -.pi / 2
        node.simdPosition = SIMD3(0, -size.y / 2 - 0.001, 0)
        return node
    }

    /// Startpunkt erscheint → Linie wächst → Endpunkt erscheint → kurze Pause → von vorn.
    private static func measurement(from start: SIMD3<Float>, to end: SIMD3<Float>) -> SCNNode {
        let group = SCNNode()
        let direction = end - start
        let length = simd_length(direction)

        let startDot = dot(at: start)
        let endDot = dot(at: end)

        // Zylinder, dessen Basis am Startpunkt liegt; wächst durch Skalierung entlang seiner Achse.
        let cylinder = SCNCylinder(radius: 0.006, height: CGFloat(length))
        cylinder.firstMaterial = material(highlight, lit: false)
        let line = SCNNode(geometry: cylinder)
        line.pivot = SCNMatrix4MakeTranslation(0, -Float(length) / 2, 0)
        line.simdPosition = start
        line.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: direction / length)

        [startDot, endDot, line].forEach(group.addChildNode)

        let pop = SCNAction.sequence([.scale(to: 1.25, duration: 0.18), .scale(to: 1.0, duration: 0.12)])
        let grow = SCNAction.customAction(duration: 1.2) { node, elapsed in
            let progress = Float(min(max(elapsed / 1.2, 0), 1))
            node.scale = SCNVector3(1, max(progress, 0.001), 1)
        }
        grow.timingMode = .easeInEaseOut

        // Gleiche Zykluslänge (3,4 s) für alle drei Knoten.
        startDot.runAction(.repeatForever(.sequence([
            .scale(to: 0, duration: 0), .wait(duration: 0.2), pop, .wait(duration: 2.9),
        ])))
        line.runAction(.repeatForever(.sequence([
            .run { $0.scale = SCNVector3(1, 0.001, 1) }, .wait(duration: 0.6), grow, .wait(duration: 1.6),
        ])))
        endDot.runAction(.repeatForever(.sequence([
            .scale(to: 0, duration: 0), .wait(duration: 1.8), pop, .wait(duration: 1.3),
        ])))
        return group
    }

    private static func dot(at position: SIMD3<Float>) -> SCNNode {
        let sphere = SCNSphere(radius: 0.016)
        sphere.firstMaterial = material(tape, lit: false)
        let node = SCNNode(geometry: sphere)
        node.simdPosition = position
        return node
    }

    private static func material(_ color: UIColor, lit: Bool) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = lit ? .physicallyBased : .constant
        material.roughness.contents = 0.9
        return material
    }
}
