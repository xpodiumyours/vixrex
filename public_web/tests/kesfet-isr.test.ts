import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { KesfetVitrini } from "@/lib/explore";
import { hizliSecenekEtiketi } from "@/lib/vixrexMesajlari";

const m = vi.hoisted(() => ({
  stateIndex: 0,
  states: [] as unknown[],
  effects: [] as Array<() => void | (() => void)>,
  push: vi.fn(),
  replace: vi.fn(),
  globalSearch: "",
  setGlobalSearch: vi.fn((deger: string) => {
    m.globalSearch = deger;
  }),
  vitrinler: [] as KesfetVitrini[],
}));

vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return {
    ...actual,
    useState<T>(initial: T | (() => T)) {
      const idx = m.stateIndex++;
      if (!(idx in m.states)) {
        m.states[idx] =
          typeof initial === "function" ? (initial as () => T)() : initial;
      }
      const setState = (next: T | ((prev: T) => T)) => {
        const prev = m.states[idx] as T;
        m.states[idx] =
          typeof next === "function" ? (next as (p: T) => T)(prev) : next;
      };
      return [m.states[idx] as T, setState] as const;
    },
    useEffect(effect: () => void | (() => void)) {
      m.effects.push(effect);
    },
    useMemo<T>(factory: () => T) {
      return factory();
    },
  };
});

vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: m.push, replace: m.replace }),
}));

vi.mock("next/link", () => ({
  default: (props: { href: string; children?: unknown }) =>
    createElement("a", { href: props.href }, props.children as never),
}));

vi.mock("@/components/app/AppShellContext", () => ({
  useAppShellSearch: () => ({
    globalSearch: m.globalSearch,
    setGlobalSearch: m.setGlobalSearch,
  }),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    auth: {
      getSession: vi.fn(async () => ({ data: { session: null } })),
    },
  },
}));

vi.mock("@/components/kesfet/VitrinKarti", () => ({
  VitrinKarti: ({ vitrin }: { vitrin: KesfetVitrini }) =>
    createElement("article", { "data-slug": vitrin.slug }, vitrin.ad),
}));

vi.mock("@/components/landing/MascotFab", () => ({
  MascotFab: () => null,
}));

vi.mock("@/lib/explore", () => ({
  kesfetVitrinleriniGetir: vi.fn(async () => m.vitrinler),
}));

import KesfetPage, { revalidate } from "@/app/(site)/kesfet/page";
import { KesfetIcerik } from "@/components/kesfet/KesfetIcerik";

const ORNEK_VITRINLER: KesfetVitrini[] = [
  {
    slug: "kiralik-kafe",
    ad: "Kiralık Kafe Şablonu",
    aciklama: "Hazır kafe vitrini",
    kategoriEtiketi: "Kafe & Lokanta",
    kategoriKimligi: "kafe_lokanta",
    kapakUrl: null,
    konum: "İstanbul",
    kiralikMi: true,
    acikMi: true,
    urunSayisi: 5,
    urunAdlari: ["Latte"],
    whatsapp: null,
    guncellemeZamani: null,
    puan: 10,
  },
  {
    slug: "normal-butik",
    ad: "Normal Butik Vitrini",
    aciklama: "Elbise ve aksesuar",
    kategoriEtiketi: "Butik",
    kategoriKimligi: "butik",
    kapakUrl: null,
    konum: "Ankara",
    kiralikMi: false,
    acikMi: true,
    urunSayisi: 8,
    urunAdlari: ["Elbise"],
    whatsapp: null,
    guncellemeZamani: null,
    puan: 8,
  },
];

async function renderKesfetIcerik(search: string) {
  vi.stubGlobal("window", { location: { search } });
  const props = {
    vitrinler: ORNEK_VITRINLER,
    baslik: "Vixrex'leri Keşfet",
    aciklama:
      "Yayındaki tüm Vixrex vitrinlerini inceleyin. Beğendiğin hazır vitrini kirala, kendi işletmenin vitrini olsun.",
  };

  m.stateIndex = 0;
  m.effects = [];
  KesfetIcerik(props);
  m.effects[0]?.();
  await Promise.resolve();

  m.stateIndex = 0;
  m.effects = [];
  return renderToStaticMarkup(KesfetIcerik(props));
}

describe("Keşfet gerçek Edge ISR ve istemci query parametreleri", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    m.stateIndex = 0;
    m.states = [];
    m.effects = [];
    m.globalSearch = "";
    m.vitrinler = ORNEK_VITRINLER;
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("kesfet/page.tsx force-dynamic ve cookies içermez, revalidate = 300 kullanır", () => {
    const kaynak = readFileSync(
      resolve(__dirname, "../src/app/(site)/kesfet/page.tsx"),
      "utf-8"
    );

    expect(revalidate).toBe(300);
    expect(kaynak).toContain("export const revalidate = 300");
    expect(kaynak).not.toContain("force-dynamic");
    expect(kaynak).not.toContain("cookies");
    expect(kaynak).not.toContain("OWNER_SESSION_COOKIE");
    expect(kaynak).not.toContain("verifyOwnerSession");
    expect(kaynak).not.toContain("searchParams");
    expect(kaynak).toContain("Vixrex'leri Keşfet");
    expect(kaynak).toContain("Yayındaki tüm Vixrex vitrinlerini inceleyin");
    expect(kaynak).toContain("Beğendiğin hazır vitrini");
  });

  it("KesfetPage sunucu bileşeni çerez veya searchParams olmadan vitrinleri geçirir", async () => {
    const element = await KesfetPage();
    const kesfet =
      Array.isArray(element.props.children)
        ? element.props.children.find(
            (c: { type?: { name?: string } } | null) =>
              c?.type?.name === "KesfetIcerik",
          )
        : element;
    expect(kesfet.props.vitrinler).toEqual(ORNEK_VITRINLER);
    expect(kesfet.props.baslik).toBe("Vixrex'leri Keşfet");
    expect(kesfet.props.aciklama).toContain("Beğendiğin hazır vitrini");
  });

  it("?yalniz_kiralik=1 parametresinde kiralık görünümüne ve filtreye geçer", async () => {
    const html = await renderKesfetIcerik("?yalniz_kiralik=1");

    expect(html).toContain(hizliSecenekEtiketi("hazir_vitrin_sec"));
    expect(html).toContain("Beğendiğini kirala, kendi vitrinin olsun");
    expect(html).toContain("1 hazır vitrin");
    expect(html).toContain("Kiralık Kafe Şablonu");
    expect(html).not.toContain("Normal Butik Vitrini");
    expect(html).toContain("Uygun olan yok, sıfırdan oluştur");
  });

  it("?kategori=kafe-lokanta parametresinde ilgili kategori filtresini uygular", async () => {
    const html = await renderKesfetIcerik("?kategori=kafe-lokanta");

    expect(html).toContain("Vixrex&#x27;leri Keşfet");
    expect(html).toContain("Kiralık Kafe Şablonu");
    expect(html).not.toContain("Normal Butik Vitrini");
  });

  it("geçersiz kategori veya yalniz_kiralik!=1 parametrelerinde varsayılan tam liste korunur", async () => {
    const html = await renderKesfetIcerik("?yalniz_kiralik=0&kategori=olmayan-kategori");

    expect(html).toContain("Vixrex&#x27;leri Keşfet");
    expect(html).toContain("Kiralık Kafe Şablonu");
    expect(html).toContain("Normal Butik Vitrini");
    expect(html).not.toContain("2 hazır vitrin");
    expect(html).not.toContain("Uygun olan yok, sıfırdan oluştur");
  });
});
