import { NextResponse } from "next/server";
import { randomUUID } from "node:crypto";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { verifyRecaptchaToken } from "@/lib/recaptchaServer";
import { PAYTR_LINK_API_URL, paytrCreateLinkPayload, paytrEnv } from "@/lib/paytr";
import { siparisOzetiMetni, whatsappBaglantisi } from "@/lib/siparisOzeti";

export const dynamic = "force-dynamic";

interface SiparisGovde {
  storeSlug?: unknown;
  customerName?: unknown;
  customerPhone?: unknown;
  customerNote?: unknown;
  fulfillment?: unknown;
  paymentMethod?: unknown;
  items?: unknown;
  recaptchaToken?: unknown;
}

interface SiparisKalemiIstek {
  productSlug: string;
  quantity: number;
}

const HATA_METNI: Record<string, string> = {
  STORE_NOT_FOUND: "Vitrin bulunamadı.",
  PRODUCT_NOT_FOUND: "Sepetteki bir ürün artık bulunmuyor. Sayfayı yenileyip tekrar dene.",
  PRODUCT_PRICE_MISSING: "Bu ürünün fiyatı belirlenmemiş; sipariş alınamıyor.",
  INVALID_QUANTITY: "Geçersiz adet.",
  INVALID_ITEMS: "Sepet boş olamaz.",
  INVALID_CUSTOMER_NAME: "İsim en az 2 karakter olmalı.",
  INVALID_CUSTOMER_PHONE: "Geçerli bir telefon numarası gir.",
  INVALID_CUSTOMER_NOTE: "Not çok uzun.",
  INVALID_FULFILLMENT: "Geçersiz teslim seçimi.",
  INVALID_PAYMENT_METHOD: "Geçersiz ödeme seçimi.",
  INVALID_AMOUNT: "Sipariş tutarı hesaplanamadı.",
  RATE_LIMITED: "Çok fazla sipariş denemesi yapıldı. Lütfen biraz sonra tekrar dene.",
};

function kalemAyristir(ham: unknown): SiparisKalemiIstek[] | null {
  if (!Array.isArray(ham) || ham.length === 0 || ham.length > 20) return null;
  const kalemler: SiparisKalemiIstek[] = [];
  for (const satir of ham) {
    const productSlug =
      typeof satir?.productSlug === "string" ? satir.productSlug.trim() : "";
    const quantity = typeof satir?.quantity === "number" ? Math.trunc(satir.quantity) : 0;
    if (!productSlug || productSlug.length > 160) return null;
    if (quantity < 1 || quantity > 99) return null;
    kalemler.push({ productSlug, quantity });
  }
  return kalemler;
}

async function odemeLinkiUret(
  origin: string,
  callbackId: string,
  urunAdi: string,
  amountKurus: number,
): Promise<string | null> {
  const env = paytrEnv();
  if (!env) return null;

  const payload = paytrCreateLinkPayload({
    merchantId: env.merchantId,
    merchantKey: env.merchantKey,
    merchantSalt: env.merchantSalt,
    name: urunAdi.slice(0, 100),
    callbackId,
    callbackLink: `${origin}/api/paytr/callback`,
    amountKurus,
  });

  const yanit = await fetch(PAYTR_LINK_API_URL, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: payload.toString(),
    cache: "no-store",
  });

  const govde = (await yanit.json().catch(() => null)) as {
    status?: string;
    link?: string;
    error_message?: string;
  } | null;

  if (!yanit.ok || !govde || govde.status !== "success" || !govde.link) {
    console.error(
      "[orders] PayTR link üretilemedi:",
      govde?.error_message ?? `http ${yanit.status}`,
    );
    return null;
  }
  return govde.link;
}

export async function POST(request: Request) {
  let govde: SiparisGovde;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const storeSlug =
    typeof govde.storeSlug === "string" ? govde.storeSlug.trim() : "";
  const customerName =
    typeof govde.customerName === "string" ? govde.customerName.trim() : "";
  const customerPhone =
    typeof govde.customerPhone === "string" ? govde.customerPhone.trim() : "";
  const customerNote =
    typeof govde.customerNote === "string" ? govde.customerNote.trim() : "";
  const fulfillment =
    typeof govde.fulfillment === "string" && govde.fulfillment === "delivery"
      ? "delivery"
      : "pickup";
  const paymentMethod =
    typeof govde.paymentMethod === "string" && govde.paymentMethod === "online"
      ? "online"
      : "cash";
  const items = kalemAyristir(govde.items);

  if (!storeSlug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }
  if (!items) {
    return NextResponse.json({ hata: HATA_METNI.INVALID_ITEMS }, { status: 400 });
  }

  const recaptchaSecret = (process.env.RECAPTCHA_SECRET_KEY || "").trim();
  if (recaptchaSecret) {
    const token =
      typeof govde.recaptchaToken === "string" ? govde.recaptchaToken.trim() : "";
    if (!token) {
      return NextResponse.json(
        { hata: "Güvenlik doğrulaması eksik. Lütfen sayfayı yenileyip tekrar dene." },
        { status: 403 },
      );
    }
    const dogrulama = await verifyRecaptchaToken(token, "order_create");
    if (!dogrulama.success) {
      console.warn("[orders] reCAPTCHA reddedildi:", dogrulama.error);
      return NextResponse.json(
        { hata: "Güvenlik doğrulaması başarısız. Lütfen sayfayı yenileyip tekrar dene." },
        { status: 403 },
      );
    }
  }

  const callbackId = `ord_${randomUUID().replace(/-/g, "")}`;

  const { data, error } = await getSupabaseAdmin().rpc("create_store_order", {
    p_store_slug: storeSlug,
    p_callback_id: callbackId,
    p_customer_name: customerName,
    p_customer_phone: customerPhone,
    p_customer_note: customerNote,
    p_fulfillment: fulfillment,
    p_payment_method: paymentMethod,
    p_items: items.map((kalem) => ({
      product_slug: kalem.productSlug,
      quantity: kalem.quantity,
    })),
  });

  if (error || !data) {
    const anahtar = error?.message ?? "";
    const metin = HATA_METNI[anahtar] ?? "Sipariş oluşturulamadı. Lütfen tekrar dene.";
    console.error("[orders] create_store_order failed:", anahtar);
    return NextResponse.json({ hata: metin }, { status: 400 });
  }

  const siparis = data as {
    order_id?: string;
    amount_kurus?: number;
    whatsapp?: string;
    store_name?: string;
    items?: Array<{
      product_name?: string;
      unit_price_kurus?: number;
      quantity?: number;
    }>;
  };
  const amountKurus =
    typeof siparis.amount_kurus === "number" ? siparis.amount_kurus : 0;
  const whatsapp = typeof siparis.whatsapp === "string" ? siparis.whatsapp : "";
  const storeName =
    typeof siparis.store_name === "string" && siparis.store_name.trim()
      ? siparis.store_name.trim()
      : storeSlug;

  const ozetMetni = siparisOzetiMetni({
    storeName,
    customerName,
    customerPhone,
    customerNote,
    fulfillment,
    paymentMethod,
    items: (siparis.items ?? []).map((kalem) => ({
      productName: typeof kalem.product_name === "string" ? kalem.product_name : "Ürün",
      quantity: typeof kalem.quantity === "number" ? kalem.quantity : 1,
      unitPriceKurus:
        typeof kalem.unit_price_kurus === "number" ? kalem.unit_price_kurus : 0,
    })),
    amountKurus,
  });
  const whatsappUrl = whatsappBaglantisi(whatsapp, ozetMetni);

  let paymentLink: string | null = null;
  let paymentUnavailable = false;
  if (paymentMethod === "online") {
    if (paytrEnv()) {
      paymentLink = await odemeLinkiUret(
        request.url.replace(/\/api\/orders.*$/, ""),
        callbackId,
        `${storeSlug} sipariş ödemesi`,
        amountKurus,
      );
      paymentUnavailable = paymentLink === null;
    } else {
      paymentUnavailable = true;
    }
  }

  return NextResponse.json({
    tamam: true,
    orderId: siparis.order_id ?? null,
    amountKurus,
    whatsappUrl,
    paymentLink,
    paymentUnavailable,
  });
}
