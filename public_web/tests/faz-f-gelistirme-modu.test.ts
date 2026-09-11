import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

describe("Faz F — tıklamalar artık Supabase'e de yazılıyor (GA'nın yanına)", () => {
  it("WhatsApp tıklaması record_vitrin_engagement çağırır", () => {
    const kaynak = oku("components/TrackedWhatsAppLink.tsx");
    expect(kaynak).toContain('.rpc("record_vitrin_engagement"');
    expect(kaynak).toContain('p_event_type: "whatsapp_click"');
  });

  it("telefon/konum tıklaması aynı RPC'yi eventName ile çağırır", () => {
    const kaynak = oku("components/TrackedContactLink.tsx");
    expect(kaynak).toContain('.rpc("record_vitrin_engagement"');
    expect(kaynak).toContain("p_event_type: eventName");
  });

  it("ürün görüntüleme izleyicisi ürün detay sayfasına eklendi", () => {
    const sayfa = oku("app/v/[slug]/urun/[productSlug]/page.tsx");
    expect(sayfa).toContain("<ProductViewTracker storeSlug={store.slug} productSlug={productSlug} />");
    const tracker = oku("components/ProductViewTracker.tsx");
    expect(tracker).toContain('p_event_type: "product_view"');
  });

  it("hepsi aynı ziyaretçi anahtarını paylaşır — üç ayrı localStorage anahtarı yok", () => {
    for (const dosya of [
      "components/TrackedWhatsAppLink.tsx",
      "components/TrackedContactLink.tsx",
      "components/ProductViewTracker.tsx",
      "components/VitrinViewTracker.tsx",
    ]) {
      expect(oku(dosya)).toContain("ziyaretAnahtariniOkuyaUret");
    }
  });
});

describe("Faz F — haftalık özet yalnız sahip oturumuyla okunur", () => {
  const migrasyon = readFileSync(
    resolve(__dirname, "../../supabase/migrations/20260902112954_faz_f_vitrin_engagement_events.sql"),
    "utf8"
  );

  it("get_haftalik_performans get_working_draft_for_session ile aynı sahip-doğrulama desenini kullanır", () => {
    expect(migrasyon).toContain("from public.owner_sessions s");
    expect(migrasyon).toContain("s.consumed_at is not null");
    expect(migrasyon).toContain("s.expires_at > now()");
  });

  it("record_vitrin_engagement yayında olmayan mağazaya yazmaz", () => {
    expect(migrasyon).toContain("and is_published = true");
  });

  it("son 7 gün penceresi kullanılıyor", () => {
    expect(migrasyon).toContain("interval '7 days'");
  });
});

describe("OwnerAssistantPanel — açılışta kendiliğinden rapor yazmaz", () => {
  it("haftalık performans ve öneriler sohbet akışına basılmaz", () => {
    const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");
    expect(panel).not.toContain("Bu hafta ${haftalikPerformans.goruntuleme}");
    expect(panel).not.toContain("Vitrininde bugün ilgilenmen gereken");
  });
});
