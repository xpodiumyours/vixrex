import type { SupabaseClient } from "@supabase/supabase-js";
import { beforeEach, describe, expect, it, vi } from "vitest";
const m = vi.hoisted(() => ({ save: vi.fn(), load: vi.fn() }));
vi.mock("@/lib/faturaIslemKaydi", () => ({ islemKaydet: m.save }));
vi.mock("@/lib/faturaIslemOku", () => ({ islemiYukle: m.load, islemYaniti: (x:{satirlar:unknown[]}) => ({tamam:true,satirlar:x.satirlar}) }));
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
const kartItem = {row_id:"1",vixrex_product_json:{title:"Kaynak ürünü",short_description:"Kaynak açıklaması",category_suggestion:"Tekstil"}, validation:{status:"ambiguous",official_product_url:"https://manufacturer.example/product",matched_attributes:[],unmatched_attributes:[]}, media:{image_url:"https://manufacturer.example/1.jpg",verification_status:"verified"}};
const kartCevabi=JSON.stringify({items:[kartItem]});
const receipt=(content:string, extra:Record<string,unknown>={})=>({stage:"cards",state:"received",httpStatus:200,contentType:"application/json",body:JSON.stringify({choices:[{message:{content},finish_reason:"stop"}]}),fingerprint:"a".repeat(64),readResult:{tedarikci:"Tedarikçi",satirlar:[{hamSatir:"K-1",model:"K-1",ad:"Kaynak ürünü",barkod:"",varyant:"Lacivert",beden:"L",marka:"",adet:2,birim:"",birimFiyat:100,tutar:200,okumaGuveni:0.8,siteGorseller:[],uretici:"Üretici",ozellikler:[{key:"fabric",label:"Kumaş",value:"Pamuk"}]}],uyarilar:["Örnek test verisi"]},...extra});
beforeEach(()=>{vi.clearAllMocks();m.save.mockResolvedValue(job);m.load.mockResolvedValue({islemKimligi:job,satirlar:[]});});
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
 it("okuma aşaması sonucu kart presetini tam bir kez kuyruğa alır",async()=>{
  const first=JSON.stringify({tedarikci:"Tedarikçi",satirlar:[line]});
  const {admin,rpc}=client(receipt(first,{stage:"reading",readResult:null}));
  const data=await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job);
  expect(data.hazirlaniyor).toBe(true); expect(m.save).not.toHaveBeenCalled();
  expect(rpc).toHaveBeenCalledWith("advance_invoice_provider_job",expect.objectContaining({p_job_id:job,p_read_result:expect.objectContaining({satirlar:expect.any(Array)}),p_body:expect.objectContaining({model:"@preset/urun-kart-olusturucu"})}));
 });
 it.each(["bozuk",'{"satirlar":[]}'])("hatalı veya boş sonuç ürün oluşturmaz: %s",async(content)=>{const {admin,rpc}=client(receipt(content));await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow();expect(m.save).not.toHaveBeenCalled();expect(rpc).toHaveBeenCalledWith("fail_invoice_provider_job",expect.objectContaining({p_job_id:job}));});
 it("model404 hazır karta dönüştürülmez",async()=>{const {admin}=client({state:"received",httpStatus:200,contentType:"text/event-stream",body:'data: {"error":{"code":404}}\n\n',fingerprint:"a".repeat(64)});await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("OKUYUCU_MODEL_BULUNAMADI");expect(m.save).not.toHaveBeenCalled();});
 it("yarım SSE sonucu kaydedilmez",async()=>{const {admin}=client({state:"received",httpStatus:200,contentType:"text/event-stream",body:'data: {"choices":[{"delta":{"content":"{}"},"finish_reason":"stop"}]}\n\n',fingerprint:"a".repeat(64)});await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("OKUYUCU_EKSIK_CEVAP");expect(m.save).not.toHaveBeenCalled();});
 it("kalıcı kayıt geçici başarısızsa alınmış yanıt silinmez ve yeni model çağrısı yapılmaz",async()=>{m.save.mockResolvedValue(null);const {admin,rpc}=client(receipt(kartCevabi));await expect(arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).rejects.toThrow("FATURA_KAYDI_EKSIK");expect(rpc.mock.calls.map(v=>v[0])).toEqual(["get_invoice_provider_response"]);});
 it("kaydı alınmış iş için yeniden işlenmez",async()=>{const {admin}=client({state:"processed"});m.load.mockResolvedValue({satirlar:[{hamSatir:"1",ad:"Ürün",model:"1",barkod:"",varyant:"",beden:"",adet:1,alisBirimFiyat:0,guven:1,sonuc:"eksik",katalog:null}]});expect((await arkaPlanFaturaSonucunuAl(admin,"store","deneme",job)).tamam).toBe(true);expect(m.save).not.toHaveBeenCalled();});
 it("mağazaya ait kayıt yoksa sonuç vermez",async()=>{const {admin,rpc}=client(null);await expect(arkaPlanFaturaSonucunuAl(admin,"other-store","deneme",job)).rejects.toThrow("FATURA_ISLEMI_BULUNAMADI");expect(rpc).toHaveBeenCalledWith("get_invoice_provider_response",{p_store_id:"other-store",p_job_id:job});expect(m.save).not.toHaveBeenCalled();});
});
