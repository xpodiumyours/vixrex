import { describe, it, expect } from "vitest";
import { kartPresetIstekGovdesi, kartPresetYanitiniOku, URUN_KART_PRESET } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";

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
  it("mükerrer ve eksik kimlikleri reddeder",async()=>{
    await expect(kartPresetYanitiniOku(response([item("1","A"),item("1","B")]),first)).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
    await expect(kartPresetYanitiniOku(response([item("1","A")]),first)).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
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
