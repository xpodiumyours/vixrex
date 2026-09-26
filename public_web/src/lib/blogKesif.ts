import type { BlogKategori, BlogListeYazisi } from "@/data/blogYazilari";

export function blogAramaMetni(metin: string): string {
  return metin
    .toLocaleLowerCase("tr-TR")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/ı/g, "i");
}

export function blogYazilariniFiltrele(
  yazilar: BlogListeYazisi[],
  arama: string,
  kategori: "Tümü" | BlogKategori,
): BlogListeYazisi[] {
  const kelimeler = blogAramaMetni(arama).trim().split(/\s+/).filter(Boolean);
  return yazilar.filter((yazi) => {
    if (kategori !== "Tümü" && yazi.kategori !== kategori) return false;
    const metin = blogAramaMetni(
      [yazi.baslik, yazi.ozet, yazi.kategori, ...yazi.sektorler].join(" "),
    );
    return kelimeler.every((kelime) => metin.includes(kelime));
  });
}
