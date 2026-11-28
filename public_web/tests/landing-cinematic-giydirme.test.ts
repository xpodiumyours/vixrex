import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { AKTIF_BUSINESS_CATEGORIES, kategoriUrlParcasi } from "@/lib/businessCategories";
import type { KategoriSablonu } from "@/lib/categoryTemplates";

const mockSablonHaritasi = vi.hoisted(() => vi.fn<() => Promise<Map<string, KategoriSablonu>>>());

vi.mock("@/lib/categoryTemplates", () => ({
  kategoriSablonHaritasi: mockSablonHaritasi,
}));

vi.mock("@/lib/siteUrl", () => ({
  getSiteUrl: () => "https://vixrex.com",
}));

vi.mock("next/link", () => ({
  default: (props: { href: string; children?: unknown; className?: string; "aria-label"?: string }) =>
    createElement(
      "a",
      {
        href: props.href,
        className: props.className,
        "aria-label": props["aria-label"],
      },
      props.children as never,
    ),
}));

vi.mock("next/image", () => ({
  default: (props: { src: string; alt: string; width?: number; height?: number; className?: string }) =>
    createElement("img", {
      src: props.src,
      alt: props.alt,
      width: props.width,
      height: props.height,
      className: props.className,
    }),
}));

vi.mock("@/components/landing/LandingApkAssistant", () => ({
  LandingApkAssistant: (props: { initialName?: string }) =>
    createElement("div", {
      "data-testid": "mock-apk-assistant",
      "data-initial-name": props.initialName ?? "",
    }),
}));

import { HeroSection } from "@/components/landing/HeroSection";
import { PhoneMockup } from "@/components/landing/PhoneMockup";
import { PhoneMockupSlaytlari } from "@/components/landing/PhoneMockupSlaytlari";
import { TemplateCatalog } from "@/components/landing/TemplateCatalog";
import { TiltCard } from "@/components/landing/TiltCard";
import { mockupProfilleriniGetir, type MockupProfili } from "@/components/landing/mockupProfilleri";

type ReactNodeShape = {
  type?: unknown;
  props?: Record<string, unknown>;
};

function elemanBul(
  node: unknown,
  kosul: (el: ReactNodeShape) => boolean,
): ReactNodeShape | null {
  if (!node || typeof node !== "object") return null;
  if (Array.isArray(node)) {
    for (const item of node) {
      const sonuc = elemanBul(item, kosul);
      if (sonuc) return sonuc;
    }
    return null;
  }
  const el = node as ReactNodeShape;
  if (kosul(el)) return el;
  return elemanBul(el.props?.children, kosul);
}

function bilesenAgaciYakala<T>(renderFn: () => T): { tree: T; html: string } {
  let captured: T | undefined;
  function Yakalayici() {
    captured = renderFn();
    return captured as never;
  }
  const html = renderToStaticMarkup(createElement(Yakalayici));
  return { tree: captured as T, html };
}

function ornekSablonHaritasi(): Map<string, KategoriSablonu> {
  const harita = new Map<string, KategoriSablonu>();
  for (const kat of AKTIF_BUSINESS_CATEGORIES) {
    harita.set(kat.id, {
      kategoriKimligi: kat.id,
      etiket: kat.label,
      kapaklar: [
        {
          id: `${kat.id}-c1`,
          url: `https://cdn.vixrex.com/category-templates/${kat.id}/cover-1.webp`,
          kucukUrl: null,
          baslik: kat.label,
          tur: "cover",
        },
        {
          id: `${kat.id}-c2`,
          url: `https://cdn.vixrex.com/category-templates/${kat.id}/cover-2.webp`,
          kucukUrl: null,
          baslik: kat.label,
          tur: "cover",
        },
      ],
      galeri: [
        {
          id: `${kat.id}-g1`,
          url: `https://cdn.vixrex.com/category-templates/${kat.id}/gallery-1.webp`,
          kucukUrl: null,
          baslik: null,
          tur: "gallery",
        },
        {
          id: `${kat.id}-g2`,
          url: `https://cdn.vixrex.com/category-templates/${kat.id}/gallery-2.webp`,
          kucukUrl: null,
          baslik: null,
          tur: "gallery",
        },
      ],
      urunler: [
        {
          id: `${kat.id}-p1`,
          url: `https://cdn.vixrex.com/category-templates/${kat.id}/product-1.webp`,
          kucukUrl: null,
          baslik: null,
          tur: "product",
        },
      ],
      toplam: 5,
    });
  }
  return harita;
}

describe("landing sinematik giydirme — gerçek girdi/çıktı doğrulaması", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockSablonHaritasi.mockResolvedValue(ornekSablonHaritasi());
  });

  describe("mockupProfilleri ve PhoneMockupSlaytlari", () => {
    it("tüm profilleri R2 şablon görselleriyle üretir ve sahte puan/değerlendirme içermez", async () => {
      const profiller = await mockupProfilleriniGetir();
      expect(profiller).toHaveLength(4);

      for (let i = 0; i < profiller.length; i += 1) {
        const profil = profiller[i];
        expect(profil.kapakUrl).toMatch(/^https:\/\/cdn\.vixrex\.com\//);
        expect(profil.aksiyonHaplari).toHaveLength(4);
        expect(profil.vitrinKartlari).toHaveLength(4);
        for (const kart of profil.vitrinKartlari) {
          expect(kart.gorselUrl).toMatch(/^https:\/\/cdn\.vixrex\.com\//);
        }

        const html = renderToStaticMarkup(
          createElement(PhoneMockupSlaytlari, { profiller, aktif: i }),
        );
        const gorunurMetin = html.replace(/<[^>]+>/g, " ");
        expect(html).toContain(profil.ad);
        expect(html).toContain(profil.basHarfler);
        expect(html).toContain(profil.konumSatiri);
        expect(html).toContain(profil.calismaSaati);
        expect(html).toContain("Örnek vitrin");
        expect(gorunurMetin).not.toContain("★");
        expect(gorunurMetin).not.toContain("4.9");
        expect(gorunurMetin).not.toContain("4.8");
        expect(gorunurMetin.toLocaleLowerCase("tr-TR")).not.toContain("değerlendirme");
        expect(html).not.toContain("data:image/");
      }
    });

    it("şablon haritası boş döndüğünde kırılmadan görselsiz yedek yüzey çizer", async () => {
      mockSablonHaritasi.mockResolvedValue(new Map());
      const profiller = await mockupProfilleriniGetir();

      expect(profiller[0].kapakUrl).toBeNull();
      expect(profiller[0].vitrinKartlari.every((k) => k.gorselUrl === null)).toBe(true);

      const html = renderToStaticMarkup(
        createElement(PhoneMockupSlaytlari, { profiller, aktif: 0 }),
      );
      expect(html).toContain(profiller[0].ad);
      expect(html).not.toContain("<img");
    });

    it("boş profil dizisi veya sınır dışı indeks için güvenli davranır", async () => {
      const bosHtml = renderToStaticMarkup(
        createElement(PhoneMockupSlaytlari, { profiller: [], aktif: 0 }),
      );
      expect(bosHtml).toBe("");

      const profiller = await mockupProfilleriniGetir();
      const sinirDisiHtml = renderToStaticMarkup(
        createElement(PhoneMockupSlaytlari, { profiller, aktif: 99 }),
      );
      expect(sinirDisiHtml).toContain(profiller[0].ad);
    });
  });

  describe("HeroSection marka, yönlendirme ve asistan formu", () => {
    it("resmi VixrexAvatar maskotunu ve gerçek yönlendirmeleri çizer; blog anahtarına uyar", async () => {
      const profiller: MockupProfili[] = await mockupProfilleriniGetir();
      const onStart = vi.fn();

      const htmlBlogKapali = renderToStaticMarkup(
        createElement(HeroSection, {
          profiller,
          blogErisimi: false,
          onStartAssistant: onStart,
        }),
      );

      expect(htmlBlogKapali).toContain("/images/vixrex_v_crystal_mascot.webp");
      expect(htmlBlogKapali).toContain('href="/kesfet"');
      expect(htmlBlogKapali).toContain('href="/giris"');
      expect(htmlBlogKapali).toContain('href="#neden-vixrex"');
      expect(htmlBlogKapali).toContain('href="#nasil-calisir"');
      expect(htmlBlogKapali).not.toContain('href="/blog"');
      expect(htmlBlogKapali).toContain('name="isletme"');
      expect(htmlBlogKapali).toContain("Ücretsiz Vitrinimi Hazırla");

      const htmlBlogAcik = renderToStaticMarkup(
        createElement(HeroSection, {
          profiller,
          blogErisimi: true,
          onStartAssistant: onStart,
        }),
      );
      expect(htmlBlogAcik).toContain('href="/blog"');
    });

    it("form gönderiminde işletme adını kırparak onStartAssistant'a aktarır", async () => {
      const profiller = await mockupProfilleriniGetir();
      const onStart = vi.fn();
      const tree = HeroSection({
        profiller,
        blogErisimi: false,
        onStartAssistant: onStart,
      });

      const formBul = (node: unknown): ((event: unknown) => void) | null => {
        if (!node || typeof node !== "object") return null;
        if (Array.isArray(node)) {
          for (const item of node) {
            const sonuc = formBul(item);
            if (sonuc) return sonuc;
          }
          return null;
        }
        const el = node as { type?: unknown; props?: { onSubmit?: (event: unknown) => void; children?: unknown } };
        if (el.type === "form" && typeof el.props?.onSubmit === "function") {
          return el.props.onSubmit;
        }
        return formBul(el.props?.children);
      };

      const onSubmit = formBul(tree);
      expect(onSubmit).toBeTypeOf("function");

      const OriginalFormData = globalThis.FormData;
      try {
        let sahteDeger = "  Örnek Butik  ";
        globalThis.FormData = class {
          get(key: string) {
            return key === "isletme" ? sahteDeger : null;
          }
        } as unknown as typeof FormData;

        const preventDefault = vi.fn();
        onSubmit?.({ preventDefault, currentTarget: {} });
        expect(preventDefault).toHaveBeenCalledTimes(1);
        expect(onStart).toHaveBeenCalledWith("Örnek Butik");

        sahteDeger = "   ";
        onSubmit?.({ preventDefault, currentTarget: {} });
        expect(onStart).toHaveBeenLastCalledWith("");
      } finally {
        globalThis.FormData = OriginalFormData;
      }
    });
  });

  describe("TemplateCatalog 6 aktif kategori sözleşmesi", () => {
    it("6 aktif kategoriyi gerçek /kesfet/... bağlantıları ve R2 görselleriyle üretir", async () => {
      const element = await TemplateCatalog();
      const html = renderToStaticMarkup(element);

      expect(AKTIF_BUSINESS_CATEGORIES).toHaveLength(6);
      expect(html).toContain("6 farklı kategoride");
      expect(html).toContain("lg:grid-cols-3");

      for (const kat of AKTIF_BUSINESS_CATEGORIES) {
        const beklenenHref = `/kesfet/${kategoriUrlParcasi(kat.id)}`;
        expect(html).toContain(`href="${beklenenHref}"`);
        expect(html).toContain(kat.label);
        expect(html).toContain(`https://cdn.vixrex.com/category-templates/${kat.id}/cover-1.webp`);
      }
      expect(html).not.toContain("data:image/");
    });

    it("şablon görselleri eksik olsa bile tüm 6 kategori bağlantısı kırılmadan üretilir", async () => {
      mockSablonHaritasi.mockResolvedValue(new Map());
      const element = await TemplateCatalog();
      const html = renderToStaticMarkup(element);

      expect(html).not.toContain("<img");
      for (const kat of AKTIF_BUSINESS_CATEGORIES) {
        expect(html).toContain(`href="/kesfet/${kategoriUrlParcasi(kat.id)}"`);
      }
    });
  });

  describe("TiltCard negatif durumları ve fare etkileşimi", () => {
    function tiltKur(reducedMotion: boolean) {
      const originalWindow = globalThis.window;
      Object.defineProperty(globalThis, "window", {
        configurable: true,
        value: {
          matchMedia: () => ({ matches: reducedMotion }),
        },
      });

      const { tree } = bilesenAgaciYakala(() =>
        TiltCard({ children: createElement("span", null, "Kart") }),
      );
      const cardEl = elemanBul(
        tree,
        (el) =>
          typeof el.props?.className === "string" &&
          el.props.className.includes("lp-tilt-card"),
      );
      const glareEl = elemanBul(
        tree,
        (el) =>
          typeof el.props?.className === "string" &&
          el.props.className.includes("lp-tilt-glare"),
      );

      const cardNode = {
        style: { transform: "" },
        getBoundingClientRect: () => ({ left: 0, top: 0, width: 200, height: 100 }),
      };
      const glareNode = { style: { background: "" } };

      const cardRef = cardEl?.props?.ref as { current: unknown };
      const glareRef = glareEl?.props?.ref as { current: unknown };
      cardRef.current = cardNode;
      glareRef.current = glareNode;

      return {
        cardNode,
        glareNode,
        onPointerMove: cardEl?.props?.onPointerMove as (event: unknown) => void,
        onPointerLeave: cardEl?.props?.onPointerLeave as () => void,
        temizle: () => {
          Object.defineProperty(globalThis, "window", {
            configurable: true,
            value: originalWindow,
          });
        },
      };
    }

    it("pointerType touch iken transform uygulamaz", () => {
      const ctx = tiltKur(false);
      try {
        ctx.onPointerMove({ pointerType: "touch", clientX: 150, clientY: 25 });
        expect(ctx.cardNode.style.transform).toBe("");
        expect(ctx.glareNode.style.background).toBe("");
      } finally {
        ctx.temizle();
      }
    });

    it("prefers-reduced-motion aktifken fare hareketinde transform uygulamaz", () => {
      const ctx = tiltKur(true);
      try {
        ctx.onPointerMove({ pointerType: "mouse", clientX: 150, clientY: 25 });
        expect(ctx.cardNode.style.transform).toBe("");
        expect(ctx.glareNode.style.background).toBe("");
      } finally {
        ctx.temizle();
      }
    });

    it("fare hareketinde 3D transform uygular ve pointerLeave sonrası sıfırlar", () => {
      const ctx = tiltKur(false);
      try {
        ctx.onPointerMove({ pointerType: "mouse", clientX: 150, clientY: 25 });
        expect(ctx.cardNode.style.transform).toContain("rotateX(");
        expect(ctx.cardNode.style.transform).toContain("rotateY(");
        expect(ctx.cardNode.style.transform).toContain("translateY(-4px)");
        expect(ctx.glareNode.style.background).toContain("radial-gradient");

        ctx.onPointerLeave();
        expect(ctx.cardNode.style.transform).toBe("");
      } finally {
        ctx.temizle();
      }
    });
  });

  describe("PhoneMockup erişilebilirlik, overlay ve slayt düğmesi etkileşimleri", () => {
    it("isChatOpen false iken klavye Enter/Space ile sohbeti açar, diğer tuşları yok sayar", async () => {
      const profiller = await mockupProfilleriniGetir();
      const onOpenChat = vi.fn();

      const { tree, html } = bilesenAgaciYakala(() =>
        PhoneMockup({
          profiller,
          isChatOpen: false,
          onOpenChat,
        }),
      );

      expect(html).not.toContain('data-testid="mock-apk-assistant"');

      const chassis = elemanBul(
        tree,
        (el) =>
          typeof el.props?.className === "string" &&
          el.props.className.includes("lp-phone-chassis"),
      );
      expect(chassis?.props?.role).toBe("button");
      expect(chassis?.props?.tabIndex).toBe(0);
      expect(chassis?.props?.["aria-label"]).toBe(
        "Vixrex Yapay Zeka Asistanını Başlat",
      );

      const onKeyDown = chassis?.props?.onKeyDown as (event: unknown) => void;
      const preventEnter = vi.fn();
      onKeyDown({ key: "Enter", preventDefault: preventEnter });
      expect(preventEnter).toHaveBeenCalledTimes(1);
      expect(onOpenChat).toHaveBeenCalledTimes(1);

      const preventSpace = vi.fn();
      onKeyDown({ key: " ", preventDefault: preventSpace });
      expect(preventSpace).toHaveBeenCalledTimes(1);
      expect(onOpenChat).toHaveBeenCalledTimes(2);

      const preventEscape = vi.fn();
      onKeyDown({ key: "Escape", preventDefault: preventEscape });
      expect(preventEscape).not.toHaveBeenCalled();
      expect(onOpenChat).toHaveBeenCalledTimes(2);
    });

    it("slayt düğmesine tıklanırken stopPropagation çağrılır ve onOpenChat tetiklenmez", async () => {
      const profiller = await mockupProfilleriniGetir();
      const onOpenChat = vi.fn();

      const { tree } = bilesenAgaciYakala(() =>
        PhoneMockup({
          profiller,
          isChatOpen: false,
          onOpenChat,
        }),
      );

      const slaytButonu = elemanBul(
        tree,
        (el) => el.type === "button" && el.props?.["aria-label"] === profiller[1].ad,
      );
      expect(slaytButonu).not.toBeNull();

      const stopPropagation = vi.fn();
      const onClick = slaytButonu?.props?.onClick as (event: unknown) => void;
      onClick({ stopPropagation });

      expect(stopPropagation).toHaveBeenCalledTimes(1);
      expect(onOpenChat).not.toHaveBeenCalled();
    });

    it("isChatOpen true iken asistan overlay aktiftir ve kasa odak/tıklama dışı kalır", async () => {
      const profiller = await mockupProfilleriniGetir();
      const onOpenChat = vi.fn();

      const { tree, html } = bilesenAgaciYakala(() =>
        PhoneMockup({
          profiller,
          isChatOpen: true,
          initialAssistantName: "Test Mağaza",
          onOpenChat,
        }),
      );

      expect(html).toContain('data-testid="mock-apk-assistant"');
      expect(html).toContain('data-initial-name="Test Mağaza"');
      expect(html).toContain("lp-phone-chassis-straight");

      const chassis = elemanBul(
        tree,
        (el) =>
          typeof el.props?.className === "string" &&
          el.props.className.includes("lp-phone-chassis"),
      );
      expect(chassis?.props?.role).toBeUndefined();
      expect(chassis?.props?.tabIndex).toBe(-1);
      expect(chassis?.props?.["aria-label"]).toBeUndefined();

      const onClick = chassis?.props?.onClick as () => void;
      const onKeyDown = chassis?.props?.onKeyDown as (event: unknown) => void;
      const preventEnter = vi.fn();
      onClick();
      onKeyDown({ key: "Enter", preventDefault: preventEnter });

      expect(preventEnter).not.toHaveBeenCalled();
      expect(onOpenChat).not.toHaveBeenCalled();
    });
  });
});
