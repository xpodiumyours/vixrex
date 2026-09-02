// Türkçe normalize – Flutter VixrexNormalizer ile aynı kural.
export function vixrexNormalize(text: string): string {
  return text
    .toLocaleLowerCase("tr-TR")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replaceAll("ı", "i")
    .replaceAll("İ", "i");
}

// Dart tarafı elle ı→i,ğ→g,ü→u,ş→s,ö→o yapar – parity için NFD de uygulanmalı
// çünkü Dart'ta "İ".toLowerCase() → "i̇" (i + combining) bırakır, TS'te de aynı.
// NFD + strip combining ile "İ" → "i" olur, Flutter testindeki "isletme adi" ile eşleşir.
export function vixrexNormalizeDartParity(text: string): string {
  return text
    .toLocaleLowerCase("tr-TR")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replaceAll("ı", "i")
    .replaceAll("ğ", "g")
    .replaceAll("ü", "u")
    .replaceAll("ş", "s")
    .replaceAll("ö", "o")
    .replaceAll("ç", "c")
    .replaceAll("İ", "i")
    .replaceAll("Ğ", "g")
    .replaceAll("Ü", "u")
    .replaceAll("Ş", "s")
    .replaceAll("Ö", "o")
    .replaceAll("Ç", "c");
}
