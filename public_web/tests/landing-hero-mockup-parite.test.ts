import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { AKTIF_BUSINESS_CATEGORIES } from "@/lib/businessCategories";
import type { KategoriSablonu } from "@/lib/categoryTemplates";

const efektCagirimlari = vi.hoisted(
  () => [] as Array<{ fn: () => void | (() => void); deps: unknown[] }>,
);

const mockSablonHaritasi = vi.hoisted(
  () => vi.fn<() => Promise<Map<string, KategoriSablonu>>>(),
);

vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return {
    ...actual,
    useEffect: (fn: () => void | (() => void), deps: unknown[]) => {
      efektCagirimlari.push({ fn, deps });
      const gercekUseEffect = actual.useEffect as unknown as (
        f: () => void | (() => void),
        d: unknown[],
      ) => void;
      return gercekUseEffect(fn, deps);
    },
  };
});

vi.mock("@/lib/categoryTemplates", () => ({
  kategoriSablonHaritasi: mockSablonHaritasi,
}));

vi.mock("@/lib/siteUrl", () => ({
  getSiteUrl: () => "https://vixrex.com",
}));

vi.mock("next/link", () => ({
  default: (props: { href: string; children?: unknown; className?: string }) =>
    createElement("a", { href: props.href, className: props.className }, props.children as never),
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
  LandingApkAssistant: () => createElement("div", { "data-testid": "mock-apk-assistant" }),
}));

import { PhoneMockup } from "@/components/landing/PhoneMockup";
import { PhoneMockupSlaytlari } from "@/components/landing/PhoneMockupSlaytlari";
import { mockupProfilleriniGetir } from "@/components/landing/mockupProfilleri";

type ReactNodeShape = {
  type?: unknown;
  props?: Record<string, unknown>;
};

function elemanBul(node: unknown, kosul: (el: ReactNodeShape) => boolean): ReactNodeShape | null {
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

function elemanTopla(
  node: unknown,
  kosul: (el: ReactNodeShape) => boolean,
  cikti: ReactNodeShape[],
): void {
  if (!node || typeof node !== "object") return;
  if (Array.isArray(node)) {
    for (const item of node) elemanTopla(item, kosul, cikti);
    return;
  }
  const el = node as ReactNodeShape;
  if (kosul(el)) cikti.push(el);
  elemanTopla(el.props?.children, kosul, cikti);
}

function altAgacindaMi(kok: ReactNodeShape, hedef: ReactNodeShape): boolean {
  if (kok === hedef) return true;
  const children = kok.props?.children;
  if (!children || typeof children !== "object") return false;
  if (Array.isArray(children)) {
    return children.some(
      (child) => typeof child === "object" && child !== null && altAgacindaMi(child as ReactNodeShape, hedef),
    );
  }
  return altAgacindaMi(children as ReactNodeShape, hedef);
}

function htmlMetin(html: string): string {
  return html
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'");
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

describe("landing telefon mockup — gerçek davranış doğrulaması", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    efektCagirimlari.length = 0;
    mockSablonHaritasi.mockResolvedValue(ornekSablonHaritasi());
  });

  it("slayt noktaları kasadan bağımsız, tıklanabilir ve 260ms geçişlidir", async () => {
    const profiller = await mockupProfilleriniGetir();
    const onOpenChat = vi.fn();
    const { tree, html } = bilesenAgaciYakala(() =>
      PhoneMockup({ profiller, isChatOpen: false, onOpenChat }),
    );

    const kasa = elemanBul(
      tree,
      (el) =>
        typeof el.props?.className === "string" &&
        el.props.className.includes("lp-phone-chassis"),
    );
    expect(kasa).not.toBeNull();

    const adlar = new Set(profiller.map((profil) => profil.ad));
    const noktalar: ReactNodeShape[] = [];
    elemanTopla(tree, (el) => el.type === "button" && adlar.has(el.props?.["aria-label"] as string), noktalar);

    expect(noktalar).toHaveLength(profiller.length);
    for (const [sira, nokta] of noktalar.entries()) {
      expect(kasa && altAgacindaMi(kasa, nokta)).toBe(false);
      const sinif = nokta.props?.className as string;
      expect(sinif).toContain("h-7");
      expect(sinif).toContain("w-7");
      expect(nokta.props?.["aria-pressed"]).toBe(sira === 0);
      const gorsel = elemanBul(nokta, (el) => el.type === "span");
      expect(gorsel).not.toBeNull();
      const gorselSinif = gorsel?.props?.className as string;
      expect(gorselSinif).toContain("h-2");
      expect(gorselSinif).toContain("duration-[260ms]");
      expect(gorselSinif).toContain(
        gorselSinif.includes("w-6") ? "w-6 bg-lp-primary" : "w-2 bg-lp-border",
      );
      expect(typeof nokta.props?.onClick).toBe("function");
    }
    expect(html).toContain("w-6 bg-lp-primary");
    expect(html).toContain("w-2 bg-lp-border");

    const stopPropagation = vi.fn();
    (noktalar[0].props?.onClick as (event: unknown) => void)({ stopPropagation });
    expect(stopPropagation).toHaveBeenCalledTimes(1);
    expect(onOpenChat).not.toHaveBeenCalled();
  });

  it("kasa başta tıklanabilir eğimli, sohbet açıkken düzleşir ve tıklamayı yok sayar", async () => {
    const profiller = await mockupProfilleriniGetir();
    const onOpenChat = vi.fn();

    const kapali = bilesenAgaciYakala(() =>
      PhoneMockup({ profiller, isChatOpen: false, onOpenChat }),
    );
    expect(kapali.html).toContain("lp-phone-chassis");
    expect(kapali.html).not.toContain("lp-phone-chassis-straight");
    const kasa = elemanBul(
      kapali.tree,
      (el) =>
        typeof el.props?.className === "string" &&
        el.props.className.includes("lp-phone-chassis"),
    );
    expect(kasa?.props?.role).toBe("button");
    expect(kasa?.props?.tabIndex).toBe(0);

    (kasa?.props?.onClick as () => void)();
    expect(onOpenChat).toHaveBeenCalledTimes(1);
    const ent = vi.fn();
    (kasa?.props?.onKeyDown as (event: unknown) => void)({ key: "Enter", preventDefault: ent });
    expect(ent).toHaveBeenCalledTimes(1);
    expect(onOpenChat).toHaveBeenCalledTimes(2);
    const bos = vi.fn();
    (kasa?.props?.onKeyDown as (event: unknown) => void)({ key: "Escape", preventDefault: bos });
    expect(bos).not.toHaveBeenCalled();
    expect(onOpenChat).toHaveBeenCalledTimes(2);

    const acik = bilesenAgaciYakala(() =>
      PhoneMockup({ profiller, isChatOpen: true, onOpenChat }),
    );
    expect(acik.html).toContain("lp-phone-chassis-straight");
    const kasaAcik = elemanBul(
      acik.tree,
      (el) =>
        typeof el.props?.className === "string" &&
        el.props.className.includes("lp-phone-chassis"),
    );
    expect(kasaAcik?.props?.role).toBeUndefined();
    expect(kasaAcik?.props?.tabIndex).toBe(-1);
    (kasaAcik?.props?.onClick as () => void)();
    (kasaAcik?.props?.onKeyDown as (event: unknown) => void)({ key: "Enter", preventDefault: vi.fn() });
    expect(onOpenChat).toHaveBeenCalledTimes(2);
  });

  it("slaytlar gerçek profil verisini ve R2 şablon görsellerini çizer; aktif slayt değişince içerik değişir", async () => {
    const profiller = await mockupProfilleriniGetir();
    expect(profiller).toHaveLength(4);

    for (let i = 0; i < profiller.length; i += 1) {
      const profil = profiller[i];
      const html = renderToStaticMarkup(
        createElement(PhoneMockupSlaytlari, { profiller, aktif: i }),
      );
      const metin = htmlMetin(html);
      expect(metin).toContain(profil.ad);
      expect(metin).toContain(profil.basHarfler);
      expect(metin).toContain(profil.konumSatiri);
      expect(metin).toContain(profil.calismaSaati);
      expect(metin).toContain(profil.bolumBasligi);
      for (const hap of profil.aksiyonHaplari) expect(metin).toContain(hap.etiket);
      for (const kart of profil.vitrinKartlari) expect(metin).toContain(kart.baslik);
      expect(html).toMatch(/https:\/\/cdn\.vixrex\.com\//);
      expect(html).not.toContain("data:image/");
    }

    const ilk = renderToStaticMarkup(createElement(PhoneMockupSlaytlari, { profiller, aktif: 0 }));
    const ikinci = renderToStaticMarkup(createElement(PhoneMockupSlaytlari, { profiller, aktif: 1 }));
    expect(ilk).toContain(profiller[0].ad);
    expect(ikinci).toContain(profiller[1].ad);
    expect(ikinci).not.toContain(profiller[0].ad);
  });

  it("slaytların görünür metninde sahte puan veya değerlendirme yoktur", async () => {
    const profiller = await mockupProfilleriniGetir();
    for (let i = 0; i < profiller.length; i += 1) {
      const html = renderToStaticMarkup(
        createElement(PhoneMockupSlaytlari, { profiller, aktif: i }),
      );
      const gorunurMetin = html.replace(/<[^>]+>/g, " ");
      expect(gorunurMetin).not.toContain("★");
      expect(gorunurMetin).not.toContain("4.9");
      expect(gorunurMetin).not.toContain("4.8");
      expect(gorunurMetin.toLocaleLowerCase("tr-TR")).not.toContain("değerlendirme");
    }
  });

  it("slayt döngüsü yalnız PhoneMockup'ta 4 saniyedir; sohbet açıkken ve azaltılmış harekette durur", async () => {
    const profiller = await mockupProfilleriniGetir();
    const originalWindow = globalThis.window;
    const setIntervalMock = vi.fn(() => 42);
    const clearIntervalMock = vi.fn();
    const matchMediaMock = vi.fn(() => ({ matches: false }));
    Object.defineProperty(globalThis, "window", {
      configurable: true,
      value: {
        matchMedia: matchMediaMock,
        setInterval: setIntervalMock,
        clearInterval: clearIntervalMock,
      },
    });
    try {
      efektCagirimlari.length = 0;
      bilesenAgaciYakala(() => PhoneMockup({ profiller, isChatOpen: false }));
      const efekt = efektCagirimlari.at(-1);
      expect(efekt?.deps).toEqual([profiller.length, false]);
      const temizle = efekt?.fn();
      expect(setIntervalMock).toHaveBeenCalledWith(expect.any(Function), 4000);
      expect(temizle).toBeTypeOf("function");
      (temizle as () => void)();
      expect(clearIntervalMock).toHaveBeenCalledWith(42);

      efektCagirimlari.length = 0;
      bilesenAgaciYakala(() => PhoneMockup({ profiller, isChatOpen: true }));
      efektCagirimlari.at(-1)?.fn();
      expect(setIntervalMock).toHaveBeenCalledTimes(1);

      matchMediaMock.mockReturnValue({ matches: true });
      efektCagirimlari.length = 0;
      bilesenAgaciYakala(() => PhoneMockup({ profiller, isChatOpen: false }));
      efektCagirimlari.at(-1)?.fn();
      expect(setIntervalMock).toHaveBeenCalledTimes(1);
    } finally {
      Object.defineProperty(globalThis, "window", {
        configurable: true,
        value: originalWindow,
      });
    }
  });

  it("PhoneMockupSlaytlari kendi efektini kurmaz — saf çizimdir", async () => {
    const profiller = await mockupProfilleriniGetir();
    efektCagirimlari.length = 0;
    renderToStaticMarkup(createElement(PhoneMockupSlaytlari, { profiller, aktif: 0 }));
    expect(efektCagirimlari).toHaveLength(0);
  });
});
