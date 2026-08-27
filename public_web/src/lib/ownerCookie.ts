import { supabase } from "./supabase";

/**
 * Sahip oturum çerezi (HttpOnly) kurar.
 *
 * app/page.tsx'teki sahipOturumuAc fonksiyonunun ortak yardımcısı.
 * Blog-yonetim ve randevu-yonetim sayfaları da aynı zinciri kullanır.
 *
 * Zincir: Supabase Auth session → /api/owner-session/self → owner-session cookie
 *
 * @returns true = çerez kuruldu, false = kurulamadı (giriş gerekli)
 */
export async function sahipOturumuAc(): Promise<boolean> {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const token = session?.access_token;
  if (!token) return false;

  const res = await fetch("/api/owner-session/self", {
    method: "POST",
    headers: { authorization: `Bearer ${token}` },
  });
  if (!res.ok) return false;

  const sonuc = await res.json();
  if (!sonuc?.yonlendir) return false;

  await fetch(sonuc.yonlendir, { redirect: "manual" });
  return true;
}
