import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";
const m = vi.hoisted(() => ({
  cookie: vi.fn((): { value: string } | undefined => ({ value: "owner" })),
  owner: vi.fn((v?: string): { slug: string } | null => v ? { slug: "deneme" } : null),
  edit: vi.fn(async (): Promise<{ slug: string }> => { throw new Error("AUTH"); }),
  rpc: vi.fn(), previous: vi.fn(), load: vi.fn(), fetch: vi.fn(),
}));
vi.mock("next/headers", () => ({ cookies: async () => ({ get: m.cookie }) }));
vi.mock("@/lib/ownerSession", () => ({ OWNER_SESSION_COOKIE: "owner", verifyOwnerSession: m.owner }));
vi.mock("@/lib/instagramServer", () => ({ verifyStoreEditToken: m.edit }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: () => ({ rpc: m.rpc, from: () => ({ select: () => ({ eq: () => ({ maybeSingle: async () => ({ data: { id: "store-1" } }) }) }) }) }) }));
vi.mock("@/lib/faturaIslemOku", async (original) => ({ ...await original<typeof import("@/lib/faturaIslemOku")>(), parmakIzindenIslemBul: m.previous, islemiYukle: m.load, islemYaniti: (x: { satirlar: unknown[] }) => ({ tamam: true, satirlar: x.satirlar }) }));
import { POST } from "@/app/api/fatura-oku/route";
import { OKUMA_PRESET } from "@/lib/faturaArkaPlanIslemi";
const png = () => new File([new Uint8Array([137,80,78,71,13,10,26,10,0,0,0,13])], "fatura.png", { type: "image/png" });
function request(files: File[] = [png()], extra: Record<string,string> = {}) {
  const form = new FormData(); form.set("slug", "deneme"); files.forEach((f) => form.append("dosya",f)); Object.entries(extra).forEach(([k,v]) => form.set(k,v));
  return new NextRequest("http://localhost/api/fatura-oku", { method: "POST", body: form });
}
const started = () => m.rpc.mock.calls.filter(([name]) => name === "enqueue_invoice_provider_job");
beforeEach(() => {
  vi.clearAllMocks(); process.env.OPENROUTER_API_KEY = "unit-test-key";
  m.cookie.mockReturnValue({ value: "owner" }); m.owner.mockImplementation((v?:string) => v ? {slug:"deneme"} : null);
  m.edit.mockRejectedValue(new Error("AUTH")); m.previous.mockResolvedValue(null); m.load.mockResolvedValue(null);
  m.rpc.mockImplementation(async (name:string) => ({ data: name === "consume_assistant_request" ? {allowed:true} : {success:true,id:"11111111-1111-4111-8111-111111111111",state:"queued"},error:null }));
  vi.stubGlobal("fetch", m.fetch);
});
describe("/api/fatura-oku otomatik iş", () => {
  it("tek fotoğrafı tek kalıcı işe verir; sonuç gelmeden kart/ürün/ücretli ikinci çağrı üretmez",async()=>{
    const res=await POST(request()); const body=await res.json();
    expect(res.status).toBe(202); expect(body.hazirlaniyor).toBe(true); expect(body.tamam).toBe(false);
    expect(body.satirlar).toBeUndefined(); expect(JSON.stringify(body)).not.toContain("unit-test-key");
    expect(started()).toHaveLength(1); const args=started()[0][1];
    expect(args.p_store_id).toBe("store-1"); expect(args.p_fingerprint).toMatch(/^[a-f0-9]{64}$/);
    expect(args.p_body.model).toBe(OKUMA_PRESET); expect(args.p_body.stream).toBe(true);
    expect(args.p_body.messages[0].content[1].image_url.url).toMatch(/^data:image\/png;base64,/);
    expect(m.fetch).not.toHaveBeenCalled();
  });
  it("iki fotoğraf aynı tek işe gider",async()=>{
    expect((await POST(request([png(),png()]))).status).toBe(202);
    expect(started()).toHaveLength(1); expect(started()[0][1].p_body.messages[0].content.filter((v:{type:string})=>v.type==='image_url')).toHaveLength(2);
  });
  it("PDF gerçek file_data ile aynı işleyiciye gider",async()=>{
    const f=new File([new Uint8Array([37,80,68,70,45,49,46,54,10,0,0,0])],"fatura.pdf",{type:"application/pdf"});
    expect((await POST(request([f]))).status).toBe(202);
    expect(started()[0][1].p_body.messages[0].content[1].file.file_data).toMatch(/^data:application\/pdf;base64,/);
  });
  it("sahiplik yoksa iş başlatılmaz",async()=>{m.cookie.mockReturnValue(undefined);expect((await POST(request())).status).toBe(401);expect(started()).toHaveLength(0);});
  it("geçerli düzenleme anahtarıyla mobil istek korunur",async()=>{m.cookie.mockReturnValue(undefined);m.edit.mockResolvedValue({slug:"deneme"});expect((await POST(request([png()],{editToken:"edit"}))).status).toBe(202);expect(m.edit).toHaveBeenCalledWith("deneme","edit");});
  it("dördüncü sayfa reddedilir",async()=>{expect((await POST(request([png(),png(),png(),png()]))).status).toBe(413);expect(started()).toHaveLength(0);});
  it("4 MB üstü reddedilir",async()=>{expect((await POST(request([new File([Buffer.alloc(4*1024*1024+1)],"big.png")]))).status).toBe(413);expect(started()).toHaveLength(0);});
  it("gerçek dosya imzası yoksa iş başlamaz",async()=>{expect((await POST(request([new File([new Uint8Array(13)],"fake.png",{type:"image/png"})]))).status).toBe(415);expect(started()).toHaveLength(0);});
  it("saatlik limit korunur",async()=>{m.rpc.mockResolvedValue({data:[{allowed:false,retry_after_seconds:45}],error:null});expect((await POST(request())).status).toBe(429);expect(started()).toHaveLength(0);});
  it("sunucu anahtarı yoksa iş başlamaz",async()=>{delete process.env.OPENROUTER_API_KEY;expect((await POST(request())).status).toBe(503);expect(started()).toHaveLength(0);});
  it("kuyruk kaydı başarısızsa hazır veya örnek kart dönmez",async()=>{m.rpc.mockImplementation(async(name:string)=>name==='consume_assistant_request'?{data:{allowed:true},error:null}:{data:null,error:{code:'MISSING'}});const res=await POST(request());expect(res.status).toBe(503);expect((await res.json()).hata).toContain('işleyicisi');expect(m.fetch).not.toHaveBeenCalled();});
  it("önceki tamamlanmış sonuç varsa yeni model işi başlamaz",async()=>{
    m.previous.mockResolvedValue("old-job");m.load.mockResolvedValue({islemKimligi:"old-job",satirlar:[{hamSatir:"satır",model:"1",ad:"Ürün",barkod:"",varyant:"",beden:"",marka:"",adet:1,birim:"adet",alisBirimFiyat:10,satirToplam:10,guven:0.8,sonuc:"eksik",katalog:{firma:"Firma",kaynakFirma:"Firma",dayanak:"ad",izinDurumu:"yok",resmiAd:"Eski ürün kartı",marka:"",aciklama:"Kaynak açıklaması",gorseller:[],gorselAdaylari:[],kaynak:"https://ornek.example/urun"}}]});
    const res=await POST(request());expect(res.status).toBe(200);expect((await res.json()).taslaklar).toHaveLength(1);expect(started()).toHaveLength(0);
  });
});
