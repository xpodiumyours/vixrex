import { createClient } from "@supabase/supabase-js";
import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { getAppUrl } from "@/lib/siteUrl";

export const dynamic = "force-dynamic";

function noStoreJson(body: Record<string, unknown>, status = 200) {
  const response = NextResponse.json(body, { status });
  response.headers.set("Cache-Control", "private, no-store, max-age=0");
  response.headers.set("Pragma", "no-cache");
  return response;
}

/**
 * vixrex.com -> Flutter Web uygulama oturum köprüsü.
 *
 * Mevcut access/refresh token'ı başka origin'e taşımıyoruz. İstek yapan
 * kullanıcının Supabase oturumunu önce Auth sunucusunda doğrulayıp aynı kullanıcı
 * için tek kullanımlık magic-link üretiyoruz. Tarayıcı Supabase action_link'ini
 * tüketince Flutter origin'inde yeni bir Supabase oturumu kurulur.
 */
export async function POST(request: NextRequest) {
  const authHeader = request.headers.get("authorization") ?? "";
  const bearerToken = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length).trim()
    : "";

  if (!bearerToken) {
    return noStoreJson({ hata: "Oturum bulunamadı." }, 401);
  }

  const supabaseUrl = (
    process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || ""
  ).trim();
  const supabaseKey = (
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    ""
  ).trim();

  if (!supabaseUrl || !supabaseKey) {
    return noStoreJson({ hata: "Sunucu yapılandırması eksik." }, 500);
  }

  // Kullanıcıya özgü istemci request içinde kurulur; istekler arasında session
  // state'i paylaşılmaz.
  const userClient = createClient(supabaseUrl, supabaseKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${bearerToken}` } },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(bearerToken);

  if (userError || !user || user.is_anonymous) {
    return noStoreJson({ hata: "Kalıcı kullanıcı oturumu doğrulanamadı." }, 401);
  }

  const email = user.email?.trim() ?? "";
  if (!email) {
    return noStoreJson({ hata: "Hesabın e-posta adresi bulunamadı." }, 409);
  }

  const appTarget = `${getAppUrl()}/app`;
  const { data: linkData, error: linkError } =
    await getSupabaseAdmin().auth.admin.generateLink({
      type: "magiclink",
      email,
      options: { redirectTo: appTarget },
    });

  if (linkError || !linkData?.properties?.action_link || !linkData.user) {
    console.error("[app-handoff] magic link üretilemedi", linkError?.message);
    return noStoreJson({ hata: "Uygulama oturumu hazırlanamadı." }, 500);
  }

  // E-posta eşleşmesi tek başına yetmez. Admin generateLink'in ürettiği bağlantı
  // doğruladığımız Supabase kullanıcısına ait değilse köprüyü kesin olarak kes.
  if (linkData.user.id !== user.id) {
    console.error("[app-handoff] kullanıcı kimliği eşleşmedi");
    return noStoreJson({ hata: "Uygulama oturumu doğrulanamadı." }, 409);
  }

  const actionLink = linkData.properties.action_link;
  try {
    const actionUrl = new URL(actionLink);
    const projectUrl = new URL(supabaseUrl);
    if (actionUrl.origin !== projectUrl.origin) {
      return noStoreJson({ hata: "Geçiş bağlantısı doğrulanamadı." }, 500);
    }
  } catch {
    return noStoreJson({ hata: "Geçiş bağlantısı doğrulanamadı." }, 500);
  }

  return noStoreJson({ yonlendir: actionLink });
}
