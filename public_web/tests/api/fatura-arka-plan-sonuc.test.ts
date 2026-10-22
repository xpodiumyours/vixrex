import type { SupabaseClient } from "@supabase/supabase-js";
import { beforeEach, describe, expect, it, vi } from "vitest";
const m = vi.hoisted(() => ({ save: vi.fn(), load: vi.fn() }));
vi.mock("@/lib/faturaIslemKaydi", () => ({ islemKaydet: m.save }));
vi.mock("@/lib/faturaIslemOku", () => ({ islemiYukle: m.load, islemYaniti: (x:{satirlar:unknown[]}) => ({tamam:true,satirlar:x.satirlar}) }));
import { arkaPlanFaturaSonucunuAl } from "@/lib/faturaArkaPlanIslemi";
import { katalogJsonunuOku } from "@/lib/faturaGoru";
const job = "11111111-1111-4111-8111-111111111111";
const line={ad:"Kaynak ürünü",model:"K-1",ham_satir:"K-1",uretici:"Üretici",beden:"L",varyant:"Lacivert",adet:2,birim_fiyat:100,site_aciklama:"Kaynak açıklaması",site_gorseller:["https://manufacturer.example/1.jpg"],site_sayfa:"https://manufacturer.example/product",ozellikler:[{key:"fabric",label:"Kumaş",value:"Pamuk"}],dogrulama_durumu:"? Belirsiz"};
function client(receipt: unknown) {
  const rpc=vi.fn(async(name:string,params?:unknown)=>{void name;void params;return {data:receipt,error:null};});
  return { admin:{rpc} as unknown as SupabaseClient, rpc };
}
const receipt=(content:string)=>({state:"received",httpStatus:200,contentType:"application/json",body:JSON.stringify({choices:[{message:{content},finish_reason:"stop"}]}),fingerprint:"a".repeat(64)});
beforeEach(()=>{vi.clearAllMocks();m.save.mockResolvedValue(job);m.load.mockResolvedValue({islemKimligi:job,satirlar:[]});});
describe("tamamlanmış arka plan sonucunun gerçek taşıma yolu",()=>{
 it("ilk preset sonucu ikinci presetin girdisidir; kart gelmeden ürün kaydedilmez", async () => {
  const ilk = { ...receipt(JSON.stringify({ tedarikci: "Toptancı", satirlar: [line] })), stage: "reading", requestId: 17 };
  const rpc = vi.fn(async (name: string) => ({ data: name === "get_invoice_provider_response" ? ilk : { success: true }, error: null }));
  const admin = { rpc } as unknown as SupabaseClient;
  vi.stubEnv("OPENROUTER_API_KEY", "unit-key");
  try {
   const sonuc = await arkaPlanFaturaSonucunuAl(admin, "store", "deneme", job);
   expect(sonuc.hazirlaniyor).toBe(true); expect(m.save).not.toHaveBeenCalled();
   expect(rpc).toHaveBeenCalledWith("advance_invoice_provider_job", expect.objectContaining({
    p_store_id: "store", p_job_id: job, p_expected_request_id: 17,
    p_body: expect.objectContaining({ model: "@preset/urun-kart-olusturucu" }),
    p_read_result: expect.objectContaining({ satirlar: [expect.objectContaining({ ad: line.ad, adet: line.adet })] }),
   }));
  } finally { vi.unstubAllEnvs(); }
 });
 it("ikinci aşama kalıcı ilk okumayla birleşir, tekrar model çağırmadan kart taslağı olur", async () => {
  const readResult = { ...katalogJsonunuOku(JSON.stringify({ tedarikci: "Toptancı", satirlar: [line] })), gercekMaliyet: 0.01 };
  const kart = { items: [{ row_id: "1", vixrex_product_json: { title: "Resmî kart", short_description: "Açıklama" },
   validation: { status: "not_researched", official_product_url: null, unmatched_attributes: ["Ağ hatası"] },
   media: { image_url: null, rights_status: "unknown" }, card_status: "draft" }] };
  const { admin, rpc } = client({ ...receipt(JSON.stringify(kart)), stage: "cards", requestId: 18, readResult });
  m.load.mockImplementation(async () => ({ islemKimligi: job, satirlar: m.save.mock.calls[0]?.[0].satirlar ?? [] }));
  const data = await arkaPlanFaturaSonucunuAl(admin, "store", "deneme", job);
  expect(data.tamam).toBe(true); expect(m.save).toHaveBeenCalledTimes(1);
  const girdi = m.save.mock.calls[0][0];
  expect(girdi.satirlar[0]).toMatchObject({ ad: "Resmî kart", adet: 2, alisBirimFiyat: 100, sonuc: "eksik" });
  expect(girdi.aramaDurumu.erisimHatasi).toBe(true);
  expect(girdi.aramaDurumu.presetCevabi.kartCevabi).toEqual(kart);
  expect(girdi.aramaDurumu.presetCevabi.asamaKullanimlari.okuma.gercekMaliyet).toBe(0.01);
  expect(rpc.mock.calls.map((c) => c[0])).toEqual(["get_invoice_provider_response"]);
 });
 it("ikinci aşamaya geçişte geçici kayıt hatası ilk sonucu başarısız diye silmez", async () => {
  const ilk = { ...receipt(JSON.stringify({ satirlar: [line] })), stage: "reading", requestId: 17 };
  const rpc = vi.fn(async (name: string) => name === "get_invoice_provider_response"
   ? { data: ilk, error: null } : { data: null, error: { code: "TEMP" } });
  vi.stubEnv("OPENROUTER_API_KEY", "unit-key");
  try {
   await expect(arkaPlanFaturaSonucunuAl({ rpc } as unknown as SupabaseClient, "store", "deneme", job))
    .rejects.toThrow("OKUYUCU_ASAMA_KAYDI_EKSIK");
   expect(rpc.mock.calls.map((c) => c[0])).toEqual(["get_invoice_provider_response", "advance_invoice_provider_job"]);
   expect(m.save).not.toHaveBeenCalled();
  } finally { vi.unstubAllEnvs(); }
 });
 it("ikinci aşamada eksik satır sonucu eski aşamanın kimliğiyle hata kaydeder; kısmi kart yazmaz", async () => {
  const readResult = katalogJsonunuOku(JSON.stringify({ satirlar: [line] }));
  const { admin, rpc } = client({ ...receipt('{"items":[]}'), stage: "cards", requestId: 18, readResult });
  await expect(arkaPlanFaturaSonucunuAl(admin, "store", "deneme", job)).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
  expect(rpc).toHaveBeenCalledWith("fail_invoice_provider_stage", {
   p_store_id: "store", p_job_id: job, p_expected_request_id: 18, p_error: "KART_SATIRLARI_ESLESMEDI",
  });
  expect(m.save).not.toHaveBeenCalled();
 });
 it("bekleyen iş hazır kart sayılmaz ve tekrar model çalıştırmaz",async()=>{const {admin,rpc}=client({state:"queued"});const data=await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job);expect(data.hazirlaniyor).toBe(true);expect(data.satirlar).toBeUndefined();expect(m.save).not.toHaveBeenCalled();expect(rpc).toHaveBeenCalledTimes(1);});
 it("tamamlanan kaynağı üretici/beden/kumaş ile atomik kayda taşır; fiyat/onay/yayın eklemez",async()=>{
  const {admin}=client(receipt(JSON.stringify({tedarikci:"Tedarikçi",satirlar:[line],gruplar:[{marka:"Üretici"}],uyarilar:["Örnek test verisi"]})));
  m.load.mockImplementation(async()=>({islemKimligi:job,satirlar:m.save.mock.calls[0]?.[0].satirlar ?? []}));
  const data=await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job);
  expect(m.save).toHaveBeenCalledTimes(1);const input=m.save.mock.calls[0][0];
  expect(input.providerJobId).toBe(job);expect(input.parmakIzi).toBe("a".repeat(64));
  expect(input.satirlar[0].katalog).toMatchObject({uretici:"Üretici",beden:"L",varyant:"Lacivert",dogrulamaDurumu:"? Belirsiz"});
  expect(input.satirlar[0].katalog.ozellikler[0].value).toBe("Pamuk");
  expect(input.aramaDurumu.presetCevabi.uyarilar).toEqual(["Örnek test verisi"]);
  expect(input.satirlar[0].satisFiyati).toBeUndefined();expect(input.satirlar[0].onayli).toBeUndefined();
  const drafts=data.taslaklar as Array<{satisFiyati:unknown;ownerApproved:boolean;isVisible:boolean}>;expect(drafts).toHaveLength(1);expect(drafts[0].ownerApproved).toBe(false);expect(drafts[0].isVisible).toBe(false);expect(drafts[0].satisFiyati).toBeNull();
 });
 it.each(["bozuk",'{"satirlar":[]}'])("hatalı veya boş sonuç ürün oluşturmaz: %s",async(content)=>{const {admin,rpc}=client(receipt(content));await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow();expect(m.save).not.toHaveBeenCalled();expect(rpc).toHaveBeenCalledWith("fail_invoice_provider_job",expect.objectContaining({p_job_id:job}));});
 it("model404 hazır karta dönüştürülmez",async()=>{const {admin}=client({state:"received",httpStatus:200,contentType:"text/event-stream",body:'data: {"error":{"code":404}}\n\n',fingerprint:"a".repeat(64)});await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("OKUYUCU_MODEL_BULUNAMADI");expect(m.save).not.toHaveBeenCalled();});
 it("yarım SSE sonucu kaydedilmez",async()=>{const {admin}=client({state:"received",httpStatus:200,contentType:"text/event-stream",body:'data: {"choices":[{"delta":{"content":"{}"},"finish_reason":"stop"}]}\n\n',fingerprint:"a".repeat(64)});await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("OKUYUCU_EKSIK_CEVAP");expect(m.save).not.toHaveBeenCalled();});
 it("kalıcı kayıt geçici başarısızsa alınmış yanıt silinmez ve yeni model çağrısı yapılmaz",async()=>{m.save.mockResolvedValue(null);const {admin,rpc}=client(receipt(JSON.stringify({satirlar:[line]})));await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("FATURA_KAYDI_EKSIK");expect(rpc.mock.calls.map(v=>v[0])).toEqual(["get_invoice_provider_response"]);});
 it("kaydı alınmış iş için yeniden işlenmez",async()=>{const {admin}=client({state:"processed"});m.load.mockResolvedValue({satirlar:[{hamSatir:"1",ad:"Ürün",model:"1",barkod:"",varyant:"",beden:"",adet:1,alisBirimFiyat:0,guven:1,sonuc:"eksik",katalog:null}]});expect((await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).tamam).toBe(true);expect(m.save).not.toHaveBeenCalled();});
 it("mağazaya ait kayıt yoksa sonuç vermez",async()=>{const {admin,rpc}=client(null);await expect(arkaPlanFaturaSonucunuAl(admin,"other-store","deneme",job)).rejects.toThrow("FATURA_ISLEMI_BULUNAMADI");expect(rpc).toHaveBeenCalledWith("get_invoice_provider_response",{p_store_id:"other-store",p_job_id:job});expect(m.save).not.toHaveBeenCalled();});
});
