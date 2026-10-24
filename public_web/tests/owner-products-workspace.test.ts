import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  stateIndex: 0,
  load: null as (() => Promise<void>) | null,
  setStore: vi.fn(),
  setLoading: vi.fn(),
  setError: vi.fn(),
  push: vi.fn(),
  getSession: vi.fn(),
  rpc: vi.fn(),
  from: vi.fn(),
  select: vi.fn(),
  eq: vi.fn(),
  maybeSingle: vi.fn(),
  fetch: vi.fn(),
}));

vi.mock("react", async (importOriginal) => ({
  ...await importOriginal<typeof import("react")>(),
  useState(initial: unknown) {
    const setters = [mocks.setStore, mocks.setLoading, mocks.setError];
    return [initial, setters[mocks.stateIndex++]];
  },
  useCallback(callback: () => Promise<void>) {
    mocks.load = callback;
    return callback;
  },
  useEffect: vi.fn(),
}));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: mocks.push }) }));
vi.mock("@/lib/supabase", () => ({
  supabase: { auth: { getSession: mocks.getSession }, rpc: mocks.rpc, from: mocks.from },
}));
vi.mock("@/components/owner/OwnerProductManager", () => ({ OwnerProductManager: () => null }));

import UrunlerPage from "@/app/app/urunler/page";

const store = {
  id: "store-1", slug: "misafir-vitrini", name: "Misafir vitrini", kategori: "Giyim & Moda",
  business_type: "Butik", products: [{ id: "draft-1", name: "Fatura taslağı", is_visible: false }],
  product_categories: [],
};

async function loadPage() {
  UrunlerPage();
  expect(mocks.load).toBeTypeOf("function");
  await mocks.load?.();
}

beforeEach(() => {
  vi.clearAllMocks();
  mocks.stateIndex = 0;
  mocks.load = null;
  mocks.getSession.mockResolvedValue({ data: { session: { user: { id: "user-1" } } }, error: null });
  mocks.rpc.mockResolvedValue({ data: { has_store: false }, error: null });
  mocks.from.mockReturnValue({ select: mocks.select });
  mocks.select.mockReturnValue({ eq: mocks.eq });
  mocks.eq.mockReturnValue({ maybeSingle: mocks.maybeSingle });
  mocks.maybeSingle.mockResolvedValue({ data: store, error: null });
  mocks.fetch.mockResolvedValue(new Response(JSON.stringify({ tamam: true, store }), { status: 200 }));
  vi.stubGlobal("fetch", mocks.fetch);
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("ürün ekranının hesap ve misafir sahipliğini çözmesi", () => {
  it("hesap vitrini varsa mevcut hesap sorgusunu kullanır", async () => {
    mocks.rpc.mockResolvedValue({ data: { has_store: true, slug: store.slug }, error: null });
    await loadPage();
    expect(mocks.rpc).toHaveBeenCalledWith("bootstrap_owner_state");
    expect(mocks.eq).toHaveBeenCalledWith("slug", store.slug);
    expect(mocks.setStore).toHaveBeenCalledWith(store);
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("hesaba bağlanmamış vitrini çerez köprüsünden görünmez taslaklarıyla yükler", async () => {
    await loadPage();
    expect(mocks.fetch).toHaveBeenCalledWith("/api/owner-workspace/current", { cache: "no-store" });
    expect(mocks.setStore).toHaveBeenCalledWith(store);
    expect(mocks.setError).not.toHaveBeenCalledWith("Vitrin bulunamadı. Önce vitrin oluştur.");
    expect(mocks.push).not.toHaveBeenCalled();
  });

  it("Supabase oturumu olmasa da geçerli sahip çerezini önce dener", async () => {
    mocks.getSession.mockResolvedValue({ data: { session: null }, error: null });
    await loadPage();
    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(mocks.setStore).toHaveBeenCalledWith(store);
    expect(mocks.push).not.toHaveBeenCalled();
  });

  it("hesap okuma hatasında farklı bir çerez vitriniyle sessizce açılmaz", async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: "temporary failure" } });
    await loadPage();
    expect(mocks.setError).toHaveBeenLastCalledWith("Vitrin bilgileri yüklenemedi. Lütfen tekrar dene.");
    expect(mocks.setStore).not.toHaveBeenCalled();
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("hesap okuma hatasını vitrin yok diye göstermez", async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: { message: "temporary failure" } });
    mocks.fetch.mockResolvedValue(new Response(JSON.stringify({ sebep: "NO_OWNER_SESSION" }), { status: 404 }));
    await loadPage();
    expect(mocks.setError).toHaveBeenLastCalledWith("Vitrin bilgileri yüklenemedi. Lütfen tekrar dene.");
    expect(mocks.setStore).not.toHaveBeenCalled();
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("hesap oturumu okunamazsa misafir vitriniyle değiştirmez", async () => {
    mocks.getSession.mockResolvedValue({ data: { session: null }, error: { message: "session unavailable" } });
    await loadPage();
    expect(mocks.setError).toHaveBeenLastCalledWith("Vitrin bilgileri yüklenemedi. Lütfen tekrar dene.");
    expect(mocks.setStore).not.toHaveBeenCalled();
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("hesapta vitrin ve sahip çerezi yoksa gerçek eksik vitrin sonucunu gösterir", async () => {
    mocks.fetch.mockResolvedValue(new Response(JSON.stringify({ sebep: "NO_OWNER_SESSION" }), { status: 404 }));
    await loadPage();
    expect(mocks.setError).toHaveBeenLastCalledWith("Vitrin bulunamadı. Önce vitrin oluştur.");
  });

  it("süresi dolmuş sahipliğe yeni vitrin kurdurmaz", async () => {
    mocks.fetch.mockResolvedValue(new Response(JSON.stringify({ sebep: "INVALID_OWNER_SESSION" }), { status: 401 }));
    await loadPage();
    expect(mocks.setError).toHaveBeenLastCalledWith("Vitrin sahiplik oturumun geçersiz veya süresi dolmuş. Vitrinine yeniden giriş yap.");
    expect(mocks.setStore).not.toHaveBeenCalled();
    expect(mocks.push).not.toHaveBeenCalled();
  });

  it("katalog hatasında boş mağaza kurulumuna geçmez", async () => {
    mocks.fetch.mockResolvedValue(new Response(JSON.stringify({ sebep: "WORKSPACE_UNAVAILABLE" }), { status: 503 }));
    await loadPage();
    expect(mocks.setError).toHaveBeenLastCalledWith("Vitrin bilgileri yüklenemedi. Lütfen tekrar dene.");
    expect(mocks.setStore).not.toHaveBeenCalled();
    expect(mocks.setLoading).toHaveBeenLastCalledWith(false);
  });

  it("hesap vitrini okunamazsa farklı bir çerez vitriniyle sessizce değiştirmez", async () => {
    mocks.rpc.mockResolvedValue({ data: { has_store: true, slug: "hesap-vitrini" }, error: null });
    mocks.maybeSingle.mockResolvedValue({ data: null, error: { message: "query failed" } });
    await loadPage();
    expect(mocks.setError).toHaveBeenLastCalledWith("Ürünler yüklenemedi. Lütfen tekrar dene.");
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("iki oturum da yoksa mevcut giriş yolunu korur", async () => {
    mocks.getSession.mockResolvedValue({ data: { session: null }, error: null });
    mocks.fetch.mockResolvedValue(new Response(JSON.stringify({ sebep: "NO_OWNER_SESSION" }), { status: 404 }));
    await loadPage();
    expect(mocks.push).toHaveBeenCalledWith("/giris");
    expect(mocks.setStore).not.toHaveBeenCalled();
  });
});
