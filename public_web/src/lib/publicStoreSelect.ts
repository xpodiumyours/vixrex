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
