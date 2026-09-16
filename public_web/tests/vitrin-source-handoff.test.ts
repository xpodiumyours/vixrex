import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  kaydetVitrinKaynakHandoff,
  tuketVitrinKaynakHandoff,
} from "../src/lib/vitrinSourceHandoff";

class MemoryStorage {
  private data = new Map<string, string>();

  getItem(key: string) {
    return this.data.get(key) ?? null;
  }

  setItem(key: string, value: string) {
    this.data.set(key, value);
  }

  removeItem(key: string) {
    this.data.delete(key);
  }
}

describe("vitrin source handoff", () => {
  beforeEach(() => {
    vi.stubGlobal("window", { sessionStorage: new MemoryStorage() });
    vi.spyOn(Date, "now").mockReturnValue(1_000_000);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("consumes kesfet only on the exact target path", () => {
    kaydetVitrinKaynakHandoff("kesfet", "/v/ornek-magaza");

    expect(tuketVitrinKaynakHandoff("/v/baska-magaza")).toBeNull();
    expect(tuketVitrinKaynakHandoff("/v/ornek-magaza")).toBe("kesfet");
    expect(tuketVitrinKaynakHandoff("/v/ornek-magaza")).toBeNull();
  });

  it("rejects an expired handoff", () => {
    kaydetVitrinKaynakHandoff("kesfet", "/v/ornek-magaza");
    vi.mocked(Date.now).mockReturnValue(1_061_000);

    expect(tuketVitrinKaynakHandoff("/v/ornek-magaza")).toBeNull();
  });

  it("ignores non-store targets", () => {
    kaydetVitrinKaynakHandoff("kesfet", "/blog/yazi");
    expect(tuketVitrinKaynakHandoff("/blog/yazi")).toBeNull();
  });
});
