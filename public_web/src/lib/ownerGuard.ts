import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

export async function sahipDogrula(
  slug: string
): Promise<{ ok: boolean; error?: string }> {
  const cookieStore = await cookies();
  const oturum = verifyOwnerSession(
    cookieStore.get(OWNER_SESSION_COOKIE)?.value,
    slug
  );
  if (!oturum) {
    return { ok: false, error: "Oturumun geçersiz veya süresi dolmuş." };
  }
  return { ok: true };
}
