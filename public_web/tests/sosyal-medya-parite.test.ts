import { describe, expect, it } from "vitest";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";

function alan(anahtar: string) {
  const sonuc = FIELD_BY_KEY.get(anahtar);
  expect(sonuc, `${anahtar} alanı şemada bulunmalı`).toBeDefined();
  return sonuc!;
}

describe("sosyal medya / dış bağlantılar — gerçek alan şeması", () => {
  it("Instagram alanını gerçek kolon ve sınırlarıyla çözer", () => {
    expect(alan("instagram")).toMatchObject({
      kolon: "instagram",
      tip: "metin",
      bolum: "contact",
      maxUzunluk: 30,
    });
  });

  it("web sitesi alanını URL olarak çözer", () => {
    expect(alan("website")).toMatchObject({
      kolon: "website",
      tip: "url",
      bolum: "contact",
    });
  });

  it("referans / pazar yeri bağlantısını yazılabilir URL kolonu olarak çözer", () => {
    expect(alan("referansLinki")).toMatchObject({
      kolon: "references_link",
      tip: "url",
      bolum: "about",
    });
  });
});
