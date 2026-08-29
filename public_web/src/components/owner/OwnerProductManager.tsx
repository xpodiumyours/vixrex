"use client";

import Image from "next/image";
import { useState, useCallback, useMemo } from "react";
import BulkProductUpload from "./BulkProductUpload";
import { OwnerCategoryManager } from "./OwnerCategoryManager";

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
  old_price_amount?: number | null;
  badge_tag?: string | null;
  fulfillment_region?: string | null;
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

function parseAmount(raw: string): number | null {
  let cleaned = raw.trim().replaceAll(/[^0-9.,]/g, "");
  if (!cleaned) return null;
  if (cleaned.includes(",") && cleaned.includes(".")) {
    cleaned = cleaned.replaceAll(".", "").replaceAll(",", ".");
  } else if (cleaned.includes(",")) {
    cleaned = cleaned.replaceAll(",", ".");
  }
  const v = Number(cleaned);
  return Number.isFinite(v) ? v : null;
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

  const categoriesWithCount = useMemo(() => {
    const map = new Map<string, number>();
    for (const p of products) {
      const cid = p.category_id;
      if (cid) map.set(cid, (map.get(cid) || 0) + 1);
    }
    return categories.map((c) => ({ ...c, productCount: map.get(c.id) || 0 }));
  }, [categories, products]);

  const [filterText, setFilterText] = useState("");
  const [filterCategory, setFilterCategory] = useState<string>("");

  const filteredProducts = useMemo(() => {
    const q = filterText.trim().toLowerCase();
    return products.filter((p) => {
      if (filterCategory && p.category_id !== filterCategory) return false;
      if (!q) return true;
      return (
        p.name.toLowerCase().includes(q) ||
        (p.description || "").toLowerCase().includes(q) ||
        (p.price_text || "").toLowerCase().includes(q) ||
        (p.badge_tag || "").toLowerCase().includes(q)
      );
    });
  }, [products, filterText, filterCategory]);

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
      oldPriceAmount: form.oldPriceAmount,
      badgeTag: form.badgeTag,
      fulfillmentRegion: form.fulfillmentRegion,
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

  const moveProduct = useCallback(async (fromIndex: number, direction: "up" | "down") => {
    const toIndex = direction === "up" ? fromIndex - 1 : fromIndex + 1;
    if (toIndex < 0 || toIndex >= products.length) return;
    const reordered = [...products];
    const [moved] = reordered.splice(fromIndex, 1);
    reordered.splice(toIndex, 0, moved);
    const newIds = reordered.map((p) => p.id);
    try {
      const response = await fetch("/api/products/reorder", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, productIds: newIds }),
      });
      if (!response.ok) throw new Error("Sıralama güncellenemedi.");
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
          <h2 id="products-title" className="text-xl font-bold text-[var(--owner-text)]">Ürünler</h2>
          <p className="mt-1 text-sm text-[var(--owner-muted)]">Vitrinindeki ürünleri ekle, düzenle veya kaldır.</p>
        </div>
        <div className="flex shrink-0 gap-2">
          <button
            type="button"
            className="owner-button-secondary"
            onClick={() => {
              setError(""); setSuccess(""); setShowBulkUpload(!showBulkUpload); setEditing(null);
            }}
            disabled={busy}
          >
            📄 Toplu Yükle
          </button>
          <button
            type="button"
            className="owner-button-primary"
            onClick={() => {
              setError(""); setSuccess(""); setShowBulkUpload(false); setEditing("new");
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

      <OwnerCategoryManager storeSlug={storeSlug} categories={categoriesWithCount} onRefresh={onRefresh} />

      {/* Arama / filtre — Flutter Explore search + product_management_sheet filter karşılığı */}
      <div className="mt-4 flex flex-col gap-2 sm:flex-row">
        <input
          value={filterText}
          onChange={(e) => setFilterText(e.target.value)}
          placeholder="Ürün ara — ad, açıklama, fiyat, rozet"
          className="owner-input flex-1 text-sm"
        />
        <select
          value={filterCategory}
          onChange={(e) => setFilterCategory(e.target.value)}
          className="owner-input sm:w-48 text-sm"
        >
          <option value="">Tüm kategoriler</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
        {(filterText || filterCategory) && (
          <span className="self-center text-xs text-[var(--owner-muted)]">{filteredProducts.length}/{products.length}</span>
        )}
      </div>

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
          storeSlug={storeSlug}
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
      ) : filteredProducts.length === 0 ? (
        <p className="mt-6 text-center text-sm text-[var(--owner-muted)]">Aramayla eşleşen ürün yok.</p>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filteredProducts.map((product) => {
            const image = product.image_urls?.find((url) => url.trim());
            return (
              <article key={product.id} className="owner-card overflow-hidden">
                <div className="relative aspect-[4/3] bg-[var(--owner-bg-soft)]">
                  {image ? (
                    <Image src={image} alt={`${product.name} ürün görseli`} fill unoptimized sizes="(min-width: 1024px) 300px, (min-width: 640px) 45vw, 100vw" className="object-cover" />
                  ) : (
                    <div className="flex h-full items-center justify-center text-sm text-[var(--owner-muted)]">Görsel eklenmedi</div>
                  )}
                </div>
                <div className="p-4">
                  <div className="flex items-start justify-between gap-3">
                    <h3 className="line-clamp-2 font-bold text-[var(--owner-text)]">{product.name}</h3>
                    <span className="shrink-0 rounded-full border border-[var(--owner-border)] px-2 py-1 text-[11px] text-[var(--owner-text-alt)]">
                      {product.stock_status || "Mevcut"}
                    </span>
                  </div>
                  <p className="mt-2 text-sm font-bold text-[var(--owner-secondary)]">{product.price_text?.trim() || "Fiyat belirtilmedi"}</p>
                  <div className="mt-1 flex flex-wrap gap-1.5">
                    {product.old_price_amount != null && <span className="text-[11px] line-through text-[var(--owner-muted)]">{product.old_price_amount} TL</span>}
                    {product.badge_tag && <span className="rounded bg-blue-500/15 px-1.5 py-0.5 text-[10px] font-bold text-blue-400">{product.badge_tag}</span>}
                    {product.fulfillment_region && <span className="text-[10px] text-[var(--owner-muted)]">• {product.fulfillment_region}</span>}
                  </div>
                  <p className="mt-1 text-xs text-[var(--owner-muted)]">{product.product_categories?.name || "Kategorisiz"}</p>
                  <div className="mt-4 grid grid-cols-3 gap-2">
                    <button type="button" className="owner-button-secondary text-xs" onClick={() => setEditing(product)} disabled={busy}>✏️</button>
                    <button type="button" className="owner-button-danger text-xs" onClick={() => setDeleting(product)} disabled={busy}>🗑️</button>
                    <div className="flex gap-0.5">
                      <button type="button" className="owner-button-secondary flex-1 text-xs" onClick={() => moveProduct(products.indexOf(product), "up")} disabled={busy || !!filterText || !!filterCategory || products.indexOf(product) === 0} title={filterText || filterCategory ? "Filtre varken sıralama kapalı" : "Yukarı taşı"}>↑</button>
                      <button type="button" className="owner-button-secondary flex-1 text-xs" onClick={() => moveProduct(products.indexOf(product), "down")} disabled={busy || !!filterText || !!filterCategory || products.indexOf(product) === products.length - 1} title={filterText || filterCategory ? "Filtre varken sıralama kapalı" : "Aşağı taşı"}>↓</button>
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
              <button type="button" className="owner-button-danger" onClick={deleteProduct} disabled={busy}>{busy ? "Siliniyor…" : "Kalıcı Sil"}</button>
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
  oldPriceAmount: number | null;
  badgeTag: string | null;
  fulfillmentRegion: string | null;
}

interface ProductFormProps {
  product: OwnerProduct | null;
  categories: OwnerProductCategory[];
  busy: boolean;
  storeSlug: string;
  onCancel: () => void;
  onSave: (value: ProductFormValue) => Promise<void>;
}

function ProductForm({ product, categories, busy, storeSlug, onCancel, onSave }: ProductFormProps) {
  const [name, setName] = useState(product?.name || "");
  const [priceText, setPriceText] = useState(product?.price_text || "");
  const [oldPriceText, setOldPriceText] = useState(product?.old_price_amount != null ? String(product.old_price_amount) : "");
  const [badgeTag, setBadgeTag] = useState(product?.badge_tag || "");
  const [fulfillmentRegion, setFulfillmentRegion] = useState(product?.fulfillment_region || "");
  const [description, setDescription] = useState(product?.description || "");
  const [imageUrls, setImageUrls] = useState<string[]>(() => (product?.image_urls || []).filter((u) => u.trim()));
  const [categoryId, setCategoryId] = useState(() => {
    const explicit = product?.category_id?.trim() ?? "";
    if (categories.some((c) => c.id === explicit)) return explicit;
    const label = product?.product_categories?.name?.trim().toLowerCase() ?? "";
    for (const c of categories) if (c.name.trim().toLowerCase() === label) return c.id;
    return categories.length > 0 ? categories[0].id : "";
  });
  const [stockStatus, setStockStatus] = useState(product?.stock_status || "Mevcut");
  const [validation, setValidation] = useState("");
  const [uploading, setUploading] = useState(false);

  async function handleFiles(files: FileList | null) {
    if (!files || files.length === 0) return;
    const remaining = 4 - imageUrls.length;
    if (remaining <= 0) {
      setValidation("Bir ürüne en fazla 4 görsel eklenebilir.");
      return;
    }
    setUploading(true);
    setValidation("");
    const toUpload = Array.from(files).slice(0, remaining);
    const newUrls: string[] = [];
    for (const file of toUpload) {
      if (file.size > 5 * 1024 * 1024) {
        setValidation(`${file.name} çok büyük. En fazla 5 MB.`);
        continue;
      }
      const form = new FormData();
      form.append("slug", storeSlug);
      form.append("productId", product?.id || "new");
      form.append("dosya", file);
      try {
        const res = await fetch("/api/product-image-upload", { method: "POST", body: form });
        const govde = await res.json();
        if (!res.ok) {
          setValidation(govde?.hata ?? "Görsel yüklenemedi.");
          continue;
        }
        if (govde.url) newUrls.push(govde.url);
      } catch {
        setValidation("Bağlantı kurulamadı.");
      }
    }
    if (newUrls.length > 0) setImageUrls((prev) => [...prev, ...newUrls].slice(0, 4));
    setUploading(false);
  }

  function moveImage(index: number, dir: -1 | 1) {
    const to = index + dir;
    if (to < 0 || to >= imageUrls.length) return;
    setImageUrls((prev) => {
      const n = [...prev];
      const [m] = n.splice(index, 1);
      n.splice(to, 0, m);
      return n;
    });
  }

  function submit(event: React.FormEvent) {
    event.preventDefault();
    const cleanName = name.trim();
    if (!cleanName) { setValidation("Ürün adı zorunludur."); return; }
    if (categories.length > 0 && !categoryId) { setValidation("Ürün kategorisi zorunludur."); return; }
    if (imageUrls.length > 4) { setValidation("Bir ürüne en fazla 4 görsel eklenebilir."); return; }
    if (imageUrls.some((url) => !/^https?:\/\//i.test(url))) { setValidation("Görsel bağlantıları http:// veya https:// ile başlamalıdır."); return; }
    const oldPriceAmount = oldPriceText.trim() ? parseAmount(oldPriceText) : null;
    if (oldPriceText.trim() && oldPriceAmount == null) { setValidation("Eski fiyat sayı olmalı."); return; }
    if (badgeTag.trim().length > 20) { setValidation("Rozet en fazla 20 karakter."); return; }

    setValidation("");
    void onSave({
      name: cleanName,
      priceText: priceText.trim(),
      description: description.trim(),
      imageUrls,
      categoryId,
      stockStatus,
      oldPriceAmount,
      badgeTag: badgeTag.trim() || null,
      fulfillmentRegion: fulfillmentRegion.trim() || null,
    });
  }

  const descriptionHelper = (() => {
    const t = description.trim();
    if (!t || t.length >= 40) return null;
    return "Açıklama kısa görünüyor — birkaç cümle eklemek müşteri güvenini ve aramada bulunmayı artırır.";
  })();

  return (
    <form onSubmit={submit} className="owner-card mb-5 p-5 sm:p-6" aria-busy={busy}>
      <h3 className="text-lg font-bold text-[var(--owner-text)]">{product ? "Ürünü Düzenle" : "Yeni Ürün"}</h3>

      {/* Görseller — Flutter'daki _buildImages karşılığı */}
      <div className="mt-4">
        <div className="flex items-center justify-between">
          <span className="text-sm font-bold text-[var(--owner-text)]">Ürün görselleri</span>
          <span className="text-xs text-[var(--owner-muted)]">{imageUrls.length}/4</span>
        </div>
        <div className="mt-2 flex gap-2 overflow-x-auto pb-2">
          {imageUrls.map((url, idx) => (
            <div key={`${url}-${idx}`} className="relative h-24 w-24 shrink-0 overflow-hidden rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg-soft)]">
              <Image src={url} alt={`görsel ${idx + 1}`} fill unoptimized sizes="96px" className="object-cover" />
              <button type="button" onClick={() => setImageUrls((p) => p.filter((_, i) => i !== idx))} className="absolute right-1 top-1 flex h-5 w-5 items-center justify-center rounded-full bg-black/60 text-[10px] text-white">✕</button>
              <div className="absolute bottom-1 left-1 right-1 flex justify-between gap-1">
                <button type="button" onClick={() => moveImage(idx, -1)} disabled={idx === 0} className="flex h-5 w-5 items-center justify-center rounded-full bg-black/60 text-[10px] text-white disabled:opacity-30">‹</button>
                <button type="button" onClick={() => moveImage(idx, 1)} disabled={idx === imageUrls.length - 1} className="flex h-5 w-5 items-center justify-center rounded-full bg-black/60 text-[10px] text-white disabled:opacity-30">›</button>
              </div>
            </div>
          ))}
          {imageUrls.length < 4 && (
            <label className={`flex h-24 w-24 shrink-0 cursor-pointer flex-col items-center justify-center gap-1 rounded-xl border border-dashed border-[var(--owner-border)] bg-[var(--owner-bg-soft)] text-xs text-[var(--owner-muted)] hover:bg-[var(--owner-bg)] ${uploading ? "pointer-events-none opacity-50" : ""}`}>
              <span className="text-lg">{uploading ? "…" : "+"}</span>
              <span className="text-[10px]">{uploading ? "Yükleniyor" : "Görsel ekle"}</span>
              <input type="file" accept="image/jpeg,image/png,image/webp" multiple className="hidden" onChange={(e) => { void handleFiles(e.target.files); e.target.value = ""; }} disabled={busy || uploading} />
            </label>
          )}
        </div>
        <p className="mt-1 text-[11px] text-[var(--owner-muted)]">İlk görsel ürün kapağıdır. Oklarla sıralayabilirsiniz. JPG/PNG/WebP, en fazla 5 MB.</p>
        {/* URL ile ekleme için yedek alan — doğrudan link de yapıştılabilir */}
        <textarea
          value={imageUrls.join("\n")}
          onChange={(e) => setImageUrls(e.target.value.split(/\r?\n/).map((u) => u.trim()).filter(Boolean).slice(0, 4))}
          placeholder="Veya her satıra bir https:// bağlantısı yapıştır"
          rows={2}
          className="owner-input mt-2 min-h-16 resize-y text-xs"
          disabled={busy || uploading}
        />
      </div>

      <div className="mt-5 grid gap-4 sm:grid-cols-2">
        <label className="space-y-2 sm:col-span-2"><span className="owner-label">Ürün adı *</span><input className="owner-input" value={name} onChange={(e) => setName(e.target.value)} maxLength={80} disabled={busy} /></label>
        <label className="space-y-2"><span className="owner-label">Fiyat</span><input className="owner-input" value={priceText} onChange={(e) => setPriceText(e.target.value)} maxLength={30} placeholder="Ör. 499 TL" disabled={busy} /></label>
        <label className="space-y-2"><span className="owner-label">Eski fiyat (üstü çizili)</span><input className="owner-input" value={oldPriceText} onChange={(e) => setOldPriceText(e.target.value)} maxLength={30} placeholder="Ör. 799" disabled={busy} /></label>
        <label className="space-y-2"><span className="owner-label">Rozet</span><input className="owner-input" value={badgeTag} onChange={(e) => setBadgeTag(e.target.value)} maxLength={20} placeholder="Örn. Yeni, -31%" disabled={busy} /></label>
        <label className="space-y-2"><span className="owner-label">Teslim bölgesi</span><input className="owner-input" value={fulfillmentRegion} onChange={(e) => setFulfillmentRegion(e.target.value)} maxLength={80} placeholder="Örn. İstanbul içi" disabled={busy} /></label>
        <label className="space-y-2"><span className="owner-label">Stok durumu</span><select className="owner-input" value={stockStatus} onChange={(e) => setStockStatus(e.target.value)} disabled={busy}>{STOCK_OPTIONS.map((s) => <option key={s}>{s}</option>)}</select></label>
        <label className="space-y-2 sm:col-span-2">
          <span className="owner-label">Kısa açıklama</span>
          <textarea className="owner-input min-h-28 resize-y" value={description} onChange={(e) => setDescription(e.target.value)} maxLength={500} disabled={busy} />
          {descriptionHelper && <span className="block text-xs text-amber-400">{descriptionHelper}</span>}
        </label>
        {categories.length > 0 ? (
          <label className="space-y-2 sm:col-span-2"><span className="owner-label">Kategori *</span><select className="owner-input" value={categoryId} onChange={(e) => setCategoryId(e.target.value)} disabled={busy}><option value="">Kategori seç</option>{categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select></label>
        ) : (
          <p className="text-sm text-[var(--owner-muted)] sm:col-span-2">Bu vitrinde kategori bulunmadığı için ürün kategorisiz kaydedilecek.</p>
        )}
      </div>
      {validation ? <p className="owner-error mt-4 text-sm" role="alert">{validation}</p> : null}
      <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
        <button type="button" className="owner-button-secondary" onClick={onCancel} disabled={busy}>İptal</button>
        <button type="submit" className="owner-button-primary" disabled={busy || uploading}>{busy ? "Kaydediliyor…" : "Ürünü Kaydet"}</button>
      </div>
    </form>
  );
}
