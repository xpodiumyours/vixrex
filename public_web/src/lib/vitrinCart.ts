export interface VitrinCartItem {
  productSlug: string;
  productName: string;
  variantKey: string;
  variantText: string;
  priceText: string;
  imageUrl: string | null;
  quantity: number;
}

export interface VitrinCartState {
  version: 1;
  items: VitrinCartItem[];
  updatedAt: string;
}

export const VITRIN_CART_EVENT = "vixrex-cart-changed";
const CART_PREFIX = "vixrex_cart:";

function cleanText(value: unknown, max = 180): string {
  return String(value ?? "").trim().slice(0, max);
}

function clampQuantity(value: unknown): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return 1;
  return Math.max(1, Math.min(999, Math.round(parsed)));
}

export function cartItemKey(item: Pick<VitrinCartItem, "productSlug" | "variantKey">) {
  return `${cleanText(item.productSlug, 120)}::${cleanText(item.variantKey, 180)}`;
}

export function normalizeCartItem(item: VitrinCartItem): VitrinCartItem {
  return {
    productSlug: cleanText(item.productSlug, 120),
    productName: cleanText(item.productName, 180),
    variantKey: cleanText(item.variantKey, 180),
    variantText: cleanText(item.variantText, 180),
    priceText: cleanText(item.priceText, 80),
    imageUrl: item.imageUrl ? cleanText(item.imageUrl, 500) : null,
    quantity: clampQuantity(item.quantity),
  };
}

export function mergeCartItem(
  items: VitrinCartItem[],
  incoming: VitrinCartItem,
): VitrinCartItem[] {
  const normalized = normalizeCartItem(incoming);
  const key = cartItemKey(normalized);
  const index = items.findIndex((item) => cartItemKey(item) === key);
  if (index < 0) return [...items, normalized];

  return items.map((item, itemIndex) =>
    itemIndex === index
      ? { ...item, quantity: clampQuantity(item.quantity + normalized.quantity) }
      : item,
  );
}

function storageKey(storeSlug: string) {
  return `${CART_PREFIX}${cleanText(storeSlug, 120)}`;
}

function emptyState(): VitrinCartState {
  return { version: 1, items: [], updatedAt: new Date(0).toISOString() };
}

export function readVitrinCart(storeSlug: string): VitrinCartState {
  if (typeof window === "undefined") return emptyState();
  try {
    const raw = window.localStorage.getItem(storageKey(storeSlug));
    if (!raw) return emptyState();
    const parsed = JSON.parse(raw) as Partial<VitrinCartState>;
    const items = Array.isArray(parsed.items)
      ? parsed.items
          .map((item) => normalizeCartItem(item as VitrinCartItem))
          .filter((item) => item.productSlug && item.productName)
      : [];
    return {
      version: 1,
      items,
      updatedAt: typeof parsed.updatedAt === "string" ? parsed.updatedAt : new Date().toISOString(),
    };
  } catch {
    return emptyState();
  }
}

function writeVitrinCart(storeSlug: string, items: VitrinCartItem[]) {
  if (typeof window === "undefined") return;
  const state: VitrinCartState = {
    version: 1,
    items,
    updatedAt: new Date().toISOString(),
  };
  try {
    window.localStorage.setItem(storageKey(storeSlug), JSON.stringify(state));
  } catch {
    // Depolama engelliyse alışveriş akışını çökertme.
  }
  window.dispatchEvent(
    new CustomEvent(VITRIN_CART_EVENT, { detail: { storeSlug: cleanText(storeSlug, 120) } }),
  );
}

export function addToVitrinCart(storeSlug: string, item: VitrinCartItem) {
  const current = readVitrinCart(storeSlug);
  const items = mergeCartItem(current.items, item);
  writeVitrinCart(storeSlug, items);
  return items;
}

export function setVitrinCartQuantity(
  storeSlug: string,
  productSlug: string,
  variantKey: string,
  quantity: number,
) {
  const key = cartItemKey({ productSlug, variantKey });
  const current = readVitrinCart(storeSlug);
  const items = current.items.map((item) =>
    cartItemKey(item) === key ? { ...item, quantity: clampQuantity(quantity) } : item,
  );
  writeVitrinCart(storeSlug, items);
  return items;
}

export function removeFromVitrinCart(
  storeSlug: string,
  productSlug: string,
  variantKey: string,
) {
  const key = cartItemKey({ productSlug, variantKey });
  const current = readVitrinCart(storeSlug);
  const items = current.items.filter((item) => cartItemKey(item) !== key);
  writeVitrinCart(storeSlug, items);
  return items;
}

export function clearVitrinCart(storeSlug: string) {
  writeVitrinCart(storeSlug, []);
}

export function cartTotalQuantity(items: VitrinCartItem[]) {
  return items.reduce((sum, item) => sum + clampQuantity(item.quantity), 0);
}

export function buildWhatsappOrderUrl(
  baseUrl: string | null | undefined,
  storeName: string,
  items: VitrinCartItem[],
): string | null {
  if (!baseUrl || items.length === 0) return null;

  const lines = items.map((item) => {
    const variant = item.variantText ? ` — ${item.variantText}` : "";
    const price = item.priceText ? ` — ${item.priceText}` : "";
    return `• ${clampQuantity(item.quantity)} × ${cleanText(item.productName, 180)}${variant}${price}`;
  });

  const message = [
    `Merhaba, ${cleanText(storeName, 120)} vitrininizden sipariş vermek istiyorum:`,
    "",
    ...lines,
    "",
    `Toplam ürün adedi: ${cartTotalQuantity(items)}`,
    "Uygunluk ve teslimat bilgisini paylaşabilir misiniz?",
  ].join("\n");

  try {
    const parsed = new URL(baseUrl);
    parsed.searchParams.set("text", message);
    return parsed.toString();
  } catch {
    const separator = baseUrl.includes("?") ? "&" : "?";
    return `${baseUrl}${separator}text=${encodeURIComponent(message)}`;
  }
}
