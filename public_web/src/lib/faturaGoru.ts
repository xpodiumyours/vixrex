/**
 * Fatura fotoğrafını okuyan TEK yer.
 *
 * Telefon uygulaması da web de `/api/fatura-oku` ucuna gider; o uç da buraya.
 * İkinci bir "okuma beyni" yoktur.
 *
 * Sağlayıcı: OpenRouter üzerinden `openai/gpt-5.6-luna`.
 *
 * Neden bu model — 2026-09-26'da gerçek faturayla (fis_4, 13 satır / 75 adet /
 * 6.034,00 TL) ölçüldü:
 *   gpt-5.6-luna      13/13 satır, 75/75 adet, 6.034 TL, 0 yanlış  ~7 kuruş
 *   gpt-5.4-mini      12/13 satır, 74/75 adet, 5 doğru adet        ~19 kuruş
 *   claude-sonnet     13/13 satır, 75/75 adet ama yalnız 5 doğru   ~4 TL
 *   ücretsiz modeller hiçbiri tutturamadı
 * luna üç kez üst üste hatasız okudu; hem en doğru hem en ucuz olduğu için
 * seçildi. Model değiştirilecekse aynı faturayla yeniden ölçülmelidir.
 *
 * Model satırları YAPILANDIRILMIŞ döndürür; yine de doğru kabul edilmez —
 * `belgeGercegiUyuyorMu` satır toplamlarını belgenin kendi toplamıyla
 * karşılaştırır. Tutmayan okuma kullanılmaz.
 */

import { kisiselVeriTemizle } from "@/lib/faturaKisiselVeri";

const ADRES = "https://openrouter.ai/api/v1/chat/completions";
export const GORU_MODELI = "openai/gpt-5.6-luna";

const SORU = [
  "Bu bir fatura tablosu. HER urun satirini oku. Yalniz JSON dondur.",
  '{"tedarikci":"","tedarikci_unvan":"","tedarikci_vergi_no":"","tedarikci_vergi_dairesi":"","tedarikci_hesap_no":"","tedarikci_adres":"","tedarikci_site":"","musteri_ad":"","musteri_unvan":"","musteri_adres":"","musteri_vergi_no":"","musteri_vergi_dairesi":"","musteri_hesap_no":"","belge_turu":"","belge_seri":"","belge_sira":"","belge_no":"","belge_tarihi":"","irsaliye_no":"","teslim_tarihi":"","para_birimi":"","vergi_turu":"","vergi_orani":0,"karekod":"","karekod_icerigi":"","internet_satis_metni":"","odeme_sekli":"","odeme_tarihi":"","tasiyan":"","gonderim_tarihi":"","iade_metni":"","satirlar":[{"ham_satir":"","model":"","ad":"","barkod":"","varyant":"","beden":"","marka":"","adet":0,"birim_fiyat":0,"tutar":0}],"toplam_adet":0,"toplam_tutar":0,"mal_bedeli":0,"kdv_tutari":0,"indirim_tutari":0,"odenecek_toplam":0}',
  "1. Her satirda adet * birim_fiyat = tutar olmali.",
  "2. Satirlarin adet toplami = toplam_adet, tutar toplami = toplam_tutar.",
  "3. toplam_adet/toplam_tutar en alttaki 'Toplam' satirindan alinir.",
  "4. Sayilari 6.034,00 -> 6034.00 bicimine cevir. Uydurma yok.",
  "5. tedarikci = faturayi kesen firmanin adi. Yazmiyorsa bos birak, tahmin etme.",
  "6. ad = faturada yazan urun adi veya urun aciklamasi. Yazmiyorsa bos birak, tahmin etme.",
  "7. ham_satir = urun satirinda gorunen metni sirasi ve degerleriyle koru.",
  "8. tedarikci_vergi_no, tedarikci_adres ve tedarikci_site yalniz belgede acikca yaziyorsa doldur; tahmin etme.",
  "9. belge_turu: belgede acikca yaziyorsa fatura, e-arsiv, irsaliye veya bilgi fisi; belge_no ve belge_tarihi yalniz belgede yaziyorsa doldur (tarih GG.AA.YYYY), tahmin etme.",
  "10. mal_bedeli, kdv_tutari, indirim_tutari ve odenecek_toplam belgede ayri ayri yaziyorsa ayri ayri doldur; yazmiyorsa null birak, hesaplayip uydurma.",
  "11. marka = urun satirinda ya da urun kodunun yaninda yazan marka adi; yazmiyorsa bos birak, faturayi kesen firmayi marka sanma, tahmin etme.",
  "12. belge_seri ve belge_sira ayri alandir: 'A 12345' yaziyorsa belge_seri='A', belge_sira='12345'. Yalniz tek numara yaziyorsa belge_no'ya yaz, belge_seri ve belge_sira bos birak.",
  "13. tedarikci_unvan, tedarikci_vergi_dairesi ve tedarikci_hesap_no yalniz belgede ayri yaziyorsa doldur; yazmiyorsa bos birak, tahmin etme.",
  "14. musteri_* alanlari musteri/alici bolumunde yaziyorsa doldur; perakende fiste ve bilgi fisinde musteri yoksa hepsini bos birak, tedarikciyi musteri sanma.",
  "15. vergi_turu ve vergi_orani belgede yaziyorsa doldur (vergi_orani orandir, 10 gibi; 6.034,00 gibi tutar degil).",
  "16. karekod: belgede karekod kutusu gorunuyorsa 'var', gorunmuyorsa bos birak. karekod_icerigi yalniz karekodun yaninda metin olarak basiliysa doldur; karekodun icini cozumlemeye calisma, uydurma.",
  "17. teslim_tarihi, irsaliye_no, para_birimi, internet_satis_metni, odeme_sekli, odeme_tarihi, tasiyan, gonderim_tarihi ve iade_metni yalniz belgede acikca yaziyorsa doldur; yazmiyorsa bos birak. para_birimi belgenin para birimidir (TL, TRY, USD...).",
].join("\n");

export interface GoruSatiri {
  hamSatir: string;
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  marka: string;
  adet: number | null;
  birimFiyat: number | null;
  tutar: number | null;
}

export interface GoruSonucu {
  /** Faturayı kesen firma. Belgede yazmıyorsa boş — tahmin edilmez. */
  tedarikci: string;
  tedarikciUnvani: string;
  tedarikciVergiNo: string;
  tedarikciVergiDairesi: string;
  tedarikciHesapNo: string;
  tedarikciAdres: string;
  tedarikciSite: string;
  musteriAd: string;
  musteriUnvani: string;
  musteriAdres: string;
  musteriVergiNo: string;
  musteriVergiDairesi: string;
  musteriHesapNo: string;
  satirlar: GoruSatiri[];
  belgeAdedi: number | null;
  belgeToplami: number | null;
  belgeTuru: string;
  belgeSeri: string;
  belgeSira: string;
  belgeNo: string;
  belgeTarihi: string;
  irsaliyeNo: string;
  teslimTarihi: string;
  paraBirimi: string;
  vergiTuru: string;
  vergiOrani: number | null;
  karekod: string;
  karekodIcerigi: string;
  internetSatisMetni: string;
  odemeSekli: string;
  odemeTarihi: string;
  tasiyan: string;
  gonderimTarihi: string;
  iadeMetni: string;
  malBedeli: number | null;
  kdvTutari: number | null;
  indirimTutari: number | null;
  odenecekToplam: number | null;
  /** Bu okumanın OpenRouter'da tuttuğu gerçek maliyet (USD). */
  maliyet: number | null;
}

function sayi(deger: unknown): number | null {
  const n = typeof deger === "number" ? deger : Number(String(deger ?? "").replace(",", "."));
  return Number.isFinite(n) ? n : null;
}

function yaziliSayi(deger: unknown): number | null {
  if (deger === null || deger === undefined || deger === "") return null;
  return sayi(deger);
}

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

/**
 * Fotoğrafı okur. Hata durumunda `Error` fırlatır — çağıran uç kullanıcıya
 * ne olduğunu kendi diliyle söyler.
 */
export async function faturayiOku(dataUrl: string): Promise<GoruSonucu> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");

  const cevap = await fetch(ADRES, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
    },
    body: JSON.stringify({
      model: GORU_MODELI,
      temperature: 0,
      usage: { include: true },
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: SORU },
            { type: "image_url", image_url: { url: dataUrl } },
          ],
        },
      ],
    }),
  });

  if (!cevap.ok) {
    // 402 = bakiye bitti; bunu ayırmak önemli, "tekrar dene" demek yanlış olur.
    throw new Error(cevap.status === 402 ? "OKUYUCU_BAKIYE_BITTI" : "OKUYUCU_CEVAP_VERMEDI");
  }

  const govde = await cevap.json().catch(() => null);
  const ham = govde?.choices?.[0]?.message?.content;
  if (typeof ham !== "string" || !ham.trim()) throw new Error("FOTOGRAFTA_YAZI_YOK");

  // Model bazen JSON'u açıklama arasına koyabiliyor; ilk süslü parantezden
  // sonuncusuna kadar alınır.
  const bas = ham.indexOf("{");
  const son = ham.lastIndexOf("}");
  if (bas < 0 || son <= bas) throw new Error("OKUMA_COZULEMEDI");

  let cozulen: unknown;
  try {
    cozulen = JSON.parse(ham.slice(bas, son + 1));
  } catch {
    throw new Error("OKUMA_COZULEMEDI");
  }

  const kok = cozulen as {
    tedarikci?: unknown;
    tedarikci_unvan?: unknown;
    tedarikci_vergi_no?: unknown;
    tedarikci_vergi_dairesi?: unknown;
    tedarikci_hesap_no?: unknown;
    tedarikci_adres?: unknown;
    tedarikci_site?: unknown;
    musteri_ad?: unknown;
    musteri_unvan?: unknown;
    musteri_adres?: unknown;
    musteri_vergi_no?: unknown;
    musteri_vergi_dairesi?: unknown;
    musteri_hesap_no?: unknown;
    belge_turu?: unknown;
    belge_seri?: unknown;
    belge_sira?: unknown;
    belge_no?: unknown;
    belge_tarihi?: unknown;
    irsaliye_no?: unknown;
    teslim_tarihi?: unknown;
    para_birimi?: unknown;
    vergi_turu?: unknown;
    vergi_orani?: unknown;
    karekod?: unknown;
    karekod_icerigi?: unknown;
    internet_satis_metni?: unknown;
    odeme_sekli?: unknown;
    odeme_tarihi?: unknown;
    tasiyan?: unknown;
    gonderim_tarihi?: unknown;
    iade_metni?: unknown;
    satirlar?: unknown;
    toplam_adet?: unknown;
    toplam_tutar?: unknown;
    mal_bedeli?: unknown;
    kdv_tutari?: unknown;
    indirim_tutari?: unknown;
    odenecek_toplam?: unknown;
  };
  const hamSatirlar = Array.isArray(kok.satirlar) ? kok.satirlar : [];

  // KVKK veri minimizasyonu: modelin okuduğu serbest metin T.C. Kimlik No veya
  // vergi numarası içerebilir. Sistem bunlara ihtiyaç duymaz (eşleştirme stok
  // kodu/barkodla yapılır; tedarikçi doğrulaması OCR çıktısından gelmez), bu
  // yüzden model yanlılıkla satıra karıştırmış olsa bile SİLİNİR. Satırın
  // geri kalanına dokunulmaz — OCR doğrulaması bozulmasın diye.
  // Ayrıntı ve kapsam: src/lib/faturaKisiselVeri.ts
  const satirlar: GoruSatiri[] = hamSatirlar.map((girdi) => {
    const s = girdi as Record<string, unknown>;
    return {
      hamSatir: kisiselVeriTemizle(metin(s.ham_satir)),
      model: metin(s.model),
      ad: metin(s.ad),
      barkod: metin(s.barkod),
      varyant: metin(s.varyant),
      beden: metin(s.beden),
      marka: metin(s.marka),
      adet: sayi(s.adet),
      birimFiyat: sayi(s.birim_fiyat),
      tutar: sayi(s.tutar),
    };
  });

  return {
    tedarikci: metin(kok.tedarikci),
    tedarikciUnvani: metin(kok.tedarikci_unvan),
    tedarikciVergiNo: metin(kok.tedarikci_vergi_no),
    tedarikciVergiDairesi: metin(kok.tedarikci_vergi_dairesi),
    tedarikciHesapNo: metin(kok.tedarikci_hesap_no),
    tedarikciAdres: metin(kok.tedarikci_adres),
    tedarikciSite: metin(kok.tedarikci_site),
    musteriAd: metin(kok.musteri_ad),
    musteriUnvani: metin(kok.musteri_unvan),
    musteriAdres: metin(kok.musteri_adres),
    musteriVergiNo: metin(kok.musteri_vergi_no),
    musteriVergiDairesi: metin(kok.musteri_vergi_dairesi),
    musteriHesapNo: metin(kok.musteri_hesap_no),
    satirlar,
    belgeAdedi: sayi(kok.toplam_adet),
    belgeToplami: sayi(kok.toplam_tutar),
    belgeTuru: metin(kok.belge_turu),
    belgeSeri: metin(kok.belge_seri),
    belgeSira: metin(kok.belge_sira),
    belgeNo: metin(kok.belge_no),
    belgeTarihi: metin(kok.belge_tarihi),
    irsaliyeNo: metin(kok.irsaliye_no),
    teslimTarihi: metin(kok.teslim_tarihi),
    paraBirimi: metin(kok.para_birimi),
    vergiTuru: metin(kok.vergi_turu),
    vergiOrani: yaziliSayi(kok.vergi_orani),
    karekod: metin(kok.karekod),
    karekodIcerigi: metin(kok.karekod_icerigi),
    internetSatisMetni: metin(kok.internet_satis_metni),
    odemeSekli: metin(kok.odeme_sekli),
    odemeTarihi: metin(kok.odeme_tarihi),
    tasiyan: metin(kok.tasiyan),
    gonderimTarihi: metin(kok.gonderim_tarihi),
    iadeMetni: metin(kok.iade_metni),
    malBedeli: yaziliSayi(kok.mal_bedeli),
    kdvTutari: yaziliSayi(kok.kdv_tutari),
    indirimTutari: yaziliSayi(kok.indirim_tutari),
    odenecekToplam: yaziliSayi(kok.odenecek_toplam),
    maliyet: sayi(govde?.usage?.cost),
  };
}
