import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
const m = vi.hoisted(() => ({ rpc: vi.fn() }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: () => ({ rpc: m.rpc }) }));
import { GET } from "@/app/api/fatura-okuyucu-durumu/route";
const oldKey = process.env.OPENROUTER_API_KEY;
beforeEach(() => { delete process.env.OPENROUTER_API_KEY; m.rpc.mockReset().mockResolvedValue({ data: true, error: null }); });
afterEach(() => { if (oldKey === undefined) delete process.env.OPENROUTER_API_KEY; else process.env.OPENROUTER_API_KEY = oldKey; });
describe("gerçek otomatik fatura işleyicisi durumu", () => {
  it("anahtar yoksa hazır değildir ve iş çağrılmaz", async () => { expect(await (await GET()).json()).toEqual({ hazir: false }); expect(m.rpc).not.toHaveBeenCalled(); });
  it("anahtar ve kurulu işleyici birlikte hazırdır", async () => { process.env.OPENROUTER_API_KEY = "unit-test-key"; expect(await (await GET()).json()).toEqual({ hazir: true }); expect(m.rpc).toHaveBeenCalledWith("invoice_provider_ready"); });
  it("kurulum yapılmadıysa yalnız anahtar hazır demeye yetmez", async () => { process.env.OPENROUTER_API_KEY = "unit-test-key"; m.rpc.mockResolvedValue({data:null,error:{code:"MISSING"}}); expect(await (await GET()).json()).toEqual({hazir:false}); });
  it("anahtar ve özel iş verisi hiçbir şekilde dışarı verilmez", async () => { process.env.OPENROUTER_API_KEY = "UNIT_KEY_PRIVATE_TEST"; const res=await GET(); expect(await res.text()).toBe('{"hazir":true}'); expect(res.headers.get("Cache-Control")).toBe("no-store"); });
});
