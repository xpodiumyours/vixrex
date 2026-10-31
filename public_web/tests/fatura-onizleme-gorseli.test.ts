import fs from "node:fs";
import path from "node:path";
import { expect, it } from "vitest";
import { onizlemeKartiGorseli } from "@/lib/faturaOnizlemeGorseli";

const depoAdresi =
  "https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/shelf-images/kiralik-butik-gunluk/products/fatura/abc123.webp";

it("depodaki fotoğraf adresi önizleme kartında korunur", () => {
  expect(onizlemeKartiGorseli(depoAdresi)).toBe(depoAdresi);
});

it("üretici sitesinden gelen adres karta giremez", () => {
  for (const adres of [
    "https://cdn.myikas.com/images/74e89546/image_3840.webp",
    "https://www.sehermensucat.com.tr/urun/fanila.jpg",
  ]) {
    expect(onizlemeKartiGorseli(adres)).toBeNull();
  }
});

it("boş, eksik ya da depo dışı adres null döner", () => {
  expect(onizlemeKartiGorseli(null)).toBeNull();
  expect(onizlemeKartiGorseli(undefined)).toBeNull();
  expect(onizlemeKartiGorseli("")).toBeNull();
  expect(onizlemeKartiGorseli("r2://shelf-images/x.webp")).toBeNull();
  expect(onizlemeKartiGorseli("https://supabase.co/depo/x.webp")).toBeNull();
});

it("önizleme kartı görseli kaydetme yanıtındaki depo adresinden okunur", () => {
  const kaynak = fs.readFileSync(
    path.join(__dirname, "..", "src", "components", "owner", "InvoiceToProducts.tsx"),
    "utf8",
  );
  expect(kaynak).toContain("onizlemeKartiGorseli(satir.gorsel)");
  expect(kaynak).not.toContain("gorsel: degerlendirmeler[satir.sira]?.gorseller[0]");
});

it("kart ızgarası da yalnız depodaki adresi çizer", () => {
  const kaynak = fs.readFileSync(
    path.join(__dirname, "..", "src", "components", "owner", "InvoiceToProducts.tsx"),
    "utf8",
  );
  expect(kaynak).toContain("const kartGorseli = onizlemeKartiGorseli(satir.gorsel)");
  expect(kaynak).not.toContain("src={degerlendirme.gorseller[0]}");
});

it("satır yanıtı depodaki görseli taşır", () => {
  const kaynak = fs.readFileSync(
    path.join(__dirname, "..", "src", "lib", "faturaIslemOku.ts"),
    "utf8",
  );
  expect(kaynak).toContain("gorsel: kayit.product_id");
  expect(kaynak).toContain("yonetilenUrunGorseliMi(url)");
});

it("kopya hazır değilse kart fotoğraf yerine hazırlanıyor der", () => {
  const kaynak = fs.readFileSync(
    path.join(__dirname, "..", "src", "components", "owner", "FaturaIslemSonucu.tsx"),
    "utf8",
  );
  expect(kaynak).toContain("Görsel hazırlanıyor");
});
