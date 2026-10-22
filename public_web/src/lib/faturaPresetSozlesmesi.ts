/** Ürün araştırması/kararı değil, mevcut preset ile Vixrex arasındaki taşıma sözleşmesi. */
export const VARSAYILAN_FATURA_PRESET = "vixrex-qwen-fatura-okuma-suzme";

export const FATURA_JSON_ORNEGI = {
  tedarikci: "", tedarikci_vergi_no: "", tedarikci_adres: "", tedarikci_site: "",
  belge_turu: "", belge_no: "", belge_tarihi: "",
  belge_ekleri: {}, gruplar: [], uyarilar: [],
  satirlar: [{
    satir_no: 1, ham_satir: "", model: "", ad: "", barkod: "", marka: "", uretici: "",
    varyant: "", beden: "", gramaj: "", adet: null, birim: "",
    birim_fiyat: null, tutar: null, okuma_guveni: null,
    site_aciklama: "", site_sayfa: "", site_gorseller: [], kategori: "",
    ozellikler: [], dogrulama_durumu: "", eslesen_bilgiler: [],
    eksikler: [], gorsel_dogrulama_durumu: "", kaynaklar: [],
  }],
  toplam_adet: null, toplam_tutar: null, mal_bedeli: null, kdv_tutari: null,
  indirim_tutari: null, odenecek_toplam: null,
};

export const FATURA_JSON_ISTEGI = [
  "Bu fatura görselini mevcut preset kapsamındaki dört aşamayı tamamlayarak işle.",
  "Okuma, kayıpsız marka gruplaması, resmî kaynak araştırması ve ürün kartı hazırlama OpenRouter içinde tamamlansın.",
  "Bu fatura gönderimi AŞAMA 1–4 için araştırma iznidir: web_search ve web_fetch araçlarını şimdi kullan; AŞAMA 2 sonunda durma, devam onayı veya yeni sohbet mesajı isteme.",
  "Bu etkileşimli sohbet değil, Vixrex taslak kart API isteğidir. Gerekli kaynaklara erişilemiyorsa gerçek eksikleri ve Araştırılamadı durumunu nihai JSON'da bildir; iş tamamlandı gibi gösterme.",
  "Mevcut doğrulama kararlarını koru; her özgün satır satirlar dizisinde eksikleriyle kalsın.",
  "Vixrex kart ekranı için yalnız geçerli JSON döndür. Aşağıdaki alan adlarını kullan; örnek boş değerler gerçek veri değildir.",
  "Bilinmeyen sayılar null, eksik listeler [] olsun. Satış fiyatı ve esnaf onayı üretme.",
  "Doğrulama durumu preset'in üçüncü aşamasındaki Doğrulandı / Belirsiz / Bulunamadı / Araştırılamadı kararlarından biri olsun.",
  "Görsel adresleri gerçek doğrudan adres, site_sayfa resmî ürün sayfası olsun. İncelenmeyen görseli doğrulanmış gösterme.",
  "Kaynaklar ve eşleşme kanıtlarını koru. Üretici adı/gramaj/özellik yoksa tahmin etme.",
  JSON.stringify(FATURA_JSON_ORNEGI),
].join("\n");
