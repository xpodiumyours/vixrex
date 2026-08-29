import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@supabase/supabase-js";

/**
 * Yeni vitrin oluşturma (sıfırdan).
 *
 * Zincir:
 *   istek { name, kategori, whatsapp, address, ... }
 *   → Supabase Auth session doğrulanır (gerçek user_id)
 *   → slug üretilir (ad + timestamp)
 *   → edit_token üretilir (32 byte hex)
 *   → create_store_with_token RPC çağrılır (SECURITY DEFINER)
 *   → store oluşur, user_id = auth.uid() olarak atanır
 *   → owner session cookie kurulur
 *   → /v/{slug} adresine redirect
 *
 * GÜVENLİK:
 *   - Supabase Auth session zorunlu (anon vitrin创建 yapamaz)
 *   - slug çakışması otomatik önlenir (RPC unique constraint)
 *   - edit_token 1 yıl süreli (create_store_with_token içinde)
 *   - user_id = auth.uid() (RPC SECURITY DEFINER)
 *
 * ÖNEMLİ: RPC'yi KULLANICININ KENDİ oturumuyla (JWT) çağırıyoruz,
 * admin/servis rolüyle DEĞİL. Böylece auth.uid() RPC içinde gerçek
 * kullanıcıya döner ve user_id doğru atanır.
 */

export const dynamic = "force-dynamic";

function generateSlug(name: string): string {
  const base = name
    .toLowerCase()
    .replace(/[çğıöşü]/g, (c) =>
      ({ ç: "c", ğ: "g", ı: "i", ö: "o", ş: "s", ü: "u" }[c] ?? c)
    )
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 40);

  const timestamp = Date.now().toString(36);
  return `${base}-${timestamp}`.slice(0, 60);
}

function generateEditToken(): string {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, (b) => b.toString(16).padStart(2, "0")).join("");
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const name = typeof govde.name === "string" ? govde.name.trim() : "";
  if (!name) {
    return NextResponse.json(
      { hata: "İşletme adı zorunludur." },
      { status: 422 }
    );
  }

  // Supabase Auth session doğrulaması
  const authHeader = request.headers.get("authorization");
  const bearerToken = authHeader?.replace("Bearer ", "");
  if (!bearerToken) {
    return NextResponse.json({ hata: "Oturum bulunamadı." }, { status: 401 });
  }

  const supabaseUrl =
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "";
  const supabaseAnonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_PUBLISHABLE_KEY ||
    "";

  // Kullanıcının kendi oturumuyla istemci oluştur — böylece auth.uid() çalışır
  const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: {
      headers: { Authorization: `Bearer ${bearerToken}` },
    },
  });

  const {
    data: { user },
    error: authError,
  } = await supabaseUser.auth.getUser(bearerToken);

  if (authError || !user) {
    return NextResponse.json({ hata: "Oturum geçersiz." }, { status: 401 });
  }

  // slug ve edit_token üret
  const slug = generateSlug(name);
  const editToken = generateEditToken();

  // Store data hazırla
  const storeData: Record<string, unknown> = {
    name,
    kategori: typeof govde.kategori === "string" ? govde.kategori.trim() : "",
    whatsapp:
      typeof govde.whatsapp === "string" ? govde.whatsapp.trim() : "",
    address: typeof govde.address === "string" ? govde.address.trim() : "",
    province_name:
      typeof govde.province_name === "string" ? govde.province_name.trim() : "",
    district_name:
      typeof govde.district_name === "string" ? govde.district_name.trim() : "",
    description:
      typeof govde.description === "string" ? govde.description.trim() : "",
    business_type:
      typeof govde.business_type === "string"
        ? govde.business_type.trim()
        : "",
    status: "draft",
    is_published: false,
  };

  const latitude = typeof govde.latitude === "number" ? govde.latitude : null;
  const longitude = typeof govde.longitude === "number" ? govde.longitude : null;
  if (
    latitude !== null && longitude !== null &&
    Number.isFinite(latitude) && Number.isFinite(longitude) &&
    latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
  ) {
    storeData.latitude = latitude;
    storeData.longitude = longitude;
    storeData.location_accuracy_meters =
      typeof govde.location_accuracy_meters === "number" &&
      Number.isFinite(govde.location_accuracy_meters)
        ? govde.location_accuracy_meters
        : null;
    storeData.location_source = "browser_gps";
    storeData.location_consent_at = new Date().toISOString();
  }

  // ADIM 0 — hesabın zaten vitrini var mı?
  //
  // Hesap başına tek vitrin kuralı veritabanında zorlanıyor. Bu kontrol
  // OLMAZSA sıra şöyle işler: vitrin oluşur → sahiplik çağrısı
  // ALREADY_OWNS_STORE ile reddeder → ortada SAHİPSİZ bir vitrin kalır.
  // Öksüz kayıt üretmemek için önce bakıyoruz.
  const { data: mevcutVitrin } = await supabaseUser
    .from("stores")
    .select("slug")
    .eq("user_id", user.id)
    .limit(1)
    .maybeSingle();

  if (mevcutVitrin?.slug) {
    return NextResponse.json(
      {
        hata:
          "Bu hesabın zaten bir vitrini var. Bir hesap yalnızca bir " +
          "vitrin yönetebilir.",
        slug: mevcutVitrin.slug,
      },
      { status: 409 }
    );
  }
  //
  // DİKKAT: `create_store_with_token` sahipliği KURMAZ. Canlı veritabanında
  // doğrulandı (2026-08-27, pg_get_functiondef): fonksiyon gövdesinde
  // `auth.uid()` HİÇ geçmiyor, `user_id` sabit `null` yazılıyor. Bu yüzden
  // RPC'yi kullanıcının kendi oturumuyla çağırmak sahipliği tek başına
  // çözmez — ikinci adım şart.
  const { error } = await supabaseUser.rpc("create_store_with_token", {
    p_slug: slug,
    p_edit_token: editToken,
    p_store: storeData,
  });

  if (error) {
    console.error("[create-store] RPC failed:", error.message);
    const metin =
      error.message === "UNIQUE_VIOLATION"
        ? "Bu isimle bir vitrin zaten var. Farklı bir isim dene."
        : "Vitrin oluşturulamadı. Lütfen tekrar dene.";
    return NextResponse.json({ hata: metin }, { status: 400 });
  }

  // ADIM 2 — vitrini oturum açmış hesaba bağla.
  //
  // `claim_store_for_user`, canlıda `auth.uid()` kullanan TEK sahiplik
  // fonksiyonudur (`link_store_to_user` boolean kabuğa çevrildi ve artık
  // kullanmıyor). Kullanıcının kendi istemcisiyle çağrılması şart; admin
  // istemcisiyle çağrılırsa `auth.uid()` yine null olur.
  //
  // Bu adım atlanırsa vitrin SAHİPSİZ doğar: kullanıcı başka cihazdan
  // giremez (`bootstrap_owner_state` user_id üzerinden arar) ve hesap
  // başına tek vitrin kuralı işlemez (kısmi unique index NULL satırları
  // kapsamaz). 2026-08-26 öncesinde canlıdaki 29 vitrinin hiçbirinde
  // user_id yoktu; aynı duruma dönmemek için bu çağrı zorunludur.
  // DİKKAT: bu fonksiyon başarısızlıkta HATA FIRLATMAZ — `{ok:false,
  // reason:...}` biçiminde VERİ döndürür (yalnız oturum yoksa UNAUTHORIZED
  // fırlatır). Sadece `error` alanına bakmak, reddedilen bir sahiplenmeyi
  // "başarılı" saymak demektir. Sonuç gövdesi de kontrol edilmeli.
  const { data: sahiplikSonucu, error: sahiplikHatasi } =
    await supabaseUser.rpc("claim_store_for_user", {
      p_edit_token: editToken,
    });

  const sahiplikTamam =
    !sahiplikHatasi &&
    typeof sahiplikSonucu === "object" &&
    sahiplikSonucu !== null &&
    (sahiplikSonucu as { ok?: unknown }).ok === true;

  if (!sahiplikTamam) {
    // Vitrin oluştu ama hesaba bağlanamadı — yarım durum. Kullanıcıya
    // "oldu" demek yanlış olur: o vitrini bir daha bulamaz.
    const sebep =
      sahiplikHatasi?.message ??
      (sahiplikSonucu as { reason?: string } | null)?.reason ??
      "BILINMEYEN";
    console.error("[create-store] claim_store_for_user başarısız:", sebep);
    return NextResponse.json(
      {
        hata:
          "Vitrin oluşturuldu ama hesabına bağlanamadı. " +
          "Lütfen tekrar giriş yapıp dene.",
        slug,
        sebep,
      },
      { status: 500 }
    );
  }

  // Landing'deki konuşma burada aynı sahip oturumuna bağlanır. Yeni bir
  // asistan kaydı/tablosu açılmaz; Flutter'ın kullandığı handoff_v1 ve
  // owner_sessions.assistant_handoff yolu aynen kullanılır.
  const assistantHandoff =
    typeof govde.assistant_handoff === "object" &&
    govde.assistant_handoff !== null
      ? govde.assistant_handoff
      : null;
  const oturumRpc = assistantHandoff
    ? "create_owner_session_with_handoff"
    : "create_owner_session";
  const oturumParametreleri = assistantHandoff
    ? {
        p_slug: slug,
        p_edit_token: editToken,
        p_assistant_handoff: assistantHandoff,
      }
    : { p_slug: slug, p_edit_token: editToken };
  const { data: oturum, error: oturumHatasi } = await supabaseUser.rpc(
    oturumRpc,
    oturumParametreleri,
  );
  const kod =
    typeof oturum === "object" && oturum !== null
      ? String((oturum as { code?: unknown }).code ?? "").trim()
      : "";
  if (oturumHatasi || !kod) {
    console.error(
      "[create-store] asistanlı sahip oturumu açılamadı:",
      oturumHatasi?.message ?? "NO_CODE",
    );
    return NextResponse.json(
      {
        hata:
          "Vitrin hesabına bağlandı ama asistan konuşması aktarılamadı. " +
          "Vitrinim sayfasından devam edebilirsin.",
        slug,
      },
      { status: 500 },
    );
  }

  const yonlendir =
    `/api/owner-session?slug=${encodeURIComponent(slug)}` +
    `&ocode=${encodeURIComponent(kod)}`;

  return NextResponse.json({
    tamam: true,
    slug,
    yonlendir,
    message: "Vitrin oluşturuldu.",
  });
}
