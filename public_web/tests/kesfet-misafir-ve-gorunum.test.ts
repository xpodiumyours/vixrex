import {
  createElement,
  type ComponentProps,
  type Context,
  type ReactElement,
} from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { KesfetVitrini } from "@/lib/explore";

const m = vi.hoisted(() => ({
  pathname: "/kesfet",
  push: vi.fn(),
  getSession: vi.fn(),
  onAuthStateChange: vi.fn(),
  unsubscribe: vi.fn(),
  authCallback: null as ((event: string, session: unknown) => void) | null,
  rpc: vi.fn(),
  from: vi.fn(),
  select: vi.fn(),
  eq: vi.fn(),
  maybeSingle: vi.fn(),
  fetch: vi.fn(),
  harnessActive: false,
  activeComponent: null as "shell" | "status" | null,
  componentStates: {} as Record<string, unknown[]>,
  componentSetters: {} as Record<string, Array<(next: unknown) => void>>,
  stateCursor: {} as Record<string, number>,
  effects: [] as Array<() => void | (() => void)>,
  contextValue: null as unknown,
}));

vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return {
    ...actual,
    useState<T>(initial: T | (() => T)) {
      if (!m.harnessActive || !m.activeComponent) {
        return actual.useState(initial);
      }
      const key = m.activeComponent;
      const states = (m.componentStates[key] ??= []);
      const setters = (m.componentSetters[key] ??= []);
      const idx = m.stateCursor[key] ?? 0;
      m.stateCursor[key] = idx + 1;
      if (!(idx in states)) {
        states[idx] =
          typeof initial === "function" ? (initial as () => T)() : initial;
      }
      if (!setters[idx]) {
        setters[idx] = (next: unknown) => {
          const prev = states[idx] as T;
          states[idx] =
            typeof next === "function"
              ? (next as (p: T) => T)(prev)
              : next;
        };
      }
      return [states[idx] as T, setters[idx] as (next: T | ((prev: T) => T)) => void] as const;
    },
    useEffect(effect: () => void | (() => void), deps?: unknown[]) {
      if (!m.harnessActive) {
        return actual.useEffect(effect, deps as never);
      }
      m.effects.push(effect);
    },
    useMemo<T>(factory: () => T, deps: unknown[]) {
      if (!m.harnessActive) {
        return actual.useMemo(factory, deps as never);
      }
      return factory();
    },
    useContext<T>(context: Context<T>) {
      if (!m.harnessActive) {
        return actual.useContext(context);
      }
      return m.contextValue as T;
    },
  };
});

vi.mock("next/navigation", () => ({
  usePathname: () => m.pathname,
  useRouter: () => ({ push: m.push }),
}));

vi.mock("next/link", () => ({
  default: (props: { href: string; className?: string; children?: unknown }) =>
    createElement(
      "a",
      { href: props.href, className: props.className },
      props.children as never,
    ),
}));

vi.mock("next/image", () => ({
  default: (props: { src: string; alt: string; className?: string }) =>
    createElement("img", { src: props.src, alt: props.alt, className: props.className }),
}));

vi.mock("@/components/recaptcha/RecaptchaProvider", () => ({
  useRecaptcha: () => ({ executeRecaptcha: vi.fn(async () => "test-token") }),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: {
    auth: {
      getSession: m.getSession,
      onAuthStateChange: m.onAuthStateChange,
    },
    rpc: m.rpc,
    from: m.from,
  },
}));

import { AppShellProvider, useAppShell } from "@/components/app/AppShellContext";
import { AppSidebar } from "@/components/app/AppSidebar";
import KesfetHata from "@/app/(site)/kesfet/error";
import KesfetYukleniyor from "@/app/(site)/kesfet/loading";
import { StatusBar } from "@/components/kesfet/StatusBar";
import { VitrinKarti } from "@/components/kesfet/VitrinKarti";
import { SiteChromeBoundary } from "@/components/site/SiteChromeBoundary";

type ShellValue = ReturnType<typeof useAppShell>;

async function statusBarVeSidebarCalistir() {
  m.harnessActive = true;
  m.effects = [];

  m.activeComponent = "shell";
  m.stateCursor.shell = 0;
  m.contextValue = null;
  const ilkKabuk = AppShellProvider({ children: null }) as ReactElement<{
    value: ShellValue;
  }>;
  const setHasOwnerStoreSpy = vi.spyOn(ilkKabuk.props.value, "setHasOwnerStore");
  m.contextValue = ilkKabuk.props.value;

  m.activeComponent = "status";
  m.stateCursor.status = 0;
  StatusBar();

  const cleanups: Array<() => void> = [];
  for (const effect of m.effects) {
    const res = effect();
    if (typeof res === "function") cleanups.push(res);
  }
  await new Promise((resolve) => setTimeout(resolve, 0));

  m.activeComponent = "shell";
  m.stateCursor.shell = 0;
  const guncelKabuk = AppShellProvider({ children: null }) as ReactElement<{
    value: ShellValue;
  }>;

  m.harnessActive = false;
  m.activeComponent = null;

  const sidebarHtml = renderToStaticMarkup(
    createElement(
      guncelKabuk.type,
      { value: guncelKabuk.props.value },
      createElement(AppSidebar),
    ),
  );

  return {
    shell: guncelKabuk.props.value,
    sidebarHtml,
    setHasOwnerStoreSpy,
    unmount: () => {
      for (const c of cleanups) c();
    },
  };
}

function ornekVitrin(overrides: Partial<KesfetVitrini> = {}): KesfetVitrini {
  return {
    slug: "portre-kuafor",
    ad: "Portre Kuaför",
    aciklama: "Saç ve bakım",
    kategoriEtiketi: "Kuaför & Güzellik",
    kategoriKimligi: "kuafor_guzellik",
    kapakUrl: "https://cdn.example.com/kapak.jpg",
    konum: "Kadıköy",
    kiralikMi: false,
    acikMi: true,
    urunSayisi: 4,
    urunAdlari: ["Fön"],
    whatsapp: null,
    guncellemeZamani: null,
    puan: null,
    ...overrides,
  };
}

describe("Paket 1B: Keşfet misafir menüsü, portre hizası ve footer", () => {
  beforeEach(() => {
    m.pathname = "/kesfet";
    m.push.mockClear();
    m.harnessActive = false;
    m.activeComponent = null;
    m.componentStates = {};
    m.componentSetters = {};
    m.stateCursor = {};
    m.effects = [];
    m.contextValue = null;

    m.getSession.mockReset();
    m.getSession.mockResolvedValue({ data: { session: null }, error: null });
    m.unsubscribe.mockReset();
    m.authCallback = null;
    m.onAuthStateChange.mockReset();
    m.onAuthStateChange.mockImplementation((cb: (event: string, session: unknown) => void) => {
      m.authCallback = cb;
      return { data: { subscription: { unsubscribe: m.unsubscribe } } };
    });
    m.rpc.mockReset();
    m.rpc.mockResolvedValue({ data: { has_store: false }, error: null });
    m.maybeSingle.mockReset();
    m.maybeSingle.mockResolvedValue({ data: { is_published: true }, error: null });
    m.eq.mockReset();
    m.eq.mockReturnValue({ maybeSingle: m.maybeSingle });
    m.select.mockReset();
    m.select.mockReturnValue({ eq: m.eq });
    m.from.mockReset();
    m.from.mockReturnValue({ select: m.select });

    m.fetch.mockReset();
    m.fetch.mockResolvedValue(
      new Response(JSON.stringify({ store: null }), { status: 200 }),
    );
    vi.stubGlobal("fetch", m.fetch);
  });

  afterEach(() => {
    m.harnessActive = false;
    m.activeComponent = null;
    vi.unstubAllGlobals();
  });

  it("VitrinKarti kapak görseli varken object-top sınıfını içerir", () => {
    const html = renderToStaticMarkup(
      createElement(VitrinKarti, { vitrin: ornekVitrin() }),
    );
    expect(html).toContain("<img");
    expect(html).toContain("object-cover object-top");
  });

  it("VitrinKarti kapak görseli yokken img ve object-top üretmez", () => {
    const html = renderToStaticMarkup(
      createElement(VitrinKarti, { vitrin: ornekVitrin({ kapakUrl: null }) }),
    );
    expect(html).not.toContain('alt="Portre Kuaför vitrin kapak görseli"');
    expect(html).not.toContain("object-top");
    expect(html).toContain("Kapak görseli eklenmedi");
  });

  it("SiteChromeBoundary /kesfet yolunda header'ı gizler, footer'ı render eder ve iç içe main üretmez", () => {
    m.pathname = "/kesfet";
    const props = {
      header: createElement("header", { "data-testid": "site-header" }, "Üst Menü"),
      footer: createElement("footer", { "data-testid": "site-footer" }, "Alt Bilgi"),
    } as ComponentProps<typeof SiteChromeBoundary>;
    const html = renderToStaticMarkup(
      createElement(SiteChromeBoundary, props, createElement("main", null, "İçerik")),
    );
    expect(html).not.toContain("site-header");
    expect(html).toContain("site-footer");
    expect(html).toContain("Alt Bilgi");
    expect(html).toContain('<div class="flex-1"><main>İçerik</main></div>');
    expect(html.match(/<main\b/g)).toHaveLength(1);
  });

  it("SiteChromeBoundary /kesfet alt kategorisinde header'ı gizleyip footer ve tek main gösterir", () => {
    m.pathname = "/kesfet/kafe-lokanta";
    const props = {
      header: createElement("header", { "data-testid": "site-header" }, "Üst Menü"),
      footer: createElement("footer", { "data-testid": "site-footer" }, "Alt Bilgi"),
    } as ComponentProps<typeof SiteChromeBoundary>;
    const html = renderToStaticMarkup(
      createElement(SiteChromeBoundary, props, createElement("main", null, "İçerik")),
    );
    expect(html).not.toContain("site-header");
    expect(html).toContain("site-footer");
    expect(html).toContain('<div class="flex-1"><main>İçerik</main></div>');
    expect(html.match(/<main\b/g)).toHaveLength(1);

    const loadingHtml = renderToStaticMarkup(
      createElement(SiteChromeBoundary, props, createElement(KesfetYukleniyor)),
    );
    const errorHtml = renderToStaticMarkup(
      createElement(
        SiteChromeBoundary,
        props,
        createElement(KesfetHata, { error: new Error("test"), reset: () => {} }),
      ),
    );
    expect(loadingHtml.match(/<main\b/g)).toHaveLength(1);
    expect(errorHtml.match(/<main\b/g)).toHaveLength(1);
  });

  it("SiteChromeBoundary diğer sayfalarda header, footer ve main korur", () => {
    m.pathname = "/hakkimizda";
    const props = {
      header: createElement("header", { "data-testid": "site-header" }, "Üst Menü"),
      footer: createElement("footer", { "data-testid": "site-footer" }, "Alt Bilgi"),
    } as ComponentProps<typeof SiteChromeBoundary>;
    const html = renderToStaticMarkup(
      createElement(SiteChromeBoundary, props, createElement("div", null, "İçerik")),
    );
    expect(html).toContain("site-header");
    expect(html).toContain("site-footer");
    expect(html).toContain('<main class="flex-1"><div>İçerik</div></main>');
  });

  it("StatusBar oturum ve mağaza yokken hasOwnerStore'u false tutar ve AppSidebar Mağaza Yönetimi göstermez", async () => {
    m.pathname = "/kesfet";
    const sonuc = await statusBarVeSidebarCalistir();

    expect(sonuc.setHasOwnerStoreSpy).toHaveBeenCalledWith(false);
    expect(sonuc.shell.hasOwnerStore).toBe(false);
    expect(sonuc.sidebarHtml).toContain("Vitrinim");
    expect(sonuc.sidebarHtml).toContain("Keşfet");
    expect(sonuc.sidebarHtml).not.toContain("Mağaza Yönetimi");
    expect(sonuc.sidebarHtml).not.toContain("/app/urunler?fatura=1");
  });

  it("StatusBar bootstrap mağaza döndürdüğünde hasOwnerStore'u true yapar, mağaza kapandığında false'a çeker", async () => {
    m.pathname = "/kesfet";
    m.getSession.mockResolvedValue({
      data: { session: { user: { id: "user-1" }, access_token: "tok" } },
      error: null,
    });
    m.rpc.mockResolvedValue({
      data: {
        has_store: true,
        store: { slug: "acik-vitrin", is_published: true },
      },
      error: null,
    });

    const acik = await statusBarVeSidebarCalistir();
    expect(m.rpc).toHaveBeenCalledWith("get_owner_workspace_bootstrap");
    expect(acik.setHasOwnerStoreSpy).toHaveBeenCalledWith(true);
    expect(acik.shell.hasOwnerStore).toBe(true);
    expect(acik.sidebarHtml).toContain("Mağaza Yönetimi");
    expect(acik.sidebarHtml).toContain("/app/urunler?fatura=1");

    acik.shell.refreshShellStatus();
    m.rpc.mockResolvedValue({
      data: { has_store: false, store: null },
      error: null,
    });
    m.fetch.mockResolvedValue(
      new Response(JSON.stringify({ store: null }), { status: 200 }),
    );

    const kapali = await statusBarVeSidebarCalistir();
    expect(kapali.setHasOwnerStoreSpy).toHaveBeenCalledWith(false);
    expect(kapali.shell.hasOwnerStore).toBe(false);
    expect(kapali.sidebarHtml).not.toContain("Mağaza Yönetimi");
    expect(kapali.sidebarHtml).not.toContain("/app/urunler?fatura=1");
  });

  it("StatusBar /api/owner-workspace/current mağaza döndürdüğünde hasOwnerStore'u true yapar, boş döndüğünde false'a çeker", async () => {
    m.pathname = "/kesfet";
    m.fetch.mockResolvedValue(
      new Response(
        JSON.stringify({ store: { slug: "misafir-vitrin", is_published: false } }),
        { status: 200 },
      ),
    );

    const misafirMagazali = await statusBarVeSidebarCalistir();
    expect(m.fetch).toHaveBeenCalledWith("/api/owner-workspace/current", {
      cache: "no-store",
    });
    expect(misafirMagazali.setHasOwnerStoreSpy).toHaveBeenCalledWith(true);
    expect(misafirMagazali.shell.hasOwnerStore).toBe(true);
    expect(misafirMagazali.sidebarHtml).toContain("Mağaza Yönetimi");
    expect(misafirMagazali.sidebarHtml).toContain("/app/urunler?fatura=1");

    misafirMagazali.shell.refreshShellStatus();
    m.fetch.mockResolvedValue(
      new Response(JSON.stringify({ store: null }), { status: 200 }),
    );

    const bos = await statusBarVeSidebarCalistir();
    expect(bos.setHasOwnerStoreSpy).toHaveBeenCalledWith(false);
    expect(bos.shell.hasOwnerStore).toBe(false);
    expect(bos.sidebarHtml).not.toContain("Mağaza Yönetimi");
  });

  it("StatusBar oturum/API hatasında fail-closed davranarak hasOwnerStore'u false tutar", async () => {
    m.pathname = "/kesfet";
    m.getSession.mockRejectedValue(new Error("network failure"));

    const hataSonucu = await statusBarVeSidebarCalistir();
    expect(hataSonucu.setHasOwnerStoreSpy).toHaveBeenCalledWith(false);
    expect(hataSonucu.shell.hasOwnerStore).toBe(false);
    expect(hataSonucu.sidebarHtml).not.toContain("Mağaza Yönetimi");
  });

  it("StatusBar yayın durumu null döndüğünde hasOwnerStore'u false bırakır", async () => {
    m.pathname = "/kesfet";
    m.getSession.mockResolvedValue({
      data: { session: { user: { id: "user-1" }, access_token: "tok" } },
      error: null,
    });
    m.rpc.mockResolvedValue({
      data: { has_store: true, slug: "yarim-vitrin", store: { slug: "yarim-vitrin" } },
      error: null,
    });
    m.maybeSingle.mockRejectedValue(new Error("db read error"));

    const sonuc = await statusBarVeSidebarCalistir();
    expect(sonuc.setHasOwnerStoreSpy).toHaveBeenCalledWith(false);
    expect(sonuc.shell.hasOwnerStore).toBe(false);
    expect(sonuc.sidebarHtml).not.toContain("Mağaza Yönetimi");
  });

  it("Keşfet loading ve error bileşenleri tek main semantiğini korur", () => {
    const loadingHtml = renderToStaticMarkup(createElement(KesfetYukleniyor));
    const errorHtml = renderToStaticMarkup(
      createElement(KesfetHata, { error: new Error("test"), reset: () => {} }),
    );
    expect(loadingHtml).toContain("<main");
    expect(errorHtml).toContain("<main");
  });

  it("StatusBar onAuthStateChange oturum değişimini dinler ve unmount'ta unsubscribe çağırır", async () => {
    m.pathname = "/kesfet";
    const sonuc = await statusBarVeSidebarCalistir();
    expect(m.onAuthStateChange).toHaveBeenCalledTimes(1);
    expect(sonuc.shell.hasOwnerStore).toBe(false);

    m.getSession.mockResolvedValue({
      data: { session: { user: { id: "user-2" }, access_token: "tok2" } },
      error: null,
    });
    m.rpc.mockResolvedValue({
      data: { has_store: true, store: { slug: "yeni-vitrin", is_published: true } },
      error: null,
    });
    m.authCallback?.("SIGNED_IN", { user: { id: "user-2" } });
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(sonuc.setHasOwnerStoreSpy).toHaveBeenCalledWith(true);

    sonuc.unmount();
    expect(m.unsubscribe).toHaveBeenCalledTimes(1);
  });

  it("AppSidebar /app yolunda Mağaza Yönetimi bloğunu üretir", () => {
    m.pathname = "/app";
    const html = renderToStaticMarkup(
      createElement(AppShellProvider, null, createElement(AppSidebar)),
    );
    expect(html).toContain("Mağaza Yönetimi");
    expect(html).toContain("/app/urunler?fatura=1");
  });
});
