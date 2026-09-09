import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({ push: vi.fn() }));

vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: mocks.push }),
}));
vi.mock("@/lib/supabase", () => ({
  supabase: {
    auth: { getSession: vi.fn(), signInAnonymously: vi.fn() },
    rpc: vi.fn(),
    from: vi.fn(),
  },
}));

import AyarlarPage from "@/app/app/ayarlar/page";

function renderAyarlar() {
  return renderToStaticMarkup(createElement(AyarlarPage));
}

describe("ayarlar parite — gerçek render", () => {
  it("ilk render gerçek yükleme yüzeyini çizer", () => {
    const html = renderAyarlar();

    expect(html).toContain("owner-shell");
    expect(html).toContain("owner-card");
    expect(html).toContain("Yükleniyor…");
  });

  it.todo(
    "Profil / Hesap Yönetimi / Verilerimi İndir / Yasal içerikleri useEffect sonrası görünür; Katman C jsdom ile kanıtlanacak",
  );
});
