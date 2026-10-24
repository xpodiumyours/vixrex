/** OpenRouter invoice-read/1.0 ile Vixrex taşıma katmanı arasındaki sözleşme. */
export const VARSAYILAN_FATURA_PRESET = "vixrex-qwen-fatura-okuma-suzme";

export const FATURA_JSON_ORNEGI = {
  contract_version: "vixrex.invoice-read/1.0",
  document: {
    document_type: null,
    document_number: null,
    document_date: null,
    supplier: { name: null, tax_id: null, address: null, website_printed_on_invoice: null },
    buyer: { name: null, tax_id: null },
    currency: null,
    totals: { goods: null, vat: null, discount: null, payable: null },
  },
  items: [{
    invoice_row_number: null, raw_text: "", product_name: null, brand: null,
    manufacturer_printed: null, model_or_code: null, gtin: null, variant_text: null,
    quantity: null, unit: null, purchase_unit_price: null, line_total: null,
    read_confidence: null,
  }],
  warnings: [],
};

export const FATURA_JSON_ISTEGI = [
  "Bu çağrı yalnız fatura okuma aşamasıdır; ürün araştırması veya kart zenginleştirmesi yapma.",
  "Faturada görünen tedarikçi, alıcı, belge ve ürün satırlarını kayıpsız çıkar. Tedarikçiyi üretici sayma.",
  "Her fatura satırını ayrı tut; satırları silme, birleştirme veya yeniden sıralama. Barkod ve kodları metin olarak, baştaki sıfırları koruyarak ver.",
  "Faturada yazmayan değeri null yap. Okunamayan değeri tahmin etme; warnings alanında açıkla.",
  "invoice_row_number yalnız belgede görünüyorsa yaz. Vixrex her satıra kendi değişmez row_id değerini atayacaktır.",
  "Bu etkileşimli sohbet değil, makine iş akışıdır. Aşama 2 sonunda durma ifadesi bu adım için geçerli değildir: bu aşamada yalnız okuma JSON'unu döndür, web araştırması yapma.",
  "Yalnız geçerli JSON döndür; Markdown, başlık veya açıklama ekleme. Satış fiyatı, stok kararı, yayın durumu veya resmî ürün kaynağı uydurma.",
  "Aşağıdaki nesne alan adları ve türleri gösteren şablondur; boş değerler gerçek veri değildir.",
  JSON.stringify(FATURA_JSON_ORNEGI),
].join("\n");
