import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";

// Sahip görsel yükleme (implementation_plan.md Commit 10).
//
// NEDEN AYRI VE DİKKATLİ:
// Supabase depolamasına yazmak SERVICE-ROLE anahtarı gerektiriyor. O anahtar
// bütün veritabanı korumalarını (RLS) atlar. Bu yüzden buradaki sahiplik
// kontrolü kusursuz olmalı — bir açık kalırsa biri başkasının vitrinine
// dosya yükleyebilir.
//
// SAVUNMA KATMANLARI
//   1. Oturum YALNIZ HttpOnly çerezden okunur. Gövdeden token kabul edilmez.
//   2. Çerez, istekteki slug'a bağlıdır (verifyOwnerSession slug'ı doğrular).
//   3. Yüklenen dosya yolu, oturumun slug'ından türetilir — istemcinin
//      verdiği bir yol KULLANILMAZ. Başka vitrinin klasörüne yazılamaz.
//   4. Dosya türü, istemcinin söylediğine değil DOSYANIN İLK BAYTLARINA
//      bakılarak doğrulanır. content-type kolayca yalan söylenebilir.
//   5. Boyut sınırı hem içerik uzunluğundan hem gerçek bayttan kontrol edilir.
//   6. Yalnız şemada `gorsel` tipinde tanımlı alanlar için yükleme kabul edilir.
//
// Bu uç YALNIZCA yükler ve adresi döndürür. Alanı kaydetmek /api/owner-draft
// işidir — böylece kayıt yolu tek ve doğrulanmış kalır.

export const dynamic = "force-dynamic";

const MAX_BAYT = 5 * 1024 * 1024; // 5 MB

const IZINLI_TURLER = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"],
]);

/**
 * Dosyanın gerçekten iddia ettiği tür olup olmadığını ilk baytlarından
 * doğrular. İstemcinin gönderdiği content-type güvenilmez.
 */
function gercekTur(bayt: Uint8Array): string | null {
  if (bayt.length < 12) return null;

  // JPEG: FF D8 FF
  if (bayt[0] === 0xff && bayt[1] === 0xd8 && bayt[2] === 0xff) {
    return "image/jpeg";
  }

  // PNG: 89 50 4E 47 0D 0A 1A 0A
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (png.every((b, i) => bayt[i] === b)) {
    return "image/png";
  }

  // WebP: "RIFF" .... "WEBP"
  const riff = [0x52, 0x49, 0x46, 0x46];
  const webp = [0x57, 0x45, 0x42, 0x50];
  if (
    riff.every((b, i) => bayt[i] === b) &&
    webp.every((b, i) => bayt[8 + i] === b)
  ) {
    return "image/webp";
  }

  return null;
}

export async function POST(request: NextRequest) {
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = String(form.get("slug") ?? "").trim();
  const anahtar = String(form.get("anahtar") ?? "").trim();
  const dosya = form.get("dosya");

  if (!slug || !anahtar) {
    return NextResponse.json(
      { hata: "Vitrin veya alan belirtilmedi." },
      { status: 400 }
    );
  }

  if (!(dosya instanceof File)) {
    return NextResponse.json({ hata: "Dosya bulunamadı." }, { status: 400 });
  }

  // Yalnız şemada görsel olarak tanımlı alanlara yükleme yapılabilir.
  const alan = FIELD_BY_KEY.get(anahtar);
  if (!alan || alan.tip !== "gorsel") {
    return NextResponse.json(
      { hata: "Bu alana görsel yüklenemez." },
      { status: 422 }
    );
  }

  // Oturum yalnız çerezden. Gövdeden token kabul edilmez.
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);

  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumunuz geçersiz veya süresi dolmuş. Önizlemeyi tekrar açın." },
      { status: 401 }
    );
  }

  if (dosya.size > MAX_BAYT) {
    return NextResponse.json(
      { hata: "Dosya çok büyük. En fazla 5 MB olabilir." },
      { status: 413 }
    );
  }

  const bayt = new Uint8Array(await dosya.arrayBuffer());
  if (bayt.length > MAX_BAYT) {
    return NextResponse.json(
      { hata: "Dosya çok büyük. En fazla 5 MB olabilir." },
      { status: 413 }
    );
  }

  // İçeriğe bakarak doğrula — istemcinin söylediğine değil.
  const tur = gercekTur(bayt);
  const uzanti = tur ? IZINLI_TURLER.get(tur) : null;
  if (!tur || !uzanti) {
    return NextResponse.json(
      { hata: "Yalnız JPG, PNG veya WebP yükleyebilirsiniz." },
      { status: 415 }
    );
  }

  // Yol, DOĞRULANMIŞ oturumun slug'ından türetilir. İstemciden gelen bir
  // yol parçası kullanılmaz — başka vitrinin klasörüne yazılamaz.
  const guvenliSlug = ownerSession.slug.replace(/[^a-zA-Z0-9-]/g, "");
  const dosyaAdi = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}.${uzanti}`;
  const yol = `${guvenliSlug}/owner/${alan.anahtar}/${dosyaAdi}`;

  try {
    const admin = getSupabaseAdmin();
    const { error } = await admin.storage
      .from("shelf-images")
      .upload(yol, bayt, { contentType: tur, upsert: false });

    if (error) {
      console.error("[owner-upload] storage error:", error.message);
      return NextResponse.json(
        { hata: "Görsel yüklenemedi. Tekrar deneyin." },
        { status: 500 }
      );
    }

    const { data } = admin.storage.from("shelf-images").getPublicUrl(yol);

    return NextResponse.json({
      tamam: true,
      anahtar: alan.anahtar,
      etiket: alan.etiket,
      url: data.publicUrl,
    });
  } catch (err) {
    // Anahtar veya yapılandırma eksikse buraya düşer. Ayrıntı loglanmaz.
    console.error(
      "[owner-upload] failed:",
      err instanceof Error ? err.message : "unknown"
    );
    return NextResponse.json(
      { hata: "Görsel yüklenemedi. Tekrar deneyin." },
      { status: 500 }
    );
  }
}
