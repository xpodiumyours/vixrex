"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";

/**
 * Öne çıkan kampanya düzenleyici — Flutter Web FeaturedCampaignSheet karşılığı.
 *
 * Yönetim alanları: bantEtiket, bantBaslik, bantAciklama, bantFiyat, bantGorsel
 * DB: featured_banner_label, featured_banner_title, featured_banner_description,
 *     featured_banner_price_text, featured_banner_image_url
 */

interface Props {
  slug: string;
  mevcut: {
    label: string;
    title: string;
    description: string;
    priceText: string;
    imageUrl: string;
  };
  onClose: () => void;
}

export function CampaignEditor({ slug, mevcut, onClose }: Props) {
  const router = useRouter();
  const [label, setLabel] = useState(mevcut.label);
  const [title, setTitle] = useState(mevcut.title);
  const [description, setDescription] = useState(mevcut.description);
  const [priceText, setPriceText] = useState(mevcut.priceText);
  const [imageUrl, setImageUrl] = useState(mevcut.imageUrl);
  const [kaydediliyor, setKaydediliyor] = useState(false);
  const [mesaj, setMesaj] = useState<string | null>(null);

  const kaydet = useCallback(async () => {
    setKaydediliyor(true);
    setMesaj(null);

    const alanlar: [string, string | null][] = [
      ["bantEtiket", label.trim() || null],
      ["bantBaslik", title.trim() || null],
      ["bantAciklama", description.trim() || null],
      ["bantFiyat", priceText.trim() || null],
      ["bantGorsel", imageUrl.trim() || null],
    ];

    try {
      for (const [anahtar, deger] of alanlar) {
        const res = await fetch("/api/owner-draft", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ slug, anahtar, deger, clientId: null }),
        });
        if (!res.ok) {
          const govde = await res.json();
          setMesaj(govde?.hata ?? "Kaydedilemedi.");
          return;
        }
      }
      router.refresh();
      onClose();
    } catch {
      setMesaj("Bağlantı kurulamadı.");
    } finally {
      setKaydediliyor(false);
    }
  }, [slug, label, title, description, priceText, imageUrl, router, onClose]);

  return (
    <div className="fixed inset-0 z-[90] flex items-end sm:items-center justify-center bg-black/60" onClick={onClose}>
      <div
        className="w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-t-2xl sm:rounded-2xl bg-[#0B1120] border border-white/10 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-white/10 bg-[#0B1120] px-5 py-4">
          <div>
            <h2 className="text-lg font-extrabold text-white">Öne Çıkan Kampanya</h2>
            <p className="text-[11px] text-white/40">Tümünü boş bırakırsan kampanya bölümü gizlenir.</p>
          </div>
          <button onClick={onClose} className="text-white/40 hover:text-white text-xl">✕</button>
        </div>

        <div className="space-y-4 px-5 py-4">
          <Field label="Etiket" value={label} onChange={setLabel} placeholder="Örn: Bu haftaya özel" />
          <Field label="Başlık" value={title} onChange={setTitle} placeholder="Kampanya başlığı" />
          <Field label="Açıklama" value={description} onChange={setDescription} placeholder="Kısa açıklama" multiline rows={3} />
          <Field label="Fiyat metni" value={priceText} onChange={setPriceText} placeholder="Örn: 499 TL'den başlayan" />
          <Field label="Görsel bağlantısı" value={imageUrl} onChange={setImageUrl} placeholder="https://..." />
        </div>

        <div className="sticky bottom-0 border-t border-white/10 bg-[#0B1120] px-5 py-3 flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 rounded-xl border border-white/20 py-2.5 text-xs font-bold text-white/60 hover:bg-white/5 transition"
          >
            İptal
          </button>
          <button
            onClick={kaydet}
            disabled={kaydediliyor}
            className="flex-1 rounded-xl bg-blue-600 py-2.5 text-xs font-bold text-white hover:bg-blue-500 transition disabled:opacity-50"
          >
            {kaydediliyor ? "Kaydediliyor…" : "Kaydet"}
          </button>
        </div>

        {mesaj && (
          <p className="px-5 pb-3 text-[11px] font-semibold text-red-400">{mesaj}</p>
        )}
      </div>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  multiline,
  rows = 2,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  multiline?: boolean;
  rows?: number;
}) {
  return (
    <div>
      <label className="mb-1 block text-xs font-bold text-white/60">{label}</label>
      {multiline ? (
        <textarea
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          rows={rows}
          className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50 resize-none"
        />
      ) : (
        <input
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
        />
      )}
    </div>
  );
}
