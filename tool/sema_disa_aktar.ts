// Şemayı tarafsız JSON'a çıkarır. Flutter tarafı bu JSON'dan üretilir.
// Elle düzenlenmez — kaynak vitrinFieldSchema.ts.
import { writeFileSync, mkdirSync } from "fs";
import { resolve, dirname } from "path";
import { VITRIN_FIELDS } from "../public_web/src/lib/vitrinFieldSchema";

const hedef = resolve(__dirname, "../shared/vitrin_alanlari.json");
mkdirSync(dirname(hedef), { recursive: true });

const cikti = {
  _uretim: "tool/sema_disa_aktar.ts — ELLE DÜZENLEME",
  _kaynak: "public_web/src/lib/vitrinFieldSchema.ts",
  alanlar: VITRIN_FIELDS.map((a) => ({
    anahtar: a.anahtar,
    tip: a.tip,
    etiket: a.etiket,
    kolon: a.kolon,
    bolum: a.bolum,
    zorunlu: a.zorunlu ?? false,
    minUzunluk: a.minUzunluk ?? null,
    maxUzunluk: a.maxUzunluk ?? null,
    min: a.min ?? null,
    max: a.max ?? null,
    secenekler: a.secenekler ?? null,
    ipucu: a.ipucu ?? null,
  })),
};

writeFileSync(hedef, JSON.stringify(cikti, null, 2) + "\n", "utf8");
console.log("alan sayisi:", cikti.alanlar.length);
console.log("zorunlu:", cikti.alanlar.filter((a) => a.zorunlu).map((a) => a.anahtar).join(", "));
