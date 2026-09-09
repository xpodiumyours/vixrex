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

import ProfilPage from "@/app/app/profil/page";

function renderProfil() {
  return renderToStaticMarkup(createElement(ProfilPage));
}

describe("profil parite — gerçek render", () => {
  it("ilk render yükleme durumunu erişilebilir şekilde gerçekten çizer", () => {
    const html = renderProfil();

    expect(html).toContain('role="status"');
    expect(html).toContain('aria-live="polite"');
    expect(html).toContain("Yükleniyor…");
    expect(html).toContain('aria-hidden="true"');
  });

  it.todo(
    "Vitrin Bağlantısı / QR / Ayarlar içerikleri useEffect sonrası görünür; Katman C jsdom etkileşim testiyle kanıtlanacak",
  );
});
