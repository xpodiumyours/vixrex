/**
 * Kategoriye özel müşteri yüzü metinleri (public vitrin shell).
 * sectionTitle / ctaLabel → vitrinProfile.ts
 */

export type CategoryCopy = {
  connectTitle: string;
  atmosphereTitle: string;
  storyTitle: string;
  emptyFeed: string;
  feedIntro: string;
  defaultBio: (name: string) => string;
  whatsappButton: string;
};

const COPY: Record<string, CategoryCopy> = {
  giyim: {
    connectTitle: "Bize ulaşın",
    atmosphereTitle: "Mağazanın hali",
    storyTitle: "Hikâyemiz",
    emptyFeed: "Henüz ürün eklenmedi.",
    feedIntro: "Yeni sezon ve seçkiler.",
    defaultBio: (name) => `${name} — yeni sezon ve koleksiyon.`,
    whatsappButton: "Ürün sor",
  },
  butik: {
    connectTitle: "Bize ulaşın",
    atmosphereTitle: "Atölye / mağaza",
    storyTitle: "Hikâyemiz",
    emptyFeed: "Henüz ürün eklenmedi.",
    feedIntro: "Özel tasarımlar ve seçkiler.",
    defaultBio: (name) => `${name} — özel tasarımlar.`,
    whatsappButton: "Ürün sor",
  },
  gida: {
    connectTitle: "Sipariş & konum",
    atmosphereTitle: "Tezgâh",
    storyTitle: "Hikâyemiz",
    emptyFeed: "Henüz ürün eklenmedi.",
    feedIntro: "Taze ürünler — sipariş için yazın.",
    defaultBio: (name) => `${name} — taze ürünler, sipariş ve konum.`,
    whatsappButton: "Sipariş sor",
  },
  firin: {
    connectTitle: "Sipariş & konum",
    atmosphereTitle: "Fırından",
    storyTitle: "Hikâyemiz",
    emptyFeed: "Bugün için ürün yok.",
    feedIntro: "Günün taze ürünleri.",
    defaultBio: (name) => `${name} — günlük taze ürünler.`,
    whatsappButton: "Sipariş sor",
  },
  kozmetik: {
    connectTitle: "Bilgi & randevu",
    atmosphereTitle: "Mağaza",
    storyTitle: "Hikâyemiz",
    emptyFeed: "Henüz ürün eklenmedi.",
    feedIntro: "Ürünler ve bakım seçimleri.",
    defaultBio: (name) => `${name} — ürünler ve bakım.`,
    whatsappButton: "Bilgi al",
  },
  dekorasyon: {
    connectTitle: "Teklif & konum",
    atmosphereTitle: "Showroom",
    storyTitle: "Hikâyemiz",
    emptyFeed: "Henüz ürün eklenmedi.",
    feedIntro: "Koleksiyon ve teklif.",
    defaultBio: (name) => `${name} — koleksiyon ve teklif.`,
    whatsappButton: "Teklif iste",
  },
  elektronik: {
    connectTitle: "Ürün sor & konum",
    atmosphereTitle: "Mağaza",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz ürün eklenmedi.",
    feedIntro: "Ürünler ve destek.",
    defaultBio: (name) => `${name} — ürünler ve destek.`,
    whatsappButton: "Ürün sor",
  },
  kirtasiye: {
    connectTitle: "Bize ulaşın",
    atmosphereTitle: "Mağaza",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz ürün eklenmedi.",
    feedIntro: "Ürünler ve konum.",
    defaultBio: (name) => `${name} — ürünler ve konum.`,
    whatsappButton: "Ürün sor",
  },
  diger: {
    connectTitle: "Bize ulaşın",
    atmosphereTitle: "Vitrin",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz içerik eklenmedi.",
    feedIntro: "Öne çıkanlar.",
    defaultBio: (name) => `${name} — iletişim ve konum.`,
    whatsappButton: "Bilgi al",
  },
  kuafor: {
    connectTitle: "Randevu & iletişim",
    atmosphereTitle: "Salon",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz hizmet kartı yok. WhatsApp veya randevu ile devam edin.",
    feedIntro: "Hizmetleri inceleyin — WhatsApp veya randevu ile ilerleyin.",
    defaultBio: (name) => `${name} — randevu ve iletişim.`,
    whatsappButton: "Randevu sor",
  },
  pet_shop_veteriner: {
    connectTitle: "Randevu & iletişim",
    atmosphereTitle: "Klinik / dükkan",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz hizmet kartı yok.",
    feedIntro: "Hizmetler — randevu veya bilgi için yazın.",
    defaultBio: (name) => `${name} — randevu ve bilgi.`,
    whatsappButton: "Bilgi al",
  },
  teknik_servis: {
    connectTitle: "Servis talebi",
    atmosphereTitle: "Atölye",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz hizmet kartı yok.",
    feedIntro: "Servis seçenekleri — talep için yazın.",
    defaultBio: (name) => `${name} — servis ve randevu.`,
    whatsappButton: "Servis talebi",
  },
  hizmet_danismanlik: {
    connectTitle: "İletişim",
    atmosphereTitle: "Çalışma alanı",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz hizmet kartı yok.",
    feedIntro: "Hizmetler — görüşme için yazın.",
    defaultBio: (name) => `${name} — danışmanlık ve randevu.`,
    whatsappButton: "Bilgi al",
  },
  egitim_ders: {
    connectTitle: "Kayıt & iletişim",
    atmosphereTitle: "Ortam",
    storyTitle: "Program hakkında",
    emptyFeed: "Henüz program eklenmedi.",
    feedIntro: "Programlar — kayıt için yazın.",
    defaultBio: (name) => `${name} — programlar ve kayıt.`,
    whatsappButton: "Bilgi al",
  },
  ev_temizlik: {
    connectTitle: "Teklif & iletişim",
    atmosphereTitle: "Hizmet",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz hizmet kartı yok.",
    feedIntro: "Hizmetler — teklif için yazın.",
    defaultBio: (name) => `${name} — teklif ve randevu.`,
    whatsappButton: "Teklif iste",
  },
  spor_fitness: {
    connectTitle: "Üyelik & randevu",
    atmosphereTitle: "Salon",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz program eklenmedi.",
    feedIntro: "Programlar — üyelik veya randevu için yazın.",
    defaultBio: (name) => `${name} — programlar ve randevu.`,
    whatsappButton: "Bilgi al",
  },
  saglik_yasam: {
    connectTitle: "Randevu & iletişim",
    atmosphereTitle: "Klinik",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz hizmet kartı yok.",
    feedIntro: "Hizmetler — randevu için yazın.",
    defaultBio: (name) => `${name} — randevu ve iletişim.`,
    whatsappButton: "Bilgi al",
  },
  oto_arac: {
    connectTitle: "Randevu & iletişim",
    atmosphereTitle: "Servis",
    storyTitle: "Hakkımızda",
    emptyFeed: "Henüz hizmet kartı yok.",
    feedIntro: "Hizmetler — randevu için yazın.",
    defaultBio: (name) => `${name} — randevu ve servis.`,
    whatsappButton: "Randevu sor",
  },
  kafe_lokanta: {
    connectTitle: "Rezervasyon & konum",
    atmosphereTitle: "Mekân",
    storyTitle: "Hikâyemiz",
    emptyFeed: "Menü henüz eklenmedi. WhatsApp ile sorabilirsiniz.",
    feedIntro: "Menü ve bugünün seçimleri.",
    defaultBio: (name) => `${name} — menü, rezervasyon ve konum.`,
    whatsappButton: "Sipariş / rezervasyon",
  },
};

export function getVitrinCopy(categoryId: string): CategoryCopy {
  return COPY[categoryId] ?? COPY.diger;
}

/** Görünen adres tekrarı (Mahallesi Mah.) — DB değiştirmez */
export function normalizeAddressDisplay(address: string | null | undefined): string | null {
  if (!address) return null;
  const cleaned = address
    .replace(/\bMahallesi\s+Mah\.?\b/gi, "Mahallesi")
    .replace(/\bMah\.?\s+Mahallesi\b/gi, "Mahallesi")
    .replace(/\s{2,}/g, " ")
    .trim();
  return cleaned || null;
}
