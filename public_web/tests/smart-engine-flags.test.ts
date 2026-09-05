import { describe, expect, it } from "vitest";
import {
  VIXREX_SMART_ENGINE_FLAG,
  VIXREX_SMART_ENGINE_STOREFRONT_FLAG,
  smartEngineStorefrontEnabledFromRows,
} from "../src/lib/smartEngineFlags";

describe("Akıllı Motor runtime kill-switch", () => {
  it("iki flag de açıkken storefront motoru açılır", () => {
    expect(
      smartEngineStorefrontEnabledFromRows([
        { flag_key: VIXREX_SMART_ENGINE_FLAG, is_enabled: true },
        { flag_key: VIXREX_SMART_ENGINE_STOREFRONT_FLAG, is_enabled: true },
      ])
    ).toBe(true);
  });

  it("tek flag eksik veya kapalıysa fail-closed", () => {
    expect(
      smartEngineStorefrontEnabledFromRows([
        { flag_key: VIXREX_SMART_ENGINE_FLAG, is_enabled: true },
      ])
    ).toBe(false);
    expect(
      smartEngineStorefrontEnabledFromRows([
        { flag_key: VIXREX_SMART_ENGINE_FLAG, is_enabled: true },
        { flag_key: VIXREX_SMART_ENGINE_STOREFRONT_FLAG, is_enabled: false },
      ])
    ).toBe(false);
  });

  it("bozuk veya yüklenememiş sonuç hiçbir zaman motoru açmaz", () => {
    expect(smartEngineStorefrontEnabledFromRows(null)).toBe(false);
    expect(
      smartEngineStorefrontEnabledFromRows([
        { flag_key: VIXREX_SMART_ENGINE_FLAG, is_enabled: "true" },
        { flag_key: VIXREX_SMART_ENGINE_STOREFRONT_FLAG, is_enabled: true },
      ])
    ).toBe(false);
  });
});
