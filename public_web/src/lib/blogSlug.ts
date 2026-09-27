export function blogSlugUret(title: string): string {
  return title
    .toLowerCase()
    .replace(
      /[çğıöşü]/g,
      (c) => ({ ç: "c", ğ: "g", ı: "i", ö: "o", ş: "s", ü: "u" })[c] ?? c
    )
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 60);
}
