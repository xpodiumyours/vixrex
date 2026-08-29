"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { taslakClientId } from "@/lib/canliVitrinSenkron";

/**
 * Bölüm görünürlüğü toggle — Flutter Web'deki SectionVisibilityCard'ın
 * Next.js karşılığı. Owner kullanıcısı vitrinindeki bölümleri
 * açıp kapatabilir (categories, products, about, gallery, blog, faq, contact).
 *
 * DB: stores.section_visibility (jsonb, varsayılan '{}').
 * Boş/nötr ise bölüm veri doluysa otomatik görünür.
 * `false` ise bölüm vitrinde gizlenir.
 */

const SECTIONS = [
  { key: "categories", label: "Kategoriler", icon: "📂" },
  { key: "products", label: "Ürünler", icon: "📦" },
  { key: "about", label: "Hakkımızda", icon: "ℹ️" },
  { key: "gallery", label: "Galeri", icon: "🖼️" },
  { key: "blog", label: "Blog", icon: "📝" },
  { key: "faq", label: "Sık Sorulan Sorular", icon: "❓" },
  { key: "contact", label: "İletişim & Konum", icon: "📍" },
] as const;

interface Props {
  slug: string;
  /** Mevcut section_visibility JSONB — null veya {} ise tümü görünür */
  visibility: Record<string, boolean> | null;
  /** Taslak yerel state'ini güncelle — useOwnerDraft.setAlan */
  setAlan: (kolon: string, deger: unknown) => void;
  /** Kaydetme durumu bildirimi */
  mesajEkle: (kimden: "asistan" | "kullanici", metin: string) => void;
}

export function SectionVisibilityToggle({
  slug,
  visibility,
  setAlan,
  mesajEkle,
}: Props) {
  const router = useRouter();
  const [kaydediliyor, setKaydediliyor] = useState(false);
  const [acik, setAcik] = useState(false);

  const toggleSection = useCallback(
    async (key: string) => {
      if (kaydediliyor) return;

      // Mevcut visibility haritasını kopyala
      const mevcut = { ...(visibility ?? {}) };
      const suankiDeger = mevcut[key] !== false; // null/undefined = görünür

      // Toggle: görünür → false (gizli); gizli → sil (otomatik görünür)
      if (suankiDeger) {
        mevcut[key] = false;
      } else {
        delete mevcut[key];
      }

      // Yerel state'i hemen güncelle (optimistic update)
      setAlan("section_visibility", mevcut);

      // Supabase'e kaydet
      setKaydediliyor(true);
      try {
        const yanit = await fetch("/api/owner-draft", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            slug,
            anahtar: "section_visibility",
            deger: mevcut,
            clientId: taslakClientId(),
          }),
        });
        const govde = await yanit.json();

        if (!yanit.ok) {
          mesajEkle(
            "asistan",
            govde?.hata ?? "Bölüm görünürlüğü kaydedilemedi."
          );
          // Geri al
          setAlan("section_visibility", visibility ?? {});
          return;
        }

        const sectionLabel =
          SECTIONS.find((s) => s.key === key)?.label ?? key;
        mesajEkle(
          "asistan",
          `${sectionLabel} bölümü ${
            suankiDeger ? "gizlendi" : "görünür hale getirildi"
          }.`
        );
        router.refresh();
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
        setAlan("section_visibility", visibility ?? {});
      } finally {
        setKaydediliyor(false);
      }
    },
    [slug, visibility, setAlan, mesajEkle, kaydediliyor, router]
  );

  return (
    <div className="border-t border-white/10 px-4 py-3">
      <button
        type="button"
        onClick={() => setAcik(!acik)}
        className="flex w-full items-center justify-between text-left text-sm font-semibold text-white/80 hover:text-white transition"
      >
        <span>Gelişmiş Ayarlar</span>
        <span
          className={`text-xs transition-transform ${acik ? "rotate-180" : ""}`}
        >
          ▾
        </span>
      </button>

      {acik && (
        <div className="mt-3 space-y-1">
          <p className="text-[11px] text-white/40 mb-2">
            Bölümlerden birini kapatırsan vitrininde görünmez. Boş bırakılırsa
            bölüm veri doluysa otomatik görünür.
          </p>

          {SECTIONS.map((section) => {
            const gorunur = visibility?.[section.key] !== false;
            return (
              <label
                key={section.key}
                className="flex items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-white/70 hover:bg-white/5 cursor-pointer transition select-none"
              >
                <span className="text-base">{section.icon}</span>
                <span className="flex-1 font-medium text-[13px]">
                  {section.label}
                </span>
                <button
                  type="button"
                  role="switch"
                  aria-checked={gorunur}
                  disabled={kaydediliyor}
                  onClick={() => toggleSection(section.key)}
                  className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full transition-colors ${
                    gorunur ? "bg-blue-500" : "bg-white/20"
                  } ${kaydediliyor ? "opacity-50" : ""}`}
                >
                  <span
                    className={`inline-block h-3.5 w-3.5 rounded-full bg-white shadow transition-transform ${
                      gorunur ? "translate-x-4" : "translate-x-0.5"
                    }`}
                  />
                </button>
              </label>
            );
          })}
        </div>
      )}
    </div>
  );
}
