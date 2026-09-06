export type VixrexBlogIntent =
  | "blog_yazisi_bul"
  | "blog_yazisi_oner"
  | "blog_yazisi_taslak_ekle"
  | "blog_taslaklarini_listele"
  | "blog_taslak_duzenle"
  | "blog_yayinla";

export type VixrexAssistantDomainDecision =
  | { domain: "storefront"; intent: null; query: "" }
  | { domain: "blog"; intent: VixrexBlogIntent; query: string }
  | { domain: "ambiguous"; intent: null; query: string };

function normalize(input: string): string {
  return input
    .toLocaleLowerCase("tr-TR")
    .replace(/[ıİ]/g, "i")
    .replace(/[şŞ]/g, "s")
    .replace(/[ğĞ]/g, "g")
    .replace(/[üÜ]/g, "u")
    .replace(/[öÖ]/g, "o")
    .replace(/[çÇ]/g, "c")
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function hasAny(text: string, tokens: readonly string[]): boolean {
  return tokens.some((token) => text.includes(token));
}

function queryFrom(text: string): string {
  const stop = new Set([
    "blog",
    "bloga",
    "blogda",
    "blogdan",
    "bloguna",
    "blogunda",
    "vitrin",
    "vitrinin",
    "vitrine",
    "vitrinime",
    "yazi",
    "yazisi",
    "yazisini",
    "yazilar",
    "yazilarimi",
    "makale",
    "rehber",
    "taslak",
    "taslagi",
    "taslagini",
    "taslaklar",
    "taslaklarimi",
    "ekle",
    "aktar",
    "cek",
    "olustur",
    "bul",
    "ara",
    "goster",
    "listele",
    "oner",
    "duzenle",
    "degistir",
    "yayinla",
    "yayina",
    "al",
    "bana",
    "bir",
  ]);
  return text
    .split(" ")
    .filter((token) => token.length > 1 && !stop.has(token))
    .join(" ")
    .trim();
}

/**
 * Üst seviye domain router'ın Blog tarafı.
 *
 * Kritik sınır: yalnız "blog" kelimesi Blog domain'e geçirmez.
 * Örn. "blog başlığını değiştir" 46-alan storefront motorunda kalır.
 * Blog domain yalnız açık içerik komutlarıyla seçilir.
 */
export function routeVixrexAssistantDomain(input: string): VixrexAssistantDomainDecision {
  const text = normalize(input);
  if (!text) return { domain: "storefront", intent: null, query: "" };

  const mentionsBlog = text.includes("blog");
  const mentionsContent = hasAny(text, ["yazi", "makale", "rehber", "taslak", "taslag"]);
  if (!mentionsBlog || !mentionsContent) {
    return { domain: "storefront", intent: null, query: "" };
  }

  const matches: VixrexBlogIntent[] = [];

  if (
    hasAny(text, ["taslak", "taslag"]) &&
    hasAny(text, ["listele", "goster", "neler", "hangileri"])
  ) {
    matches.push("blog_taslaklarini_listele");
  }
  if (hasAny(text, ["yayinla", "yayina al"])) {
    matches.push("blog_yayinla");
  }
  if (
    hasAny(text, ["duzenle", "degistir"]) &&
    hasAny(text, ["yazi", "taslak", "taslag", "makale"])
  ) {
    matches.push("blog_taslak_duzenle");
  }
  if (
    hasAny(text, ["ekle", "aktar", "cek", "taslak olustur", "taslak ekle"]) &&
    hasAny(text, ["yazi", "makale", "rehber"])
  ) {
    matches.push("blog_yazisi_taslak_ekle");
  }
  if (text.includes("oner")) {
    matches.push("blog_yazisi_oner");
  }
  if (hasAny(text, ["bul", "ara"])) {
    matches.push("blog_yazisi_bul");
  }

  const unique = [...new Set(matches)];
  const query = queryFrom(text);
  if (unique.length > 1) return { domain: "ambiguous", intent: null, query };
  if (unique.length === 1) return { domain: "blog", intent: unique[0], query };
  return { domain: "storefront", intent: null, query: "" };
}
