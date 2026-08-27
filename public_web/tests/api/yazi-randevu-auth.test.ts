import { describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

/**
 * YAZI VE RANDEVU API'LERİNİN YETKİ SÖZLEŞMESİ (2026-08-27).
 *
 * Randevu tarafı için ayrı bir iddia var ve sebebi somut: bu rota ilk
 * hâlinde `respond_to_appointment` RPC'sini `service_role` istemcisiyle
 * çağırıyordu. O fonksiyon yetkiyi `auth.uid()` üzerinden kuruyor (canlı
 * gövdeden okundu); `service_role`'de `auth.uid()` NULL olduğu için
 * karşılaştırma hiçbir zaman tutmuyordu ve HER çağrı 'UNAUTHORIZED' ile
 * düşüyordu — özellik hiç çalışmıyordu.
 *
 * Artık POST, çağıranın Supabase erişim jetonunu istiyor. Aşağıdaki iki
 * iddia o düzeltmeyi kilitliyor: jeton yoksa 401, ve o durumda yönetici
 * istemcisine hiç dokunulmuyor.
 */

const { mockGet, mockGetSupabaseAdmin } = vi.hoisted(() => ({
  mockGet: vi.fn(() => undefined),
  mockGetSupabaseAdmin: vi.fn(),
}));

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({ get: mockGet })),
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: mockGetSupabaseAdmin,
}));

import { POST as YAZI_POST } from "@/app/api/articles/route";
import { POST as RANDEVU_POST } from "@/app/api/appointments/route";

const SLUG = "deneme-vitrin";
const RANDEVU_ID = "22222222-2222-2222-2222-222222222222";

function istek(url: string, govde: Record<string, unknown>, jeton?: string) {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (jeton) headers.authorization = `Bearer ${jeton}`;

  return new NextRequest(url, {
    method: "POST",
    headers,
    body: JSON.stringify(govde),
  });
}

describe("/api/articles sahip oturumu sözleşmesi", () => {
  it("çerez yoksa 401 döner ve yönetici istemcisine dokunmaz", async () => {
    const response = await YAZI_POST(
      istek("http://localhost/api/articles", { slug: SLUG, title: "Deneme" })
    );

    expect(response.status).toBe(401);
    expect(mockGetSupabaseAdmin).not.toHaveBeenCalled();
  });
});

describe("/api/appointments yetki sözleşmesi", () => {
  it("çerez yoksa 401 döner", async () => {
    const response = await RANDEVU_POST(
      istek("http://localhost/api/appointments", {
        slug: SLUG,
        appointmentId: RANDEVU_ID,
        action: "confirm",
      })
    );

    expect(response.status).toBe(401);
    expect(mockGetSupabaseAdmin).not.toHaveBeenCalled();
  });

  it("Supabase erişim jetonu olmadan RPC çağrılmaz", async () => {
    // Sahip çerezi geçerli olsa bile jeton yoksa durmalı: RPC `auth.uid()`
    // istiyor, jetonsuz çağrı her zaman UNAUTHORIZED ile düşerdi ve
    // kullanıcı bunu "sunucu bozuk" diye görürdü.
    const response = await RANDEVU_POST(
      istek("http://localhost/api/appointments", {
        slug: SLUG,
        appointmentId: RANDEVU_ID,
        action: "confirm",
      })
    );

    expect(response.status).toBe(401);
    expect(mockGetSupabaseAdmin).not.toHaveBeenCalled();
  });
});
