/**
 * Fatura metninden KİŞİSEL VERİ TEMİZLİĞİ (KVKK veri minimizasyonu).
 *
 * NEDEN VAR (2026-10-01):
 *   Fatura fotoğrafı OpenAI'ye gönderilip okunuyor. Fotoğrafta esnafın
 *   MÜŞTERİSİNE ait kişisel veriler de var — T.C. Kimlik No ve vergi numarası.
 *   Sistem bu verilere İHTİYAÇ DUYMAZ:
 *     - Ürün eşleştirme firmanın kendi sitesinde yapılır; ada göre tahmin yok.
 *     - Tedarikçi doğrulaması OCR çıktısından değil, DIŞARIDAN geçilen
 *       `tedarikciKimligi`'nden gelir (`faturaEslestir.ts:222`).
 *   Yani bu veriler hiçbir işe yaramıyor — yalnızca saklanıyordu.
 *
 * KAPSAM — kullanıcı kararı (2026-10-01):
 *   Silinen:  T.C. Kimlik No ve vergi numarası (maskeleme/işaretleme yok —
 *             "hiç girmesin verilerimize" kararı).
 *   Korunan:  ürün satırı metni, stok kodu, barkod, ürün adı, adet, fiyat,
 *             tutar, marka, beden, varyant, belge no/tarihi, tedarikçi bilgisi.
 *   Gerekçe: OCR doğrulaması (`belgeGercegiUyuyorMu`) satır metnini ve
 *             toplamları karşılaştırır; satırın içinden başka veri silmek
 *             eşleştirmeyi ve tutarlılık kontrolünü bozabilir.
 *
 * NEDEN AKIŞLI TEMİZLİK, NEDEN DÜZ REGEX:
 *   T.C. Kimlik No 11 hane, vergi numarası 10-11 haneli rakamdır; ürün
 *   satırındaki stok kodu (`16747`) ve fiyatlar da rakamdır. "Her 10-11
 *   haneli rakamı sil" kuralı stok kodlarını da siler ve akışı bozardı.
 *   Bu yüzden:
 *     1. Adaylar, kimlik/vergi numarası BAĞLAMINDA geçen yerlerden seçilir
 *        ("TCKN", "T.C.", "Kimlik No", "Vergi No", "VKN" vb.).
 *     2. 11 haneli aday TCKN algoritmasıyla DOĞRULANIR; geçerliyse kesin
 *        TCKN'dir ve bağlam olmasa da silinir (veri minimizasyonu lehine).
 *     3. 10 haneli aday YALNIZCA vergi bağlamı varsa silinir; bağlam yoksa
 *        ürün kodu/fiyat olabileceği için DOKUNULMAZ.
 */

/**
 * T.C. Kimlik No algoritmik doğrulaması.
 * İlk 10 haneden checksum hesaplanır, 11. hane ile karşılaştırılır.
 */
export function tcknGecerliMi(deger: string): boolean {
  if (!/^[1-9][0-9]{10}$/.test(deger)) return false;
  const hane = [...deger].map(Number);
  let tekToplam = 0;
  let ciftToplam = 0;
  for (let i = 0; i < 10; i += 1) {
    if (i % 2 === 0) tekToplam += hane[i];
    else ciftToplam += hane[i] * 2;
  }
  const beklenen = (10 - ((tekToplam + ciftToplam) % 10)) % 10;
  return hane[10] === beklenen;
}

// T.C.K.N, TCKN, T.C. Kimlik No, Kimlik No, TC Kimlik No gibi yazımlar.
// Nokta ve boşluk varyantlarının hepsini kapsar.
const KIMLIK_BAGLAM = [
  /\bt\s*\.?\s*c\s*\.?\s*(?:k\s*\.?\s*n\s*\.?|kimlik)?/gi,
  /\bkimlik\s*(?:no|numara|numarası)/gi,
];

const VERGI_BAGLAM = [
  /\bv\s*\.?\s*e\s*\.?\s*r\s*\.?\s*g\s*\.?\s*i\s*(?:no|numara|numarası)?/gi,
  /\bvkn/gi,
];

/** Bağlam kelimesinin ardından geçen uzun rakam dizilerini toplar. */
function baglamliRakamlar(metin: string, desenler: RegExp[]): Set<string> {
  const bulunan = new Set<string>();
  for (const desen of desenler) {
    const re = new RegExp(desen.source, "gi");
    let eslesme: RegExpExecArray | null;
    while ((eslesme = re.exec(metin)) !== null) {
      // Numara, bağlam kelimesinden sonra 60 karakter içinde olabilir
      // ("Kimlik No : 123..." / "TCKN\n\n123...").
      const sonrasi = metin.slice(eslesme.index, eslesme.index + eslesme[0].length + 60);
      const rakamlar = sonrasi.match(/\b\d{10,11}\b/g);
      if (rakamlar) for (const rakam of rakamlar) bulunan.add(rakam);
      if (eslesme.index === re.lastIndex) re.lastIndex += 1;
    }
  }
  return bulunan;
}

/**
 * Serbest metinden T.C. Kimlik No ve vergi numarasını SİLER.
 *
 * @returns temizlenmiş metin — satırın geri kalanı birebir korunur.
 */
export function kisiselVeriTemizle(metin: string): string {
  if (!metin) return metin;

  const tcknAdaylari = baglamliRakamlar(metin, KIMLIK_BAGLAM);
  const vergiAdaylari = baglamliRakamlar(metin, VERGI_BAGLAM);

  // 11 hane: algoritmik doğrulama. Bağlam olmasa da kesin TCKN ise silinir.
  for (const aday of metin.match(/\b\d{11}\b/g) ?? []) {
    if (tcknGecerliMi(aday)) tcknAdaylari.add(aday);
  }

  // 10 hane: YALNIZ vergi bağlamı doğrulanmışsa silinir. Aksi hâlde ürün
  // kodu/fiyat olabilir — dokunulmaz.
  for (const aday of metin.match(/\b\d{10}\b/g) ?? []) {
    if (vergiAdaylari.has(aday)) vergiAdaylari.add(aday);
  }

  const silinecek = new Set<string>([...tcknAdaylari, ...vergiAdaylari]);
  if (silinecek.size === 0) return metin;

  return metin
    .split(/(\b\d{10,11}\b)/g)
    .filter((parca) => !(/\b\d{10,11}\b/.test(parca) && silinecek.has(parca)))
    .join("");
}