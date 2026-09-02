import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { serbestMetindenAlanlariCikar } from "../src/lib/serbestMetinCikarim";

describe("serbestMetindenAlanlariCikar — karışık gerçekçi paragraflar", () => {
  it("WhatsApp + saat + ilçe + kategori + adres bir arada geçen paragraftan hepsini çıkarır", () => {
    const sonuc = serbestMetindenAlanlariCikar(
      "Merhaba, Kadıköy'de bir kuaförüm var. WhatsApp'tan 0532 123 45 67 " +
        "numaramdan ulaşabilirsiniz. Hafta içi 09:00 - 19:00 arası açığız. " +
        "Bahariye Cad. No:12'de hizmet veriyoruz."
    );
    expect(sonuc.whatsapp).toBe("905321234567");
    expect(sonuc.kategoriEtiketi).toBe("Kuaför");
    expect(sonuc.calismaSaatleriMetni).toBe("09:00 - 19:00");
    expect(sonuc.ilAdi).toBe("İstanbul");
    expect(sonuc.ilceAdi).toBe("Kadıköy");
    expect(sonuc.adres).toContain("Bahariye Cad");
    expect(sonuc.adres).toContain("No:12");
  });

  it("telefon yoksa yalnız o alan boş kalır, geri kalanı yine çıkar", () => {
    const sonuc = serbestMetindenAlanlariCikar(
      "Kadıköy'de bir kuaförüm var, hafta içi 09:00 - 19:00 arası açığız."
    );
    expect(sonuc.whatsapp).toBeUndefined();
    expect(sonuc.kategoriEtiketi).toBe("Kuaför");
    expect(sonuc.calismaSaatleriMetni).toBe("09:00 - 19:00");
  });

  it.each([
    ["0532 123 45 67"],
    ["+90 532 123 45 67"],
    ["532-123-45-67"],
    ["05321234567"],
  ])("telefon yazım biçimi %s her zaman aynı normalize sonucu verir", (yazim) => {
    const sonuc = serbestMetindenAlanlariCikar(`WhatsApp numaramız ${yazim}.`);
    expect(sonuc.whatsapp).toBe("905321234567");
  });

  it("il belirtilmeden belirsiz bir ilçe geçerse il/ilçe boş kalır — tahmin yok", () => {
    const sonuc = serbestMetindenAlanlariCikar("Kemer'de küçük bir kırtasiyem var.");
    expect(sonuc.ilAdi).toBeUndefined();
    expect(sonuc.ilceAdi).toBeUndefined();
  });

  it("net bir kategori kelimesi yoksa kategoriEtiketi boş kalır", () => {
    const sonuc = serbestMetindenAlanlariCikar("Merhaba, ben Furkan, sizi bekleriz.");
    expect(sonuc.kategoriEtiketi).toBeUndefined();
  });

  it("hiçbir cümle isAddressValid'i geçmezse adres boş kalır — tahmin yok", () => {
    const sonuc = serbestMetindenAlanlariCikar(
      "Merkezde küçük bir dükkanım var, herkes bilir, kolayca bulunur."
    );
    expect(sonuc.adres).toBeUndefined();
  });

  it("telefon numarası tek başına adres olarak yanlış eşleşmez", () => {
    const sonuc = serbestMetindenAlanlariCikar("WhatsApp'tan 0532 123 45 67 numaramızdan ulaşın.");
    expect(sonuc.adres).toBeUndefined();
  });

  it("yapısal güvence: kaynak dosyasında işletme-adı alanının kolonu ('name') hiç geçmez", () => {
    const kaynak = readFileSync(
      resolve(__dirname, "../src/lib/serbestMetinCikarim.ts"),
      "utf8"
    );
    // vitrinFieldSchema.ts'te isletmeAdi alanının kolonu "name" — bu motor
    // gerçek işletme kimliğini asla tahmin etmediği için ne VITRIN_FIELDS'in
    // "isletmeAdi" anahtarını ne de "name" kolonunu hiç referans eder.
    expect(kaynak).not.toContain("isletmeAdi");
    expect(kaynak.toLowerCase()).not.toMatch(/\bname\b/);
  });

  it("kafe işletmesi — farklı kategori/adres/saat kombinasyonuyla doğrular", () => {
    const sonuc = serbestMetindenAlanlariCikar(
      "Beşiktaş'ta küçük bir kafemiz var, İhlamurdere Cad. No:5'te. " +
        "Her gün 08:00 - 23:00 arası açığız. Rezervasyon için 0533 987 65 43."
    );
    expect(sonuc.kategoriEtiketi).toBe("Kafe / Lokanta");
    expect(sonuc.ilAdi).toBe("İstanbul");
    expect(sonuc.ilceAdi).toBe("Beşiktaş");
    expect(sonuc.calismaSaatleriMetni).toBe("08:00 - 23:00");
    expect(sonuc.whatsapp).toBe("905339876543");
    expect(sonuc.adres).toContain("İhlamurdere Cad");
  });

  it("oto tamir işletmesi — kategori sözlüğünde 'oto'/'araç' takma adları üzerinden çözülür", () => {
    const sonuc = serbestMetindenAlanlariCikar(
      "Ankara Çankaya'da oto tamir servisiyiz, hafta içi 09:00 - 18:00 açığız."
    );
    expect(sonuc.kategoriEtiketi).toBeDefined();
    expect(sonuc.ilAdi).toBe("Ankara");
    expect(sonuc.ilceAdi).toBe("Çankaya");
    expect(sonuc.calismaSaatleriMetni).toBe("09:00 - 18:00");
  });

  it("dönüş tipi işletme adı için hiçbir alan tanımlamaz", () => {
    const sonuc = serbestMetindenAlanlariCikar(
      "Ben Furkan, Kadıköy'de kuaförüm, WhatsApp 0532 123 45 67."
    );
    expect(Object.keys(sonuc)).not.toContain("isletmeAdi");
    expect(Object.keys(sonuc)).not.toContain("name");
  });
});
