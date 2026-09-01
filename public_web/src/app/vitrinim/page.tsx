import Link from "next/link";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { PUBLIC_STORE_SELECT } from "@/lib/publicStoreSelect";
import { VitrinimClient } from "./VitrinimClient";

export const dynamic = "force-dynamic";
export const metadata = { robots: { index: false, follow: false } };

function cookieSlug(token: string | undefined): string {
  if (!token) return "";
  try {
    const payload = token.split(".")[0];
    const decoded = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as {
      slug?: unknown;
    };
    return typeof decoded.slug === "string" ? decoded.slug : "";
  } catch {
    return "";
  }
}

export default async function VitrinimPage() {
  const cookieStore = await cookies();
  const ownerCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerCookie, cookieSlug(ownerCookie));
  if (!ownerSession) redirect("/app");

  const admin = getSupabaseAdmin();
  const [draftResult, storeResult, productsResult, categoriesResult] = await Promise.all([
    admin.rpc("get_working_draft_for_session", { p_session_token: ownerSession.sessionToken }),
    admin.from("stores").select(`${PUBLIC_STORE_SELECT},updated_at`).eq("id", ownerSession.storeId).eq("slug", ownerSession.slug).maybeSingle(),
    admin.from("products").select("id, slug, name, description, price_text, image_urls, category_id, stock_status, product_categories(name)").eq("store_id", ownerSession.storeId),
    admin.from("product_categories").select("id, name").eq("store_id", ownerSession.storeId),
  ]);

  if (draftResult.error || !draftResult.data || storeResult.error || !storeResult.data || productsResult.error || categoriesResult.error) {
    return (
      <main className="owner-shell flex items-center justify-center px-4">
        <section className="owner-card max-w-md p-6 text-center">
          <h1 className="text-xl font-bold text-[var(--owner-text)]">Vitrin yüklenemedi</h1>
          <p className="mt-2 text-sm text-[var(--owner-muted)]">Sahip oturumunu yeniden açıp tekrar deneyin.</p>
          <Link href={`/v/${ownerSession.slug}`} className="owner-button-primary mt-5 inline-flex">Vitrine dön</Link>
        </section>
      </main>
    );
  }

  const draftPayload = draftResult.data as { draft_data?: Record<string, unknown> };
  return (
    <VitrinimClient
      store={{ ...storeResult.data, products: productsResult.data ?? [], product_categories: categoriesResult.data ?? [] }}
      initialDraft={draftPayload.draft_data ?? storeResult.data}
    />
  );
}
