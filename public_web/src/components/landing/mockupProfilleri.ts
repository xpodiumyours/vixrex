import { kategoriSablonHaritasi } from "@/lib/categoryTemplates";
import { kategoriUrlParcasi } from "@/lib/businessCategories";

/**
 * Hero telefon mockup'ındaki dört örnek profil — envanter §2.3.
 *
 * Adlar Flutter landing'deki tanıtım mockup'ıyla aynı tutuldu (ürün kararı,
 * 2026-08-26): bunlar bir vitrin vaadini gösteren reklam görselleridir.
 *
 * İKİ FARK var, ikisi de bilinçli:
 *   1. Görseller uydurma Unsplash bağlantılarından değil, GERÇEK şablon
 *      kütüphanesinden gelir (category_image_templates). Flutter'da bu
 *      eşleme bozuktu: 20 arayüz anahtarının 11'i veritabanındaki 19
 *      kanonik kimlikle eşleşmiyordu, o kartlar sessizce yedek görsele
 *      düşüyordu. Burada doğrudan kanonik kimlik kullanılıyor.
 *   2. Tıklama `/v/demo-*` demo vitrinine değil, o kategorinin Keşfet
 *      sayfasına gider. Demo vitrinler #345 ile aramadan çıkarılıyor;
 *      ana sayfadan oraya iç bağlantı vermek o bağlantıyı boşa harcardı.
 */

export type MockupProfili = {
  ad: string;
  kategoriSeridi: string;
  kategoriKimligi: string;
  kapakUrl: string | null;
  galeriUrlleri: string[];
  hedefUrl: string;
};

const TANIMLAR = [
  { ad: "Aymira Giyim", serit: "KADIN GİYİM / BUTİK", kimlik: "giyim" },
  { ad: "Lezzet Durağı", serit: "KAFE / RESTORAN", kimlik: "kafe_lokanta" },
  { ad: "Nova Kuaför", serit: "KUAFÖR / GÜZELLİK", kimlik: "kuafor" },
  { ad: "TeknoFix", serit: "TELEFON TEKNİK SERVİS", kimlik: "teknik_servis" },
] as const;

export async function mockupProfilleriniGetir(): Promise<MockupProfili[]> {
  const sablonlar = await kategoriSablonHaritasi();

  return TANIMLAR.map((tanim) => {
    const sablon = sablonlar.get(tanim.kimlik);
    return {
      ad: tanim.ad,
      kategoriSeridi: tanim.serit,
      kategoriKimligi: tanim.kimlik,
      kapakUrl: sablon?.kapaklar[0]?.url ?? null,
      galeriUrlleri: (sablon?.galeri ?? []).slice(0, 3).map((g) => g.url),
      hedefUrl: `/kesfet/${kategoriUrlParcasi(tanim.kimlik)}`,
    };
  });
}
