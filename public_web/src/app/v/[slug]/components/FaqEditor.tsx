"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";

/**
 * SSS düzenleyici — Flutter Web FaqEditorSheet'in Next.js karşılığı.
 * Soru-cevap çiftlerini ekler, düzenler, siler.
 *
 * DB: stores.faq_items (jsonb array)
 */

interface FaqItem {
  id: string;
  question: string;
  answer: string;
}

interface Props {
  slug: string;
  items: FaqItem[];
  onClose: () => void;
}

export function FaqEditor({ slug, items, onClose }: Props) {
  const router = useRouter();
  const [drafts, setDrafts] = useState<FaqItem[]>(
    () => items.length > 0 ? items : [{ id: `faq-${Date.now()}`, question: "", answer: "" }]
  );
  const [kaydediliyor, setKaydediliyor] = useState(false);
  const [mesaj, setMesaj] = useState<string | null>(null);

  const ekle = useCallback(() => {
    setDrafts((prev) => [
      ...prev,
      { id: `faq-${Date.now()}`, question: "", answer: "" },
    ]);
  }, []);

  const sil = useCallback((index: number) => {
    setDrafts((prev) => {
      const yeni = prev.filter((_, i) => i !== index);
      return yeni.length > 0 ? yeni : [{ id: `faq-${Date.now()}`, question: "", answer: "" }];
    });
  }, []);

  const guncelle = useCallback((index: number, alan: "question" | "answer", deger: string) => {
    setDrafts((prev) => prev.map((d, i) => (i === index ? { ...d, [alan]: deger } : d)));
  }, []);

  const kaydet = useCallback(async () => {
    setKaydediliyor(true);
    setMesaj(null);

    // Boş olanları filtrele
    const temizItems = drafts
      .filter((d) => d.question.trim() && d.answer.trim())
      .map((d, i) => ({
        id: d.id || `faq-${i + 1}`,
        question: d.question.trim(),
        answer: d.answer.trim(),
      }));

    try {
      const res = await fetch("/api/owner-structured-field", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, kolon: "faq_items", deger: temizItems }),
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
            <h2 className="text-lg font-extrabold text-white">Sık Sorulan Sorular</h2>
            <p className="text-[11px] text-white/40">Boş soru/cevaplar kaydedilmez.</p>
          </div>
          <button onClick={onClose} className="text-white/40 hover:text-white text-xl">✕</button>
        </div>

        <div className="space-y-4 px-5 py-4">
          {drafts.map((draft, i) => (
            <div key={draft.id} className="rounded-xl bg-white/5 border border-white/10 p-3 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-white/60">Soru {i + 1}</span>
                <button
                  onClick={() => sil(i)}
                  className="text-[10px] text-red-400 hover:text-red-300"
                >
                  Sil
                </button>
              </div>
              <input
                type="text"
                value={draft.question}
                onChange={(e) => guncelle(i, "question", e.target.value)}
                placeholder="Soru yazın..."
                className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
              />
              <textarea
                value={draft.answer}
                onChange={(e) => guncelle(i, "answer", e.target.value)}
                placeholder="Cevap yazın..."
                rows={3}
                className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50 resize-none"
              />
            </div>
          ))}

          <button
            onClick={ekle}
            disabled={drafts.length >= 20}
            className="w-full rounded-xl border border-dashed border-white/20 py-2 text-xs font-semibold text-white/50 hover:text-white/70 hover:border-white/30 transition disabled:opacity-30"
          >
            + Soru ekle
          </button>
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
