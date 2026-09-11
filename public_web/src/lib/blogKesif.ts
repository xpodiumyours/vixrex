import type { BlogKategori, BlogListeYazisi } from "@/data/blogYazilari";

function aramaMetniniNormallestir(metin: string): string {
  return metin
    .toLocaleLowerCase("tr-TR")
    .replaceAll("ı", "i")
    .replaceAll("ğ", "g")
    .replaceAll("ü", "u")
    .replaceAll("ş", "s")
    .replaceAll("ö", "o")
    .replaceAll("ç", "c")
    .replace(/\s+/g, " ")
    .trim();
}

export function blogYazilariniFiltrele(
  yazilar: BlogListeYazisi[],
  arama: string,
  kategori: "Tümü" | BlogKategori,
): BlogListeYazisi[] {
  const sorgu = aramaMetniniNormallestir(arama);

  return yazilar.filter((yazi) => {
    if (kategori !== "Tümü" && yazi.kategori !== kategori) return false;
    if (!sorgu) return true;

    const aranabilirMetin = aramaMetniniNormallestir(
      [
        yazi.baslik,
        yazi.ozet,
        yazi.kategori,
        yazi.icerikTuru.replaceAll("_", " "),
        ...yazi.sektorler,
      ].join(" "),
    );

    return sorgu
      .split(" ")
      .filter(Boolean)
      .every((kelime) => aranabilirMetin.includes(kelime));
  });
}
