"use client";

import { supabase } from "@/lib/supabase";

export async function yorumDurumunuDegistir(id: string, mevcutDurum: string) {
  const yeniDurum = mevcutDurum === "hidden" ? "published" : "hidden";
  return supabase.rpc("set_product_comment_status", {
    p_comment_id: id,
    p_status: yeniDurum,
  });
}

/**
 * 2026-11-13 (AGENTS.md Kural 25 & 26):
 * Altyapısı/verisi hazır olmayan özellik ekrana basılmaz,
 * esnaf yönetim formunun tepesine analitik barikatı kurulamaz.
 * Bu bileşen ekranda yer işgal etmez.
 */
export function OwnerDashboardMetrics() {
  return null;
}
