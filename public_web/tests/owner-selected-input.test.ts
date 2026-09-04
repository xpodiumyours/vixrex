import { describe, expect, it } from "vitest";
import { serbestMetindenAlanlariCikar } from "@/lib/serbestMetinCikarim";
import { VIXREX_NIYET_SOZLUGU } from "@/lib/vixrexNiyetSozlugu";
import { extractVixrexValue } from "@/lib/vixrexValueExtractor";
import { seciliKimlikTelefonKestirmesiniCikar } from "@/lib/ownerSelectedInput";

const isletme = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "isletmeAdi")!;
const whatsapp = VIXREX_NIYET_SOZLUGU.find((a) => a.anahtar === "whatsapp")!;

describe("seçili işletme adı + sondaki telefon", () => {
  const gercekGirdi = "Çarşı teknik servis 05421702573";

  it("seçili İşletme Adı bağlamında ana metni işletme adı olarak ayırır", () => {
    expect(seciliKimlikTelefonKestirmesiniCikar(gercekGirdi)).toEqual({
      anaDeger: "Çarşı teknik servis",
    });
    expect(extractVixrexValue(gercekGirdi, isletme)).toBe("Çarşı teknik servis");
    expect(extractVixrexValue(gercekGirdi, whatsapp)).toBe("05421702573");
  });

  it("genel bonus çıkarıcı aynı metni kategori/adres diye yanlış dağıtmaz", () => {
    const sonuc = serbestMetindenAlanlariCikar(gercekGirdi);
    expect(sonuc.whatsapp).toBe("905421702573");
    expect(sonuc.kategoriEtiketi).toBeUndefined();
    expect(sonuc.adres).toBeUndefined();
  });

  it("açıkça etiketlenmiş mevcut zengin cümle davranışına müdahale etmez", () => {
    const klasik = "işletme adım Konak Kafe, whatsapp numaram 0542 180 25 73";
    expect(seciliKimlikTelefonKestirmesiniCikar(klasik)).toBeNull();
    expect(extractVixrexValue(klasik, isletme)).toBe("Konak Kafe");
    expect(extractVixrexValue(klasik, whatsapp)).toBe("0542 180 25 73");
  });

  it("telefonla biten normal uzun paragrafı kimlik cevabı sanmaz", () => {
    const paragraf =
      "Beşiktaş'ta küçük bir kafemiz var, İhlamurdere Cad. No:5'te. " +
      "Her gün 08:00 - 23:00 arası açığız. Rezervasyon için 0533 987 65 43.";

    expect(seciliKimlikTelefonKestirmesiniCikar(paragraf)).toBeNull();
    const sonuc = serbestMetindenAlanlariCikar(paragraf);
    expect(sonuc.kategoriEtiketi).toBe("Kafe / Lokanta");
    expect(sonuc.calismaSaatleriMetni).toBe("08:00 - 23:00");
    expect(sonuc.whatsapp).toBe("905339876543");
    expect(sonuc.adres).toContain("İhlamurdere Cad");
  });
});
