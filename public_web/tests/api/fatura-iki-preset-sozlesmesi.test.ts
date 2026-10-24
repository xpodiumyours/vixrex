import { describe, it, expect } from "vitest";
import { kartPresetIstekGovdesi, kartPresetYanitiniOku, URUN_KART_PRESET } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { satirdanFaturaTaslagi } from "@/lib/faturaTaslagi";

const first = {
  tedarikci: "Tedarikçi",
  satirlar: [
    { rowId:"row-0001", hamSatir:"1", model:"A", ad:"İlk", barkod:"111", varyant:"", beden:"", marka:"X", adet:3, birim:"adet", birimFiyat:10, tutar:30, okumaGuveni:1 },
    { rowId:"row-0002", hamSatir:"2", model:"B", ad:"İkinci", barkod:"222", varyant:"", beden:"", marka:"Y", adet:4, birim:"adet", birimFiyat:20, tutar:80, okumaGuveni:1 },
  ],
} as GoruSonucu;
const item = (id: string, title: string) => ({
  row_id:`row-${id.padStart(4,"0")}`,
  vixrex_product_json:{title,short_description:title+" açıklama",category_suggestion:"Gıda"},
  validation:{status:"verified",official_product_url:"https://example.com/p/"+id,matched_attributes:[],unmatched_attributes:[]},
  media:{image_url:"https://example.com/p/"+id+".jpg",verification_status:"verified"},
});
const response = (items: unknown[]) => new Response(JSON.stringify({
  choices:[{message:{content:JSON.stringify({items})},finish_reason:"stop"}],
}),{status:200,headers:{"content-type":"application/json"}});
const researchItem = (rowId = "row-0001", overrides: Record<string, unknown> = {}) => ({
  row_id: rowId,
  product: {
    official_name: "İlk resmi ürün", brand: "X", manufacturer: "Üretici X", gtin: "111",
    model_or_code: "A", variant: null, category: "Gıda", short_description: "Resmî açıklama", attributes: [{name:"Alerjen",value:"Gluten"}],
  },
  verification: { status: "verified", matched_attributes: ["gtin", "model_or_code"], unmatched_attributes: [], note: null },
  source: {
    source_type: "manufacturer_site", official_domain: "example.com",
    product_page_url: "https://www.example.com/p/1", image_url: "https://cdn.example.com/1.jpg",
    image_page_url: "https://www.example.com/p/1", image_rights_status: "unknown",
    evidence: [
      { url: "https://www.example.com/p/1", kind: "official_product_page", observation: "Ürün kodu A" },
      { url: "https://www.example.com/about", kind: "official_company_identity", observation: "Üretici X" },
    ],
  },
  ...overrides,
});
const researchResponse = (items: unknown[]) => new Response(JSON.stringify({
  choices:[{message:{content:JSON.stringify({contract_version:"vixrex.product-research/1.0",items,warnings:[]})},finish_reason:"stop"}],
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
  it("fatura kaynak verisini sabit row_id ile aktarır; ürün araştırmasını ikinci preset'e bırakır",()=>{
    const arastirma = {siteAciklama:"Kaynak açıklaması",siteSayfa:"https://example.com/ilk",
      siteGorseller:["https://example.com/ilk-1.jpg","https://example.com/ilk-2.jpg"],
      siteKategori:"Gıda",uretici:"Üretici",ozellikler:[{key:"ingredients",value:"Fındık"}],
      dogrulamaDurumu:"Belirsiz",eslesenBilgiler:["Marka"],eksikler:["Gramaj"],
      gorselDogrulamaDurumu:"Araştırılamadı",kaynaklar:[{url:"https://example.com/ilk",type:"manufacturer"}]};
    const req=kartPresetIstekGovdesi({...first,satirlar:[{...first.satirlar[0],...arastirma},first.satirlar[1]]});
    const content=(req.messages as Array<{content:string}>)[0].content;
    const payload=JSON.parse(content.slice(content.lastIndexOf("\n")+1));
    expect(payload.contract_version).toBe("vixrex.product-research-input/1.0");
    expect(payload.items[0]).toMatchObject({row_id:"row-0001",invoice_item:{
      raw_text:"1",model_or_code:"A",gtin:"111",quantity:3,purchase_unit_price:10,
    }});
    expect(payload.items[1]).toMatchObject({row_id:"row-0002",invoice_item:{gtin:"222"}});
    expect(payload).not.toHaveProperty("previous_product_research");
    expect(payload.items[0].invoice_item).not.toHaveProperty("sale_price");
  });
  it("bulunamayan üründe faturadaki ad korunur, doğrulanmamış görsel karta alınmaz",async()=>{
    const okuma = {...first, satirlar:[first.satirlar[0]]};
    const result=await kartPresetYanitiniOku(response([{
      row_id:"row-0001",vixrex_product_json:{title:"İlk",short_description:"",category_suggestion:""},
      validation:{status:"not_found",official_product_url:"",matched_attributes:[],unmatched_attributes:["Ürün"]},
      media:{image_url:"",rights_status:"unknown"},card_status:"blocked",
    }]),okuma);
    expect(result.sonuc.satirlar[0]).toMatchObject({siteAciklama:"",siteSayfa:"",siteGorseller:[],dogrulamaDurumu:"Bulunamadı",eksikler:["Ürün"]});
    expect(result.sonuc.satirlar[0].ad).toBe("İlk");
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
  it("platformdan bağımsız v1 ürün cevabında doğru row_id resmi ürün taslağına dönüşür",async()=>{
    const oneRow = {...first,satirlar:[first.satirlar[0]]};
    const result = await kartPresetYanitiniOku(researchResponse([researchItem()]),oneRow);
    const draft = satirdanFaturaTaslagi(faturaSatiriniAktar(result.sonuc.satirlar[0],"Toptancı"));
    expect(result.sonuc.satirlar[0]).toMatchObject({ad:"İlk resmi ürün",siteSayfa:"https://www.example.com/p/1",siteGorsel:"https://cdn.example.com/1.jpg",dogrulamaDurumu:"Doğrulandı"});
    expect(result.sonuc.satirlar[0].ozellikler).toEqual([{key:"Alerjen",label:"Alerjen",value:"Gluten"}]);
    expect(draft).toMatchObject({name:"İlk resmi ürün",brand:"X",description:"Resmî açıklama",satisFiyati:null,ownerApproved:false,isVisible:false});
  });
  it("barkod çelişkisi doğrulamayı düşürür ve şüpheli görseli taslağa sokmaz",async()=>{
    const oneRow = {...first,satirlar:[first.satirlar[0]]};
    const result = await kartPresetYanitiniOku(researchResponse([researchItem("row-0001",{
      product:{...(researchItem() as {product:Record<string,unknown>}).product,gtin:"999"},
    })]),oneRow);
    expect(result.sonuc.satirlar[0]).toMatchObject({ad:"İlk",siteSayfa:"",siteGorsel:"",dogrulamaDurumu:"Belirsiz"});
  });
  it("barkod eşleşse bile markadaki çelişki doğrulamayı düşürür",async()=>{
    const product = (researchItem() as {product:Record<string,unknown>}).product;
    const result = await kartPresetYanitiniOku(researchResponse([researchItem("row-0001",{
      product:{...product,brand:"Y"},
    })]),{...first,satirlar:[first.satirlar[0]]});
    expect(result.sonuc.satirlar[0]).toMatchObject({siteSayfa:"",siteGorsel:"",dogrulamaDurumu:"Belirsiz"});
  });
  it("resmî alan adı gibi görünen sahte alt dizgeyi reddeder",async()=>{
    const oneRow = {...first,satirlar:[first.satirlar[0]]};
    const base = researchItem() as {source:Record<string,unknown>};
    const source = {...base.source,product_page_url:"https://example.com.evil.test/p/1",image_page_url:"https://example.com.evil.test/p/1"};
    const result = await kartPresetYanitiniOku(researchResponse([researchItem("row-0001",{source})]),oneRow);
    expect(result.sonuc.satirlar[0]).toMatchObject({siteSayfa:"",siteGorsel:"",dogrulamaDurumu:"Belirsiz"});
  });
  it("v1 cevabı satırları atlayamaz veya mükerrer row_id kullanamaz",async()=>{
    await expect(kartPresetYanitiniOku(researchResponse([researchItem("row-0001"),researchItem("row-0001")]),first)).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
    await expect(kartPresetYanitiniOku(researchResponse([researchItem("row-0001")]),first)).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
  });
  it("v1 ürün nesnesine satış fiyatı gibi sözleşme dışı alan eklenirse yanıtı reddeder",async()=>{
    const unsafe = researchItem() as {product:Record<string,unknown>};
    await expect(kartPresetYanitiniOku(researchResponse([researchItem("row-0001",{
      product:{...unsafe.product,sale_price:999},
    })]),{...first,satirlar:[first.satirlar[0]]})).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
  });
  it("üçüncü taraf sayfası verified dese bile Vixrex resmî doğrulamayı düşürür",async()=>{
    const base = researchItem() as {source:Record<string,unknown>};
    const result = await kartPresetYanitiniOku(researchResponse([researchItem("row-0001",{
      source:{...base.source,source_type:"third_party"},
    })]),{...first,satirlar:[first.satirlar[0]]});
    expect(result.sonuc.satirlar[0]).toMatchObject({siteSayfa:"",siteGorsel:"",dogrulamaDurumu:"Belirsiz"});
  });
});
