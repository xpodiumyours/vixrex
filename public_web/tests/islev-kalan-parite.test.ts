import { describe, expect, it } from "vitest";
import {
  EDITABLE_COLUMNS,
  FIELD_BY_KEY,
  SECTION_DOM_ID,
  fieldsOfSection,
} from "@/lib/vitrinFieldSchema";

function alan(anahtar: string) {
  const sonuc = FIELD_BY_KEY.get(anahtar);
  expect(sonuc, `${anahtar} alanı şemada bulunmalı`).toBeDefined();
  return sonuc!;
}

describe("kalan işlevler — gerçek VitrinField şema davranışı", () => {
  it("konum/harita alanlarını gerçek kolon, bölüm ve sayı sınırlarıyla çözer", () => {
    expect(alan("haritaEtiketi")).toMatchObject({
      kolon: "map_label",
      bolum: "contact",
      tip: "metin",
    });
    expect(alan("konumMetni")).toMatchObject({
      kolon: "hero_location_text",
      bolum: "hero",
    });
    expect(alan("enlem")).toMatchObject({ kolon: "latitude", min: -90, max: 90 });
    expect(alan("boylam")).toMatchObject({ kolon: "longitude", min: -180, max: 180 });
  });

  it("galeri alanlarını gerçek gallery bölümünden döndürür", () => {
    const galeri = fieldsOfSection("gallery");
    expect(galeri.map((item) => item.kolon)).toEqual(
      expect.arrayContaining([
        "gallery_section_kicker",
        "gallery_section_title",
        "gallery_action_label",
        "gallery_action_href",
      ]),
    );
    expect(SECTION_DOM_ID.gallery).toBe("galeri");
  });

  it("hakkımızda alanlarını gerçek about bölümünden döndürür", () => {
    const hakkinda = fieldsOfSection("about");
    expect(hakkinda.map((item) => item.kolon)).toEqual(
      expect.arrayContaining([
        "about_kicker",
        "about_title",
        "corporate_bio",
        "about_image_url",
        "about_image_caption",
        "references_link",
      ]),
    );
    expect(SECTION_DOM_ID.about).toBe("hakkimizda");
  });

  it("kanıtlanan kolonların sunucu yazılabilir listesinden gerçekten geçtiğini doğrular", () => {
    for (const kolon of [
      "map_label",
      "hero_location_text",
      "gallery_section_kicker",
      "about_title",
      "references_link",
    ]) {
      expect(EDITABLE_COLUMNS).toContain(kolon);
    }
  });
});
