import { describe, expect, it } from "vitest";
import { temizlenmisSeciliDeger } from "@/app/v/[slug]/hooks/useOwnerActions";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";

// 2026-09-03 (Casper canlıda buldu, kiralık-kafe vitrini): "İşletme Adı"
// kutusu seçiliyken esnaf tüm bir cümle yazdı ("işletme adım Konak Kafe,
// whatsapp numaram 0542...") — telefon numarası OLDUĞU GİBİ isim alanının
// içine yapıştı ("KONAK KAFE 05421802573"). Bu dosya `gonder()`'ın seçili-
// alan dalının artık kutuya YAZILDIĞI GİBİ değil, `temizlenmisSeciliDeger`
// üzerinden geçtiğini gerçek fonksiyon çağrısıyla doğrular.
const isletmeAdi = FIELD_BY_KEY.get("isletmeAdi")!;
const adres = FIELD_BY_KEY.get("adres")!;
const whatsapp = FIELD_BY_KEY.get("whatsapp")!;
const hakkindaMetin = FIELD_BY_KEY.get("hakkindaMetin")!;

describe("temizlenmisSeciliDeger — seçili kutu zengin cümleyi doğru ayırır", () => {
  it("Casper'ın gerçek örneği: isim kutusu whatsapp'ı yutmaz", () => {
    const cumle = "işletme adım Konak Kafe, whatsapp numaram 0542 180 25 73";
    expect(temizlenmisSeciliDeger(cumle, isletmeAdi)).toBe("Konak Kafe");
  });

  it("bonus'un zaten kapsadığı bir alan (whatsapp) seçiliyken kendi normalize edilmiş değeri kullanılır", () => {
    const cumle = "işletme adım Konak Kafe, whatsapp numaram 0542 180 25 73";
    expect(temizlenmisSeciliDeger(cumle, whatsapp)).toBe("905421802573");
  });

  it("adres kutusu seçiliyken de whatsapp'tan önce kesilir", () => {
    const cumle = "adresimiz Atatürk Cad. No:24 Kadıköy, whatsapp numaram 0542 180 25 73";
    expect(temizlenmisSeciliDeger(cumle, adres)).toBe("Atatürk Cad. No:24 Kadıköy");
  });

  it("cümlede başka bir alana dair ipucu yoksa metin OLDUĞU GİBİ kalır (uzun düz metin kırılmaz)", () => {
    const uzunMetin =
      "Ürünlerimizi elle üretiyoruz, kalite kontrolünden geçirdikten sonra özenle paketliyoruz.";
    expect(temizlenmisSeciliDeger(uzunMetin, hakkindaMetin)).toBe(uzunMetin);
  });

  it("seçili İşletme Adı yokken preview paragrafı adı kirletmez", () => {
    const cumle =
      "Merhaba, Kadıköy’de bir kuaförüm var. WhatsApp numaram 0532 123 45 67. " +
      "Hafta içi 09:00–19:00 arası açığız. Bahariye Cad. No:12’de hizmet veriyoruz.";
    expect(temizlenmisSeciliDeger(cumle, isletmeAdi)).toBeNull();
  });

  it("seçili alan bulunamadığında güvenli bonus alanlar kaybolmadan batch yoluna gider", () => {
    const kaynak = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/hooks/useOwnerActions.ts"),
      "utf8"
    );
    const baslangic = kaynak.indexOf("if (temiz === null)");
    const bitis = kaynak.indexOf("gonderilecek = temiz", baslangic);
    const blok = kaynak.slice(baslangic, bitis);
    expect(blok).toContain("await bonusAlanlariCikarVeKaydet");
    expect(blok).toContain("setKaydediliyor(true)");
    expect(blok).toContain("setKaydediliyor(false)");
    expect(blok).not.toContain('fetch("/api/owner-draft"');
  });

  it("gerçekten ayrıştırılamayan karışık cümlede null döner (abstain — ham metin yazılmaz)", () => {
    // İki farklı serbest-metin alanı aynı cümlede, ikisi de anahtar
    // kelimeyle işaretlenmemiş — güvenle ayıramayız.
    const cumle =
      "yirmi yıldır burada hizmet veriyoruz whatsapp numaram 0542 180 25 73 arayabilirsiniz";
    expect(temizlenmisSeciliDeger(cumle, hakkindaMetin)).toBeNull();
  });
});
