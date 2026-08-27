import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { revalidateTag } from "next/cache";
import { NextResponse, type NextRequest } from "next/server";
import { OWNER_SESSION_COOKIE } from "@/lib/ownerSession";

export const dynamic = "force-dynamic";

type KimlikSonucu =
  | { ok: true; client: SupabaseClient }
  | { ok: false; response: NextResponse };

function kullaniciIstemcisi(token: string): SupabaseClient | null {
  const url =
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "";
  const anonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    "";
  if (!url || !anonKey) return null;

  return createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
}

async function kimlikDogrula(request: NextRequest): Promise<KimlikSonucu> {
  const authHeader = request.headers.get("authorization") ?? "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length).trim()
    : "";
  if (!token) {
    return {
      ok: false,
      response: NextResponse.json({ hata: "Oturum bulunamadı." }, { status: 401 }),
    };
  }

  const client = kullaniciIstemcisi(token);
  if (!client) {
    return {
      ok: false,
      response: NextResponse.json(
        { hata: "Sunucu yapılandırması eksik." },
        { status: 500 }
      ),
    };
  }

  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) {
    return {
      ok: false,
      response: NextResponse.json({ hata: "Oturum geçersiz." }, { status: 401 }),
    };
  }
  return { ok: true, client };
}

async function govdeOku(request: NextRequest) {
  try {
    return (await request.json()) as Record<string, unknown>;
  } catch {
    return null;
  }
}

function vitrinOnbelleginiTemizle(slug: string) {
  for (const tag of [
    `store-${slug}`,
    `products-${slug}`,
    "kesfet",
    "sitemap",
  ]) {
    revalidateTag(tag, { expire: 0 });
  }
}

function sahipCereziniSil(response: NextResponse) {
  response.cookies.set(OWNER_SESSION_COOKIE, "", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 0,
  });
  return response;
}

export async function PATCH(request: NextRequest) {
  const govde = await govdeOku(request);
  const slug = typeof govde?.slug === "string" ? govde.slug.trim() : "";
  if (!govde || !slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }

  const kimlik = await kimlikDogrula(request);
  if (!kimlik.ok) return kimlik.response;

  const { error } = await kimlik.client.rpc(
    "withdraw_store_publication_consent",
    { p_slug: slug, p_edit_token: "" }
  );
  if (error) {
    console.error("[account] unpublish failed:", error.message);
    return NextResponse.json(
      { hata: "Vitrin yayından kaldırılamadı." },
      { status: error.message === "STORE_UPDATE_NOT_ALLOWED" ? 403 : 500 }
    );
  }

  vitrinOnbelleginiTemizle(slug);
  return NextResponse.json({ tamam: true });
}

export async function DELETE(request: NextRequest) {
  const govde = await govdeOku(request);
  if (!govde) {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const target = govde.target;
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const confirmation =
    typeof govde.confirmation === "string" ? govde.confirmation.trim() : "";
  if ((target !== "store" && target !== "account") || confirmation !== "SİL") {
    return NextResponse.json(
      { hata: "Onaylamak için tam olarak SİL yazın." },
      { status: 422 }
    );
  }
  if (target === "store" && !slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }

  const kimlik = await kimlikDogrula(request);
  if (!kimlik.ok) return kimlik.response;

  const { error } =
    target === "store"
      ? await kimlik.client.rpc("delete_store_with_token", {
          p_slug: slug,
          p_edit_token: "",
        })
      : await kimlik.client.rpc("delete_user_account");
  if (error) {
    console.error(`[account] ${target} delete failed:`, error.message);
    return NextResponse.json(
      {
        hata:
          target === "store"
            ? "Vitrin silinemedi."
            : "Hesap silinemedi.",
      },
      {
        status:
          error.message === "STORE_DELETE_NOT_ALLOWED" ? 403 : 500,
      }
    );
  }

  if (slug) vitrinOnbelleginiTemizle(slug);
  return sahipCereziniSil(NextResponse.json({ tamam: true }));
}
