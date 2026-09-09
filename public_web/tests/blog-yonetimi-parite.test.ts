import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({ push: vi.fn() }));

vi.mock("next/navigation", () => ({
  useParams: () => ({ slug: "test-vitrin" }),
  useRouter: () => ({ push: mocks.push }),
}));
vi.mock("@/lib/supabase", () => ({
  supabase: {
    auth: { getSession: vi.fn(), signInAnonymously: vi.fn() },
  },
}));
vi.mock("@/lib/ownerCookie", () => ({ sahipOturumuAc: vi.fn() }));

import BlogYonetimPage from "@/app/v/[slug]/blog-yonetim/page";

function renderBlog() {
  return renderToStaticMarkup(createElement(BlogYonetimPage));
}

describe("blog yönetimi parite — gerçek render", () => {
  it("yönetim yüzeyi ve yeni yazı alanını gerçekten çizer", () => {
    const html = renderBlog();

    expect(html).toContain("Blog Yönetimi");
    expect(html).toContain("Yazı Yönetimi");
    expect(html).toContain("Yeni Yazı Oluştur");
    expect(html).toContain('placeholder="Yazı başlığı..."');
    expect(html).toContain(">Oluştur</button>");
    expect(html).toContain('href="/v/test-vitrin"');
  });

  it.todo(
    "Taslak / İnceleme / Yayında durumları ve SEO puanı yüklü yazı verisi sonrası görünür; etkileşimli veri yükleme katmanında kanıtlanacak",
  );
});
