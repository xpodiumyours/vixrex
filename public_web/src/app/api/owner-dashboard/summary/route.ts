import { createClient } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";

type BootstrapSonucu = {
  has_store?: boolean;
  slug?: string;
  edit_token?: string;
};

type PremiumSonucu = {
  is_premium?: boolean;
  premium_expires_at?: string | null;
};

function hataYaniti(mesaj: string, durum: number) {
  return NextResponse.json({ hata: mesaj }, { status: durum });
}

export async function GET(request: NextRequest) {
  const authHeader = request.headers.get("authorization");
  const bearerToken = authHeader?.replace("Bearer ", "").trim();
  if (!bearerToken) {
    return hataYaniti("Oturum bulunamadı.", 401);
  }

  const supabaseUrl =
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "";
  const supabaseAnonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    "";

  if (!supabaseUrl || !supabaseAnonKey) {
    return hataYaniti("Sunucu yapılandırması eksik.", 500);
  }

  // Her üç RPC de sahipliği auth.uid() ve/veya sahibin edit token'ı ile
  // doğrular. Yönetici istemcisi auth.uid() bilgisini kaybeder; kullanılmaz.
  const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${bearerToken}` } },
  });

  const {
    data: { user },
    error: authError,
  } = await supabaseUser.auth.getUser(bearerToken);

  if (authError || !user || user.is_anonymous) {
    return hataYaniti("Oturum geçersiz.", 401);
  }

  const { data: durum, error: durumHatasi } = await supabaseUser.rpc(
    "bootstrap_owner_state"
  );

  if (durumHatasi) {
    console.error("[owner-dashboard/summary] vitrin hatası:", durumHatasi.message);
    return hataYaniti("Vitrin durumu alınamadı.", 500);
  }

  const sahiplik = (durum ?? {}) as BootstrapSonucu;
  const slug = (sahiplik.slug ?? "").trim();
  const editToken = (sahiplik.edit_token ?? "").trim();
  if (sahiplik.has_store !== true || !slug || !editToken) {
    return hataYaniti("Vitrin bulunamadı.", 404);
  }

  const [ziyaretYaniti, premiumYaniti] = await Promise.all([
    supabaseUser.rpc("get_today_vitrin_view_count", {
      p_slug: slug,
      p_edit_token: editToken,
    }),
    supabaseUser.rpc("get_store_premium_status", {
      p_slug: slug,
      p_edit_token: editToken,
    }),
  ]);

  if (ziyaretYaniti.error || premiumYaniti.error) {
    console.error(
      "[owner-dashboard/summary] ölçüm hatası:",
      ziyaretYaniti.error?.message ?? premiumYaniti.error?.message
    );
    return hataYaniti("Pano bilgileri alınamadı.", 500);
  }

  const ziyaretSayisi = Number(ziyaretYaniti.data);
  const premium = (premiumYaniti.data ?? {}) as PremiumSonucu;

  return NextResponse.json({
    tamam: true,
    slug,
    bugunkuZiyaret:
      Number.isFinite(ziyaretSayisi) && ziyaretSayisi >= 0 ? ziyaretSayisi : 0,
    premiumAktif: premium.is_premium === true,
    premiumBitis: premium.premium_expires_at ?? null,
  });
}
