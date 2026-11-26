const SITEMAP_DISI_SLUGLAR = new Set([
  "aasd-mwj3ln80",
  "sssss-mwpepeiq",
  "dename-mwjm5i7b",
  "drbrme-mwjho6k1",
  "deneri-m-mvlf57cg",
]);

const YASAKLI_KELIMELER = ["test", "deneme", "debug", "demo", "dename"];

const JUNK_SLUGLAR = [
  "asdf",
  "asdfg",
  "qwerty",
  "qwert",
  "zxcv",
  "1234",
  "12345",
  "aasd",
  "sssss",
];

export function isTestOrDenemeStore(store: {
  slug?: string | null;
  name?: string | null;
  is_demo?: boolean | null;
}): boolean {
  if (store.is_demo === true) {
    return false;
  }

  const slug = (store.slug || "").trim().toLowerCase();
  const name = (store.name || "").trim().toLowerCase();

  if (SITEMAP_DISI_SLUGLAR.has(slug)) {
    return true;
  }

  const baseSlug = slug.replace(/-(mw[a-z0-9]+|[a-z0-9]{6,10})$/, "");

  const hedefler = [slug, baseSlug, name];
  for (const hedef of hedefler) {
    for (const kelime of YASAKLI_KELIMELER) {
      if (hedef.includes(kelime)) {
        return true;
      }
    }
  }

  for (const hedef of hedefler) {
    if (/^(.)\1{2,}$/.test(hedef)) {
      return true;
    }
    if (JUNK_SLUGLAR.some((j) => hedef === j || hedef.startsWith(`${j}-`))) {
      return true;
    }
  }

  return false;
}
