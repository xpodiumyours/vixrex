import { beforeAll, describe, expect, it, vi } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { NextRequest } from "next/server";

/**
 * PANO ÖLÇÜM ROTASI SÖZLEŞMESİ (2026-08-28).
 *
 * Bu rota iki ölçüm RPC'si çağırıyor ve İKİSİ AYNI YETKİYLE ÇAĞRILAMIYOR —
 * canlıdan ölçüldü:
 *
 *   get_store_premium_status     → anon ✓ authenticated ✓ service_role ✓
 *   get_today_vitrin_view_count  → anon ✓ authenticated ✗ service_role ✓
 *
 * İlk hâlinde ikisi de kullanıcı jetonuyla çağrılıyordu; ziyaret sayacı
 * her istekte yetki hatası veriyor, rota 500 dönüyor ve pano ne sayı ne
 * premium durumu gösterebiliyordu. Yani özellik hiç çalışmıyordu.
 *
 * Aşağıdaki iddialar o ayrımı kilitliyor. Bu projede "yanlış istemciyle
 * RPC çağırma" hatası beş kez çıktı; altıncısı olmasın.
 */

const ROTA = resolve(
  __dirname,
  "../../src/app/api/owner-dashboard/summary/route.ts"
);
const kaynak = readFileSync(ROTA, "utf8");

const { mockKullaniciRpc, mockYoneticiRpc, mockGetUser } = vi.hoisted(() => ({
  mockKullaniciRpc: vi.fn(),
  mockYoneticiRpc: vi.fn(),
  mockGetUser: vi.fn(),
}));

vi.mock("@supabase/supabase-js", () => ({
  createClient: vi.fn(() => ({
    auth: { getUser: mockGetUser },
    rpc: mockKullaniciRpc,
  })),
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: vi.fn(() => ({ rpc: mockYoneticiRpc })),
}));

import { GET } from "@/app/api/owner-dashboard/summary/route";

beforeAll(() => {
  // Rota env yoksa "Sunucu yapılandırması eksik" ile 500 döner; testte
  // gerçek anahtar gerekmiyor, yalnız varlıkları aranıyor.
  process.env.NEXT_PUBLIC_SUPABASE_URL ||= "http://localhost:54321";
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||= "test-anon-key";
});

function istek(jeton?: string) {
  const headers: Record<string, string> = {};
  if (jeton) headers.authorization = `Bearer ${jeton}`;
  return new NextRequest("http://localhost/api/owner-dashboard/summary", {
    headers,
  });
}

describe("pano ölçüm rotası yetki sözleşmesi", () => {
  it("ziyaret sayacı kullanıcı jetonuyla çağrılmaz", () => {
    // Kaynak taraması: authenticated rolünün bu RPC'de yetkisi yok.
    expect(kaynak).not.toMatch(
      /supabaseUser\s*\.\s*rpc\(\s*["']get_today_vitrin_view_count["']/
    );
    expect(kaynak).toMatch(
      /getSupabaseAdmin\(\)\s*\.\s*rpc\(\s*["']get_today_vitrin_view_count["']/
    );
  });

  it("sahiplik sorgusu yönetici istemcisiyle çağrılmaz", () => {
    // `bootstrap_owner_state` auth.uid() istiyor; yönetici istemcisinde boş.
    expect(kaynak).not.toMatch(
      /getSupabaseAdmin\(\)\s*\.\s*rpc\(\s*["']bootstrap_owner_state["']/
    );
  });

  it("jeton yokken 401 döner ve hiçbir RPC çağrılmaz", async () => {
    mockKullaniciRpc.mockClear();
    mockYoneticiRpc.mockClear();

    const yanit = await GET(istek());

    expect(yanit.status).toBe(401);
    expect(mockKullaniciRpc).not.toHaveBeenCalled();
    expect(mockYoneticiRpc).not.toHaveBeenCalled();
  });

  it("düzenleme anahtarını tarayıcıya taşımaz", async () => {
    mockKullaniciRpc.mockClear();
    mockYoneticiRpc.mockClear();
    mockGetUser.mockResolvedValue({
      data: { user: { id: "u1", is_anonymous: false } },
      error: null,
    });
    mockKullaniciRpc.mockImplementation((ad: string) => {
      if (ad === "bootstrap_owner_state") {
        return Promise.resolve({
          data: { has_store: true, slug: "deneme", edit_token: "gizli-anahtar" },
          error: null,
        });
      }
      return Promise.resolve({
        data: { is_premium: false, premium_expires_at: null },
        error: null,
      });
    });
    mockYoneticiRpc.mockResolvedValue({ data: 7, error: null });

    const yanit = await GET(istek("jeton"));
    const govde = await yanit.json();

    expect(yanit.status).toBe(200);
    expect(JSON.stringify(govde)).not.toContain("gizli-anahtar");
    expect(govde.bugunkuZiyaret).toBe(7);
  });
});
