import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const bearerToken = request.headers
    .get("authorization")
    ?.replace(/^Bearer\s+/i, "")
    .trim();

  if (!slug || !bearerToken) {
    return NextResponse.json({ hata: "Oturum bilgisi eksik." }, { status: 401 });
  }

  const supabaseUrl =
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "";
  const supabaseAnonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    "";
  const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${bearerToken}` } },
  });

  const {
    data: { user },
    error: authError,
  } = await supabaseUser.auth.getUser(bearerToken);

  if (authError || !user || user.is_anonymous) {
    return NextResponse.json(
      { hata: "Google hesabı bağlanamadı. Lütfen tekrar dene." },
      { status: 401 },
    );
  }

  const cookieStore = await cookies();
  const ownerSession = verifyOwnerSession(
    cookieStore.get(OWNER_SESSION_COOKIE)?.value,
    slug,
  );
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Vitrin sahip oturumu bulunamadı. Vitrini yeniden açıp dene." },
      { status: 401 },
    );
  }

  // İmzalı çerezin yanında canlı owner_sessions kaydını da doğrula.
  const { error: oturumHatasi } = await supabaseUser.rpc("extend_owner_session", {
    p_session_token: ownerSession.sessionToken,
  });
  if (oturumHatasi) {
    return NextResponse.json(
      { hata: "Vitrin sahip oturumunun süresi dolmuş." },
      { status: 401 },
    );
  }

  const admin = getSupabaseAdmin();
  const { data: vitrin, error: vitrinHatasi } = await admin
    .from("stores")
    .select("edit_token, user_id")
    .eq("id", ownerSession.storeId)
    .eq("slug", slug)
    .maybeSingle();

  if (vitrinHatasi || !vitrin?.edit_token) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }
  if (vitrin.user_id === user.id) {
    return NextResponse.json({ tamam: true, slug });
  }
  if (vitrin.user_id) {
    return NextResponse.json(
      { hata: "Bu vitrin başka bir hesaba bağlı." },
      { status: 409 },
    );
  }

  const { data: sahiplikSonucu, error: sahiplikHatasi } =
    await supabaseUser.rpc("claim_store_for_user", {
      p_edit_token: vitrin.edit_token,
    });
  const tamam =
    !sahiplikHatasi &&
    typeof sahiplikSonucu === "object" &&
    sahiplikSonucu !== null &&
    (sahiplikSonucu as { ok?: unknown }).ok === true;

  if (!tamam) {
    const sebep =
      sahiplikHatasi?.message ??
      (sahiplikSonucu as { reason?: string } | null)?.reason ??
      "BILINMEYEN";
    const mesaj =
      sebep === "ALREADY_OWNS_STORE"
        ? "Bu Google hesabına zaten başka bir vitrin bağlı."
        : "Vitrin Google hesabına bağlanamadı. Lütfen tekrar dene.";
    return NextResponse.json({ hata: mesaj }, { status: 409 });
  }

  return NextResponse.json({ tamam: true, slug });
}
