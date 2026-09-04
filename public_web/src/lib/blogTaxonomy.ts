import blogTaxonomyContract from "../../../shared/blog_taxonomy.json";
import {
  BUSINESS_CATEGORIES,
  type BusinessCategoryCore,
  kategoriUrlParcasi,
  kategoriUrlParcasindanCoz,
} from "@/lib/businessCategories";

export type BlogLocationScope = "national" | "province" | "district";

export interface BlogTaxonomyItem {
  id: string;
  label: string;
  description?: string;
}

interface BlogTaxonomyContract {
  topics: BlogTaxonomyItem[];
  purposes: BlogTaxonomyItem[];
  locationScopes: BlogLocationScope[];
  rules: {
    maxTagsPerArticle: number;
    maxTagLength: number;
    maxSectorIdsPerArticle: number;
    maxProvinceCodesPerArticle: number;
  };
}

const contract = blogTaxonomyContract as BlogTaxonomyContract;

function assertUnique(items: readonly BlogTaxonomyItem[], name: string): void {
  const ids = new Set<string>();
  for (const item of items) {
    if (!item.id || !item.label || ids.has(item.id)) {
      throw new Error(`${name} sözleşmesi geçersiz: ${item.id}`);
    }
    ids.add(item.id);
  }
}

assertUnique(contract.topics, "Blog konu");
assertUnique(contract.purposes, "Blog amaç");

export const BLOG_TOPICS = contract.topics;
export const BLOG_PURPOSES = contract.purposes;
export const BLOG_LOCATION_SCOPES = contract.locationScopes;
export const BLOG_TAXONOMY_RULES = contract.rules;

const TOPIC_BY_ID = new Map(BLOG_TOPICS.map((item) => [item.id, item]));
const PURPOSE_BY_ID = new Map(BLOG_PURPOSES.map((item) => [item.id, item]));
const SECTOR_BY_ID = new Map(BUSINESS_CATEGORIES.map((item) => [item.id, item]));

export function blogTopicById(id: string | null | undefined): BlogTaxonomyItem | null {
  if (!id) return null;
  return TOPIC_BY_ID.get(id) ?? null;
}

export function blogPurposeById(id: string | null | undefined): BlogTaxonomyItem | null {
  if (!id) return null;
  return PURPOSE_BY_ID.get(id) ?? null;
}

export function blogSectorById(id: string | null | undefined): BusinessCategoryCore | null {
  if (!id) return null;
  return SECTOR_BY_ID.get(id) ?? null;
}

export function blogSectorUrl(id: string): string {
  return kategoriUrlParcasi(id);
}

export function blogSectorFromUrl(part: string): BusinessCategoryCore | null {
  return kategoriUrlParcasindanCoz(part);
}

export function normalizeBlogTag(raw: string): string {
  return raw
    .trim()
    .toLocaleLowerCase("tr-TR")
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9çğıöşü-]/gi, "")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, BLOG_TAXONOMY_RULES.maxTagLength);
}

export function normalizeBlogTags(values: readonly string[]): string[] {
  const unique = new Set<string>();
  for (const value of values) {
    const normalized = normalizeBlogTag(value);
    if (normalized) unique.add(normalized);
    if (unique.size >= BLOG_TAXONOMY_RULES.maxTagsPerArticle) break;
  }
  return [...unique];
}

export function validBlogTopic(id: string): boolean {
  return TOPIC_BY_ID.has(id);
}

export function validBlogPurpose(id: string): boolean {
  return PURPOSE_BY_ID.has(id);
}

export function validBlogSectorIds(ids: readonly string[]): boolean {
  return ids.length <= BLOG_TAXONOMY_RULES.maxSectorIdsPerArticle && ids.every((id) => SECTOR_BY_ID.has(id));
}
