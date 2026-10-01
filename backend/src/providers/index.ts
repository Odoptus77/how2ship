import type { Config } from "../config.js";
import type { Carrier } from "../model.js";
import { DHLProvider } from "./dhl.js";
import { MockProvider } from "./mock.js";
import { Ship24Provider } from "./ship24.js";
import type { TrackingProvider } from "./types.js";

/** Wählt je Paketdienst den passenden Anbieter. */
export class ProviderRegistry {
  private readonly byName = new Map<string, TrackingProvider>();

  constructor(
    private readonly dhl?: TrackingProvider,
    private readonly ship24?: TrackingProvider,
    private readonly mock?: TrackingProvider,
  ) {
    for (const p of [dhl, ship24, mock]) if (p) this.byName.set(p.name, p);
  }

  static fromConfig(config: Config): ProviderRegistry {
    if (config.useMockProvider) return new ProviderRegistry(undefined, undefined, new MockProvider());
    const dhl = config.dhlApiKey ? new DHLProvider(config.dhlApiKey) : undefined;
    const ship24 = config.ship24ApiKey ? new Ship24Provider(config.ship24ApiKey) : undefined;
    // Ohne echte Anbieter: Mock, damit die App lokal vollständig testbar ist.
    const mock = !dhl && !ship24 ? new MockProvider() : undefined;
    return new ProviderRegistry(dhl, ship24, mock);
  }

  /** DHL/Deutsche Post → DHL-API (kostenlos), sonst Ship24; ohne Konfiguration → Mock. */
  forCarrier(carrier: Carrier): TrackingProvider | undefined {
    if (this.mock) return this.mock;
    if ((carrier === "dhl" || carrier === "deutschePost") && this.dhl) return this.dhl;
    return this.ship24 ?? (carrier === "dhl" || carrier === "deutschePost" ? this.dhl : undefined);
  }

  byProviderName(name: string): TrackingProvider | undefined {
    return this.byName.get(name);
  }

  get names(): string[] {
    return [...this.byName.keys()];
  }
}
