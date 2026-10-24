import { isValidElement, type ReactElement, type ReactNode } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { OWNER_SESSION_COOKIE, signOwnerSession } from "../src/lib/ownerSession";

const runtime = vi.hoisted(() => ({
  cookie: undefined as string | undefined,
  draft: null as Record<string, unknown> | null,
  from: vi.fn(),
  rpc: vi.fn(),
}));

vi.mock("@/lib/supabase", () => ({
  supabase: { from: runtime.from, rpc: runtime.rpc },
}));
vi.mock("next/headers", () => ({
  cookies: async () => ({
    get: (name: string) =>
      name === OWNER_SESSION_COOKIE && runtime.cookie
        ? { value: runtime.cookie }
        : undefined,
  }),
}));
vi.mock("next/cache", () => ({ unstable_cache: (fn: unknown) => fn }));
vi.mock("../src/app/v/[slug]/VitrinProfileView", () => ({ default: "storefront" }));
vi.mock("../src/app/v/[slug]/OwnerWorkspaceShell", () => ({ default: "workspace" }));
vi.mock("../src/app/v/[slug]/ProductCatalog", () => ({ default: "catalog" }));

import StorePage from "../src/app/v/[slug]/page";

const STORE_ID = "11111111-1111-1111-1111-111111111111";
const SLUG = "deneme-vitrin";
const SESSION_TOKEN = "ab".repeat(32);
const store = {
  id: STORE_ID,
  slug: SLUG,
  name: "Yayınlı Vitrin",
  status: "Açık",
  is_published: true,
};

function elements(node: ReactNode): ReactElement<Record<string, unknown>>[] {
  if (Array.isArray(node)) return node.flatMap(elements);
  if (!isValidElement<Record<string, unknown>>(node)) return [];
  return [node, ...elements(node.props.children as ReactNode)];
}

async function renderPage(searchParams: Record<string, string> = {}) {
  return elements(await StorePage({
    params: Promise.resolve({ slug: SLUG }),
    searchParams: Promise.resolve(searchParams),
  }));
}

function ownerReturn(nodes: ReactElement<Record<string, unknown>>[]) {
  return nodes.find((node) => node.props.href === `/v/${SLUG}?editor=1`);
}

beforeEach(() => {
  vi.stubEnv("OWNER_SESSION_SECRET", "test-owner-return-".repeat(3));
  runtime.cookie = undefined;
  runtime.draft = {
    store_id: STORE_ID,
    slug: SLUG,
    draft_data: { ...store, name: "Çalışma taslağı" },
  };
  runtime.from.mockImplementation((table: string) => {
    const result = {
      data: table === "stores" ? store : table === "booking_settings" ? null : [],
      error: null,
    };
    const promise = Promise.resolve(result);
    const query = {
      select: () => query,
      eq: () => query,
      order: () => query,
      limit: () => promise,
      maybeSingle: () => promise,
      then: promise.then.bind(promise),
    };
    return query;
  });
  runtime.rpc.mockImplementation(async (name: string) => ({
    data: name === "get_working_draft_for_session"
      ? runtime.draft
      : { categories: [], products: [] },
    error: null,
  }));
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.clearAllMocks();
});

describe("yayınlı vitrinden mevcut sahip asistanına dönüş", () => {
  it("müşteriye dönüş bağlantısı veya sahip çalışma alanı göstermez", async () => {
    const nodes = await renderPage();
    expect(ownerReturn(nodes)).toBeUndefined();
    expect(nodes.some((node) => node.type === "workspace")).toBe(false);
    expect(runtime.rpc).not.toHaveBeenCalled();
  });

  it("doğrulanmış sahip yayınlı içeriği görür ve aynı vitrinin asistanına döner", async () => {
    runtime.cookie = signOwnerSession(STORE_ID, SLUG, SESSION_TOKEN);
    const nodes = await renderPage();
    const link = ownerReturn(nodes);
    expect(link).toBeDefined();
    expect(link?.props.prefetch).toBe(false);
    expect(elements(link).some((node) => node.props.children === "Vixrex Asistan ile düzenle")).toBe(true);
    expect(nodes.find((node) => node.type === "storefront")?.props).toMatchObject({
      storeName: "Yayınlı Vitrin", ownerMode: false,
    });
    expect(nodes.some((node) => node.type === "workspace")).toBe(false);
    expect(runtime.rpc).toHaveBeenCalledWith("get_working_draft_for_session", {
      p_session_token: SESSION_TOKEN,
    });
  });

  it("dönüş hedefi mevcut çalışma alanını açar; ikinci dönüş düğmesi çıkarmaz", async () => {
    runtime.cookie = signOwnerSession(STORE_ID, SLUG, SESSION_TOKEN);
    const nodes = await renderPage({ editor: "1" });
    expect(ownerReturn(nodes)).toBeUndefined();
    expect(nodes.some((node) => node.type === "workspace")).toBe(true);
    expect(nodes.find((node) => node.type === "storefront")?.props).toMatchObject({
      storeName: "Çalışma taslağı", ownerMode: true,
    });
  });

  it("başka vitrinin geçerli sahip çereziyle dönüş bağlantısı göstermez", async () => {
    runtime.cookie = signOwnerSession(STORE_ID, "baska-vitrin", SESSION_TOKEN);
    expect(ownerReturn(await renderPage())).toBeUndefined();
    expect(runtime.rpc).not.toHaveBeenCalled();
  });

  it("imzası bozulmuş çerezle dönüş bağlantısı göstermez", async () => {
    runtime.cookie = signOwnerSession(STORE_ID, SLUG, SESSION_TOKEN) + "bozuk";
    expect(ownerReturn(await renderPage())).toBeUndefined();
    expect(runtime.rpc).not.toHaveBeenCalled();
  });

  it("veritabanı oturumu doğrulayamazsa dönüş bağlantısı göstermez", async () => {
    runtime.cookie = signOwnerSession(STORE_ID, SLUG, SESSION_TOKEN);
    runtime.draft = null;
    expect(ownerReturn(await renderPage())).toBeUndefined();
  });

  it.each([
    { store_id: "22222222-2222-2222-2222-222222222222", slug: SLUG },
    { store_id: STORE_ID, slug: "baska-vitrin" },
  ])("çerez ile taslağın mağazası uyuşmazsa dönüş bağlantısı göstermez: %j", async (mismatch) => {
    runtime.cookie = signOwnerSession(STORE_ID, SLUG, SESSION_TOKEN);
    runtime.draft = { ...runtime.draft, ...mismatch };
    expect(ownerReturn(await renderPage())).toBeUndefined();
  });
});
