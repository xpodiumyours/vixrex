import type { ProductItem } from "@/lib/products";

export interface RichProductItem extends ProductItem {
  priceAmount?: number | null;
  currency?: string;
  stockQuantity?: number | null;
  brand?: string | null;
  barcode?: string | null;
  metadata?: unknown;
  variants?: unknown;
  seoTitle?: string | null;
  seoDescription?: string | null;
}
