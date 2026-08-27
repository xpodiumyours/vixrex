"use client";

import Image from "next/image";
import { useState, useCallback } from "react";
import BulkProductUpload from "./BulkProductUpload";

export interface OwnerProductCategory {
  id: string;
  name: string;
}

export interface OwnerProduct {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  price_text: string | null;
  image_urls: string[] | null;
  category_id: string | null;
  stock_status: string | null;
  product_categories?: { name?: string | null } | null;
}

interface OwnerProductManagerProps {
  storeSlug: string;
  products: OwnerProduct[];
  categories: OwnerProductCategory[];
  onRefresh: () => Promise<void>;
}

const STOCK_OPTIONS = ["Mevcut", "Tükendi", "Son birkaç adet"] as const;

function responseError(payload: unknown, fallback: string) {
  if (payload && typeof payload === "object" && "hata" in payload) {
    const message = (payload as { hata?: unknown }).hata;
    if (typeof message === "string" && message.trim()) return message;
  }
  return fallback;
}

export function OwnerProductManager({
  storeSlug,
  products,
  categories,
  onRefresh,
}: OwnerProductManagerProps) {
  const [editing, setEditing] = useState<OwnerProduct | "new" | null>(null);
  const [deleting, setDeleting] = useState<OwnerProduct | null>(null);
  const [showBulkUpload, setShowBulkUpload] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function saveProduct(form: ProductFormValue) {
    setBusy(true);
    setError("");
    setSuccess("");

    const isNew = editing === "new";
    const body = {
      slug: storeSlug,
      name: form.name,
      description: form.description,
      priceText: form.priceText,
      imageUrls: form.imageUrls,
      categoryId: form.categoryId,
      stockStatus: form.stockStatus,
      ...(!isNew && editing ? { productId: editing.id } : {}),
    };

    try {
      const response = await fetch("/api/products", {
        method: isNew ? "POST" : "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const payload = await response.json().catch(() => null);
      if (!response.ok) {
        throw new Error(responseError(payload, isNew ? "Ürün oluşturulamadı." : "Ürün güncellenemedi."));
      }

      // POST mevcut RPC sözleşmesinde stok durumu taşımıyor. Ürün kimliği
      // döndükten sonra hazır PATCH yolu ile seçilen Flutter stok değeri yazılır.
      if (isNew && payload?.id && form.stockStatus !== "Mevcut") {
        const stockResponse = await fetch("/api/products", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ...body, productId: payload.id }),
        });
        if (!stockResponse.ok) {
          throw new Error("Ürün oluşturuldu ancak stok durumu kaydedilemedi. Ürünü yeniden düzenle.");
        }
      }

      await onRefresh();
      setEditing(null);
      setSuccess(isNew ? "Ürün kaydedildi." : "Ürün güncellendi.");
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : "Ürün kaydedilemedi.");
    } finally {
      setBusy(false);
    }
  }

  async function deleteProduct() {
    if (!deleting) return;
    setBusy(true);
    setError("");
    setSuccess("");
    try {
      const response = await fetch("/api/products", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, productId: deleting.id }),
      });
      const payload = await response.json().catch(() => null);
      if (!response.ok) {
        throw new Error(responseError(payload, "Ürün silinemedi. Lütfen tekrar dene."));
      }
      await onRefresh();
      setDeleting(null);
      setSuccess("Ürün kalıcı olarak silindi.");
    } catch (deleteError) {
      setError(deleteError instanceof Error ? deleteError.message : "Ürün silinemedi.");
    } finally {
      setBusy(false);
    }
  }

  // ─── Sıralama ─────────────────────────────────────────────────────

  const moveProduct = useCallback(async (fromIndex: number, direction: "up" | "down") => {
    const toIndex = direction === "up" ? fromIndex - 1 : fromIndex + 1;
    if (toIndex < 0 || toIndex >= products.length) return;

    // Yeni sıralama oluştur
    const reordered = [...products];
    const [moved] = reordered.splice(fromIndex, 1);
    reordered.splice(toIndex, 0, moved);

    // Optimistic update
    const newIds = reordered.map((p) => p.id);

    try {
      const response = await fetch("/api/products/reorder", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, productIds: newIds }),
      });
      if (!response.ok) {
        throw new Error("Sıralama güncellenemedi.");
      }
      await onRefresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sıralama güncellenemedi.");
      await onRefresh();
    }
  }, [products, storeSlug, onRefresh]);

  return (
    <section className="mt-8" aria-labelledby="products-title" aria-busy={busy}>
      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 id="products-title" className="text-xl font-bold text-[var(--owner-text)]">
            Ürünler
          </h2>
          <p className="mt-1 text-sm text-[var(--owner-muted)]">
            Vitrinindeki ürünleri ekle, düzenle veya kaldır.
          </p>
        </div>
        <div className="flex shrink-0 gap-2">
          <button
            type="button"
            className="owner-button-secondary"
            onClick={() => {
              setError("");
              setSuccess("");
              setShowBulkUpload(!showBulkUpload);
              setEditing(null);
            }}
            disabled={busy}
          >
            📄 Toplu Yükle
          </button>
          <button
            type="button"
            className="owner-button-primary"
            onClick={() => {
              setError("");
              setSuccess("");
              setShowBulkUpload(false);
              setEditing("new");
            }}
            disabled={busy}
          >
            + Ürün Ekle
          </button>
        </div>
      </div>

      {error ? <p className="owner-error mb-4 text-sm" role="alert">{error}</p> : null}
      {success ? (
        <p className="mb-4 rounded-xl border border-[var(--owner-success)]/40 bg-[var(--owner-success)]/10 p-3 text-sm text-[var(--owner-success)]" role="status">
          {success}
        </p>
      ) : null}

      {/* Toplu Yükleme */}
      {showBulkUpload && !editing && (
        <BulkProductUpload
          storeSlug={storeSlug}
          categories={categories}
          onUploaded={async () => {
            await onRefresh();
            setShowBulkUpload(false);
            setSuccess("Ürünler toplu olarak eklendi.");
          }}
        />
      )}

      {editing ? (
        <ProductForm
          key={editing === "new" ? "new" : editing.id}
          product={editing === "new" ? null : editing}
          categories={categories}
          busy={busy}
          onCancel={() => setEditing(null)}
          onSave={saveProduct}
        />
      ) : products.length === 0 ? (
        <div className="owner-card px-5 py-10 text-center sm:px-8">
          <h3 className="font-bold text-[var(--owner-text)]">Henüz ürün yok</h3>
          <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-[var(--owner-muted)]">
            İlk ürününü ekleyerek vitrininin kataloğunu oluşturmaya başla.
          </p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {products.map((product) => {
            const image = product.image_urls?.find((url) => url.trim());
            return (
              <article key={product.id} className="owner-card overflow-hidden">
                <div className="relative aspect-[4/3] bg-[var(--owner-bg-soft)]">
                  {image ? (
                    <Image
                      src={image}
                      alt={`${product.name} ürün görseli`}
                      fill
                      unoptimized
                      sizes="(min-width: 1024px) 300px, (min-width: 640px) 45vw, 100vw"
                      className="object-cover"
                    />
                  ) : (
                    <div className="flex h-full items-center justify-center text-sm text-[var(--owner-muted)]">
                      Görsel eklenmedi
                    </div>
                  )}
                </div>
                <div className="p-4">
                  <div className="flex items-start justify-between gap-3">
                    <h3 className="line-clamp-2 font-bold text-[var(--owner-text)]">{product.name}</h3>
                    <span className="shrink-0 rounded-full border border-[var(--owner-border)] px-2 py-1 text-[11px] text-[var(--owner-text-alt)]">
                      {product.stock_status || "Mevcut"}
                    </span>
                  </div>
                  <p className="mt-2 text-sm font-bold text-[var(--owner-secondary)]">
                    {product.price_text?.trim() || "Fiyat belirtilmedi"}
                  </p>
                  <p className="mt-1 text-xs text-[var(--owner-muted)]">
                    {product.product_categories?.name || "Kategorisiz"}
                  </p>
                  <div className="mt-4 grid grid-cols-3 gap-2">
                    <button type="button" className="owner-button-secondary text-xs" onClick={() => setEditing(product)} disabled={busy}>
                      ✏️
                    </button>
                    <button type="button" className="owner-button-danger text-xs" onClick={() => setDeleting(product)} disabled={busy}>
                      🗑️
                    </button>
                    <div className="flex gap-0.5">
                      <button
                        type="button"
                        className="owner-button-secondary flex-1 text-xs"
                        onClick={() => moveProduct(products.indexOf(product), "up")}
                        disabled={busy || products.indexOf(product) === 0}
                        title="Yukarı taşı"
                      >
                        ↑
                      </button>
                      <button
                        type="button"
                        className="owner-button-secondary flex-1 text-xs"
                        onClick={() => moveProduct(products.indexOf(product), "down")}
                        disabled={busy || products.indexOf(product) === products.length - 1}
                        title="Aşağı taşı"
                      >
                        ↓
                      </button>
                    </div>
                  </div>
                </div>
              </article>
            );
          })}
        </div>
      )}

      {deleting ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/70 p-4 sm:items-center" role="presentation">
          <div className="owner-card w-full max-w-md p-5 sm:p-6" role="dialog" aria-modal="true" aria-labelledby="delete-product-title">
            <h2 id="delete-product-title" className="text-xl font-bold text-[var(--owner-text)]">Ürünü Sil</h2>
            <p className="mt-3 text-sm leading-6 text-[var(--owner-text-alt)]">
              <strong>{deleting.name}</strong> kalıcı olarak silinecek. Bu işlem geri alınamaz.
            </p>
            <div className="mt-6 grid grid-cols-2 gap-3">
              <button type="button" className="owner-button-secondary" onClick={() => setDeleting(null)} disabled={busy}>Vazgeç</button>
              <button type="button" className="owner-button-danger" onClick={deleteProduct} disabled={busy}>
                {busy ? "Siliniyor…" : "Kalıcı Sil"}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}

interface ProductFormValue {
  name: string;
  priceText: string;
  description: string;
  imageUrls: string[];
  categoryId: string;
  stockStatus: string;
}

interface ProductFormProps {
  product: OwnerProduct | null;
  categories: OwnerProductCategory[];
  busy: boolean;
  onCancel: () => void;
  onSave: (value: ProductFormValue) => Promise<void>;
}

function ProductForm({ product, categories, busy, onCancel, onSave }: ProductFormProps) {
  const [name, setName] = useState(product?.name || "");
  const [priceText, setPriceText] = useState(product?.price_text || "");
  const [description, setDescription] = useState(product?.description || "");
  const [imageText, setImageText] = useState((product?.image_urls || []).join("\n"));
  const [categoryId, setCategoryId] = useState(product?.category_id || "");
  const [stockStatus, setStockStatus] = useState(product?.stock_status || "Mevcut");
  const [validation, setValidation] = useState("");

  function submit(event: React.FormEvent) {
    event.preventDefault();
    const cleanName = name.trim();
    if (!cleanName) {
      setValidation("Ürün adı zorunludur.");
      return;
    }
    if (categories.length > 0 && !categoryId) {
      setValidation("Ürün kategorisi zorunludur.");
      return;
    }
    const imageUrls = imageText.split(/\r?\n/).map((url) => url.trim()).filter(Boolean);
    if (imageUrls.length > 4) {
      setValidation("Bir ürüne en fazla 4 görsel eklenebilir.");
      return;
    }
    if (imageUrls.some((url) => !/^https?:\/\//i.test(url))) {
      setValidation("Görsel bağlantıları http:// veya https:// ile başlamalıdır.");
      return;
    }
    setValidation("");
    void onSave({ name: cleanName, priceText: priceText.trim(), description: description.trim(), imageUrls, categoryId, stockStatus });
  }

  return (
    <form onSubmit={submit} className="owner-card mb-5 p-5 sm:p-6" aria-busy={busy}>
      <h3 className="text-lg font-bold text-[var(--owner-text)]">{product ? "Ürünü Düzenle" : "Yeni Ürün"}</h3>
      <div className="mt-5 grid gap-4 sm:grid-cols-2">
        <label className="space-y-2 sm:col-span-2"><span className="owner-label">Ürün adı *</span><input className="owner-input" value={name} onChange={(event) => setName(event.target.value)} maxLength={80} disabled={busy} /></label>
        <label className="space-y-2"><span className="owner-label">Fiyat</span><input className="owner-input" value={priceText} onChange={(event) => setPriceText(event.target.value)} maxLength={30} placeholder="Ör. 499 TL" disabled={busy} /></label>
        <label className="space-y-2"><span className="owner-label">Stok durumu</span><select className="owner-input" value={stockStatus} onChange={(event) => setStockStatus(event.target.value)} disabled={busy}>{STOCK_OPTIONS.map((status) => <option key={status}>{status}</option>)}</select></label>
        <label className="space-y-2 sm:col-span-2"><span className="owner-label">Kısa açıklama</span><textarea className="owner-input min-h-28 resize-y" value={description} onChange={(event) => setDescription(event.target.value)} maxLength={500} disabled={busy} /></label>
        <label className="space-y-2 sm:col-span-2"><span className="owner-label">Ürün görselleri</span><textarea className="owner-input min-h-24 resize-y" value={imageText} onChange={(event) => setImageText(event.target.value)} placeholder="Her satıra bir görsel bağlantısı" disabled={busy} /><span className="block text-xs text-[var(--owner-muted)]">En fazla 4 görsel bağlantısı.</span></label>
        {categories.length > 0 ? <label className="space-y-2 sm:col-span-2"><span className="owner-label">Kategori *</span><select className="owner-input" value={categoryId} onChange={(event) => setCategoryId(event.target.value)} disabled={busy}><option value="">Kategori seç</option>{categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}</select></label> : <p className="text-sm text-[var(--owner-muted)] sm:col-span-2">Bu vitrinde kategori bulunmadığı için ürün kategorisiz kaydedilecek.</p>}
      </div>
      {validation ? <p className="owner-error mt-4 text-sm" role="alert">{validation}</p> : null}
      <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
        <button type="button" className="owner-button-secondary" onClick={onCancel} disabled={busy}>İptal</button>
        <button type="submit" className="owner-button-primary" disabled={busy}>{busy ? "Kaydediliyor…" : "Ürünü Kaydet"}</button>
      </div>
    </form>
  );
}
