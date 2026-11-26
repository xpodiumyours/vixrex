const TEST_STORE_PATTERN = /(test|deneme|aasd|sssss|dename|-mw[a-z0-9]{6,})/i;

export type TestStoreFilterInput = {
  name?: string | null;
  slug?: string | null;
  is_demo?: boolean | null;
};

export function isTestOrDenemeStore(store: TestStoreFilterInput): boolean {
  if (store.is_demo === true) return false;
  const name = (store.name ?? "").trim();
  const slug = (store.slug ?? "").trim();
  return TEST_STORE_PATTERN.test(name) || TEST_STORE_PATTERN.test(slug);
}
