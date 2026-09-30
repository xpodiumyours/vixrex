import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";
const m=vi.hoisted(()=>({rpc:vi.fn(),satir:vi.fn(),medya:vi.fn(),yayin:vi.fn(),create:vi.fn(),update:vi.fn()}));
vi.mock("next/headers",()=>({cookies:async()=>({get:()=>({value:"owner"})})}));
vi.mock("@/lib/ownerSession",()=>({OWNER_SESSION_COOKIE:"owner",verifyOwnerSession:()=>({storeId:"store-1"})}));
vi.mock("@/lib/supabaseAdmin",()=>({getSupabaseAdmin:()=>({rpc:m.rpc,from:()=>{
 const q={select:()=>q,eq:()=>q,single:async()=>({data:{id:"store-1",edit_token:"token",name:"Esnaf"},error:null})};return q;
}})}));
vi.mock("@/lib/faturaUrunBaglantisi",async(importOriginal)=>({...await importOriginal<typeof import("@/lib/faturaUrunBaglantisi")>(),satiriDogrula:m.satir}));
vi.mock("@/lib/productCoreServer",()=>({createRichCoreProduct:m.create,updateRichCoreProduct:m.update,publishInvoiceProduct:m.yayin}));
vi.mock("@/lib/productIntake",()=>({urunGirdisiniHazirla:async({govde}:{govde:Record<string,unknown>})=>({durum:"hazir",girdi:{...govde,priceAmount:499,metadata:{},variants:[]}})}));
vi.mock("@/lib/productImagePolicy",()=>({FATURA_MIN_PRODUCT_IMAGES:1,yonetilenUrunGorseliMi:(url:string)=>url.startsWith("https://depo.example/")}));
vi.mock("@/lib/faturaGorsel",()=>({kaynakGorselleriniHazirla:m.medya}));
vi.mock("@/lib/vitrinYayinDogrula",()=>({tuketicideGorunenler:async()=>null,vitrinOnbelleginiYenile:vi.fn()}));
import { POST } from "@/app/api/products/batch/route";
function request(){return new NextRequest("http://localhost/api/products/batch",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({slug:"esnaf",products:[{
 name:"İstemcinin değiştirdiği ad",description:"İstemcinin değiştirdiği açıklama",sourceType:"invoice",imageUrls:["https://firma.example/model.jpg"],
 priceText:"499 TL",stockQuantity:8,ownerApproved:true,stokOnaylandi:true,yayinIstegi:true,kartDurumu:"kanitli",purchasePriceAmount:1,
 islemKimligi:"11111111-1111-4111-8111-111111111111",satirSirasi:0,
}]})});}
beforeEach(()=>{
 vi.clearAllMocks();
 m.satir.mockResolvedValue({satirId:"satir-1",sonuc:"kanitli",urunId:null,izinliGorseller:new Set(["https://firma.example/model.jpg"]),alisBirimFiyati:450,
 katalog:{resmiAd:"Resmî model",aciklama:"Resmî açıklama",marka:"Üretici",kaynak:"https://firma.example/urun/model"}});
 m.medya.mockResolvedValue({gorseller:[{url:"https://depo.example/model.jpg",kaynakGorsel:"https://firma.example/model.jpg",kaynakSayfa:"https://firma.example/urun/model",genislik:1200,yukseklik:1200}],reddedilenler:[],altyapiSorunu:false});
 m.rpc.mockResolvedValue({data:{success:true,id:"urun-1",slug:"model",created:true,kayit:"yeni"},error:null});
 m.yayin.mockResolvedValue({success:true,id:"urun-1"});
});
describe("fatura atomik kayıt kapısı",()=>{
 it("kayıtlı kaynak ve alış bilgisi kullanılır; ürün ayrı RPC ile oluşturulmaz",async()=>{
  const body=await(await POST(request())).json();expect(body.yayinda).toBe(1);
  expect(m.rpc).toHaveBeenCalledWith("save_invoice_product",expect.objectContaining({p_line_id:"satir-1",p_purchase_price:450,
   p_product:expect.objectContaining({name:"Resmî model",description:"Resmî açıklama",brand:"Üretici",imageUrls:["https://depo.example/model.jpg"]})}));
  expect(m.create).not.toHaveBeenCalled();expect(m.update).not.toHaveBeenCalled();
 });
 it("transaction hatası mevcut ürünü ayrı bir silme yoluna sokmaz ve yayın olmaz",async()=>{
  const row=await m.satir();m.satir.mockResolvedValue({...row,urunId:"mevcut-urun"});
  m.rpc.mockResolvedValue({data:null,error:{message:"transaction failed"}});
  const body=await(await POST(request())).json();expect(body.hatali).toBe(1);expect(body.eklenen).toBe(0);
  expect(m.yayin).not.toHaveBeenCalled();expect(m.create).not.toHaveBeenCalled();expect(m.update).not.toHaveBeenCalled();
 });
 it.each(["erisilemedi","depoya-yazilamadi"])("%s görsel dış bağlantıyla yayına kaçmaz",async(sebep)=>{
  m.medya.mockResolvedValue({gorseller:[],reddedilenler:[{kaynakGorsel:"https://firma.example/model.jpg",sebep}],altyapiSorunu:true});
  const body=await(await POST(request())).json();expect(body.hatali).toBe(1);expect(body.eklenen).toBe(0);expect(m.rpc).not.toHaveBeenCalled();expect(m.yayin).not.toHaveBeenCalled();
 });
 it("kaynak kaydı yoksa istemcinin kanıtlı etiketi kurtarmaz",async()=>{
  const row=await m.satir();m.satir.mockResolvedValue({...row,katalog:null});
  const body=await(await POST(request())).json();expect(body.hatali).toBe(1);expect(m.rpc).not.toHaveBeenCalled();expect(m.yayin).not.toHaveBeenCalled();
 });
});
