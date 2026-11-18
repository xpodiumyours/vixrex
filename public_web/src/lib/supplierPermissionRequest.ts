import { supabase } from "@/lib/supabase";

export const SUPPLIER_PERMISSION_TOKEN_RE = /^[0-9a-f]{64}$/i;
export const SUPPLIER_PERMISSION_UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface SupplierPermissionProductPreview {
  id: string;
  name: string;
  slug: string;
  brand: string;
  model: string;
  image_urls: string[];
  permission_status: "bekliyor" | "onaylandi";
}

export interface SupplierPermissionRequestView {
  store_name: string;
  store_slug: string;
  brand: string;
  status: "bekliyor" | "onaylandi" | "reddedildi";
  created_at: string;
  expires_at: string;
  product_count: number;
  line_count: number;
  products: SupplierPermissionProductPreview[];
}

export function sanitizePermissionText(value: unknown): string {
  if (typeof value !== "string") return "";
  return value
    .replace(/\bTR\d{2}[0-9A-Z]{22,24}\b/gi, "")
    .replace(/\b\d{10,11}\b/g, "")
    .replace(/(?:alış|toptan|maliyet|birim\s*fiyat|unit\s*price|purchase\s*price|iskonto|vade|ettn|vkn|tckn)[^,\n;]*/gi, "")
    .replace(/\s+/g, " ")
    .trim();
}

function safeImageUrls(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter((item) => /^https?:\/\//i.test(item));
}

function normalizeStatus(raw: unknown): "bekliyor" | "onaylandi" | "reddedildi" {
  if (raw === "onaylandi" || raw === "reddedildi") return raw;
  return "bekliyor";
}

function normalizeProductPreview(
  raw: unknown,
  fallbackBrand: string,
): SupplierPermissionProductPreview | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const row = raw as Record<string, unknown>;
  const id = typeof row.id === "string" ? row.id.trim() : "";
  const name = sanitizePermissionText(row.name);
  if (!id || !name) return null;
  return {
    id,
    name,
    slug: typeof row.slug === "string" ? row.slug.trim() : "",
    brand: sanitizePermissionText(row.brand) || fallbackBrand,
    model: sanitizePermissionText(row.model),
    image_urls: safeImageUrls(row.image_urls),
    permission_status: row.permission_status === "onaylandi" ? "onaylandi" : "bekliyor",
  };
}

export function normalizeSupplierPermissionPayload(
  raw: unknown,
): SupplierPermissionRequestView | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const obj = raw as Record<string, unknown>;
  const storeName = sanitizePermissionText(obj.store_name);
  const storeSlug = typeof obj.store_slug === "string" ? obj.store_slug.trim() : "";
  const brand = sanitizePermissionText(obj.brand);
  if (!storeName || !storeSlug || !brand) return null;

  const products = Array.isArray(obj.products)
    ? obj.products
        .map((item) => normalizeProductPreview(item, brand))
        .filter((item): item is SupplierPermissionProductPreview => item !== null)
    : [];

  return {
    store_name: storeName,
    store_slug: storeSlug,
    brand,
    status: normalizeStatus(obj.status),
    created_at: typeof obj.created_at === "string" ? obj.created_at : "",
    expires_at: typeof obj.expires_at === "string" ? obj.expires_at : "",
    product_count:
      typeof obj.product_count === "number" && Number.isFinite(obj.product_count)
        ? obj.product_count
        : products.length,
    line_count:
      typeof obj.line_count === "number" && Number.isFinite(obj.line_count)
        ? obj.line_count
        : 0,
    products,
  };
}

export async function fetchSupplierPermissionRequest(
  token: string,
): Promise<SupplierPermissionRequestView | null> {
  const cleanToken = token.trim().toLowerCase();
  if (!SUPPLIER_PERMISSION_TOKEN_RE.test(cleanToken)) return null;
  const { data, error } = await supabase.rpc("get_supplier_permission_request", {
    p_token: cleanToken,
  });
  if (error || !data) return null;
  return normalizeSupplierPermissionPayload(data);
}
