import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";
import { verifyRecaptchaToken } from "@/lib/recaptchaServer";

// V-21 (attack-vectors.md, 2026-08-18): BookingWizardClient.tsx reCAPTCHA
// fişini alıp yalnız console.log ediyordu, create_appointment_request
// RPC'sine hiç göndermiyordu — RPC anon anahtarla doğrudan çağrılabildiği
// için (Flutter uygulaması da AYNI RPC'yi doğrudan çağırıyor, bkz.
// lib/services/booking_service.dart) bu doğrulamayı RPC seviyesinde
// zorunlu kılmak Flutter'ı kırar.
//
// ÇÖZÜM: yalnız WEB akışı için bu ara katman eklendi. Web istemcisi artık
// RPC'yi doğrudan değil bu rotayı çağırıyor; rota reCAPTCHA'yı sunucu
// tarafında doğrulayıp SONRA aynı RPC'yi (aynı anon istemciyle, davranış
// değişmeden) çağırıyor. Flutter'ın doğrudan RPC çağrısı DOKUNULMADI —
// bugünkü davranışı aynen korunuyor, bu yalnız web'in girdiği ek bir kapı.

interface CreateBookingBody {
  storeSlug?: unknown;
  customerName?: unknown;
  customerPhone?: unknown;
  customerNotes?: unknown;
  serviceTitle?: unknown;
  servicePrice?: unknown;
  serviceDuration?: unknown;
  appointmentTime?: unknown;
  recaptchaToken?: unknown;
}

export async function POST(request: Request) {
  let body: CreateBookingBody;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: { message: "Geçersiz istek." } }, { status: 400 });
  }

  const storeSlug = typeof body.storeSlug === "string" ? body.storeSlug.trim() : "";
  const customerName = typeof body.customerName === "string" ? body.customerName.trim() : "";
  const customerPhone = typeof body.customerPhone === "string" ? body.customerPhone.trim() : "";
  const customerNotes = typeof body.customerNotes === "string" ? body.customerNotes.trim() : "";
  const serviceTitle = typeof body.serviceTitle === "string" ? body.serviceTitle.trim() : "";
  const servicePrice = typeof body.servicePrice === "string" ? body.servicePrice : "";
  const serviceDuration =
    typeof body.serviceDuration === "number" ? body.serviceDuration : 30;
  const appointmentTime =
    typeof body.appointmentTime === "string" ? body.appointmentTime : "";
  const recaptchaToken =
    typeof body.recaptchaToken === "string" ? body.recaptchaToken.trim() : "";

  if (!storeSlug || !customerName || !customerPhone || !serviceTitle || !appointmentTime) {
    return NextResponse.json(
      { error: { message: "Eksik randevu bilgisi." } },
      { status: 400 },
    );
  }

  if (!recaptchaToken) {
    return NextResponse.json(
      { error: { message: "Güvenlik doğrulaması eksik. Lütfen sayfayı yenileyip tekrar dene." } },
      { status: 403 },
    );
  }

  const recaptchaResult = await verifyRecaptchaToken(recaptchaToken, "booking_create");
  if (!recaptchaResult.success) {
    console.warn("[create-booking] reCAPTCHA reddedildi:", recaptchaResult.error);
    return NextResponse.json(
      { error: { message: "Güvenlik doğrulaması başarısız. Lütfen sayfayı yenileyip tekrar dene." } },
      { status: 403 },
    );
  }

  const { data, error } = await supabase.rpc("create_appointment_request", {
    p_store_slug: storeSlug,
    p_customer_name: customerName,
    p_customer_phone: customerPhone,
    p_customer_notes: customerNotes,
    p_service_title: serviceTitle,
    p_service_price: servicePrice,
    p_service_duration: serviceDuration,
    p_appointment_time: appointmentTime,
  });

  if (error) {
    console.error("[create-booking] RPC hatası:", error.message);
    return NextResponse.json({ error: { message: error.message } }, { status: 400 });
  }

  return NextResponse.json({ data });
}
