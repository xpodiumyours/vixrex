/**
 * Ürün ayrı kuyruğu — F4 (tek kaynak paritesi)
 *
 * Flutter: lib/services/working_draft/* (draft) vs ProductCatalogSyncService (products) ayrı.
 * Next: draft kuyruğu = /api/owner-draft (store_working_drafts.draft_data)
 *       ürün kuyruğu = burası — localStorage `vixrex_product_queue_v1`, sadece products/product_categories.
 *
 * Neden ayrı ve güvenli:
 * - Draft (metin alanlar, il/ilçe, logo) ile ürün (image_urls, category_id, stock_status) farklı tablo/RLS/transaction.
 * - Tek kuyrukta ürün image upload’u (5 MB, sıkıştırma) takılsa vitrin metinleri de bloklanır.
 * - Ayrı kuyruk = vitrin kaydedildi mesajı hemen, ürün “kuyrukta, bağlantı gelince” ayrı mesaj — debug net.
 *
 * Kullanım: OwnerProductManager save/delete/reorder fetch’i network hatasında enqueue eder,
 *           navigator.onLine + visibilitychange’da flushProductQueue dener.
 */

const STORAGE_KEY = "vixrex_product_queue_v1";
const MAX_OPS = 50;

export type ProductQueueOp = {
  id: string;
  slug: string;
  type: "create" | "update" | "delete" | "reorder";
  payload: Record<string, unknown>;
  createdAt: number;
  attempts: number;
};

function safeParse(value: string | null): ProductQueueOp[] {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? (parsed as ProductQueueOp[]) : [];
  } catch {
    return [];
  }
}

export function productQueueRead(): ProductQueueOp[] {
  if (typeof window === "undefined" || typeof localStorage === "undefined") return [];
  return safeParse(localStorage.getItem(STORAGE_KEY));
}

export function productQueueWrite(ops: ProductQueueOp[]): void {
  if (typeof window === "undefined" || typeof localStorage === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(ops.slice(0, MAX_OPS)));
  } catch {
    // quota doluysa sessizce atla — ürün kaybı draft’ı etkilemez
  }
}

export function productQueueEnqueue(op: Omit<ProductQueueOp, "id" | "createdAt" | "attempts">): ProductQueueOp {
  const entry: ProductQueueOp = {
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    createdAt: Date.now(),
    attempts: 0,
    ...op,
  };
  const current = productQueueRead();
  current.push(entry);
  productQueueWrite(current);
  return entry;
}

export function productQueueDequeue(id: string): void {
  const current = productQueueRead();
  productQueueWrite(current.filter((op) => op.id !== id));
}

export function productQueueClear(slug?: string): void {
  if (!slug) {
    productQueueWrite([]);
    return;
  }
  productQueueWrite(productQueueRead().filter((op) => op.slug !== slug));
}

export function productQueueCount(slug?: string): number {
  const all = productQueueRead();
  return slug ? all.filter((op) => op.slug === slug).length : all.length;
}

/**
 * Kuyruğu sırayla dener — her op için verilen `executor` çağrılır.
 * Başarılı → dequeue, başarısız → attempts++ ve bırak (max 3 denemede at).
 * Network yoksa hiç denemez.
 */
export async function productQueueFlush(
  executor: (op: ProductQueueOp) => Promise<boolean>,
  slug?: string,
): Promise<{ flushed: number; remaining: number }> {
  if (typeof navigator !== "undefined" && !navigator.onLine) {
    return { flushed: 0, remaining: productQueueCount(slug) };
  }
  const ops = productQueueRead().filter((op) => !slug || op.slug === slug);
  let flushed = 0;
  for (const op of ops) {
    try {
      const ok = await executor(op);
      if (ok) {
        productQueueDequeue(op.id);
        flushed++;
      } else {
        // attempts artır
        const all = productQueueRead();
        const idx = all.findIndex((x) => x.id === op.id);
        if (idx >= 0) {
          all[idx].attempts++;
          if (all[idx].attempts >= 3) all.splice(idx, 1);
          productQueueWrite(all);
        }
      }
    } catch {
      // network hatası — bir sonrakini denemeden dur
      break;
    }
  }
  return { flushed, remaining: productQueueCount(slug) };
}

// Draft kuyruğundan ayrı olduğunu kanıtlamak için draft anahtarını export etme — testler bunu kontrol eder
export const PRODUCT_QUEUE_STORAGE_KEY = STORAGE_KEY;
// Draft kuyruğu (varsa) farklı anahtar kullanmalı — `vixrex_` prefix’i paylaşır ama suffix’i farklı
export const DRAFT_QUEUE_KEY_HINT = "vixrex_working_draft";
