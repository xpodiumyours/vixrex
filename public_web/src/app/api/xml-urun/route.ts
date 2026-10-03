import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";

export const dynamic = "force-dynamic";

const AZAMI_BAYT = 5 * 1024 * 1024;
const AZAMI_SANYE = 20000;

function yasakAdres(konak: string): boolean {
  const kucuk = konak.toLowerCase().replace(/^\[/, "").replace(/\]$/, "");
  if (
    kucuk === "localhost" ||
    kucuk.endsWith(".localhost") ||
    kucuk.endsWith(".local") ||
    kucuk.endsWith(".internal")
  ) {
    return true;
  }
  if (
    /^127\./.test(kucuk) ||
    /^10\./.test(kucuk) ||
    /^192\.168\./.test(kucuk) ||
    /^169\.254\./.test(kucuk) ||
    /^0\./.test(kucuk)
  ) {
    return true;
  }
  if (/^172\.(1[6-9]|2\d|3[01])\./.test(kucuk)) return true;
  if (kucuk === "::1" || kucuk.startsWith("fe80:")) return true;
  return false;
}

export async function GET(request: NextRequest) {
  const slug = request.nextUrl.searchParams.get("slug")?.trim() || "";
  const hamUrl = request.nextUrl.searchParams.get("url")?.trim() || "";

  if (!slug) return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });

  const cookieStore = await cookies();
  if (!verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug)) {
    return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
  }

  let hedef: URL;
  try {
    hedef = new URL(hamUrl);
  } catch {
    return NextResponse.json({ hata: "Geçerli bir XML linki değil." }, { status: 422 });
  }
  if (hedef.protocol !== "http:" && hedef.protocol !== "https:") {
    return NextResponse.json(
      { hata: "Yalnız http veya https bağlantıları yüklenebilir." },
      { status: 422 },
    );
  }
  if (yasakAdres(hedef.hostname)) {
    return NextResponse.json({ hata: "Bu adresten okuma yapılamaz." }, { status: 422 });
  }

  const zamanAsimi = new AbortController();
  const zaman = setTimeout(() => zamanAsimi.abort(), AZAMI_SANYE);
  try {
    const cevap = await fetch(hedef, {
      redirect: "follow",
      cache: "no-store",
      signal: zamanAsimi.signal,
    });
    if (!cevap.ok) {
      return NextResponse.json({ hata: `XML yüklenemedi: ${cevap.status}` }, { status: 502 });
    }
    if (!cevap.body) {
      return NextResponse.json({ hata: "XML boş görünüyor." }, { status: 502 });
    }
    const okuyucu = cevap.body.getReader();
    const parcalar: Uint8Array[] = [];
    let toplam = 0;
    for (;;) {
      const { done, value } = await okuyucu.read();
      if (done) break;
      if (value) {
        toplam += value.byteLength;
        if (toplam > AZAMI_BAYT) {
          await okuyucu.cancel().catch(() => undefined);
          return NextResponse.json(
            { hata: "XML dosyası çok büyük (en fazla 5 MB)." },
            { status: 413 },
          );
        }
        parcalar.push(value);
      }
    }
    const birlesik = new Uint8Array(toplam);
    let kaydirma = 0;
    for (const parca of parcalar) {
      birlesik.set(parca, kaydirma);
      kaydirma += parca.byteLength;
    }
    return NextResponse.json({ ok: true, xml: new TextDecoder().decode(birlesik) });
  } catch {
    if (zamanAsimi.signal.aborted) {
      return NextResponse.json({ hata: "XML indirme zaman aşımına uğradı." }, { status: 504 });
    }
    return NextResponse.json({ hata: "XML indirilemedi. Bağlantıyı kontrol et." }, { status: 502 });
  } finally {
    clearTimeout(zaman);
  }
}
