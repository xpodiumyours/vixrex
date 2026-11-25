import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  from: vi.fn(),
  inCall: vi.fn(),
  eqCall: vi.fn(),
  notFound: vi.fn(() => {
    throw new Error("NEXT_NOT_FOUND");
  }),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    from: mocks.from,
    auth: {
      signInWithOAuth: vi.fn(async () => ({ error: null })),
    },
  },
}));

vi.mock("next/navigation", () => ({
  notFound: mocks.notFound,
}));

vi.mock("next/link", () => ({
  default: (props: { href: string; children?: unknown; className?: string }) =>
    createElement(
      "a",
      { href: props.href, className: props.className },
      props.children as never,
    ),
}));

vi.mock("next/font/local", () => ({
  default: () => ({ variable: "--font-mock" }),
}));

vi.mock("@sentry/nextjs", () => ({
  ErrorBoundary: (props: { children?: unknown }) => props.children,
}));

vi.mock("@/app/globals.css", () => ({}));
vi.mock("@/app/vixrex-app-ui.css", () => ({}));
vi.mock("@/components/cookie-consent/CookieConsentRoot", () => ({
  CookieConsentRoot: () => null,
}));
vi.mock("@/components/recaptcha/RecaptchaProvider", () => ({
  RecaptchaProvider: (props: { children?: unknown }) => props.children,
}));
vi.mock("@/components/app/AppShellBoundary", () => ({
  AppShellBoundary: (props: { children?: unknown }) => props.children,
}));
vi.mock("@/components/site/SiteChromeBoundary", () => ({
  SiteChromeBoundary: (props: { children?: unknown }) => props.children,
}));
vi.mock("@/components/site/SiteFooter", () => ({
  SiteFooter: () => null,
}));
vi.mock("@/components/site/SiteHeader", () => ({
  SiteHeader: () => null,
}));
vi.mock("@/lib/jsonLd", () => ({
  organizationJsonLd: () => ({}),
  webSiteJsonLd: () => ({}),
  safeJsonLdHtml: () => "{}",
}));
vi.mock("@/lib/siteUrl", () => ({
  getSiteUrl: () => "https://vixrex.com",
}));
vi.mock("@/data/blogYazilari", () => ({
  blogYayindaMi: () => false,
}));
vi.mock("@/components/landing/BlogRehberleri", () => ({
  BlogRehberleri: () => null,
}));
vi.mock("@/components/landing/ComparisonSection", () => ({
  ComparisonSection: () => null,
}));
vi.mock("@/components/landing/FeaturesSection", () => ({
  FeaturesSection: () => null,
}));
vi.mock("@/components/landing/LandingChatWrapper", () => ({
  LandingChatWrapper: () => null,
}));
vi.mock("@/components/landing/StepsSection", () => ({
  StepsSection: () => null,
}));
vi.mock("@/components/landing/TemplateCatalog", () => ({
  TemplateCatalog: () => null,
}));
vi.mock("@/components/landing/TrustBand", () => ({
  TrustBand: () => null,
}));
vi.mock("@/components/landing/ValueBand", () => ({
  ValueBand: () => null,
}));
vi.mock("@/components/landing/mockupProfilleri", () => ({
  mockupProfilleriniGetir: async () => [],
}));

import LegalTypePage from "@/app/legal/[type]/page";
import PrivacyPage from "@/app/privacy/page";
import GirisPage from "@/app/giris/page";
import KayitPage from "@/app/kayit/page";
import { GoogleGirisButonu } from "@/components/owner/GoogleGirisButonu";
import { metadata as rootMetadata } from "@/app/layout";
import { metadata as siteLayoutMetadata } from "@/app/(site)/layout";
import { metadata as homeMetadata } from "@/app/(site)/page";

function kurLegalSupabaseMock(data: unknown) {
  const result = { data, error: null };
  const builder: Record<string, unknown> = {
    in: (col: string, values: unknown) => {
      mocks.inCall(col, values);
      return builder;
    },
    eq: (col: string, val: unknown) => {
      mocks.eqCall(col, val);
      return builder;
    },
    limit: () => builder,
    maybeSingle: async () => result,
  };

  mocks.from.mockReturnValue({
    select: () => builder,
  });
}

describe("Google OAuth, Play yasal gereksinimleri ve SEO tam uyum paketi", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("LegalTypePage (data-deletion ve 404 sınırları)", () => {
    it("data-deletion için DB'den dataDeletion döndüğünde 404 fırlatmadan render eder", async () => {
      kurLegalSupabaseMock({
        title: "Veri Silme Talebi",
        subtitle: "Hesabınızı ve verilerinizi nasıl silebileceğiniz.",
        version: "data-deletion-2026-08-28",
        sections: [
          {
            title: "Uygulama İçinden Silme",
            body: "Hesap ve Veri Yönetimi ekranından silebilirsiniz.",
          },
          {
            title: "E-posta ile Talep",
            body: "destek@vixrex.com adresine yazabilirsiniz. En geç 30 gün içinde sonuçlandırılır.",
          },
        ],
      });

      const html = renderToStaticMarkup(
        await LegalTypePage({ params: Promise.resolve({ type: "data-deletion" }) }),
      );

      expect(mocks.notFound).not.toHaveBeenCalled();
      expect(mocks.inCall).toHaveBeenCalledWith("document_type", [
        "data-deletion",
        "dataDeletion",
      ]);
      expect(html).toContain("Veri Silme Talebi");
      expect(html).toContain("Uygulama İçinden Silme");
      expect(html).toContain("destek@vixrex.com");
      expect(html).toContain("30 gün");
    });

    it("data-deletion için DB null döndüğünde 404 fırlatmadan kurumsal yedek içeriği render eder", async () => {
      kurLegalSupabaseMock(null);

      const html = renderToStaticMarkup(
        await LegalTypePage({ params: Promise.resolve({ type: "data-deletion" }) }),
      );

      expect(mocks.notFound).not.toHaveBeenCalled();
      expect(html).toContain("Hesap ve Veri Silme");
      expect(html).toContain("Uygulama İçinden Silme");
      expect(html).toContain("Silinen Veriler");
      expect(html).toContain("E-posta ile Talep");
      expect(html).toContain("destek@vixrex.com");
      expect(html).toContain("30 gün");
    });

    it("geçersiz type için notFound fırlatır", async () => {
      kurLegalSupabaseMock(null);

      await expect(
        LegalTypePage({ params: Promise.resolve({ type: "bilinmeyen-tur" }) }),
      ).rejects.toThrow("NEXT_NOT_FOUND");
      expect(mocks.notFound).toHaveBeenCalledOnce();
    });

    it("privacy, terms ve consent türlerinde DB null döndüğünde notFound fırlatır", async () => {
      kurLegalSupabaseMock(null);

      for (const type of ["privacy", "terms", "consent"]) {
        mocks.notFound.mockClear();
        await expect(
          LegalTypePage({ params: Promise.resolve({ type }) }),
        ).rejects.toThrow("NEXT_NOT_FOUND");
        expect(mocks.notFound).toHaveBeenCalledOnce();
      }
    });
  });

  describe("PrivacyPage (Google OAuth & Play 6 zorunlu beyan)", () => {
    it("AI/ML eğitim yasağı, Limited Use, HTTPS/TLS, RLS, silme yolu ve kapsamları içerir", () => {
      const html = renderToStaticMarkup(createElement(PrivacyPage));

      expect(html).toContain("openid");
      expect(html).toContain("email");
      expect(html).toContain("profile");
      expect(html).toContain("ad-soyad");
      expect(html).toContain("e-posta adresi");
      expect(html).toContain("profil fotoğrafı");
      expect(html).toContain("kimlik doğrulama");
      expect(html).toContain("Limited Use");
      expect(html).toContain("Google API Hizmetleri Kullanıcı Verileri Politikası");
      expect(html).toContain("AI/ML");
      expect(html).toContain("makine öğrenmesi");
      expect(html).toContain("HTTPS/TLS");
      expect(html).toContain("RLS");
      expect(html).toContain('href="/legal/data-deletion"');
      expect(html).toContain("destek@vixrex.com");
      expect(html).toContain("30 gün");
    });
  });

  describe("GirisPage, KayitPage ve GoogleGirisButonu", () => {
    it("GirisPage resmi 4 renkli Google G SVG ve 'Google ile oturum açın' metnini render eder", () => {
      const html = renderToStaticMarkup(createElement(GirisPage));

      expect(html).toContain('viewBox="0 0 24 24"');
      expect(html).toContain("#4285F4");
      expect(html).toContain("#34A853");
      expect(html).toContain("#FBBC05");
      expect(html).toContain("#EA4335");
      expect(html).toContain("#FFFFFF");
      expect(html).toContain("#747775");
      expect(html).toContain("#1F1F1F");
      expect(html).toContain("Google ile oturum açın");
    });

    it("KayitPage resmi 4 renkli Google G SVG ve 'Google ile oturum açın' metnini render eder", () => {
      const html = renderToStaticMarkup(createElement(KayitPage));

      expect(html).toContain('viewBox="0 0 24 24"');
      expect(html).toContain("#4285F4");
      expect(html).toContain("#34A853");
      expect(html).toContain("#FBBC05");
      expect(html).toContain("#EA4335");
      expect(html).toContain("Google ile oturum açın");
    });

    it("GoogleGirisButonu disabled iken 'Google açılıyor…' yazar ve devre dışı kalır", () => {
      const html = renderToStaticMarkup(
        createElement(GoogleGirisButonu, { disabled: true, onClick: () => {} }),
      );

      expect(html).toContain("disabled");
      expect(html).toContain("Google açılıyor…");
      expect(html).not.toContain("Google ile oturum açın");
    });
  });

  describe("SEO ve Robots Metadata ayrımı", () => {
    it("kök layout.tsx metadata içinde robots bulunmaz", () => {
      expect(rootMetadata.robots).toBeUndefined();
    });

    it("(site)/layout.tsx metadata içinde index, follow ve max-image-preview: large bulunur", () => {
      expect(siteLayoutMetadata.robots).toEqual({
        index: true,
        follow: true,
        googleBot: {
          "max-image-preview": "large",
        },
      });
    });

    it("(site)/page.tsx metadata içinde openGraph.images ve twitter.images bulunur", () => {
      expect(homeMetadata.openGraph?.images).toEqual([
        { url: "/icon-512.png", width: 512, height: 512, alt: "Vixrex" },
      ]);
      expect(homeMetadata.twitter).toEqual({
        card: "summary",
        title: "Vixrex — İşletmenin dijital vitrini",
        description:
          "Tek linkte işletme bilgilerin, ürünlerin, adresin ve WhatsApp iletişimin.",
        images: ["/icon-512.png"],
      });
    });
  });
});
