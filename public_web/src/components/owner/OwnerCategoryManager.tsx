"use client";

import { useState, useCallback } from "react";

export interface OwnerCat {
  id: string;
  name: string;
  productCount?: number;
}

interface Props {
  storeSlug: string;
  categories: OwnerCat[];
  onRefresh: () => Promise<void>;
}

export function OwnerCategoryManager({ storeSlug, categories, onRefresh }: Props) {
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [newName, setNewName] = useState("");
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editName, setEditName] = useState("");
  const [deletingCat, setDeletingCat] = useState<OwnerCat | null>(null);
  const [replacementId, setReplacementId] = useState("");

  const refresh = useCallback(async () => {
    await onRefresh();
  }, [onRefresh]);

  async function addCategory() {
    const name = newName.trim();
    if (!name) { setError("Kategori adı zorunludur."); return; }
    setBusy(true); setError("");
    try {
      const res = await fetch("/api/product-categories", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, name }),
      });
      const govde = await res.json();
      if (!res.ok) throw new Error(govde?.hata || "Oluşturulamadı.");
      setNewName("");
      await refresh();
    } catch (e) { setError(e instanceof Error ? e.message : "Hata"); }
    finally { setBusy(false); }
  }

  async function renameCategory() {
    if (!editingId) return;
    const name = editName.trim();
    if (!name) { setError("Kategori adı zorunludur."); return; }
    setBusy(true); setError("");
    try {
      const res = await fetch("/api/product-categories", {
        method: "PATCH", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, categoryId: editingId, name }),
      });
      const govde = await res.json();
      if (!res.ok) throw new Error(govde?.hata || "Güncellenemedi.");
      setEditingId(null); setEditName("");
      await refresh();
    } catch (e) { setError(e instanceof Error ? e.message : "Hata"); }
    finally { setBusy(false); }
  }

  async function deleteCategory() {
    if (!deletingCat) return;
    setBusy(true); setError("");
    try {
      const replacements = categories.filter((c) => c.id !== deletingCat.id);
      const rep = replacementId || replacements[0]?.id || "";
      const res = await fetch("/api/product-categories", {
        method: "DELETE", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, categoryId: deletingCat.id, replacementId: rep }),
      });
      const govde = await res.json();
      if (!res.ok) throw new Error(govde?.hata || "Silinemedi.");
      setDeletingCat(null); setReplacementId("");
      await refresh();
    } catch (e) { setError(e instanceof Error ? e.message : "Hata"); }
    finally { setBusy(false); }
  }

  async function move(index: number, dir: -1 | 1) {
    const to = index + dir;
    if (to < 0 || to >= categories.length) return;
    const reordered = [...categories];
    const [m] = reordered.splice(index, 1);
    reordered.splice(to, 0, m);
    setBusy(true);
    try {
      const res = await fetch("/api/product-categories", {
        method: "PATCH", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, categoryIds: reordered.map((c) => c.id) }),
      });
      if (!res.ok) throw new Error("Sıralama güncellenemedi.");
      await refresh();
    } catch (e) { setError(e instanceof Error ? e.message : "Hata"); }
    finally { setBusy(false); }
  }

  if (!open) {
    return (
      <button type="button" onClick={() => setOpen(true)} className="owner-button-secondary text-xs">
        🏷️ Kategoriler ({categories.length})
      </button>
    );
  }

  return (
    <div className="owner-card p-4 sm:p-5 mt-3">
      <div className="flex items-center justify-between">
        <h3 className="font-bold text-[var(--owner-text)]">Ürün Kategorileri</h3>
        <button onClick={() => setOpen(false)} className="text-sm text-[var(--owner-muted)]">✕</button>
      </div>
      {error && <p className="owner-error mt-3 text-sm" role="alert">{error}</p>}
      <div className="mt-4 flex gap-2">
        <input value={newName} onChange={(e) => setNewName(e.target.value)} placeholder="Yeni kategori adı" maxLength={40} className="owner-input flex-1 text-sm" disabled={busy} />
        <button onClick={addCategory} disabled={busy || !newName.trim()} className="owner-button-primary text-xs disabled:opacity-50">Ekle</button>
      </div>

      <div className="mt-4 space-y-2">
        {categories.map((cat, idx) => (
          <div key={cat.id} className="flex items-center gap-2 rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg-soft)] px-3 py-2">
            <span className="text-xs text-[var(--owner-muted)]">↕</span>
            <div className="flex-1 min-w-0">
              {editingId === cat.id ? (
                <input value={editName} onChange={(e) => setEditName(e.target.value)} maxLength={40} className="owner-input text-xs py-1" autoFocus />
              ) : (
                <>
                  <p className="text-sm font-bold text-[var(--owner-text)] truncate">{cat.name}</p>
                  <p className="text-[11px] text-[var(--owner-muted)]">{cat.productCount ?? 0} ürün</p>
                </>
              )}
            </div>
            <div className="flex items-center gap-1 shrink-0">
              <button onClick={() => move(idx, -1)} disabled={idx===0||busy} className="owner-button-secondary px-1.5 py-1 text-[10px] disabled:opacity-30">↑</button>
              <button onClick={() => move(idx, 1)} disabled={idx===categories.length-1||busy} className="owner-button-secondary px-1.5 py-1 text-[10px] disabled:opacity-30">↓</button>
              {editingId === cat.id ? (
                <>
                  <button onClick={renameCategory} disabled={busy} className="owner-button-primary px-2 py-1 text-[10px]">Kaydet</button>
                  <button onClick={() => setEditingId(null)} className="owner-button-secondary px-2 py-1 text-[10px]">Vazgeç</button>
                </>
              ) : (
                <>
                  <button onClick={() => { setEditingId(cat.id); setEditName(cat.name); }} className="owner-button-secondary px-2 py-1 text-[10px]">✏️</button>
                  <button onClick={() => { setDeletingCat(cat); setReplacementId(categories.find((c)=>c.id!==cat.id)?.id || ""); }} disabled={categories.length<=1} className="owner-button-danger px-2 py-1 text-[10px] disabled:opacity-30">🗑️</button>
                </>
              )}
            </div>
          </div>
        ))}
      </div>

      {deletingCat && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" onClick={() => setDeletingCat(null)}>
          <div className="owner-card w-full max-w-sm p-5" onClick={(e)=>e.stopPropagation()} role="dialog" aria-modal="true">
            <h4 className="font-bold text-[var(--owner-text)]">Kategoriyi Sil</h4>
            <p className="mt-2 text-sm text-[var(--owner-text-alt)]">
              {deletingCat.name} silinecek. İçindeki ürünler başka kategoriye taşınacak.
            </p>
            {categories.filter((c)=>c.id!==deletingCat.id).length>0 && (
              <label className="mt-3 block space-y-1">
                <span className="text-xs font-bold text-[var(--owner-text)]">Taşınacak kategori</span>
                <select value={replacementId} onChange={(e)=>setReplacementId(e.target.value)} className="owner-input text-sm">
                  {categories.filter((c)=>c.id!==deletingCat.id).map((c)=><option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </label>
            )}
            <div className="mt-4 grid grid-cols-2 gap-2">
              <button onClick={()=>setDeletingCat(null)} className="owner-button-secondary">Vazgeç</button>
              <button onClick={deleteCategory} disabled={busy} className="owner-button-danger">{busy ? "Siliniyor…" : "Sil ve Taşı"}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
