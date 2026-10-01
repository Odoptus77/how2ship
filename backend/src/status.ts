import type { ShipmentStatus } from "./model.js";

/**
 * DHL Shipment Tracking – Unified: statusCode ∈ pre-transit | transit | delivered | failure | unknown.
 * „In Zustellung“ hat keinen eigenen Code und wird am Text erkannt.
 */
export function statusFromDHL(statusCode: string | undefined, text = ""): ShipmentStatus {
  switch (statusCode) {
    case "delivered":
      return "delivered";
    case "failure":
      return "problem";
    case "transit":
      return looksOutForDelivery(text) ? "outForDelivery" : "inTransit";
    case "pre-transit":
      return "registered";
    default:
      return looksOutForDelivery(text) ? "outForDelivery" : "registered";
  }
}

/**
 * Ship24 statusMilestone ∈ pending | info_received | in_transit | out_for_delivery |
 * failed_attempt | available_for_pickup | delivered | exception
 */
export function statusFromShip24(milestone: string | undefined | null): ShipmentStatus {
  switch (milestone) {
    case "delivered":
      return "delivered";
    case "out_for_delivery":
      return "outForDelivery";
    case "in_transit":
    case "available_for_pickup":
      return "inTransit";
    case "failed_attempt":
    case "exception":
      return "problem";
    default:
      return "registered";
  }
}

export function looksOutForDelivery(text: string): boolean {
  return /in zustellung|zustellfahrzeug|wird heute zugestellt|out for delivery|with delivery courier/i.test(text);
}

/** Reihenfolge für „Fortschritt“ – zugestellt ist endgültig, Probleme können zwischendurch auftreten. */
const rank: Record<ShipmentStatus, number> = {
  registered: 0,
  inTransit: 1,
  outForDelivery: 2,
  problem: 2,
  delivered: 3,
};

/** Status, über den der Nutzer benachrichtigt werden soll – oder `undefined`. */
export function notifiableChange(previous: ShipmentStatus, next: ShipmentStatus): ShipmentStatus | undefined {
  if (previous === next) return undefined;
  if (previous === "delivered") return undefined; // nach Zustellung keine Nachrichten mehr
  if (next === "problem" || next === "outForDelivery" || next === "delivered") return next;
  if (next === "inTransit" && rank[previous] < rank.inTransit) return next;
  return undefined;
}

export function pushText(status: ShipmentStatus, label: string): { title: string; body: string } {
  switch (status) {
    case "inTransit":
      return { title: "Paket unterwegs 🚚", body: `${label} ist beim Paketdienst angekommen und unterwegs.` };
    case "outForDelivery":
      return { title: "Heute in Zustellung 📦", body: `${label} wird heute zugestellt.` };
    case "delivered":
      return { title: "Zugestellt ✅", body: `${label} wurde zugestellt.` };
    case "problem":
      return { title: "Problem bei der Zustellung", body: `${label}: Bitte prüfe den Status beim Paketdienst.` };
    case "registered":
      return { title: "Sendung angemeldet", body: `${label} ist beim Paketdienst angemeldet.` };
  }
}
