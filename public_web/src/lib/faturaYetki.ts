import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { verifyStoreEditToken } from "@/lib/instagramServer";

export type YetkiSonucu =
  | { tamam: true; storeId: string; slug: string }
  | { tamam: false; durum: 401 | 404; hata: string };

export async function sahipYetkisi(slug: string, editToken: string): Promise<YetkiSonucu> {
  if (!slug) return { tamam: false, durum: 404, hata: "Vitrin belirtilmedi." };

  const cookieStore = await cookies();
  const cerezliOturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (cerezliOturum) {
    return { tamam: true, storeId: cerezliOturum.storeId, slug: cerezliOturum.slug ?? slug };
  }

  if (!editToken) {
    return { tamam: false, durum: 401, hata: "Oturumun geçersiz veya süresi dolmuş." };
  }
  try {
    const store = await verifyStoreEditToken(slug, editToken);
    if (!store.id) return { tamam: false, durum: 404, hata: "Vitrin bulunamadı." };
    return { tamam: true, storeId: store.id, slug: store.slug ?? slug };
  } catch {
    return { tamam: false, durum: 401, hata: "Oturumun geçersiz veya süresi dolmuş." };
  }
}
