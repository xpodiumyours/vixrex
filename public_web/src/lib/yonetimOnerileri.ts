// Faz E (Tek Asistan planı, 2026-09-02) — yönetim modu: "bugün ilgilenmen
// gereken en önemli şey". Yayınlanmış bir vitrin için kural tabanlı öneri
// üretir. API maliyeti yok — mevcut alanlardan hesaplanır.

export interface YonetimOnerisi {
  id: string;
  mesaj: string;
}

export function yonetimOnerileriUret(
  draft: Record<string, unknown>,
  urunFiyatsizSayisi: number,
  urunAciklamasizSayisi: number
): YonetimOnerisi[] {
  const oneriler: YonetimOnerisi[] = [];

  if (urunFiyatsizSayisi > 0) {
    oneriler.push({
      id: "urun_fiyat",
      mesaj: `${urunFiyatsizSayisi} ürününde fiyat yok. Fiyatları tamamlayalım mı?`,
    });
  }

  if (!String(draft.working_hours ?? "").trim()) {
    oneriler.push({
      id: "calisma_saatleri",
      mesaj: "Çalışma saatlerin bulunmuyor. Google'dan gelen müşteriler için bunu eklemeni öneririm.",
    });
  }

  if (!String(draft.logo_url ?? "").trim()) {
    oneriler.push({
      id: "logo",
      mesaj: "Logon henüz yok. Eklersen vitrinin daha güvenilir görünür.",
    });
  }

  if (urunAciklamasizSayisi >= 3) {
    oneriler.push({
      id: "urun_aciklama",
      mesaj: `${urunAciklamasizSayisi} ürününün açıklaması boş. Önce bunları tamamlamanı öneririm.`,
    });
  }

  return oneriler;
}
