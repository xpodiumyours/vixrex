import { EDITABLE_COLUMNS } from "./vitrinFieldSchema";

const PUBLIC_STORE_SYSTEM_COLUMNS = [
  "id",
  "slug",
  "status",
  "marketplace_links",
  "gallery_items",
  "faq_items",
  "about_values",
  "section_visibility",
  "is_published",
  "is_demo",
  "product_storage_version",
  "rating_score",
  "review_count",
] as const;

export const PUBLIC_STORE_SELECT = [
  ...new Set([...PUBLIC_STORE_SYSTEM_COLUMNS, ...EDITABLE_COLUMNS]),
].join(",");

export const PUBLIC_STORE_SELECT_WITH_VERIFICATION =
  `${PUBLIC_STORE_SELECT},business_verified_at`;

/**
 * Keşfet listesi için DAR seçim listesi.
 *
 * `PUBLIC_STORE_SELECT` ~70 kolon taşıyor; tek bir vitrin sayfası için
 * doğru, ama 50 kartlık liste için israf. Kart yalnız aşağıdakileri
 * gösteriyor.
 *
 * `user_id` bu listeye ASLA girmemeli: V-09 (20260818050000) o kolonun
 * SELECT yetkisini authenticated'ten çekti ve PostgreSQL, sorguda geçen
 * her kolon için yetki arar — kolonun varlığı TÜM sorguyu 42501 ile
 * düşürür. Bu hata bu depoda iki kez oldu (20260820210000 Keşfet'i,
 * 20260826000000 sahiplik sorgusunu düşürmüştü).
 */
export const EXPLORE_STORE_SELECT = [
  "id",
  "slug",
  "name",
  "description",
  "address",
  "kategori",
  "business_type",
  "shelf_image_url",
  "logo_url",
  "province_name",
  "district_name",
  "status",
  "is_demo",
  "whatsapp",
  "rating_score",
  "review_count",
  "updated_at",
].join(",");
