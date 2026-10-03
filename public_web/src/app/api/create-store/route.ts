import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { yayinSahiplikKarari } from "@/lib/yayinSahiplikKarari";
import { kesfetOnbelleginiYenile } from "@/lib/explore";

/**
 * Yeni vitrin oluşturma (sıfırdan).
 *
 * Zincir:
 *   istek { name, kategori, whatsapp, address, ... }
 *   → Supabase Auth session doğrulanır (gerçek user_id)
 *   → slug üretilir (ad + timestamp)
 *   → edit_token üretilir (32 byte hex)
 *   → create_store_with_token RPC çağrılır (SECURITY DEFINER)
 *   → store yayınlanır; kalıcı kullanıcıysa user_id hesaba bağlanır,
 *     anonim kullanıcıysa Flutter gibi cihaz sahip oturumuyla devam eder
 *   → owner session cookie kurulur
 *   → /v/{slug} adresine redirect
 *
 * GÜVENLİK:
 *   - Supabase Auth session zorunlu (anonim Supabase oturumu kabul edilir)
 *   - slug çakışması otomatik önlenir (RPC unique constraint)
 *   - edit_token 1 yıl süreli (create_store_with_token içinde)
 *   - Kalıcı hesap sahipliği claim_store_for_user ile kurulur
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

const YASAL_BELGE_TURLERI = ["privacy", "terms", "consent"] as const;
type YasalBelgeTuru = (typeof YASAL_BELGE_TURLERI)[number];

type AktifYasalBelgeler = Record<
  YasalBelgeTuru,
  { version: string; content_hash: string }
>;

// `accept_store_legal_consent` RPC'si aktif sürümü SUNUCUDA okuyup
// damgalar; istemci gövdesinden gelen sürüm/hash güvenilmezdir. Landing
// asistanı da aynı damgayı, aynı kaynaktan üretmek zorunda.
function aktifYasalBelgeleriHaritala(
  satirlar: unknown,
): AktifYasalBelgeler | null {
  if (!Array.isArray(satirlar)) return null;

  const bulunan = new Map<string, { version: string; content_hash: string }>();
  for (const satir of satirlar as Record<string, unknown>[]) {
    const tur = String(satir.document_type ?? "");
    const version = String(satir.version ?? "").trim();
    const hash = String(satir.content_hash ?? "").trim();
    if (tur && version && hash) bulunan.set(tur, { version, content_hash: hash });
  }

  const sonuc = {} as AktifYasalBelgeler;
  for (const tur of YASAL_BELGE_TURLERI) {
    const belge = bulunan.get(tur);
    if (!belge) return null;
    sonuc[tur] = belge;
  }
  return sonuc;
}

/**
 * Yayın zincirinden (veritabanı) dönen kodların esnafa söylenen hâli.
 *
 * Zincirde iki yerde hata çıkabilir: vitrin kaydı ve yayına alma. İkisinde
 * de `error.message` ham bir koddur (`STORE_WHATSAPP_INVALID` gibi).
 * Kullanıcıya o ham kodu göstermek onun yapamayacağı bir şeyi istemek
 * demektir — neyin eksik olduğunu cümleyle söylüyoruz ki kapayıp
 * tamamlayabilsin.
 */
const RPC_HATA_METNI: Record<string, string> = {
  STORE_NAME_REQUIRED: "İşletme adı zorunludur.",
  STORE_CATEGORY_REQUIRED:
    "Yayına çıkmak için geçerli bir kategori seçmen gerekiyor.",
  STORE_WHATSAPP_REQUIRED: "Yayına çıkmak için WhatsApp numarası gerekli.",
  STORE_WHATSAPP_INVALID:
    "WhatsApp numarası geçerli görünmüyor. 05XX XXX XX XX biçiminde yaz.",
  STORE_ADDRESS_REQUIRED: "Yayına çıkmak için açık adres gerekli.",
  STORE_PROVINCE_REQUIRED: "Yayına çıkmak için il bilgisi gerekli.",
  STORE_DISTRICT_REQUIRED: "Yayına çıkmak için ilçe bilgisi gerekli.",
  PRIVACY_NOTICE_REQUIRED:
    "Aydınlatma Metni onayı olmadan vitrin yayına alınamaz.",
  TERMS_ACCEPTANCE_REQUIRED:
    "Kullanım Şartları onayı olmadan vitrin yayına alınamaz.",
  PUBLICATION_CONSENT_REQUIRED:
    "Açık Rıza Beyanı onayı olmadan vitrin yayına alınamaz.",
  PRIVACY_NOTICE_VERSION_INVALID:
    "Aydınlatma Metni sürümü güncellenmiş. Sayfayı yenileyip onay ver.",
  TERMS_VERSION_INVALID:
    "Kullanım Şartları sürümü güncellenmiş. Sayfayı yenileyip onay ver.",
  PUBLICATION_CONSENT_VERSION_INVALID:
    "Açık Rıza Beyanı sürümü güncellenmiş. Sayfayı yenileyip onay ver.",
  PRODUCT_IMAGE_REQUIRED:
    "Yayına çıkmak için en az bir ürüne fotoğraf ekle.",
};

/** Ham RPC kodunu — varsa — esnafın anlayacağı cümleye çevirir. */
function hataMetni(kod: string, yedek: string): string {
  if (kod === "UNIQUE_VIOLATION") {
    return "Bu isimle bir vitrin zaten var. Farklı bir isim dene.";
  }
  return RPC_HATA_METNI[kod] ?? yedek;
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

  const sahiplikKarari = yayinSahiplikKarari(user);

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
    status: "Açık",
    is_published: true,
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
  if (sahiplikKarari.claimStore) {
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
  }

  // ADIM 0.5 — "Yayınla" demeye yetecek kadar bilgi var mı?
  //
  // NEDEN BURADA: vitrin taslakta bırakılmıyor, yayına alınıyor. Yayın
  // kapısı veritabanında şunları zorunlu tutuyor: ad, kategori, WhatsApp,
  // adres, il, ilçe. Bunları eksik yakalarsak kullanıcı "Vitrin
  // oluşturulamadı" gibi muğlak bir yerde kalmasın — NEYİN eksik olduğunu
  // baştan söyleyelim ki kapayıp tamamlasın, tekrar bastığında vitrin
  // anında yayında olsun. Taslak üretip sessizce bırakmak yok.
  const eksik: string[] = [];

  const kategori = String(storeData.kategori ?? "");
  if (!kategori || ["diğer", "diger"].includes(kategori.toLowerCase())) {
    eksik.push("kategori");
  }

  const whatsapp = String(storeData.whatsapp ?? "");
  const whatsappRakamlari = whatsapp.replace(/[^0-9]/g, "");
  const whatsappGecerli =
    whatsapp !== "" &&
    !/[a-zA-Z]/.test(whatsapp) &&
    (/^05\d{9}$/.test(whatsappRakamlari) ||
      /^5\d{9}$/.test(whatsappRakamlari) ||
      /^905\d{9}$/.test(whatsappRakamlari));
  if (!whatsappGecerli) eksik.push("WhatsApp numarası (05XX XXX XX XX)");

  if (!String(storeData.address ?? "")) eksik.push("açık adres");
  if (!String(storeData.province_name ?? "")) eksik.push("il");
  if (!String(storeData.district_name ?? "")) eksik.push("ilçe");

  if (eksik.length > 0) {
    return NextResponse.json(
      {
        hata:
          "Vitrini yayınlamak için şu bilgiler eksik: " +
          eksik.join(", ") +
          ". Tamamlayıp tekrar dene — bilgiler tam olduğu an vitrinin " +
          "anında yayına alınır.",
        eksik,
      },
      { status: 422 }
    );
  }

  // Yasal onay da yayın için şart. Tek bir "onayladım" yeterli: landing'de
  // o düğme üç kutu işaretlenmeden basılmıyor (yasalOnayVerildi), oluşturma
  // ekranındaki tek kutu da üç metnin tamamını kapsıyor — tıpkı paneldeki
  // accept_store_legal_consent'in hiçbir bayrak almadan kaydı yazması gibi.
  // Onay VERİLMEDİYSE vitrin hiç oluşmuyor; neyin eksik olduğunu söylüyoruz.
  const yayinOnayi =
    govde.legal_consent === true ||
    (govde.privacy_notice_acknowledged === true &&
      govde.terms_accepted === true &&
      (govde.publication_consent_accepted === true ||
        govde.explicit_consent_given === true));

  if (!yayinOnayi) {
    return NextResponse.json(
      {
        hata:
          "Vitrini yayınlamak için üç yasal onayın tamamı gerekli: " +
          "Aydınlatma Metni, Kullanım Şartları ve Açık Rıza Beyanı. " +
          "Onayları işaretle, vitrinin anında yayında olsun.",
        eksik: ["yasal onay"],
      },
      { status: 422 }
    );
  }

  // ADIM 1 — vitrini oluştur.
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
    return NextResponse.json(
      {
        hata: hataMetni(
          error.message,
          "Vitrin oluşturulamadı. Lütfen tekrar dene.",
        ),
      },
      { status: 400 }
    );
  }

  // ADIM 2 — kalıcı oturumsa vitrini hesaba bağla. Anonim oturumda
  // Flutter ile aynı şekilde cihaz sahip oturumu korunur; Google kimliği
  // yayın sonrasında bağlandığında aynı claim RPC'si çalıştırılır.
  //
  // `claim_store_for_user`, canlıda `auth.uid()` kullanan TEK sahiplik
  // fonksiyonudur (`link_store_to_user` boolean kabuğa çevrildi ve artık
  // kullanmıyor). Kullanıcının kendi istemcisiyle çağrılması şart; admin
  // istemcisiyle çağrılırsa `auth.uid()` yine null olur.
  //
  // Kalıcı kullanıcıda bu adım atlanırsa vitrin hesaptan bulunamaz.
  // DİKKAT: bu fonksiyon başarısızlıkta HATA FIRLATMAZ — `{ok:false,
  // reason:...}` biçiminde VERİ döndürür (yalnız oturum yoksa UNAUTHORIZED
  // fırlatır). Sadece `error` alanına bakmak, reddedilen bir sahiplenmeyi
  // "başarılı" saymak demektir. Sonuç gövdesi de kontrol edilmeli.
  if (sahiplikKarari.claimStore) {
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
  }

  // PR4-C15: yeni mağaza + çalışma taslağı hazırla — yayın gibi konuşma
  await supabaseUser.rpc("get_or_create_working_draft", {
    p_slug: slug,
    p_edit_token: editToken,
  });

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

  // ADIM 5 — vitrini GERÇEKTEN yayınla.
  //
  // `create_store_with_token` INSERT'i is_published=false yazıp bitiyor
  // (20260824050000); Flutter da bu yüzden ardından `update_store_with_token`
  // çağırıyor. Web'de bu ikinci adım yoktu: asistan "yayınlandı" derdi,
  // vitrin taslak kalır, Keşfet'e girmez ve müşteri linki 404 verirdi.
  //
  // Yayın denemesi bilinçli olarak SAHİPLİK ve oturum kurulduktan SONRA
  // yapılır: yayın kapısı reddederse vitrin sahipsiz/öksüz kalmaz, kullanıcı
  // Vitrinim ekranından tekrar yayınlayabilir.
  // Erken kontrolde `yayinOnayi` zorunlu tutuldu; damga için aynı sonucu
  // kullanıyoruz ki "onay var ama damga yok" diye ikiye bölünmesin.
  const yasalOnay = yayinOnayi;
  let belgeler: AktifYasalBelgeler | null = null;
  if (yasalOnay) {
    const { data: belgeSatirlari } = await supabaseUser
      .from("legal_documents")
      .select("document_type, version, content_hash")
      .in("document_type", [...YASAL_BELGE_TURLERI])
      .eq("is_active", true);
    belgeler = aktifYasalBelgeleriHaritala(belgeSatirlari);

    // Onay alındı ama sistemde aktif belge kaydı yoksa yayın kapısı
    // reddedecek. Sessizce taslak bırakmak yerine baştan söyleyelim.
    if (!belgeler) {
      return NextResponse.json(
        {
          hata:
            "Yasal metinlerin güncel kaydı bulunamadı, bu yüzden yayın " +
            "yapılamıyor. Birkaç dakika sonra tekrar dene.",
          slug,
        },
        { status: 500 }
      );
    }
  }

  const yasalDamga: Record<string, unknown> = belgeler
    ? {
        privacy_notice_acknowledged: true,
        privacy_notice_version: belgeler.privacy.version,
        privacy_notice_hash: belgeler.privacy.content_hash,
        terms_accepted: true,
        terms_version: belgeler.terms.version,
        terms_hash: belgeler.terms.content_hash,
        publication_consent_accepted: true,
        publication_consent_version: belgeler.consent.version,
        publication_consent_hash: belgeler.consent.content_hash,
      }
    : {};

  const { error: yayinHatasi } = await supabaseUser.rpc(
    "update_store_with_token",
    {
      p_slug: slug,
      p_edit_token: editToken,
      p_store: { ...storeData, ...yasalDamga },
    },
  );

  if (yayinHatasi) {
    console.error("[create-store] yayınlama başarısız:", yayinHatasi.message);
    return NextResponse.json(
      {
        hata: hataMetni(
          yayinHatasi.message,
          "Vitrinin oluşturuldu ama yayınlanamadı. " +
            "Vitrinim sayfasından tekrar yayınlayabilirsin.",
        ),
        slug,
        yonlendir,
        sebep: yayinHatasi.message,
      },
      { status: 500 },
    );
  }

  // Yayın bitti. Keşfet listesi 5 dakika saklanıyor; hemen düşürülmezse
  // esnaf kendi vitrinini dakikalarca göremez.
  kesfetOnbelleginiYenile();

  return NextResponse.json({
    tamam: true,
    slug,
    yonlendir,
    hesapKorumasiz: sahiplikKarari.hesapKorumasiz,
    message: "Vitrin oluşturuldu.",
  });
}
