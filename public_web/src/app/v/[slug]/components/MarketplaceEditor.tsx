"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";

const PLATFORM_OPTIONS = [
  "Trendyol",
  "Hepsiburada",
  "N11",
  "Amazon",
  "Çiçeksepeti",
  "Shopier",
  "Google İşletme",
  "Diğer",
  "Özel...",
] as const;

interface MarketplaceLink {
  id: string;
  platform: string;
  url: string;
  subtitle?: string;
}

interface Props {
  slug: string;
  links: MarketplaceLink[];
  onClose: () => void;
  inline?: boolean;
}

export function MarketplaceEditor({ slug, links, onClose, inline = false }: Props) {
  const router = useRouter();
  const [drafts, setDrafts] = useState<MarketplaceLink[]>(
    () => (links.length > 0 ? links : [{ id: `ml-${Date.now()}`, platform: "", url: "", subtitle: "" }])
  );
  const [kaydediliyor, setKaydediliyor] = useState(false);
  const [mesaj, setMesaj] = useState<string | null>(null);

  const ekle = useCallback(() => {
    setDrafts((prev) => [...prev, { id: `ml-${Date.now()}`, platform: "", url: "", subtitle: "" }]);
  }, []);

  const sil = useCallback((index: number) => {
    setDrafts((prev) => {
      const n = prev.filter((_, i) => i !== index);
      return n.length > 0 ? n : [{ id: `ml-${Date.now()}`, platform: "", url: "", subtitle: "" }];
    });
  }, []);

  const guncelle = useCallback((index: number, alan: keyof MarketplaceLink, deger: string) => {
    setDrafts((prev) => prev.map((d, i) => (i === index ? { ...d, [alan]: deger } : d)));
  }, []);

  const kaydet = useCallback(async () => {
    setKaydediliyor(true);
    setMesaj(null);
    const temiz = drafts
      .filter((d) => d.platform.trim() && d.url.trim())
      .map((d) => ({
        id: d.id,
        platform: d.platform.trim(),
        url: d.url.trim(),
        subtitle: d.subtitle?.trim() || "",
      }));

    // URL validation — only http/https
    for (const l of temiz) {
      if (!/^https?:\/\//i.test(l.url) && !l.url.startsWith("/")) {
        setMesaj(`"${l.platform}" bağlantısı http:// veya https:// ile başlamalı.`);
        setKaydediliyor(false);
        return;
      }
    }

    try {
      const res = await fetch("/api/owner-structured-field", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, kolon: "marketplace_links", deger: temiz }),
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

  const content = (
    <>
        <div className={`sticky top-0 z-10 flex items-center justify-between border-b px-5 py-4 ${inline ? "border-lp-border bg-lp-surface" : "border-white/10 bg-[#0B1120]"}`}>
          <div>
            <h2 className={`text-lg font-extrabold ${inline ? "text-lp-text" : "text-white"}`}>Pazaryeri Bağlantıları</h2>
            <p className={`text-[11px] ${inline ? "text-lp-muted" : "text-white/40"}`}>Trendyol, Hepsiburada gibi linklerini ekle. Boş olanlar kaydedilmez.</p>
          </div>
          {!inline && <button onClick={onClose} className="text-white/40 hover:text-white text-xl">✕</button>}
        </div>

        <div className="space-y-3 px-5 py-4">
          {drafts.map((draft, i) => {
            const isCustom = draft.platform === "Özel..." || (!PLATFORM_OPTIONS.includes(draft.platform as typeof PLATFORM_OPTIONS[number]) && draft.platform !== "");
            const dropdownValue = isCustom ? "Özel..." : draft.platform;
            return (
              <div key={draft.id} className="rounded-xl bg-white/5 border border-white/10 p-3 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-white/60">Bağlantı {i + 1}</span>
                  <button onClick={() => sil(i)} className="text-[10px] text-red-400 hover:text-red-300">Sil</button>
                </div>
                <select
                  value={dropdownValue}
                  onChange={(e) => {
                    const v = e.target.value;
                    if (v === "Özel...") guncelle(i, "platform", "Özel...");
                    else guncelle(i, "platform", v);
                  }}
                  className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white focus:outline-none focus:border-blue-500/50"
                >
                  <option value="">Platform seç</option>
                  {PLATFORM_OPTIONS.map((p) => (
                    <option key={p} value={p} className="bg-[#0B1120]">{p}</option>
                  ))}
                </select>
                {isCustom && (
                  <input
                    type="text"
                    value={draft.platform === "Özel..." ? "" : draft.platform}
                    onChange={(e) => guncelle(i, "platform", e.target.value)}
                    placeholder="Bağlantı başlığı (ör. Randevu al)"
                    className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
                  />
                )}
                <input
                  type="url"
                  value={draft.url}
                  onChange={(e) => guncelle(i, "url", e.target.value)}
                  placeholder="https://..."
                  className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
                />
                <input
                  type="text"
                  value={draft.subtitle || ""}
                  onChange={(e) => guncelle(i, "subtitle", e.target.value)}
                  placeholder="Kısa açıklama (isteğe bağlı)"
                  className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-xs text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
                />
              </div>
            );
          })}
          <button
            onClick={ekle}
            disabled={drafts.length >= 10}
            className="w-full rounded-xl border border-dashed border-white/20 py-2 text-xs font-semibold text-white/50 hover:text-white/70 hover:border-white/30 transition disabled:opacity-30"
          >
            + Bağlantı ekle
          </button>
        </div>

        <div className={`sticky bottom-0 border-t px-5 py-3 flex gap-3 ${inline ? "border-lp-border bg-lp-surface" : "border-white/10 bg-[#0B1120]"}`}>
          <button onClick={onClose} className={`flex-1 rounded-xl border py-2.5 text-xs font-bold transition ${inline ? "border-lp-border text-lp-muted hover:bg-lp-surface-soft" : "border-white/20 text-white/60 hover:bg-white/5"}`}>İptal</button>
          <button onClick={kaydet} disabled={kaydediliyor} className="flex-1 rounded-xl bg-blue-600 py-2.5 text-xs font-bold text-white hover:bg-blue-500 transition disabled:opacity-50">
            {kaydediliyor ? "Kaydediliyor…" : "Kaydet"}
          </button>
        </div>
        {mesaj && <p className="px-5 pb-3 text-[11px] font-semibold text-red-400">{mesaj}</p>}
      </>
  );

  if (inline) {
    return <div className="w-full overflow-hidden rounded-xl border border-lp-border bg-lp-surface shadow-sm">{content}</div>;
  }

  return (
    <div className="fixed inset-0 z-[90] flex items-end sm:items-center justify-center bg-black/60" onClick={onClose}>
      <div className="w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-t-2xl sm:rounded-2xl bg-[#0B1120] border border-white/10 shadow-2xl" onClick={(e) => e.stopPropagation()}>
        {content}
      </div>
    </div>
  );
}
