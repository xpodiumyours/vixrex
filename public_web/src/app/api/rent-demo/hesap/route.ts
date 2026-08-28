import { createClient } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";

type KiralamaSonucu = {
  ok?: boolean;
  reason?: string;
  slug?: string;
  retry_after?: number;
};

function hataYaniti(mesaj: string, durum: number) {
  return NextResponse.json({ hata: mesaj }, { status: durum });
}

export async function POST(request: NextRequest) {
  const authHeader = request.headers.get("authorization");
  const bearerToken = authHeader?.replace("Bearer ", "").trim();
  if (!bearerToken) {
    return hataYaniti("Oturum bulunamadı.", 401);
  }

  let body: { slug?: unknown };
  try {
    body = await request.json();
  } catch {
    return hataYaniti("Geçersiz istek.", 400);
  }

  const sourceSlug = typeof body.slug === "string" ? body.slug.trim() : "";
  if (!sourceSlug) {
    return hataYaniti("Kiralama isteğinde vitrin bilgisi eksik.", 400);
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

  // RPC yetkiyi auth.uid() üzerinden kurar. Bu yüzden yönetici istemcisi
  // değil, çağıranın erişim jetonunu taşıyan anonim anahtarlı istemci gerekir.
  const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${bearerToken}` } },
  });

  const {
    data: { user },
    error: authError,
  } = await supabaseUser.auth.getUser(bearerToken);

  if (authError || !user) {
    return hataYaniti("Oturum geçersiz.", 401);
  }

  const { data, error } = await supabaseUser.rpc("rent_demo_for_account", {
    p_source_slug: sourceSlug,
  });

  if (error) {
    console.error("[rent-demo/hesap] kiralama hatası:", error.message);
    return hataYaniti("Şu anda kiralanamıyor.", 500);
  }

  const sonuc = (data ?? {}) as KiralamaSonucu;
  const slug = (sonuc.slug ?? "").trim();

  switch (sonuc.reason) {
    case "RENTED":
      if (!slug) return hataYaniti("Şu anda kiralanamıyor.", 500);
      return NextResponse.json({ tamam: true, slug });
    case "ALREADY_OWNS_STORE":
      return NextResponse.json(
        { tamam: false, sebep: "ALREADY_OWNS_STORE", slug },
        { status: 409 }
      );
    case "ANONYMOUS_SESSION":
      return hataYaniti("Bu işlem için kalıcı hesabınla giriş yapmalısın.", 401);
    case "RATE_LIMITED":
      return NextResponse.json(
        {
          hata: "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar dene.",
          retryAfter: sonuc.retry_after,
        },
        { status: 429 }
      );
    case "SOURCE_NOT_FOUND":
      return hataYaniti("Bu şablon artık kiralık değil.", 404);
    case "SLUG_GENERATION_FAILED":
    default:
      return hataYaniti("Şu anda kiralanamıyor.", 500);
  }
}
