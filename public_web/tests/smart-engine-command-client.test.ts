import { describe, expect, it, vi } from "vitest";
import {
  executeSmartEngineCommand,
  undoSmartEngineCommand,
} from "@/lib/smartEngineCommandClient";

const ids = [
  "11111111-1111-4111-8111-111111111111",
  "22222222-2222-4222-8222-222222222222",
  "33333333-3333-4333-8333-333333333333",
  "44444444-4444-4444-8444-444444444444",
  "55555555-5555-4555-8555-555555555555",
];

function idFactory() {
  let index = 0;
  return () => ids[index++] ?? "66666666-6666-4666-8666-666666666666";
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function requestBody(init?: RequestInit): Record<string, unknown> {
  return JSON.parse(String(init?.body ?? "{}")) as Record<string, unknown>;
}

describe("smartEngineCommandClient", () => {
  it("tek commandId altında draft version'ı authoritative response ile zincirler", async () => {
    const seen: Record<string, unknown>[] = [];
    const fetchImpl = vi.fn(async (_url: string | URL | Request, init?: RequestInit) => {
      const body = requestBody(init);
      seen.push(body);
      const version = Number(body.expectedDraftVersion) + 1;
      return jsonResponse({ tamam: true, taslakSurumu: version, replayed: false });
    }) as unknown as typeof fetch;

    const result = await executeSmartEngineCommand({
      slug: "test-esnaf",
      initialDraftVersion: 7,
      actions: [
        { anahtar: "telefon", deger: "02128880000" },
        { anahtar: "website", deger: "https://ornek.com" },
      ],
      fetchImpl,
      idFactory: idFactory(),
    });

    expect(result.status).toBe("succeeded");
    expect(result.commandId).toBe(ids[0]);
    expect(result.draftVersion).toBe(9);
    expect(result.succeeded).toHaveLength(2);
    expect(result.failed).toHaveLength(0);
    expect(result.stopped).toHaveLength(0);
    expect(seen.map((body) => body.expectedDraftVersion)).toEqual([7, 8]);
    expect(seen.map((body) => body.commandId)).toEqual([ids[0], ids[0]]);
    expect(seen.map((body) => body.actionId)).toEqual([ids[1], ids[2]]);
  });

  it("kesin field-level no-write hatasında bağımsız sonraki alanı dener", async () => {
    let call = 0;
    const seenVersions: unknown[] = [];
    const fetchImpl = vi.fn(async (_url: string | URL | Request, init?: RequestInit) => {
      const body = requestBody(init);
      seenVersions.push(body.expectedDraftVersion);
      call += 1;
      if (call === 1) {
        return jsonResponse(
          { hata: "Geçersiz değer.", kod: "INVALID_FIELD_VALUE" },
          422,
        );
      }
      return jsonResponse({ tamam: true, taslakSurumu: 5 });
    }) as unknown as typeof fetch;

    const result = await executeSmartEngineCommand({
      slug: "test-esnaf",
      initialDraftVersion: 4,
      actions: [
        { anahtar: "website", deger: "ftp://yanlis" },
        { anahtar: "telefon", deger: "02128880000" },
      ],
      fetchImpl,
      idFactory: idFactory(),
    });

    expect(result.status).toBe("partial_result");
    expect(result.failed.map((item) => item.code)).toEqual(["INVALID_FIELD_VALUE"]);
    expect(result.succeeded.map((item) => item.anahtar)).toEqual(["telefon"]);
    expect(result.stopped).toHaveLength(0);
    expect(seenVersions).toEqual([4, 4]);
  });

  it("conflict sonrası kalan action'ları server'a göndermez", async () => {
    let call = 0;
    const fetchImpl = vi.fn(async () => {
      call += 1;
      if (call === 1) return jsonResponse({ tamam: true, taslakSurumu: 11 });
      return jsonResponse(
        { hata: "Taslak değişti.", kod: "DRAFT_VERSION_CONFLICT" },
        409,
      );
    }) as unknown as typeof fetch;

    const result = await executeSmartEngineCommand({
      slug: "test-esnaf",
      initialDraftVersion: 10,
      actions: [
        { anahtar: "telefon", deger: "02128880000" },
        { anahtar: "website", deger: "https://ornek.com" },
        { anahtar: "instagram", deger: "ornek" },
      ],
      fetchImpl,
      idFactory: idFactory(),
    });

    expect(fetchImpl).toHaveBeenCalledTimes(2);
    expect(result.status).toBe("partial_result");
    expect(result.succeeded).toHaveLength(1);
    expect(result.failed[0]?.code).toBe("DRAFT_VERSION_CONFLICT");
    expect(result.stopped).toEqual([
      { anahtar: "instagram", deger: "ornek", code: "DRAFT_VERSION_CONFLICT" },
    ]);
  });

  it("network/unknown outcome durumunda kalan action'ları durdurur", async () => {
    const networkFetch = vi.fn(async () => {
      throw new Error("offline");
    }) as unknown as typeof fetch;

    const network = await executeSmartEngineCommand({
      slug: "test-esnaf",
      initialDraftVersion: 2,
      actions: [
        { anahtar: "telefon", deger: "02128880000" },
        { anahtar: "website", deger: "https://ornek.com" },
      ],
      fetchImpl: networkFetch,
      idFactory: idFactory(),
    });

    expect(network.status).toBe("failed");
    expect(network.failed[0]?.code).toBe("NETWORK_ERROR");
    expect(network.stopped[0]?.anahtar).toBe("website");

    const unknownFetch = vi.fn(async () => jsonResponse({ tamam: true })) as unknown as typeof fetch;
    const unknown = await executeSmartEngineCommand({
      slug: "test-esnaf",
      initialDraftVersion: 2,
      actions: [
        { anahtar: "telefon", deger: "02128880000" },
        { anahtar: "website", deger: "https://ornek.com" },
      ],
      fetchImpl: unknownFetch,
      idFactory: idFactory(),
    });

    expect(unknown.failed[0]?.code).toBe("UNKNOWN_MUTATION_OUTCOME");
    expect(unknown.stopped[0]?.anahtar).toBe("website");
  });

  it("Undo alan listesi değil yalnız commandId gönderir ve authoritative version döndürür", async () => {
    let sent: Record<string, unknown> = {};
    const fetchImpl = vi.fn(async (_url: string | URL | Request, init?: RequestInit) => {
      sent = requestBody(init);
      return jsonResponse({
        tamam: true,
        replayed: false,
        taslakSurumu: 14,
        geriAlinanIslemSayisi: 3,
      });
    }) as unknown as typeof fetch;

    const result = await undoSmartEngineCommand({
      slug: "test-esnaf",
      commandId: ids[0],
      clientId: "client-1",
      fetchImpl,
    });

    expect(result).toEqual({
      ok: true,
      replayed: false,
      draftVersion: 14,
      rolledBackActionCount: 3,
    });
    expect(sent).toEqual({
      slug: "test-esnaf",
      commandId: ids[0],
      clientId: "client-1",
    });
    expect(sent).not.toHaveProperty("anahtarlar");
  });

  it("Undo conflict'i success gibi göstermez", async () => {
    const fetchImpl = vi.fn(async () =>
      jsonResponse({ hata: "Geri alınamaz.", kod: "UNDO_CONFLICT" }, 409),
    ) as unknown as typeof fetch;

    const result = await undoSmartEngineCommand({
      slug: "test-esnaf",
      commandId: ids[0],
      fetchImpl,
    });

    expect(result).toEqual({
      ok: false,
      code: "UNDO_CONFLICT",
      message: "Geri alınamaz.",
    });
  });
});
