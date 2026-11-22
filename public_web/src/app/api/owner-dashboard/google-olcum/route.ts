import { createSign } from "node:crypto";
import { createClient } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";

const OLUMLU_OLAYLAR = ["whatsapp_click", "phone_click", "directions_click"];

type BootstrapSonucu = { has_store?: boolean; slug?: string };

function base64url(deger: string | Buffer) {
  return Buffer.from(deger)
    .toString("base64")
    .replace(/=+$/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function googleAnahtari() {
  const email = (process.env.GOOGLE_ANALYTICS_CLIENT_EMAIL ?? "").trim();
  const anahtar = (process.env.GOOGLE_ANALYTICS_PRIVATE_KEY ?? "").replace(/\\n/g, "\n").trim();
  const mulk = (process.env.GA4_PROPERTY_ID ?? "").trim();
  if (!email || !anahtar || !mulk) return null;
  return { email, anahtar, mulk };
}

async function erisimJetonu(email: string, anahtar: string) {
  const simdi = Math.floor(Date.now() / 1000);
  const baslik = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const govde = base64url(
    JSON.stringify({
      iss: email,
      scope: "https://www.googleapis.com/auth/analytics.readonly",
      aud: "https://oauth2.googleapis.com/token",
      iat: simdi,
      exp: simdi + 3600,
    }),
  );
  const imzaci = createSign("RSA-SHA256");
  imzaci.update(`${baslik}.${govde}`);
  imzaci.end();
  const imza = base64url(imzaci.sign(anahtar));

  const yanit = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${baslik}.${govde}.${imza}`,
    }),
    cache: "no-store",
  });

  if (!yanit.ok) return null;
  const veri = (await yanit.json()) as { access_token?: string };
  return veri.access_token ?? null;
}

async function rapor(
  mulk: string,
  jeton: string,
  govde: Record<string, unknown>,
) {
  const yanit = await fetch(
    `https://analyticsdata.googleapis.com/v1beta/properties/${mulk}:runReport`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${jeton}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(govde),
      cache: "no-store",
    },
  );
  if (!yanit.ok) return null;
  return (await yanit.json()) as {
    rows?: Array<{ dimensionValues?: Array<{ value?: string }>; metricValues?: Array<{ value?: string }> }>;
  };
}

export async function GET(request: NextRequest) {
  const anahtar = googleAnahtari();
  if (!anahtar) return new NextResponse(null, { status: 204 });

  const bearerToken = request.headers.get("authorization")?.replace("Bearer ", "").trim();
  if (!bearerToken) return new NextResponse(null, { status: 401 });

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "";
  const supabaseAnonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || process.env.SUPABASE_PUBLISHABLE_KEY || "";
  if (!supabaseUrl || !supabaseAnonKey) return new NextResponse(null, { status: 500 });

  const supabaseUser = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${bearerToken}` } },
  });

  const {
    data: { user },
    error: authError,
  } = await supabaseUser.auth.getUser(bearerToken);
  if (authError || !user || user.is_anonymous) return new NextResponse(null, { status: 401 });

  const { data: durum, error: durumHatasi } = await supabaseUser.rpc("bootstrap_owner_state");
  if (durumHatasi) return new NextResponse(null, { status: 500 });

  const slug = ((durum ?? {}) as BootstrapSonucu).slug?.trim() ?? "";
  if (!slug) return new NextResponse(null, { status: 404 });

  const gun = Math.min(90, Math.max(1, Number(request.nextUrl.searchParams.get("gun") ?? 7) || 7));
  const jeton = await erisimJetonu(anahtar.email, anahtar.anahtar);
  if (!jeton) return new NextResponse(null, { status: 204 });

  const vitrinYolu = `^/v/${slug.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(/urun/.*)?$`;
  const olayYolu = `^/v/${slug.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(/|$)`;

  const [sayfaRaporu, olayRaporu, kaynakRaporu] = await Promise.all([
    rapor(anahtar.mulk, jeton, {
      dateRanges: [{ startDate: `${gun}daysAgo`, endDate: "today" }],
      dimensions: [{ name: "pagePath" }],
      metrics: [{ name: "screenPageViews" }],
      dimensionFilter: {
        filter: { fieldName: "pagePath", stringFilter: { matchType: "FULL_REGEXP", value: vitrinYolu } },
      },
      limit: 1000,
    }),
    rapor(anahtar.mulk, jeton, {
      dateRanges: [{ startDate: `${gun}daysAgo`, endDate: "today" }],
      dimensions: [{ name: "eventName" }, { name: "pagePath" }],
      metrics: [{ name: "eventCount" }],
      dimensionFilter: {
        andGroup: {
          expressions: [
            {
              filter: {
                fieldName: "eventName",
                inListFilter: { values: OLUMLU_OLAYLAR },
              },
            },
            {
              filter: { fieldName: "pagePath", stringFilter: { matchType: "FULL_REGEXP", value: olayYolu } },
            },
          ],
        },
      },
      limit: 10000,
    }),
    rapor(anahtar.mulk, jeton, {
      dateRanges: [{ startDate: `${gun}daysAgo`, endDate: "today" }],
      dimensions: [{ name: "pageReferrer" }],
      metrics: [{ name: "screenPageViews" }],
      dimensionFilter: {
        andGroup: {
          expressions: [
            {
              filter: { fieldName: "pagePath", stringFilter: { matchType: "FULL_REGEXP", value: olayYolu } },
            },
            {
              notExpression: {
                filter: {
                  fieldName: "pageReferrer",
                  stringFilter: { matchType: "CONTAINS", value: "vixrex.com" },
                },
              },
            },
          ],
        },
      },
      limit: 100,
    }),
  ]);

  if (!sayfaRaporu || !olayRaporu) return new NextResponse(null, { status: 502 });

  const urunOnEki = `/v/${slug}/urun/`;
  let vitrin = 0;
  let urun = 0;
  for (const satir of sayfaRaporu.rows ?? []) {
    const yol = satir.dimensionValues?.[0]?.value ?? "";
    const adet = Number(satir.metricValues?.[0]?.value ?? 0) || 0;
    if (yol.startsWith(urunOnEki)) urun += adet;
    else vitrin += adet;
  }

  const olaylar: Record<string, number> = { whatsapp_click: 0, phone_click: 0, directions_click: 0 };
  for (const satir of olayRaporu.rows ?? []) {
    const ad = satir.dimensionValues?.[0]?.value ?? "";
    if (!Object.hasOwn(olaylar, ad)) continue;
    olaylar[ad] += Number(satir.metricValues?.[0]?.value ?? 0) || 0;
  }

  const kaynaklar: Record<string, number> = {
    google: 0,
    haritalar: 0,
    dogrudan: 0,
    instagram: 0,
    diger: 0,
  };
  for (const satir of kaynakRaporu?.rows ?? []) {
    const kaynak = (satir.dimensionValues?.[0]?.value ?? "").toLowerCase();
    const adet = Number(satir.metricValues?.[0]?.value ?? 0) || 0;
    if (!kaynak) kaynaklar.dogrudan += adet;
    else if (kaynak.includes("maps.") || kaynak.includes("/maps")) kaynaklar.haritalar += adet;
    else if (kaynak.includes("google.")) kaynaklar.google += adet;
    else if (kaynak.includes("instagram")) kaynaklar.instagram += adet;
    else kaynaklar.diger += adet;
  }

  return NextResponse.json(
    {
      kaynak: "Google Analytics 4",
      gun,
      vitrinGoruntuleme: vitrin,
      urunGoruntuleme: urun,
      whatsapp: olaylar.whatsapp_click,
      telefon: olaylar.phone_click,
      yolTarifi: olaylar.directions_click,
      kaynaklar,
    },
    { headers: { "cache-control": "private, no-store" } },
  );
}
