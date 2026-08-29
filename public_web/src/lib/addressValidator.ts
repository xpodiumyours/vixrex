/**
 * İşletme adresi doğrulama — Flutter `lib/utils/address_validator.dart` ile parite.
 *
 * Kural: İl ve ilçe ayrı alanlar, burada yalnız açık adres (sokak/cadde/mahalle + kapı no) aranıyor.
 * Eşik bilerek dar: "asd" geçmemeli, "Atatürk Cad. No:24" geçmeli.
 * Kaynak: AddressValidator.minUzunluk=10, yerBelirtecListesi, hataMesaji.
 */
export const ADDRESS_MIN_LENGTH = 10;

const YER_BELIRTECLERI = [
  "cad",
  "sok",
  "mah",
  "bulv",
  "blv",
  "apt",
  "blok",
  "sit",
  "plaza",
  "çarşı",
  "carsi",
  "pasaj",
  "sanayi",
  "osb",
  "küme",
  "kume",
];

export function addressHataMesaji(adres: string | null | undefined): string | null {
  const metin = (adres ?? "").trim();

  if (metin.length === 0) {
    return "Adres gerekli. Örnek: Atatürk Cad. No:24";
  }

  if (metin.length < ADDRESS_MIN_LENGTH) {
    return "Adres çok kısa. Müşterinin seni bulabilmesi için sokak/cadde ve kapı numarası yaz. Örnek: Atatürk Cad. No:24";
  }

  const kucuk = metin.toLowerCase();
  const rakamVar = /\d/.test(metin);
  const yerBelirteciVar = YER_BELIRTECLERI.some((b) => kucuk.includes(b));

  if (!rakamVar && !yerBelirteciVar) {
    return "Adres eksik görünüyor. Sokak/cadde adı veya kapı numarası ekle. Örnek: Atatürk Cad. No:24";
  }

  return null;
}

export function isAddressValid(adres: string | null | undefined): boolean {
  return addressHataMesaji(adres) === null;
}
