import { readdirSync, readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const landingDizini = resolve(__dirname, "../src/components/landing");
const siteDizini = resolve(__dirname, "../src/components/site");

function dizinKaynagi(dizin: string): string {
  return readdirSync(dizin)
    .filter((ad) => ad.endsWith(".tsx") || ad.endsWith(".ts"))
    .map((ad) => readFileSync(resolve(dizin, ad), "utf-8"))
    .join("\n");
}

const kaynak = dizinKaynagi(landingDizini) + "\n" + dizinKaynagi(siteDizini);

/**
 * Landing port metin sözleşmesi (#344, 2026-08-26).
 *
 * Ana sayfanın metinleri Flutter landing'inden çıkarılan envantere göre
 * birebir taşındı (docs/research/landing-port-envanteri-2026-08-25.md §2).
 * İki yüzey aynı vaadi farklı cümlelerle anlatmaya başlarsa hangisinin
 * doğru olduğu belirsizleşir; bu test o kaymayı yakalar.
 *
 * Kesme işaretlerine dikkat: envanterde U+2019 (') kullanılıyor, düz
 * tırnak (') değil.
 */
const ZORUNLU_METINLER = [
  // §2.1 üst gezinme
  "Vitrinleri Keşfet",
  "Giriş Yap",
  // §2.2 hero
  "VİXREX ASİSTAN İLE DİJİTAL VİTRİN",
  "Vixrex Asistan",
  "birkaç dakikada hazır",
  "Ücretsiz Vitrinimi Hazırla",
  "SSL Güvenli Koruma",
  "Kredi kartı gerekmez",
  "Komisyon yok",
  "Link ve QR hazır",
  // §2.4 değer bandı
  "Müşterin ihtiyaç duyduğu her bilgiye tek linkten ulaşsın",
  "Google İşletme",
  // §2.5 özellik kartları
  "Dijital vitrinini kolayca hazırla",
  "Dakikalar içinde yayına alın",
  "Müşteriler size doğrudan ulaşsın",
  "Her kanalda aynı vitrini paylaşın",
  "Bilgilerini panelden güncelle",
  // §2.6 karşılaştırma
  "Dijital vitrinin için gerekenler tek yerde",
  "Ayrı ayrı kurulum",
  "Vixrex ile",
  "Tek panel, tek link, doğrudan iletişim",
  // §2.7 güven bandı
  "Başlarken sürpriz yok",
  "Satıştan komisyon alınmaz",
  "Kodsuz kurulum",
  // §2.8 adımlar
  "Üç adımda dijital vitrinin hazır",
  "Vitrininizi kurun",
  "Yayınla",
  "Müşterilerinize duyurun",
  // §2.9 şablon kataloğu
  "HAZIR ŞABLONLAR",
  "İşletme Kategorine Özel Hazır Görseller",
  "Hazır görseller →",
  // §2.10 alt CTA
  "İşletmenizi tek linkte müşterilerinizle buluşturun",
  "Vixrex Oluştur",
  // §2.11 altbilgi
  "VIXREX",
  "İşletmenizin paylaşılabilir dijital vitrini",
];

describe("landing port — envanterdeki metinler yerinde", () => {
  for (const metin of ZORUNLU_METINLER) {
    it(`"${metin}" sayfada geçiyor`, () => {
      expect(kaynak).toContain(metin);
    });
  }

  it("kesme işaretleri U+2019 — düz tırnak kullanılmamış", () => {
    expect(kaynak).toContain("Vixrex’e");
    expect(kaynak).toContain("Vixrex’ini");
    expect(kaynak).not.toContain("Vixrex'e ekle");
  });

  it("2026-08-22'de kaldırılan emoji önekleri geri gelmemiş", () => {
    for (const emoji of ["🔒", "💳", "🎯", "🔗", "✅"]) {
      expect(kaynak).not.toContain(emoji);
    }
  });

  it("kategori sayısı tek kaynaktan gelir, metne gömülmez", () => {
    // Flutter'da başlıkta "12 farklı kategoride" yazıyor ama 20 kart
    // çiziliyordu; veritabanında ise 19 kanonik kimlik var. Sayı artık
    // BUSINESS_CATEGORIES.length'ten okunur.
    expect(kaynak).toContain("{kategoriSayisi} farklı kategoride");
    expect(kaynak).not.toContain("12 farklı kategoride");
  });
});
