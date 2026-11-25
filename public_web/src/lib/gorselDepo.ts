import { createHash, createHmac } from "node:crypto";
import { yonetilenR2Originleri } from "@/lib/productImagePolicy";

export { yonetilenR2Originleri };

export interface DepoIstemcisi {
  storage: {
    from: (kova: string) => {
      upload: (
        yol: string,
        bayt: Uint8Array,
        secenekler: { contentType: string; cacheControl: string; upsert: boolean },
      ) => Promise<{ error: { message: string } | null }>;
      getPublicUrl: (yol: string) => { data: { publicUrl: string } };
    };
  };
}

export interface R2Yapilandirmasi {
  accountId: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucketName: string;
  publicUrl: string;
}

export interface GorselYuklemeIstegi {
  admin?: DepoIstemcisi;
  yol: string;
  bayt: Uint8Array;
  contentType: string;
  cacheControl: string;
  upsert?: boolean;
  fetcher?: typeof fetch;
}

const KOVA = "shelf-images";
const R2_BOLGE = "auto";
const R2_SERVIS = "s3";
const S3_LIST_LIMIT = 1000;
const S3_MAX_SAYFA = 1000;

function awsEncode(deger: string): string {
  return encodeURIComponent(deger).replace(
    /[!'()*]/g,
    (karakter) => `%${karakter.charCodeAt(0).toString(16).toUpperCase()}`,
  );
}

function anahtarKodla(yol: string): string {
  return yol
    .replace(/^\/+/, "")
    .split("/")
    .map(awsEncode)
    .join("/");
}

function sha256Hex(veri: string | Uint8Array): string {
  return createHash("sha256").update(veri).digest("hex");
}

function hmac(anahtar: string | Buffer, veri: string): Buffer {
  return createHmac("sha256", anahtar).update(veri, "utf8").digest();
}

function asciiSirala(a: string, b: string): number {
  if (a < b) return -1;
  if (a > b) return 1;
  return 0;
}

function xmlKacir(deger: string): string {
  return deger
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function xmlCoz(deger: string): string {
  return deger
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, "&");
}

function xmlTekEtiketOku(xml: string, etiket: string): string | null {
  const eslesme = new RegExp(`<${etiket}>([\\s\\S]*?)</${etiket}>`, "i").exec(xml);
  return eslesme ? xmlCoz(eslesme[1].trim()) : null;
}

function xmlAnahtarlariCikar(xml: string): string[] {
  const anahtarlar: string[] = [];
  const eslesmeler = xml.matchAll(/<Key>([\s\S]*?)<\/Key>/gi);
  for (const eslesme of eslesmeler) {
    const anahtar = xmlCoz(eslesme[1].trim());
    if (anahtar) anahtarlar.push(anahtar);
  }
  return anahtarlar;
}

export function r2Yapilandirmasi(): R2Yapilandirmasi | null {
  const accountId = String(process.env.R2_ACCOUNT_ID || "").trim();
  const accessKeyId = String(process.env.R2_ACCESS_KEY_ID || "").trim();
  const secretAccessKey = String(process.env.R2_SECRET_ACCESS_KEY || "").trim();
  const bucketName = String(process.env.R2_BUCKET_NAME || "").trim();
  const publicUrlRaw = String(process.env.R2_PUBLIC_URL || "").trim();
  const nextPublicUrlRaw = String(process.env.NEXT_PUBLIC_R2_PUBLIC_URL || "").trim();

  const temelAlanlar = [accountId, accessKeyId, secretAccessKey, bucketName, publicUrlRaw];
  if (temelAlanlar.every((alan) => !alan)) {
    return null;
  }
  if (temelAlanlar.some((alan) => !alan)) {
    throw new Error("R2 yapılandırması eksik: tüm R2 ortam değişkenleri tanımlı olmalıdır.");
  }
  if (!/^[a-zA-Z0-9_-]+$/.test(accountId)) {
    throw new Error("R2_ACCOUNT_ID geçersiz.");
  }
  if (!/^[a-zA-Z0-9._-]+$/.test(bucketName)) {
    throw new Error("R2_BUCKET_NAME geçersiz.");
  }

  let parsedPublic: URL;
  try {
    parsedPublic = new URL(publicUrlRaw);
  } catch {
    throw new Error("R2_PUBLIC_URL geçerli bir adres değil.");
  }
  if (parsedPublic.protocol !== "https:" || parsedPublic.username || parsedPublic.password) {
    throw new Error("R2_PUBLIC_URL geçerli bir https:// adresi olmalıdır.");
  }

  if (nextPublicUrlRaw) {
    let parsedNext: URL;
    try {
      parsedNext = new URL(nextPublicUrlRaw);
    } catch {
      throw new Error("NEXT_PUBLIC_R2_PUBLIC_URL geçerli bir adres değil.");
    }
    if (
      parsedNext.protocol !== "https:" ||
      parsedNext.username ||
      parsedNext.password ||
      parsedNext.origin !== parsedPublic.origin
    ) {
      throw new Error("NEXT_PUBLIC_R2_PUBLIC_URL ile R2_PUBLIC_URL origin uyuşmuyor.");
    }
  }

  const temizPath = parsedPublic.pathname.replace(/\/+$/, "");
  return {
    accountId,
    accessKeyId,
    secretAccessKey,
    bucketName,
    publicUrl: `${parsedPublic.origin}${temizPath}`,
  };
}

export function imzaliR2Istek(param: {
  r2: R2Yapilandirmasi;
  method: "GET" | "PUT" | "POST";
  canonicalUri: string;
  queryParams?: Array<[string, string]>;
  headers?: Record<string, string>;
  body?: string | Uint8Array;
  tarih?: Date;
}): { url: string; headers: Record<string, string> } {
  const simdi = param.tarih ?? new Date();
  const amzDate = simdi.toISOString().replace(/[:-]|\.\d{3}/g, "");
  const dateStamp = amzDate.slice(0, 8);
  const host = `${param.r2.accountId}.r2.cloudflarestorage.com`;
  const payloadHash = sha256Hex(param.body ?? "");

  const siraliQuery = (param.queryParams ?? [])
    .map(([k, v]): [string, string] => [awsEncode(k), awsEncode(v)])
    .sort((a, b) => {
      const kFark = asciiSirala(a[0], b[0]);
      return kFark !== 0 ? kFark : asciiSirala(a[1], b[1]);
    });
  const canonicalQuery = siraliQuery
    .map(([k, v]) => `${k}=${v}`)
    .join("&");

  const imzalanacakBasliklar: Record<string, string> = {
    host,
    "x-amz-content-sha256": payloadHash,
    "x-amz-date": amzDate,
  };
  for (const [k, v] of Object.entries(param.headers ?? {})) {
    imzalanacakBasliklar[k.toLowerCase()] = v.trim();
  }

  const siraliBaslikAdlari = Object.keys(imzalanacakBasliklar).sort(asciiSirala);
  const canonicalHeaders = siraliBaslikAdlari
    .map((ad) => `${ad}:${imzalanacakBasliklar[ad]}\n`)
    .join("");
  const signedHeaders = siraliBaslikAdlari.join(";");

  const canonicalRequest = [
    param.method,
    param.canonicalUri,
    canonicalQuery,
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join("\n");

  const credentialScope = `${dateStamp}/${R2_BOLGE}/${R2_SERVIS}/aws4_request`;
  const stringToSign = [
    "AWS4-HMAC-SHA256",
    amzDate,
    credentialScope,
    sha256Hex(canonicalRequest),
  ].join("\n");

  const kDate = hmac(`AWS4${param.r2.secretAccessKey}`, dateStamp);
  const kRegion = hmac(kDate, R2_BOLGE);
  const kService = hmac(kRegion, R2_SERVIS);
  const kSigning = hmac(kService, "aws4_request");
  const signature = hmac(kSigning, stringToSign).toString("hex");

  const istekBasliklari: Record<string, string> = {
    ...imzalanacakBasliklar,
    authorization: `AWS4-HMAC-SHA256 Credential=${param.r2.accessKeyId}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
  };
  delete istekBasliklari.host;

  const url = `https://${host}${param.canonicalUri}${canonicalQuery ? `?${canonicalQuery}` : ""}`;
  return { url, headers: istekBasliklari };
}

export async function gorselDepoyaYukle(istek: GorselYuklemeIstegi): Promise<string> {
  const r2 = r2Yapilandirmasi();
  if (r2) {
    const temizYol = istek.yol.replace(/^\/+/, "");
    if (!temizYol) {
      throw new Error("Depo yolu boş olamaz.");
    }
    const canonicalUri = `/${awsEncode(r2.bucketName)}/${anahtarKodla(temizYol)}`;
    const { url, headers } = imzaliR2Istek({
      r2,
      method: "PUT",
      canonicalUri,
      headers: {
        "content-type": istek.contentType,
        "cache-control": `public, max-age=${istek.cacheControl}, immutable`,
      },
      body: istek.bayt,
    });
    const yanit = await (istek.fetcher ?? fetch)(url, {
      method: "PUT",
      headers,
      body: Buffer.from(istek.bayt),
    });
    if (!yanit.ok) {
      await yanit.body?.cancel();
      throw new Error(`R2 yukleme hatasi: HTTP ${yanit.status}`);
    }
    return `${r2.publicUrl}/${anahtarKodla(temizYol)}`;
  }

  if (!istek.admin) {
    throw new Error("Depo istemcisi bulunamadı.");
  }

  const { error } = await istek.admin.storage.from(KOVA).upload(istek.yol, istek.bayt, {
    contentType: istek.contentType,
    cacheControl: istek.cacheControl,
    upsert: istek.upsert ?? false,
  });
  if (error) {
    throw new Error(error.message || "Depoya yüklenemedi.");
  }
  const { data } = istek.admin.storage.from(KOVA).getPublicUrl(istek.yol);
  return data.publicUrl;
}

function guvenliR2OnekiHazirla(onek: string): string | null {
  const ham = onek.trim().replace(/^\/+/, "");
  if (!ham) return null;
  if (ham.includes("..") || /%2e/i.test(ham) || ham.includes("\\") || /[?#\s]/.test(ham)) {
    return null;
  }
  const parcalar = ham.split("/").filter(Boolean);
  if (parcalar.length === 0) return null;
  if (parcalar.some((parca) => !/^[a-zA-Z0-9_-]+$/.test(parca))) {
    return null;
  }
  return `${parcalar.join("/")}/`;
}

export async function vitrinR2OnekSil(
  onek: string,
  fetcher?: typeof fetch,
): Promise<number> {
  const prefix = guvenliR2OnekiHazirla(onek);
  if (!prefix) return 0;

  try {
    const r2 = r2Yapilandirmasi();
    if (!r2) return 0;

    const aktifFetcher = fetcher ?? fetch;
    const canonicalUri = `/${awsEncode(r2.bucketName)}`;
    const silinecekler: string[] = [];
    const gorulenTokenlar = new Set<string>();
    let continuationToken: string | undefined;

    for (let sayfa = 0; sayfa < S3_MAX_SAYFA; sayfa++) {
      const queryParams: Array<[string, string]> = [
        ["list-type", "2"],
        ["max-keys", String(S3_LIST_LIMIT)],
        ["prefix", prefix],
      ];
      if (continuationToken) {
        queryParams.push(["continuation-token", continuationToken]);
      }

      const { url, headers } = imzaliR2Istek({
        r2,
        method: "GET",
        canonicalUri,
        queryParams,
      });
      const yanit = await aktifFetcher(url, { method: "GET", headers });
      if (!yanit.ok) {
        await yanit.body?.cancel();
        throw new Error(`R2 listeleme hatasi: HTTP ${yanit.status}`);
      }

      const xml = await yanit.text();
      const anahtarlar = xmlAnahtarlariCikar(xml).filter((k) => k.startsWith(prefix));
      silinecekler.push(...anahtarlar);

      const kesildi = /<IsTruncated>\s*true\s*<\/IsTruncated>/i.test(xml);
      const sonrakiToken = xmlTekEtiketOku(xml, "NextContinuationToken");
      if (!kesildi || !sonrakiToken || gorulenTokenlar.has(sonrakiToken)) break;
      gorulenTokenlar.add(sonrakiToken);
      continuationToken = sonrakiToken;
    }

    if (silinecekler.length === 0) return 0;

    let toplamSilinen = 0;
    for (let i = 0; i < silinecekler.length; i += S3_LIST_LIMIT) {
      const parca = silinecekler.slice(i, i + S3_LIST_LIMIT);
      const xmlGovde = `<?xml version="1.0" encoding="UTF-8"?><Delete>${parca
        .map((anahtar) => `<Object><Key>${xmlKacir(anahtar)}</Key></Object>`)
        .join("")}</Delete>`;
      const contentMd5 = createHash("md5").update(xmlGovde, "utf8").digest("base64");

      const { url, headers } = imzaliR2Istek({
        r2,
        method: "POST",
        canonicalUri,
        queryParams: [["delete", ""]],
        headers: {
          "content-type": "application/xml",
          "content-md5": contentMd5,
        },
        body: xmlGovde,
      });

      const yanit = await aktifFetcher(url, {
        method: "POST",
        headers,
        body: xmlGovde,
      });
      if (!yanit.ok) {
        await yanit.body?.cancel();
        throw new Error(`R2 silme hatasi: HTTP ${yanit.status}`);
      }

      const silmeXml = await yanit.text();
      const silinenSayisi = [...silmeXml.matchAll(/<Deleted>/gi)].length;
      const hataSayisi = [...silmeXml.matchAll(/<Error>/gi)].length;
      toplamSilinen +=
        silinenSayisi > 0 ? silinenSayisi : Math.max(0, parca.length - hataSayisi);
    }

    return toplamSilinen;
  } catch (hata) {
    console.error(
      "[gorsel-depo] R2 silme hatası:",
      hata instanceof Error ? hata.message : hata,
    );
    return 0;
  }
}

export async function vitrinR2GorselleriniSil(
  slug: string,
  fetcher?: typeof fetch,
): Promise<number> {
  const guvenliSlug = slug.replace(/[^a-zA-Z0-9-]/g, "");
  if (!guvenliSlug) return 0;
  return vitrinR2OnekSil(`${guvenliSlug}/`, fetcher);
}
