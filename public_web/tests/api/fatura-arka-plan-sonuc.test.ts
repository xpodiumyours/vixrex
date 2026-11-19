import type { SupabaseClient } from "@supabase/supabase-js";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
const m = vi.hoisted(() => ({
 save: vi.fn(),
 load: vi.fn(),
 localImageCompletion: vi.fn(async ({ satirlar }: { satirlar: unknown[] }) => satirlar),
 localImageSelection: vi.fn(async ({ satirlar }: { satirlar: unknown[] }) => satirlar),
}));
vi.mock("@/lib/faturaGorsel", () => ({ gorselsizSatirlariTamamla: m.localImageCompletion }));
vi.mock("@/lib/faturaGorselSecimi", () => ({ adayGorselleriniSec: m.localImageSelection }));
vi.mock("@/lib/faturaIslemKaydi", () => ({ islemKaydet: m.save }));
vi.mock("@/lib/faturaIslemOku", () => ({ islemiYukle: m.load, islemYaniti: (x:{satirlar:unknown[]}) => ({tamam:true,satirlar:x.satirlar}) }));
vi.mock("@/lib/faturaOtomatikTaslakKaydi", () => ({ faturaTaslakYanitiniHazirla: async (_admin: unknown, _store: string, _slug: string, kayit: { satirlar: never[]; islemKimligi: string }) => ({ tamam: true, satirlar: kayit.satirlar, taslaklar: (await import("@/lib/faturaTaslagi")).faturaTaslaklari(kayit.satirlar, kayit.islemKimligi) }) }));
import { arkaPlanFaturaSonucunuAl } from "@/lib/faturaArkaPlanIslemi";
const job = "11111111-1111-4111-8111-111111111111";
const line={ad:"Kaynak ürünü",model:"K-1",ham_satir:"K-1",uretici:"Üretici",beden:"L",varyant:"Lacivert",adet:2,birim_fiyat:100,site_aciklama:"Kaynak açıklaması",site_gorseller:["https://manufacturer.example/1.jpg"],site_sayfa:"https://manufacturer.example/product",ozellikler:[{key:"fabric",label:"Kumaş",value:"Pamuk"}],dogrulama_durumu:"? Belirsiz"};
function client(receipt: unknown) {
  const rpc=vi.fn(async(name:string,params?:unknown)=>{
    void params;
    if (name === "advance_invoice_provider_job") return {data:{success:true,state:"queued",stage:"cards",id:job},error:null};
    return {data:receipt,error:null};
  });
  return { admin:{rpc} as unknown as SupabaseClient, rpc };
}
const kartItem = {
  row_id:"1", raw_invoice_line:"K-1", brand:"", barcode:null, code:"K-1",
  invoice_data:{quantity:2,unit:"",unit_price:100,total_amount:200},
  vixrex_product_json:{
    title:"Kaynak ürünü",brand:"",short_description:"Kaynak açıklaması",category_suggestion:"Tekstil",
    variant:null,consumer_sale_price:null,stock_quantity:null,
  },
  validation:{
    status:"ambiguous",official_domain:"manufacturer.example",
    official_product_url:"https://manufacturer.example/product",matched_attributes:[],unmatched_attributes:[],
  },
  media:{
    image_url:"https://manufacturer.example/1.jpg",source_url:"https://manufacturer.example/product",
    verification_status:"verified",rights_status:"unknown",
  },
  card_status:"draft",duplicate_group:null,canonical_row_id:null,
};
const kartCevabi=JSON.stringify({
  summary:{total_rows:1,verified_count:0,draft_count:1,not_found_count:0},
  items:[kartItem],
});
const receipt=(content:string, extra:Record<string,unknown>={})=>({stage:"cards",state:"received",httpStatus:200,contentType:"application/json",body:JSON.stringify({choices:[{message:{content},finish_reason:"stop"}]}),fingerprint:"a".repeat(64),readResult:{presetAkis:"yeni",tedarikci:"Tedarikçi",satirlar:[{hamSatir:"K-1",model:"K-1",ad:"Kaynak ürünü",barkod:"",varyant:"Lacivert",beden:"L",marka:"",adet:2,birim:"",birimFiyat:100,tutar:200,okumaGuveni:0.8,siteGorseller:[],uretici:"Üretici",ozellikler:[{key:"fabric",label:"Kumaş",value:"Pamuk"}]}],uyarilar:["Örnek test verisi"]},...extra});
beforeEach(()=>{vi.clearAllMocks();m.save.mockResolvedValue(job);m.load.mockResolvedValue({islemKimligi:job,satirlar:[]});});
afterEach(()=>{vi.unstubAllEnvs();});
describe("tamamlanmış arka plan sonucunun gerçek taşıma yolu",()=>{
 it("bekleyen iş hazır kart sayılmaz ve tekrar model çalıştırmaz",async()=>{const {admin,rpc}=client({state:"queued"});const data=await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job);expect(data.hazirlaniyor).toBe(true);expect(data.satirlar).toBeUndefined();expect(m.save).not.toHaveBeenCalled();expect(rpc).toHaveBeenCalledTimes(1);});
 it("tamamlanan kart kaynağını üretici/beden/kumaş ile atomik kayda taşır; fiyat/onay/yayın eklemez",async()=>{
  const {admin}=client(receipt(kartCevabi));
  m.load.mockImplementation(async()=>({islemKimligi:job,satirlar:m.save.mock.calls[0]?.[0].satirlar ?? []}));
  const data=await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job);
  expect(m.save).toHaveBeenCalledTimes(1);const input=m.save.mock.calls[0][0];
  expect(input.providerJobId).toBe(job);expect(input.parmakIzi).toBe("a".repeat(64));
  expect(input.satirlar[0].katalog).toMatchObject({uretici:"Üretici",beden:"L",varyant:"Lacivert",dogrulamaDurumu:"Belirsiz"});
  expect(input.satirlar[0].katalog.ozellikler[0].value).toBe("Pamuk");
  expect(input.aramaDurumu.presetCevabi.uyarilar).toEqual(["Örnek test verisi"]);
  expect(input.satirlar[0].satisFiyati).toBeUndefined();expect(input.satirlar[0].onayli).toBeUndefined();
  const drafts=data.taslaklar as Array<{satisFiyati:unknown;ownerApproved:boolean;isVisible:boolean}>;expect(drafts).toHaveLength(1);expect(drafts[0].ownerApproved).toBe(false);expect(drafts[0].isVisible).toBe(false);expect(drafts[0].satisFiyati).toBeNull();
 });
 it("yeni akış OpenRouter araştırmasını Vixrex'te yeniden yapmaz",async()=>{
  const {admin}=client(receipt(kartCevabi));
  m.load.mockImplementation(async()=>({islemKimligi:job,satirlar:m.save.mock.calls[0]?.[0].satirlar ?? []}));
  await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job);
  expect(m.localImageCompletion).not.toHaveBeenCalled();
  expect(m.localImageSelection).not.toHaveBeenCalled();
 });
 it("okuma aşaması sonucu kart presetini tam bir kez kuyruğa alır",async()=>{
  vi.stubEnv("PRESET_AKIS","yeni");
  const first=JSON.stringify({tedarikci:"Tedarikçi",satirlar:[line]});
  const {admin,rpc}=client(receipt(first,{stage:"reading",readResult:null}));
  const data=await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job);
  expect(data.hazirlaniyor).toBe(true); expect(m.save).not.toHaveBeenCalled();
  expect(rpc).toHaveBeenCalledWith("advance_invoice_provider_job",expect.objectContaining({p_job_id:job,p_read_result:expect.objectContaining({presetAkis:"yeni",satirlar:expect.any(Array)}),p_body:expect.objectContaining({model:"@preset/vixrex-urun-karti-v2"})}));
 });
 it("kart cevabında ortam değişse bile işteki yeni akış korunur",async()=>{
  vi.stubEnv("PRESET_AKIS","mevcut");
  const satisFiyatli={...kartItem,vixrex_product_json:{...kartItem.vixrex_product_json,consumer_sale_price:100}};
  const {admin}=client(receipt(JSON.stringify({items:[satisFiyatli]})));
  await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("KART_YANITI_COZULEMEDI");
  expect(m.save).not.toHaveBeenCalled();
 });
 it("önceki işte akış alanı yoksa varsayılan akış (akis()) korunur",async()=>{
  const eskiIs=receipt(JSON.stringify({items:[kartItem]}));
  delete (eskiIs.readResult as Record<string,unknown>).presetAkis;
  const {admin}=client(eskiIs);
  m.load.mockImplementation(async()=>({islemKimligi:job,satirlar:m.save.mock.calls[0]?.[0].satirlar ?? []}));
  const data=await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job);
  expect(data.tamam).toBe(true);expect(m.save).toHaveBeenCalledTimes(1);
 });
 it.each(["bozuk",'{\"satirlar\":[]}'])("hatalı veya boş sonuç ürün oluşturmaz: %s",async(content)=>{const {admin,rpc}=client(receipt(content));await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow();expect(m.save).not.toHaveBeenCalled();expect(rpc).toHaveBeenCalledWith("fail_invoice_provider_job",expect.objectContaining({p_job_id:job}));});
 it("model404 hazır karta dönüştürülmez",async()=>{const {admin}=client({stage:"reading",state:"received",httpStatus:200,contentType:"text/event-stream",body:'data: {"error":{"code":404}}\n\n',fingerprint:"a".repeat(64)});await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("OKUYUCU_MODEL_BULUNAMADI");expect(m.save).not.toHaveBeenCalled();});
 it("yarım SSE sonucu kaydedilmez",async()=>{const {admin}=client({state:"received",httpStatus:200,contentType:"text/event-stream",body:'data: {"choices":[{"delta":{"content":"{}"},"finish_reason":"stop"}]}\n\n',fingerprint:"a".repeat(64)});await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("OKUYUCU_EKSIK_CEVAP");expect(m.save).not.toHaveBeenCalled();});
 it("kalıcı kayıt geçici başarısızsa alınmış yanıt silinmez ve yeni model çağrısı yapılmaz",async()=>{m.save.mockResolvedValue(null);const {admin,rpc}=client(receipt(kartCevabi));await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("FATURA_KAYDI_EKSIK");expect(rpc.mock.calls.map(v=>v[0])).toEqual(["get_invoice_provider_response"]);});
 it("kaydı alınmış iş için yeniden işlenmez",async()=>{const {admin}=client({state:"processed"});m.load.mockResolvedValue({satirlar:[{hamSatir:"1",ad:"Ürün",model:"1",barkod:"",varyant:"",beden:"",adet:1,alisBirimFiyat:0,guven:1,sonuc:"eksik",katalog:null}]});expect((await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).tamam).toBe(true);expect(m.save).not.toHaveBeenCalled();});
 it("mağazaya ait kayıt yoksa sonuç vermez",async()=>{const {admin,rpc}=client(null);await expect(arkaPlanFaturaSonucunuAl(admin,"other-store","deneme",job)).rejects.toThrow("FATURA_ISLEMI_BULUNAMADI");expect(rpc).toHaveBeenCalledWith("get_invoice_provider_response",{p_store_id:"other-store",p_job_id:job});expect(m.save).not.toHaveBeenCalled();});

 describe("çok parçalı kart isteğinde atomik CAS kilidi ve paralel fetch", () => {
  const cokluOkuma = (adet: number) =>
    JSON.stringify({
      tedarikci: "Tedarikçi",
      satirlar: Array.from({ length: adet }, (_, i) => ({
        ...line,
        satir_no: i + 1,
        model: `K-${i + 1}`,
        ad: `Ürün ${i + 1}`,
        ham_satir: `K-${i + 1}`,
      })),
    });

  function casClient(receiptData: unknown, lockData: unknown) {
    const rpc = vi.fn(async () => ({ data: receiptData, error: null }));
    const guncellemeler: Array<Record<string, unknown>> = [];
    const zincir = (payload: Record<string, unknown>) => {
      const api = {
        eq: () => api,
        select: () => ({ maybeSingle: async () => ({ data: lockData, error: null }) }),
        then: (resolve: (v: { error: null }) => void) => {
          void payload;
          resolve({ error: null });
        },
      };
      return api;
    };
    const from = vi.fn(() => ({
      update: (payload: Record<string, unknown>) => {
        guncellemeler.push(payload);
        return zincir(payload);
      },
    }));
    return { admin: { rpc, from } as unknown as SupabaseClient, rpc, from, guncellemeler };
  }

  it("7 satırlı faturada CAS kilidi alıp paralel fetch ile tüm parçaları tek seferde kaydeder", async () => {
    vi.stubEnv("PRESET_AKIS", "yeni");
    vi.stubEnv("OPENROUTER_API_KEY", "sk-or-test-key");
    const fetchMock = vi.fn(async (_url: unknown, init?: RequestInit) => {
      const reqBody = JSON.parse(String(init?.body ?? "{}")) as {
        messages: Array<{ content: string }>;
      };
      const payload = JSON.parse(reqBody.messages[0].content.slice(reqBody.messages[0].content.lastIndexOf("\n") + 1)) as {
        groups: Array<{ rows: Array<{ row_id: string }> }>;
      };
      const items = payload.groups.flatMap((g) => g.rows).map((r) => ({ ...kartItem, row_id: r.row_id }));
      return new Response(
        JSON.stringify({
          choices: [{ message: { content: JSON.stringify({ items }) }, finish_reason: "stop" }],
          usage: { prompt_tokens: 50, completion_tokens: 25, cost: 0.01 },
        }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    });
    vi.stubGlobal("fetch", fetchMock);

    const { admin, rpc, guncellemeler } = casClient(
      receipt(cokluOkuma(7), { stage: "reading", readResult: null }),
      { job_id: job },
    );
    m.load.mockImplementation(async () => ({ islemKimligi: job, satirlar: m.save.mock.calls[0]?.[0].satirlar ?? [] }));

    const data = await arkaPlanFaturaSonucunuAl(admin, "store", "deneme", job);
    expect(data.tamam).toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(guncellemeler[0]).toMatchObject({ stage: "cards", state: "queued" });
    expect(guncellemeler[1]).toEqual({ state: "received" });
    expect(m.save).toHaveBeenCalledTimes(1);
    expect(m.save.mock.calls[0][0].satirlar).toHaveLength(7);
    expect(rpc).not.toHaveBeenCalledWith("advance_invoice_provider_job", expect.anything());
    vi.unstubAllGlobals();
  });

  it("CAS kilidi alınamazsa fetch veya kayıt yapmadan kartlaniyor döner", async () => {
    vi.stubEnv("PRESET_AKIS", "yeni");
    vi.stubEnv("OPENROUTER_API_KEY", "sk-or-test-key");
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);
    const { admin } = casClient(receipt(cokluOkuma(7), { stage: "reading", readResult: null }), null);

    const data = await arkaPlanFaturaSonucunuAl(admin, "store", "deneme", job);
    expect(data).toMatchObject({ hazirlaniyor: true, asama: "kartlaniyor", islemKimligi: job });
    expect(fetchMock).not.toHaveBeenCalled();
    expect(m.save).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
  });

  it("çok parçalı yolda anahtar yoksa veya fetch hata verirse işi fail eder", async () => {
    vi.stubEnv("PRESET_AKIS", "yeni");
    vi.stubEnv("OPENROUTER_API_KEY", "");
    vi.stubEnv("FATURA_PRIZ_API_KEY", "");
    vi.stubEnv("GEMINI_API_KEY", "");
    vi.stubEnv("GOOGLE_API_KEY", "");
    const { admin: noKeyAdmin, rpc: noKeyRpc } = casClient(
      receipt(cokluOkuma(7), { stage: "reading", readResult: null }),
      { job_id: job },
    );
    await expect(arkaPlanFaturaSonucunuAl(noKeyAdmin, "store", "deneme", job)).rejects.toThrow("OKUYUCU_HAZIR_DEGIL");
    expect(noKeyRpc).toHaveBeenCalledWith("fail_invoice_provider_job", expect.objectContaining({ p_error: "OKUYUCU_HAZIR_DEGIL" }));

    vi.stubEnv("OPENROUTER_API_KEY", "sk-or-test-key");
    vi.stubGlobal("fetch", vi.fn(async () => {
      throw new Error("network down");
    }));
    const { admin: netAdmin, rpc: netRpc } = casClient(
      receipt(cokluOkuma(7), { stage: "reading", readResult: null }),
      { job_id: job },
    );
    await expect(arkaPlanFaturaSonucunuAl(netAdmin, "store", "deneme", job)).rejects.toThrow("OKUYUCU_CEVAP_VERMEDI");
    expect(netRpc).toHaveBeenCalledWith("fail_invoice_provider_job", expect.objectContaining({ p_error: "OKUYUCU_CEVAP_VERMEDI" }));
    expect(m.save).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
  });
 });
});
