"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";

interface GalleryItem {
  id?: string;
  imageUrl: string;
  title?: string;
}

interface Props {
  slug: string;
  items: GalleryItem[];
  onClose: () => void;
}

export function GalleryEditor({ slug, items, onClose }: Props) {
  const router = useRouter();
  const [drafts, setDrafts] = useState<GalleryItem[]>(
    () => (items.length > 0 ? items : [{ imageUrl: "", title: "" }])
  );
  const [kaydediliyor, setKaydediliyor] = useState(false);
  const [yukleniyorIndex, setYukleniyorIndex] = useState<number | null>(null);
  const [mesaj, setMesaj] = useState<string | null>(null);

  const ekle = useCallback(() => {
    setDrafts((prev) => (prev.length >= 12 ? prev : [...prev, { imageUrl: "", title: "" }]));
  }, []);

  const sil = useCallback((index: number) => {
    setDrafts((prev) => {
      const n = prev.filter((_, i) => i !== index);
      return n.length > 0 ? n : [{ imageUrl: "", title: "" }];
    });
  }, []);

  const guncelle = useCallback((index: number, alan: "imageUrl" | "title", deger: string) => {
    setDrafts((prev) => prev.map((d, i) => (i === index ? { ...d, [alan]: deger } : d)));
  }, []);

  const tasima = useCallback((from: number, dir: -1 | 1) => {
    const to = from + dir;
    if (to < 0 || to >= drafts.length) return;
    setDrafts((prev) => {
      const n = [...prev];
      const [m] = n.splice(from, 1);
      n.splice(to, 0, m);
      return n;
    });
  }, [drafts.length]);

  const dosyaYukle = useCallback(async (index: number, file: File) => {
    setYukleniyorIndex(index);
    setMesaj(null);
    try {
      const form = new FormData();
      form.append("slug", slug);
      // owner-upload requires a valid vitrin gorsel anahtari — use logo as proxy
      form.append("anahtar", "logo");
      form.append("dosya", file);
      const up = await fetch("/api/owner-upload", { method: "POST", body: form });
      const govde = await up.json();
      if (!up.ok) {
        setMesaj(govde?.hata ?? "Görsel yüklenemedi.");
        return;
      }
      guncelle(index, "imageUrl", govde.url);
    } catch {
      setMesaj("Bağlantı kurulamadı.");
    } finally {
      setYukleniyorIndex(null);
    }
  }, [slug, guncelle]);

  const kaydet = useCallback(async () => {
    setKaydediliyor(true);
    setMesaj(null);
    const temiz = drafts
      .filter((d) => d.imageUrl.trim())
      .map((d, i) => ({
        id: d.id || `gallery-${Date.now()}-${i}`,
        imageUrl: d.imageUrl.trim(),
        title: d.title?.trim() || "",
      }));
    if (temiz.length > 12) {
      setMesaj("En fazla 12 galeri görseli eklenebilir.");
      setKaydediliyor(false);
      return;
    }
    for (const t of temiz) {
      if (!/^https?:\/\//i.test(t.imageUrl)) {
        setMesaj("Görsel bağlantıları http:// veya https:// ile başlamalı.");
        setKaydediliyor(false);
        return;
      }
    }
    try {
      const res = await fetch("/api/owner-structured-field", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, kolon: "gallery_items", deger: temiz }),
      });
      const govde = await res.json();
      if (!res.ok) {
        setMesaj(govde?.hata ?? "Kaydedilemedi.");
        return;
      }
      router.refresh();
      onClose();
    } catch {
      setMesaj("Bağlantı kurulamadı.");
    } finally {
      setKaydediliyor(false);
    }
  }, [slug, drafts, router, onClose]);

  return (
    <div className="fixed inset-0 z-[90] flex items-end sm:items-center justify-center bg-black/60" onClick={onClose}>
      <div
        className="w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-t-2xl sm:rounded-2xl bg-[#0B1120] border border-white/10 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-white/10 bg-[#0B1120] px-5 py-4">
          <div>
            <h2 className="text-lg font-extrabold text-white">Galeri</h2>
            <p className="text-[11px] text-white/40">En fazla 12 görsel. İlk görsel vitrin kapağına yakın gösterilir.</p>
          </div>
          <button onClick={onClose} className="text-white/40 hover:text-white text-xl">✕</button>
        </div>

        <div className="space-y-4 px-5 py-4">
          {drafts.map((draft, i) => (
            <div key={`${draft.imageUrl}-${i}`} className="rounded-xl bg-white/5 border border-white/10 p-3 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-white/60">Görsel {i + 1}</span>
                <div className="flex items-center gap-1">
                  <button onClick={() => tasima(i, -1)} disabled={i === 0} className="text-[10px] text-white/40 hover:text-white disabled:opacity-20 px-1">↑</button>
                  <button onClick={() => tasima(i, 1)} disabled={i === drafts.length - 1} className="text-[10px] text-white/40 hover:text-white disabled:opacity-20 px-1">↓</button>
                  <button onClick={() => sil(i)} className="ml-1 text-[10px] text-red-400 hover:text-red-300">Sil</button>
                </div>
              </div>
              <div className="flex gap-2">
                <input
                  type="url"
                  value={draft.imageUrl}
                  onChange={(e) => guncelle(i, "imageUrl", e.target.value)}
                  placeholder="https://..."
                  className="flex-1 rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
                />
                <label className={`flex cursor-pointer items-center justify-center rounded-lg border border-dashed border-white/20 bg-white/5 px-3 text-xs font-semibold text-white/60 hover:bg-white/10 ${yukleniyorIndex === i ? "pointer-events-none opacity-50" : ""}`}>
                  {yukleniyorIndex === i ? "…" : "📷"}
                  <input
                    type="file"
                    accept="image/jpeg,image/png,image/webp"
                    className="hidden"
                    onChange={(e) => {
                      const f = e.target.files?.[0];
                      e.target.value = "";
                      if (f) void dosyaYukle(i, f);
                    }}
                  />
                </label>
              </div>
              <input
                type="text"
                value={draft.title || ""}
                onChange={(e) => guncelle(i, "title", e.target.value)}
                placeholder="Etiket (ör. Mağaza vitrini) — isteğe bağlı"
                maxLength={40}
                className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-1.5 text-xs text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
              />
            </div>
          ))}
          <button
            onClick={ekle}
            disabled={drafts.length >= 12}
            className="w-full rounded-xl border border-dashed border-white/20 py-2 text-xs font-semibold text-white/50 hover:text-white/70 hover:border-white/30 transition disabled:opacity-30"
          >
            + Görsel ekle ({drafts.filter(d => d.imageUrl.trim()).length}/12)
          </button>
        </div>

        <div className="sticky bottom-0 border-t border-white/10 bg-[#0B1120] px-5 py-3 flex gap-3">
          <button onClick={onClose} className="flex-1 rounded-xl border border-white/20 py-2.5 text-xs font-bold text-white/60 hover:bg-white/5 transition">İptal</button>
          <button onClick={kaydet} disabled={kaydediliyor} className="flex-1 rounded-xl bg-blue-600 py-2.5 text-xs font-bold text-white hover:bg-blue-500 transition disabled:opacity-50">
            {kaydediliyor ? "Kaydediliyor…" : "Kaydet"}
          </button>
        </div>
        {mesaj && <p className="px-5 pb-3 text-[11px] font-semibold text-red-400">{mesaj}</p>}
      </div>
    </div>
  );
}
