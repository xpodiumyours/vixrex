import { describe, it, expect } from "vitest";
import { kartPresetIstekGovdesi, kartPresetYanitiniOku, URUN_KART_PRESET } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { satirdanFaturaTaslagi } from "@/lib/faturaTaslagi";

const first = {
  tedarikci: "Tedarikçi",
  satirlar: [
    { hamSatir:"1", model:"A", ad:"İlk", barkod:"111", varyant:"", beden:"", marka:"X", adet:3, birim:"adet", birimFiyat:10, tutar:30, okumaGuveni:1 },
    { hamSatir:"2", model:"B", ad:"İkinci", barkod:"222", varyant:"", beden:"", marka:"Y", adet:4, birim:"adet", birimFiyat:20, tutar:80, okumaGuveni:1 },
  ],
} as GoruSonucu;
const item = (id: string, title: string) => ({
  row_id:id,
  vixrex_product_json:{title,short_description:title+" açıklama",category_suggestion:"Gıda"},
  validation:{status:"verified",official_product_url:"https://example.com/p/"+id,matched_attributes:[],unmatched_attributes:[]},
  media:{image_url:"https://example.com/p/"+id+".jpg",verification_status:"verified"},
});
const response = (items: unknown[]) => new Response(JSON.stringify({
  choices:[{message:{content:JSON.stringify({items})},finish_reason:"stop"}],
}),{status:200,headers:{"content-type":"application/json"}});
describe("gerçek ikinci preset JSON sözleşmesi",()=>{
  it("satır sırası değişse de kimliğe göre ürünleri eşleştirir",async()=>{
    const result=await kartPresetYanitiniOku(response([item("2","B ürün"),item("1","A ürün")]),first);
    expect(result.sonuc.satirlar.map(s=>s.ad)).toEqual(["A ürün","B ürün"]);
    expect(result.sonuc.satirlar.map(s=>s.barkod)).toEqual(["111","222"]);
    expect(result.sonuc.satirlar.map(s=>s.adet)).toEqual([3,4]);
    expect(result.sonuc.satirlar[0].siteSayfa).toContain("/1");
  });
  it("kart markası, varyant/gramaj ve izin kararı katalogdan tüketici alanlarına kadar korunur",async()=>{
    const kart = item("1","A ürün");
    const okuma = {...first,satirlar:[{...first.satirlar[0],varyant:"Sade",gramaj:"175 g"}]};
    const result = await kartPresetYanitiniOku(response([{
      ...kart,
      vixrex_product_json:{...kart.vixrex_product_json,brand:"Üreticinin markası",variant:"175 g tekli paket",consumer_sale_price:999,stock_quantity:999},
      media:{image_url:"",source_url:"https://example.com/p/1.jpg",rights_status:"authorized"},
    }]),okuma);
    const satir = faturaSatiriniAktar(result.sonuc.satirlar[0],"Tedarikçi");
    expect(satir.marka).toBe("X");
    expect(satir.varyant).toBe("Sade");
    expect(satir.katalog).toMatchObject({marka:"Üreticinin markası",varyant:"175 g tekli paket",gramaj:"175 g",izinDurumu:"var",gorseller:["https://example.com/p/1.jpg"]});
    expect(faturaKatalogMetadatasi(satir.katalog ?? {}).attributes?.map(a=>a.value)).toEqual(expect.arrayContaining(["Sade","175 g tekli paket","175 g"]));
    expect(satirdanFaturaTaslagi(satir)).toMatchObject({brand:"Üreticinin markası",satisFiyati:null,stokOnerisi:3,ownerApproved:false,isVisible:false});
  });
  it("mükerrer ve eksik kimlikleri reddeder",async()=>{
    await expect(kartPresetYanitiniOku(response([item("1","A"),item("1","B")]),first)).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
    await expect(kartPresetYanitiniOku(response([item("1","A")]),first)).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
  });
  it("ilk araştırmanın açıklama, görsel, özellik ve kaynaklarını kendi satırıyla ikinci presete taşır",()=>{
    const arastirma = {siteAciklama:"Kaynak açıklaması",siteSayfa:"https://example.com/ilk",
      siteGorseller:["https://example.com/ilk-1.jpg","https://example.com/ilk-2.jpg"],
      siteKategori:"Gıda",uretici:"Üretici",ozellikler:[{key:"ingredients",value:"Fındık"}],
      dogrulamaDurumu:"Belirsiz",eslesenBilgiler:["Marka"],eksikler:["Gramaj"],
      gorselDogrulamaDurumu:"Araştırılamadı",kaynaklar:[{url:"https://example.com/ilk",type:"manufacturer"}]};
    const req=kartPresetIstekGovdesi({...first,satirlar:[{...first.satirlar[0],...arastirma},first.satirlar[1]]});
    const content=(req.messages as Array<{content:string}>)[0].content;
    const payload=JSON.parse(content.slice(content.lastIndexOf("\n")+1));
    expect(payload.groups[0].rows[0]).toMatchObject({row_id:"1",previous_product_research:{
      description:arastirma.siteAciklama,product_url:arastirma.siteSayfa,image_urls:arastirma.siteGorseller,
      category:"Gıda",manufacturer:"Üretici",attributes:arastirma.ozellikler,
      validation_status:"Belirsiz",matched_attributes:["Marka"],unmatched_attributes:["Gramaj"],
      image_validation_status:"Araştırılamadı",sources:arastirma.kaynaklar,
    }});
    expect(payload.groups[1].rows[0]).toMatchObject({row_id:"2",barcode:"222"});
    expect(payload.groups[1].rows[0].previous_product_research).not.toHaveProperty("product_url");
  });
  it("ikinci presetin açık bulunamadı kararını ilk araştırmanın görseliyle değiştirmez",async()=>{
    const okuma={...first,satirlar:[{...first.satirlar[0],siteAciklama:"İlk açıklama",siteSayfa:"https://example.com/ilk",siteGorseller:["https://example.com/ilk.jpg"]}]};
    const result=await kartPresetYanitiniOku(response([{
      row_id:"1",vixrex_product_json:{title:"İlk",short_description:"",category_suggestion:""},
      validation:{status:"not_found",official_product_url:"",matched_attributes:[],unmatched_attributes:["Ürün"]},
      media:{image_url:"",rights_status:"unknown"},card_status:"blocked",
    }]),okuma);
    expect(result.sonuc.satirlar[0]).toMatchObject({siteAciklama:"",siteSayfa:"",siteGorseller:[],dogrulamaDurumu:"Bulunamadı",eksikler:["Ürün"]});
    expect(okuma.satirlar[0].siteGorseller).toEqual(["https://example.com/ilk.jpg"]);
  });
  it("OpenRouter preset ayarlarını değiştirmeden var olan model adresine gönderir",()=>{
    const req=kartPresetIstekGovdesi(first);
    expect(req.model).toBe(URUN_KART_PRESET);
    expect(req.model).toBe("@preset/urun-kart-olusturucu");
    const messages=req.messages as Array<{content:string}>;
    expect(messages[0].content).toContain("row_id");
    expect(req).not.toHaveProperty("tools");
    expect(req).not.toHaveProperty("system");
  });
});
