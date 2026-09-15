export function parseProductPriceNumber(value: unknown): number | null {
  if (typeof value !== "string" && typeof value !== "number") return null;
  const raw = String(value).trim();
  if (!raw) return null;

  let cleaned = raw.replace(/[^0-9.,]/g, "");
  if (!cleaned) return null;

  const lastComma = cleaned.lastIndexOf(",");
  const lastDot = cleaned.lastIndexOf(".");

  if (lastComma !== -1 && lastDot !== -1) {
    const decimalSeparator = lastComma > lastDot ? "," : ".";
    const thousandsSeparator = decimalSeparator === "," ? "." : ",";
    cleaned = cleaned.replaceAll(thousandsSeparator, "");
    if (decimalSeparator === ",") cleaned = cleaned.replaceAll(",", ".");
  } else if (lastComma !== -1) {
    cleaned = cleaned.replaceAll(",", ".");
  } else if (/^\d{1,3}(?:\.\d{3})+$/.test(cleaned)) {
    cleaned = cleaned.replaceAll(".", "");
  }

  const amount = Number(cleaned);
  return Number.isFinite(amount) && amount >= 0 ? amount : null;
}

export function parseProductPriceString(value: unknown): string | undefined {
  const amount = parseProductPriceNumber(value);
  return amount == null ? undefined : String(amount);
}
