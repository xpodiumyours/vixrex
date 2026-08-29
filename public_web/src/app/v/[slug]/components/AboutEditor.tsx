"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";

/**
 * Hakkımızda düzenleyici — Flutter Web AboutEditorSheet'in Next.js karşılığı.
 *
 * Yönetim alanları: kicker, title, body, imageUrl, imageCaption, values (max 3)
 * DB: about_kicker, about_title, corporate_bio, about_image_url, about_image_caption,
 *     about_values (jsonb array)
 */

interface AboutValue {
  id: string;
  title: string;
  description: string;
}

interface Props {
  slug: string;
  mevcut: {
    kicker: string;
    title: string;
    body: string;
    imageUrl: string;
    imageCaption: string;
    values: AboutValue[];
  };
  onClose: () => void;
}

export function AboutEditor({ slug, mevcut, onClose }: Props) {
  const router = useRouter();
  const [kicker, setKicker] = useState(mevcut.kicker);
  const [title, setTitle] = useState(mevcut.title);
  const [body, setBody] = useState(mevcut.body);
  const [imageUrl, setImageUrl] = useState(mevcut.imageUrl);
  const [imageCaption, setImageCaption] = useState(mevcut.imageCaption);
  const [values, setValues] = useState<AboutValue[]>(
    mevcut.values.length > 0
      ? mevcut.values
      : [
          { id: "about-value-1", title: "", description: "" },
          { id: "about-value-2", title: "", description: "" },
          { id: "about-value-3", title: "", description: "" },
        ]
  );
  const [kaydediliyor, setKaydediliyor] = useState(false);
  const [mesaj, setMesaj] = useState<string | null>(null);

  const valueGuncelle = useCallback((index: number, alan: "title" | "description", deger: string) => {
    setValues((prev) => prev.map((v, i) => (i === index ? { ...v, [alan]: deger } : v)));
  }, []);

  const kaydet = useCallback(async () => {
    setKaydediliyor(true);
    setMesaj(null);

    const temizValues = values
      .filter((v) => v.title.trim())
      .map((v) => ({
        id: v.id,
        title: v.title.trim(),
        description: v.description.trim(),
      }));

    // Hakkımızda metin alanları şemadaki anahtarlarla owner-draft üzerinden,
    // değer kartları ise JSONB kolon olarak structured-field üzerinden kaydedilir.
    const alanlar: [string, string | null][] = [
      ["hakkindaUstBaslik", kicker.trim() || null],
      ["hakkindaBaslik", title.trim() || null],
      ["hakkindaMetin", body.trim() || null],
      ["hakkindaGorsel", imageUrl.trim() || null],
      ["hakkindaGorselAlt", imageCaption.trim() || null],
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
      // about_values JSONB — şemada yok, yapılandırılmış alan yolu
      const valuesRes = await fetch("/api/owner-structured-field", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, kolon: "about_values", deger: temizValues }),
      });
      if (!valuesRes.ok) {
        const govde = await valuesRes.json();
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
  }, [slug, kicker, title, body, imageUrl, imageCaption, values, router, onClose]);

  return (
    <div className="fixed inset-0 z-[90] flex items-end sm:items-center justify-center bg-black/60" onClick={onClose}>
      <div
        className="w-full max-w-lg max-h-[85vh] overflow-y-auto rounded-t-2xl sm:rounded-2xl bg-[#0B1120] border border-white/10 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-white/10 bg-[#0B1120] px-5 py-4">
          <div>
            <h2 className="text-lg font-extrabold text-white">Hakkımızda</h2>
            <p className="text-[11px] text-white/40">Boş bırakırsan vitrinde bu bölüm gizlenir.</p>
          </div>
          <button onClick={onClose} className="text-white/40 hover:text-white text-xl">✕</button>
        </div>

        <div className="space-y-4 px-5 py-4">
          <Field label="Üst etiket" value={kicker} onChange={setKicker} placeholder="Örn: Atmosfer'in hikâyesi" />
          <Field label="Başlık" value={title} onChange={setTitle} placeholder="Kısa, güçlü bir cümle" />
          <Field label="Hikâye" value={body} onChange={setBody} placeholder="İşletmeni anlatan metin" multiline rows={5} />
          <Field label="Görsel bağlantısı" value={imageUrl} onChange={setImageUrl} placeholder="https://..." />
          <Field label="Görsel alt yazı" value={imageCaption} onChange={setImageCaption} placeholder="Örn: Küçük seriler, özenli seçimler" />

          <div>
            <p className="mb-2 text-xs font-bold text-white/60">Değer kartları (en fazla 3)</p>
            {values.map((v, i) => (
              <div key={v.id} className="mb-3 rounded-xl bg-white/5 border border-white/10 p-3 space-y-2">
                <span className="text-[10px] font-bold text-white/40">Kart {i + 1}</span>
                <input
                  type="text"
                  value={v.title}
                  onChange={(e) => valueGuncelle(i, "title", e.target.value)}
                  placeholder="Başlık"
                  className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
                />
                <input
                  type="text"
                  value={v.description}
                  onChange={(e) => valueGuncelle(i, "description", e.target.value)}
                  placeholder="Kısa açıklama"
                  className="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-blue-500/50"
                />
              </div>
            ))}
          </div>
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
