// VitrinViewTracker.tsx'ten çıkarıldı (Faz F, 2026-09-02) — tıklama/görüntüleme
// event'leri de aynı ziyaretçi anahtarını kullanmalı, kod üç yerde
// tekrarlanmasın.

const SESSION_KEY_STORAGE_KEY = "vixrex_visit_session";

export function ziyaretAnahtariniOkuyaUret(): string {
  try {
    const existing = window.localStorage.getItem(SESSION_KEY_STORAGE_KEY);
    if (existing && existing.length >= 16) return existing;
  } catch {
    // localStorage erişilemezse (gizli sekme, engellenmiş depolama) sorun
    // değil — aşağıda yeni bir anahtar üretilir, bu ziyaret yine sayılır.
  }

  const generated =
    typeof crypto !== "undefined" && "randomUUID" in crypto
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

  try {
    window.localStorage.setItem(SESSION_KEY_STORAGE_KEY, generated);
  } catch {
    // depolanamazsa sorun değil, bu ziyaret yine de sayılır — yalnız
    // ertesi gün aynı tarayıcıdan gelen ziyaret ayrı sayılabilir.
  }

  return generated;
}
