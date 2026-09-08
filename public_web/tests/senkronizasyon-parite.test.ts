import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => {
  process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "anon-test";
  return {
    refresh: vi.fn(),
    useEffect: vi.fn(),
    createClient: vi.fn(),
    channel: vi.fn(),
    removeChannel: vi.fn(),
  };
});

vi.mock("react", () => ({ useEffect: mocks.useEffect }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ refresh: mocks.refresh }),
}));
vi.mock("@supabase/supabase-js", () => ({ createClient: mocks.createClient }));

import {
  taslakClientId,
  useCanliVitrinSenkron,
} from "@/lib/canliVitrinSenkron";
import { broadcastTaslakGuncellendi } from "@/lib/workingDraftBroadcast";

type Registration = {
  kind: string;
  config: Record<string, unknown>;
  callback: (payload: { payload?: Record<string, unknown> }) => void;
};

type CreatedChannel = {
  name: string;
  registrations: Registration[];
  api: {
    on: ReturnType<typeof vi.fn>;
    subscribe: ReturnType<typeof vi.fn>;
    send: ReturnType<typeof vi.fn>;
  };
};

let createdChannels: CreatedChannel[] = [];
let cleanup: (() => void) | null = null;

beforeEach(() => {
  vi.clearAllMocks();
  createdChannels = [];
  cleanup = null;

  mocks.channel.mockImplementation((name: string) => {
    const registrations: Registration[] = [];
    const api = {
      on: vi.fn(),
      subscribe: vi.fn(),
      send: vi.fn().mockResolvedValue({ status: "ok" }),
    };
    api.on.mockImplementation(
      (kind: string, config: Record<string, unknown>, callback: Registration["callback"]) => {
        registrations.push({ kind, config, callback });
        return api;
      },
    );
    api.subscribe.mockReturnValue(api);
    createdChannels.push({ name, registrations, api });
    return api;
  });

  mocks.createClient.mockReturnValue({
    channel: mocks.channel,
    removeChannel: mocks.removeChannel,
  });

  mocks.useEffect.mockImplementation((effect: () => void | (() => void)) => {
    const sonuc = effect();
    cleanup = typeof sonuc === "function" ? sonuc : null;
  });
});

describe("canlı senkronizasyon — gerçek kanal kurulumu ve olay davranışı", () => {
  it("stores ve draft kanallarını gerçekten kurar; dış olay yeniler, kendi yankısını atlar", () => {
    useCanliVitrinSenkron("ornek-magaza", true, true);

    const canli = createdChannels.find((kanal) => kanal.name === "vitrin_ornek-magaza");
    const taslak = createdChannels.find((kanal) => kanal.name === "draft:ornek-magaza");
    expect(canli).toBeDefined();
    expect(taslak).toBeDefined();

    expect(canli!.registrations).toHaveLength(1);
    expect(canli!.registrations[0]).toMatchObject({
      kind: "postgres_changes",
      config: {
        event: "UPDATE",
        schema: "public",
        table: "stores",
        filter: "slug=eq.ornek-magaza",
      },
    });
    expect(taslak!.registrations).toHaveLength(1);
    expect(taslak!.registrations[0]).toMatchObject({
      kind: "broadcast",
      config: { event: "alan_guncellendi" },
    });

    canli!.registrations[0].callback({});
    expect(mocks.refresh).toHaveBeenCalledTimes(1);

    taslak!.registrations[0].callback({
      payload: { clientId: "baska-sekme", deger: "kullanilmamali" },
    });
    expect(mocks.refresh).toHaveBeenCalledTimes(2);

    taslak!.registrations[0].callback({
      payload: { clientId: taslakClientId() },
    });
    expect(mocks.refresh).toHaveBeenCalledTimes(2);

    cleanup?.();
    expect(mocks.removeChannel).toHaveBeenCalledTimes(2);
    expect(mocks.removeChannel).toHaveBeenCalledWith(canli!.api);
    expect(mocks.removeChannel).toHaveBeenCalledWith(taslak!.api);
  });

  it("etkin değilse Supabase istemcisi veya kanal açmaz", () => {
    useCanliVitrinSenkron("ornek-magaza", false, true);

    expect(mocks.createClient).not.toHaveBeenCalled();
    expect(mocks.channel).not.toHaveBeenCalled();
  });

  it("taslak broadcast'i gerçekten yalnız clientId taşır; alan adı/değeri göndermez", async () => {
    broadcastTaslakGuncellendi("ornek-magaza", "client-7");
    await Promise.resolve();
    await Promise.resolve();

    const taslak = createdChannels.find((kanal) => kanal.name === "draft:ornek-magaza");
    expect(taslak).toBeDefined();
    expect(taslak!.api.send).toHaveBeenCalledTimes(1);

    const gonderilen = taslak!.api.send.mock.calls[0][0];
    expect(gonderilen).toEqual({
      type: "broadcast",
      event: "alan_guncellendi",
      payload: { clientId: "client-7" },
    });
    expect(Object.keys(gonderilen.payload)).toEqual(["clientId"]);
  });
});
