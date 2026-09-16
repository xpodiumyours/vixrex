import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const root = resolve(__dirname, "../..");
const read = (path: string) => readFileSync(resolve(root, path), "utf8");

const migration = read(
  "supabase/migrations/20260916080000_owner_analytics_measurement_security.sql",
);
const whatsapp = read("public_web/src/components/TrackedWhatsAppLink.tsx");
const contact = read("public_web/src/components/TrackedContactLink.tsx");
const productView = read("public_web/src/components/ProductViewTracker.tsx");

describe("owner analytics measurement contract", () => {
  it("locks direct engagement table access behind RLS", () => {
    expect(migration).toContain(
      "alter table public.vitrin_engagement_events enable row level security",
    );
    expect(migration).toContain(
      "revoke all on table public.vitrin_engagement_events from anon, authenticated",
    );
  });

  it("adds the missing product foreign-key index", () => {
    expect(migration).toContain(
      "idx_vitrin_engagement_events_product_id",
    );
  });

  it("persists only known engagement surfaces through the v2 RPC", () => {
    expect(migration).toContain("record_vitrin_engagement_v2");
    expect(migration).toContain("vitrin_engagement_events_surface_check");
    expect(migration).toContain("'product_quick_view'");
    expect(migration).toContain("'storefront_floating'");
    expect(whatsapp).toContain('.rpc("record_vitrin_engagement_v2"');
    expect(whatsapp).toContain("p_surface: context.clickLocation");
    expect(contact).toContain('.rpc("record_vitrin_engagement_v2"');
    expect(contact).toContain("p_surface: context.clickLocation");
    expect(productView).toContain('.rpc("record_vitrin_engagement_v2"');
    expect(productView).toContain('p_surface: "product_detail"');
  });

  it("extends the visit source contract only with the proven kesfet source", () => {
    expect(migration).toContain("'diger_site', 'kesfet'");
    expect(migration).not.toContain("'dijital_carsi'");
  });
});
