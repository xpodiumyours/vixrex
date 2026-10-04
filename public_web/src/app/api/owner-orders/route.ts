import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

export const dynamic = "force-dynamic";

const GECERLI_DURUMLAR = new Set(["new", "confirmed", "delivered", "cancelled"]);

const DURUM_METNI: Record<string, string> = {
  new: "Yeni",
  confirmed: "Onaylandı",
  delivered: "Teslim Edildi",
  cancelled: "İptal",
};

function siparisYaniti(satir: {
  id: string;
  callback_id: string;
  customer_name: string;
  customer_phone: string;
  customer_note: string;
  fulfillment: string;
  payment_method: string;
  status: string;
  payment_status: string;
  amount_kurus: number;
  currency: string;
  created_at: string;
  paid_at: string | null;
  store_order_items: Array<{
    id: string;
    product_name: string;
    unit_price_kurus: number;
    quantity: number;
  }>;
}) {
  return {
    id: satir.id,
    customerName: satir.customer_name,
    customerPhone: satir.customer_phone,
    customerNote: satir.customer_note,
    fulfillment: satir.fulfillment,
    paymentMethod: satir.payment_method,
    status: satir.status,
    statusLabel: DURUM_METNI[satir.status] ?? satir.status,
    paymentStatus: satir.payment_status,
    amountKurus: satir.amount_kurus,
    currency: satir.currency,
    createdAt: satir.created_at,
    paidAt: satir.paid_at,
    items: (satir.store_order_items ?? []).map((kalem) => ({
      id: kalem.id,
      productName: kalem.product_name,
      unitPriceKurus: kalem.unit_price_kurus,
      quantity: kalem.quantity,
    })),
  };
}

const SIPARIS_SECIM =
  "id,callback_id,customer_name,customer_phone,customer_note,fulfillment,payment_method,status,payment_status,amount_kurus,currency,created_at,paid_at,store_order_items(id,product_name,unit_price_kurus,quantity)";

async function oturumDogrula(request: NextRequest, slug: string) {
  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  return verifyOwnerSession(ownerSessionCookie, slug);
}

export async function GET(request: NextRequest) {
  const slug = request.nextUrl.searchParams.get("slug")?.trim() ?? "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }

  const ownerSession = await oturumDogrula(request, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumunuz geçersiz veya süresi dolmuş." },
      { status: 401 },
    );
  }

  const { data, error } = await getSupabaseAdmin()
    .from("store_orders")
    .select(SIPARIS_SECIM)
    .eq("store_id", ownerSession.storeId)
    .order("created_at", { ascending: false })
    .limit(100);

  if (error) {
    console.error("[owner-orders] liste okunamadı:", error.message);
    return NextResponse.json({ hata: "Siparişler yüklenemedi." }, { status: 500 });
  }

  return NextResponse.json({
    tamam: true,
    siparisler: ((data as Parameters<typeof siparisYaniti>[0][]) ?? []).map(siparisYaniti),
  });
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const orderId = typeof govde.orderId === "string" ? govde.orderId.trim() : "";
  const status = typeof govde.status === "string" ? govde.status.trim() : "";

  if (!slug || !orderId) {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }
  if (!GECERLI_DURUMLAR.has(status)) {
    return NextResponse.json({ hata: "Geçersiz durum." }, { status: 400 });
  }

  const ownerSession = await oturumDogrula(request, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumunuz geçersiz veya süresi dolmuş." },
      { status: 401 },
    );
  }

  const { data, error } = await getSupabaseAdmin()
    .from("store_orders")
    .update({ status })
    .eq("id", orderId)
    .eq("store_id", ownerSession.storeId)
    .select(SIPARIS_SECIM)
    .single();

  if (error || !data) {
    console.error("[owner-orders] durum güncellenemedi:", error?.message);
    return NextResponse.json({ hata: "Sipariş güncellenemedi." }, { status: 400 });
  }

  return NextResponse.json({
    tamam: true,
    siparis: siparisYaniti(data as Parameters<typeof siparisYaniti>[0]),
  });
}
