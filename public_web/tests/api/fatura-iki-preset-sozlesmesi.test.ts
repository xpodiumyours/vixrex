import { afterEach, beforeEach, describe, it, expect, vi } from "vitest";

beforeEach(() => vi.stubEnv("PRESET_AKIS", "yeni"));
afterEach(() => vi.unstubAllEnvs());
import { kartPresetIstekGovdesi, kartPresetYanitiniOku, URUN_KART_PRESET_YENI } from "@/lib/faturaKartPreset";
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
  row_id: id, raw_invoice_line: id, brand: "X", barcode: null, code: null,
  invoice_data: { quantity: 1, unit: "adet", unit_price: 10, total_amount: 10 },
  vixrex_product_json: {
    title, brand: "X", short_description: title + " açıklama", category_suggestion: "Gıda",
    variant: null, consumer_sale_price: null, stock_quantity: null,
  },
  validation: {
    status: "verified", official_domain: "example.com", official_product_url: "https://example.com/p/" + id,
    matched_attributes: [], unmatched_attributes: [],
  },
  media: {
    image_url: "https://example.com/p/" + id + ".jpg", source_url: "https://example.com/p/" + id,
    verification_status: "verified", rights_status: "unknown",
  },
  card_status: "draft", duplicate_group: null, canonical_row_id: null,
});
const response = (items: unknown[], summary: Record<string, unknown> = {
  total_rows: items.length, verified_count: items.length, draft_count: items.length, not_found_count: 0,
}) => new Response(JSON.stringify({
  choices: [{ message: { content: JSON.stringify({ summary, items }) }, finish_reason: "stop" }],
}), { status: 200, headers: { "content-type": "application/json" } });
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
      media:{...kart.media,image_url:"",source_url:"https://example.com/p/1.jpg",rights_status:"authorized"},
    }]),okuma);
    const satir = faturaSatiriniAktar(result.sonuc.satirlar[0],"Tedarikçi");
    expect(satir.marka).toBe("X");
    expect(satir.varyant).toBe("Sade");
    expect(satir.katalog).toMatchObject({marka:"Üreticinin markası",varyant:"175 g tekli paket",gramaj:"175 g",izinDurumu:"var",gorseller:[]});
    expect(faturaKatalogMetadatasi(satir.katalog ?? {}).attributes?.map(a=>a.value)).toEqual(expect.arrayContaining(["Sade","175 g tekli paket","175 g"]));
    expect(satirdanFaturaTaslagi(satir)).toMatchObject({brand:"Üreticinin markası",satisFiyati:null,stokOnerisi:3,ownerApproved:false,isVisible:false});
  });
  it("faturadan eksik kalan row_id varsa tüm kart yanıtını reddeder",async()=>{
    await expect(kartPresetYanitiniOku(response([item("1","A ürün")]),first))
      .rejects.toThrow("KART_YANITI_COZULEMEDI");
  });
  it("mükerrer row_id için ilk kayıt kazanmaz, tüm yanıt reddedilir",async()=>{
    await expect(kartPresetYanitiniOku(response([item("1","A ürün"),item("1","B ürün"),item("2","C ürün")]),first))
      .rejects.toThrow("KART_YANITI_COZULEMEDI");
  });
  it("yabancı, geçersiz veya bozuk satırları sessizce atmaz",async()=>{
    for (const items of [
      [item("9","X"),item("2","Y")],
      [{...item("1","A"),row_id:"01"},item("2","B")],
      [item("1","A"),{row_id:"2"}],
      [item("1","A"),null],
    ]) {
      await expect(kartPresetYanitiniOku(response(items),first))
        .rejects.toThrow("KART_YANITI_COZULEMEDI");
    }
  });
  it("zorunlu iç alanlar, türler ve summary eksikse tüm yanıt reddedilir",async()=>{
    for (const bozuk of [
      {...item("1","A"),validation:{status:"verified"}},
      {...item("1","A"),media:{image_url:null}},
      {...item("1","A"),invoice_data:{quantity:"2"}},
      {...item("1","A"),vixrex_product_json:{title:"A"}},
      {...item("1","A"),card_status:"blocked"},
      {...item("1","A"),unexpected: true},
    ]) {
      await expect(kartPresetYanitiniOku(response([bozuk,item("2","B")]),first))
        .rejects.toThrow("KART_YANITI_COZULEMEDI");
    }
    await expect(kartPresetYanitiniOku(response([item("1","A"),item("2","B")],{total_rows:1}),first))
      .rejects.toThrow("KART_YANITI_COZULEMEDI");
  });
  it("boşlukla değiştirilmiş duplicate_group reddedilir",async()=>{
    await expect(kartPresetYanitiniOku(response([
      {...item("1","A"),duplicate_group:" grup",canonical_row_id:"1"},
      {...item("2","B"),duplicate_group:" grup",canonical_row_id:"1"},
    ]),first)).rejects.toThrow("KART_YANITI_COZULEMEDI");
  });
  it("OpenRouter kanonik row_id=2 ve grup bilgisi kalıcı kataloga geçer",async()=>{
    const result=await kartPresetYanitiniOku(response([
      {...item("1","A"),duplicate_group:"grup-2",canonical_row_id:"2"},
      {...item("2","B"),duplicate_group:"grup-2",canonical_row_id:"2"},
    ]),first);
    const satirlar=result.sonuc.satirlar.map(s=>faturaSatiriniAktar(s,"Tedarikçi"));
    expect(satirlar.map(s=>[s.katalog?.duplicateGroup,s.katalog?.canonicalRowId]))
      .toEqual([["grup-2","2"],["grup-2","2"]]);
    expect(satirdanFaturaTaslagi(satirlar[1])).toMatchObject({
      duplicateGroup:"grup-2",canonicalRowId:"2",
    });
  });
  it("bozuk kanonik grup bağlantısını yeni ürün kararı vermeden reddeder",async()=>{
    await expect(kartPresetYanitiniOku(response([
      {...item("1","A"),duplicate_group:"grup",canonical_row_id:"1"},
      {...item("2","B"),duplicate_group:"grup",canonical_row_id:"2"},
    ]),first)).rejects.toThrow("KART_YANITI_COZULEMEDI");
  });
  it("eski yol düz/karma biçimi kabul etmeye devam eder",async()=>{
    vi.stubEnv("PRESET_AKIS","mevcut");
    const duz={
      row_id:"1",
      title:"ELT1302 Elit Erkek Elastan Sıfır Yaka Uzun Kol Fanila",
      brand:"Elit (Tutku Elit)",
      category_suggestion:"İç Giyim > Erkek > Fanila",
      variant:"Resmî sayfada görüntülenen varyant: Beyaz; faturada: Siyah",
      short_description:"Seher Mensucat üretimi ELT1302 fanila.",
      consumer_sale_price:null,stock_quantity:null,
      official_product_url:"https://example.com/elt1302",
      image_url:null,image_urls:["https://example.com/elt1302.jpg"],
      image_validation_status:"not_reviewed",rights_status:"unknown",
      matched_attributes:["Ürün kodu (ELT1302)"],
      unmatched_attributes:["Renk: faturada Siyah, sayfada Beyaz"],
      sources:[{url:"https://example.com/elt1302",type:"official_manufacturer_product_page",fetched:true}],
      validation:{status:"ambiguous",notes:"Renk doğrulanamadı."},
    };
    const result=await kartPresetYanitiniOku(response([duz]),first);
    const satir=result.sonuc.satirlar[0];
    expect(satir.ad).toBe("ELT1302 Elit Erkek Elastan Sıfır Yaka Uzun Kol Fanila");
    expect(satir.dogrulamaDurumu).toBe("Belirsiz");
    expect(satir.siteSayfa).toBe("https://example.com/elt1302");
    expect(satir.siteGorsel).toBe("https://example.com/elt1302.jpg");
    expect(satir.siteGorseller).toEqual(["https://example.com/elt1302.jpg"]);
    expect(satir.siteMarka).toBe("Elit (Tutku Elit)");
    expect(satir.siteKategori).toBe("İç Giyim > Erkek > Fanila");
    expect(satir.siteVaryant).toBe("Resmî sayfada görüntülenen varyant: Beyaz; faturada: Siyah");
    expect(satir.siteAciklama).toBe("Seher Mensucat üretimi ELT1302 fanila.");
    expect(satir.eslesenBilgiler).toEqual(["Ürün kodu (ELT1302)"]);
    expect(satir.eksikler).toEqual(["Renk: faturada Siyah, sayfada Beyaz"]);
    expect(satir.gorselDogrulamaDurumu).toBe("not_reviewed");
    expect(satir.gorselKullanimDurumu).toBe("unknown");
    expect(satir.barkod).toBe("111");
    expect(satir.adet).toBe(3);
    expect(satir.tutar).toBe(30);
    expect(satir.kaynaklar?.[0]).toMatchObject({status:"ambiguous",notes:"Renk doğrulanamadı.",official_product_url:"https://example.com/elt1302"});
    expect(satir.kaynaklar).toContainEqual(expect.objectContaining({url:"https://example.com/elt1302",fetched:true}));
  });
  it("eski yolda düz biçimde başlıksız bulunamadı satırı korunur",async()=>{
    vi.stubEnv("PRESET_AKIS","mevcut");
    const duz={
      row_id:"2",brand:"Tut",category_suggestion:"",
      image_validation_status:"not_reviewed",rights_status:"unknown",
      unmatched_attributes:["Tüm ürün özellikleri: resmî ürün sayfası bulunamadı"],
      validation:{status:"not_found"},
    };
    const result=await kartPresetYanitiniOku(response([duz]),first);
    const satir=result.sonuc.satirlar[1];
    expect(satir.dogrulamaDurumu).toBe("Bulunamadı");
    expect(satir.ad).toBe("İkinci");
    expect(satir.barkod).toBe("222");
    expect(satir.adet).toBe(4);
    expect(satir.tutar).toBe(80);
    expect(satir.eksikler).toEqual(["Tüm ürün özellikleri: resmî ürün sayfası bulunamadı"]);
    expect(satir.siteSayfa).toBe("");
  });
  it("ilk preset yalnız okuma verir; önceki ürün araştırması ikinci presete taşınmaz",()=>{
    const arastirma = {siteAciklama:"Eski açıklama",siteSayfa:"https://example.com/ilk",
      siteGorseller:["https://example.com/ilk-1.jpg"],dogrulamaDurumu:"Belirsiz"};
    const req=kartPresetIstekGovdesi({...first,satirlar:[{...first.satirlar[0],...arastirma},first.satirlar[1]]});
    const content=(req.messages as Array<{content:string}>)[0].content;
    const payload=JSON.parse(content.slice(content.lastIndexOf("\n")+1));
    expect(payload.groups[0].rows[0]).toMatchObject({row_id:"1",barcode:"111"});
    expect(payload.groups[0].rows[0]).not.toHaveProperty("previous_product_research");
    expect(content).not.toContain("Eski açıklama");
    expect(content).not.toContain("https://example.com/ilk");
  });
  it("source_url resmî ürün sayfasıysa fotoğraf diye kullanılmaz",async()=>{
    const result=await kartPresetYanitiniOku(response([{
      ...item("1","A ürün"),
      media:{...item("1","A ürün").media,image_url:null,source_url:"https://example.com/urun",verification_status:"not_researched"},
    }]),{...first,satirlar:[first.satirlar[0]]});
    expect(result.sonuc.satirlar[0].siteSayfa).toBe("https://example.com/p/1");
    expect(result.sonuc.satirlar[0].siteGorseller).toEqual([]);
  });
  it("katı ikinci preset media.source_url alanını ürün sayfası olarak taşır; fotoğraf olarak kullanmaz",async()=>{
    const temel=item("1","A ürün");
    const sonuc=await kartPresetYanitiniOku(response([{
      ...temel,
      validation:{...temel.validation,status:"ambiguous",official_product_url:null,unmatched_attributes:["Beden belirsiz"]},
      media:{...temel.media,image_url:null,source_url:"https://example.com/resmi-urun",verification_status:"not_reviewed"},
    }]),{...first,satirlar:[first.satirlar[0]]});
    const satir=sonuc.sonuc.satirlar[0];
    expect(satir.siteSayfa).toBe("https://example.com/resmi-urun");
    expect(satir.siteGorsel).toBe("");
    expect(satir.siteGorseller).toEqual([]);
    expect(satir.dogrulamaDurumu).toBe("Belirsiz");
    expect(satir.eksikler).toEqual(["Beden belirsiz"]);
  });
  it("yalnız görsel kaynak adresi verified kanıtı değildir",async()=>{
    const temel=item("1","A ürün");
    const sonuc=await kartPresetYanitiniOku(response([{
      ...temel,
      validation:{...temel.validation,official_product_url:null},
      media:{...temel.media,image_url:"https://cdn.example.com/image.webp",source_url:"https://example.com/urun"},
    }]),{...first,satirlar:[first.satirlar[0]]});
    const satir=sonuc.sonuc.satirlar[0];
    expect(satir.siteSayfa).toBe("https://example.com/urun");
    expect(satir.dogrulamaDurumu).toBe("Araştırılamadı");
    expect(satir.eksikler).toContain("Doğrulanmış ürün için resmî sayfa kanıtı eksik; doğrulanmış kabul edilmedi.");
    const aktarim=faturaSatiriniAktar(satir,"Tedarikçi");
    expect(aktarim.sonuc).toBe("eksik");
  });
  it("doğrulanmış resmî sayfa, görselin kaynak sayfasına göre önceliklidir",async()=>{
    const temel=item("1","A ürün");
    const sonuc=await kartPresetYanitiniOku(response([{
      ...temel,
      validation:{...temel.validation,official_product_url:"https://example.com/asli"},
      media:{...temel.media,image_url:"https://cdn.example.com/image.webp",source_url:"https://example.com/fotograf-kaynagi"},
    }]),{...first,satirlar:[first.satirlar[0]]});
    expect(sonuc.sonuc.satirlar[0].siteSayfa).toBe("https://example.com/asli");
    expect(sonuc.sonuc.satirlar[0].siteGorseller).toEqual(["https://cdn.example.com/image.webp"]);
  });
  it("ikinci presetin açık bulunamadı kararını ilk araştırmanın görseliyle değiştirmez",async()=>{
    const okuma={...first,satirlar:[{...first.satirlar[0],siteAciklama:"İlk açıklama",siteSayfa:"https://example.com/ilk",siteGorseller:["https://example.com/ilk.jpg"]}]};
    const temel=item("1","İlk");
    const result=await kartPresetYanitiniOku(response([{
      ...temel,
      vixrex_product_json:{...temel.vixrex_product_json,short_description:"",category_suggestion:""},
      validation:{...temel.validation,status:"not_found",official_product_url:null,unmatched_attributes:["Ürün"]},
      media:{...temel.media,image_url:null,source_url:null},
    }]),okuma);
    expect(result.sonuc.satirlar[0]).toMatchObject({siteAciklama:"",siteSayfa:"",siteGorseller:[],dogrulamaDurumu:"Bulunamadı",eksikler:["Ürün"]});
    expect(okuma.satirlar[0].siteGorseller).toEqual(["https://example.com/ilk.jpg"]);
  });
  it("OpenRouter preset ayarlarını değiştirmeden var olan model adresine gönderir",()=>{
    const req=kartPresetIstekGovdesi(first);
    expect(req.model).toBe(URUN_KART_PRESET_YENI);
    expect(req.model).toBe("@preset/vixrex-urun-karti-v2");
    const messages=req.messages as Array<{content:string}>;
    expect(messages[0].content).toContain("row_id");
    expect(req).not.toHaveProperty("tools");
    expect(req).not.toHaveProperty("provider");
    expect(req).not.toHaveProperty("response_format");
    expect(req).not.toHaveProperty("system");
  });
});
