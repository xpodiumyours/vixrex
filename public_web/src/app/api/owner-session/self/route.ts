import { createClient } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";

/**
 * "Giriş yapmış kullanıcının kendi vitrini için sahip oturumu aç."
 *
 * NEDEN VAR (2026-08-27)
 * Sahip çerezini (`vixrex_owner_session`) üreten tek yer
 * `/api/owner-session`. O rota `consume_owner_session(p_slug, p_code)`
 * çağırıyor ve **tek kullanımlık kod** bekliyor — canlı veritabanında
 * doğrulandı: `edit_token` kabul etmiyor, `owner_sessions` tablosuna
 * bakıyor.
 *
 * `/app` panosu bu zinciri atlayıp düzenleme anahtarını doğrudan `ocode`
 * olarak gönderiyordu. Kod bulunamadığı için çerez HİÇ kurulmuyordu ve
 * ürün ekle/düzenle/sil çağrılarının tamamı 401 alıyordu. Yani web'deki
 * ürün yönetimi "bir süre sonra bozuluyor" değil, hiç çalışmıyordu.
 *
 * Eksik olan halka bu rota: hesabın vitrinini bulur, onun anahtarıyla
 * tek kullanımlık kodu üretir ve mevcut rotaya devreder.
 *
 * ZİNCİR
 *   Supabase Auth (Bearer)
 *     → bootstrap_owner_state()        hesabın vitrini + edit_token
 *     → create_owner_session(slug, token)   tek kullanımlık kod
 *     → 303 /api/owner-session?slug&ocode   çerezi O kurar
 *
 * `ownerSession.ts`, `proxy.ts` ve `api/owner-session/route.ts`
 * DEĞİŞMEDİ — sahip çerezini üreten tek yer tek kaldı. Bu, #344 planının
 * (Faz 2) açık şartıydı.
 */

type BootstrapSonucu = {
  has_store?: boolean;
  slug?: string;
  edit_token?: string;
  reason?: string;
};

function hataYaniti(mesaj: string, durum: number, sebep?: string) {
  return NextResponse.json({ hata: mesaj, sebep }, { status: durum });
}

export async function POST(request: NextRequest) {
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

  // Kullanıcının KENDİ oturumuyla çalış: her iki RPC de `auth.uid()`
  // üzerinden yetki kuruyor. Yönetici istemcisiyle çağrılırsa `auth.uid()`
  // null olur ve sahiplik kurulamaz.
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

  const { data: durum, error: durumHatasi } = await supabaseUser.rpc(
    "bootstrap_owner_state"
  );

  if (durumHatasi) {
    console.error("[owner-session/self] bootstrap hatası:", durumHatasi.message);
    return hataYaniti("Vitrin durumu okunamadı.", 500, durumHatasi.message);
  }

  const sonuc = (durum ?? {}) as BootstrapSonucu;

  if (sonuc.has_store !== true) {
    // Hata değil: hesabın henüz vitrini yok. Çağıran taraf kurulum
    // akışına yönlendirsin.
    return NextResponse.json(
      { tamam: false, sebep: sonuc.reason ?? "NO_STORE" },
      { status: 404 }
    );
  }

  const slug = (sonuc.slug ?? "").trim();
  const editToken = (sonuc.edit_token ?? "").trim();

  if (!slug || !editToken) {
    // Vitrin var ama anahtar yok — sahip modunda düzenleme yapılamaz.
    // Sessizce "başarılı" dönmek kullanıcıyı çalışmayan bir ekrana sokar.
    return hataYaniti(
      "Vitrinin düzenleme anahtarı bulunamadı.",
      409,
      "NO_EDIT_TOKEN"
    );
  }

  const { data: oturum, error: oturumHatasi } = await supabaseUser.rpc(
    "create_owner_session",
    { p_slug: slug, p_edit_token: editToken }
  );

  if (oturumHatasi) {
    console.error(
      "[owner-session/self] create_owner_session hatası:",
      oturumHatasi.message
    );
    return hataYaniti("Sahip oturumu açılamadı.", 500, oturumHatasi.message);
  }

  const kod =
    typeof oturum === "object" && oturum !== null
      ? String((oturum as { code?: unknown }).code ?? "").trim()
      : "";

  if (!kod) {
    return hataYaniti("Sahip oturumu kodu üretilemedi.", 500, "NO_CODE");
  }

  // Çerezi mevcut rota kuruyor; burada yalnız devrediyoruz.
  const hedef = new URL(
    `/api/owner-session?slug=${encodeURIComponent(slug)}&ocode=${encodeURIComponent(kod)}`,
    request.url
  );

  return NextResponse.json({ tamam: true, slug, yonlendir: hedef.pathname + hedef.search });
}
