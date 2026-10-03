"use client";

import { useState } from "react";
import type { FiyatAyarModu } from "@/lib/topluAlanGuncelle";

export type TopluAksiyon =
  | { tip: "fiyat"; mod: FiyatAyarModu; deger: number }
  | { tip: "stok"; deger: string }
  | { tip: "kategori"; kategoriId: string };

interface OwnerTopluDuzenleProps {
  seciliSayi: number;
  kategoriler: Array<{ id: string; name: string }>;
  onKapat: () => void;
  onUygula: (aksiyon: TopluAksiyon) => Promise<void>;
}

type Alan = "fiyat" | "stok" | "kategori";

const ALAN_ETIKETLERI: Array<{ alan: Alan; etiket: string }> = [
  { alan: "fiyat", etiket: "Fiyat" },
  { alan: "stok", etiket: "Stok durumu" },
  { alan: "kategori", etiket: "Kategori" },
];

const FIYAT_MODLLERI: Array<{ mod: FiyatAyarModu; etiket: string }> = [
  { mod: "increasePercent", etiket: "Yüzde artır (ör. %10 zam)" },
  { mod: "decreasePercent", etiket: "Yüzde azalt (indirim)" },
  { mod: "increaseAmount", etiket: "Sabit tutar ekle (TL)" },
  { mod: "decreaseAmount", etiket: "Sabit tutar düş (TL)" },
  { mod: "setExact", etiket: "Hepsini aynı tutara eşitle" },
];

const STOK_SECENEKLERI = ["Mevcut", "Tükendi", "Son birkaç adet"] as const;

export function OwnerTopluDuzenle({
  seciliSayi,
  kategoriler,
  onKapat,
  onUygula,
}: OwnerTopluDuzenleProps) {
  const [alan, setAlan] = useState<Alan>("fiyat");
  const [fiyatModu, setFiyatModu] = useState<FiyatAyarModu>("increasePercent");
  const [fiyatDeger, setFiyatDeger] = useState("");
  const [stokDeger, setStokDeger] = useState<string>(STOK_SECENEKLERI[0]);
  const [kategoriId, setKategoriId] = useState(kategoriler[0]?.id ?? "");
  const [hata, setHata] = useState("");
  const [busy, setBusy] = useState(false);

  const yuzdeModu = fiyatModu === "increasePercent" || fiyatModu === "decreasePercent";

  async function uygula() {
    setHata("");
    let aksiyon: TopluAksiyon;
    if (alan === "fiyat") {
      const sayi = Number(fiyatDeger.trim().split(",").join("."));
      if (!fiyatDeger.trim() || !Number.isFinite(sayi)) {
        setHata("Geçerli bir sayı gir.");
        return;
      }
      aksiyon = { tip: "fiyat", mod: fiyatModu, deger: sayi };
    } else if (alan === "stok") {
      aksiyon = { tip: "stok", deger: stokDeger };
    } else {
      if (!kategoriId) {
        setHata("Önce en az bir kategori oluşturman gerekiyor.");
        return;
      }
      aksiyon = { tip: "kategori", kategoriId };
    }
    setBusy(true);
    try {
      await onUygula(aksiyon);
      onKapat();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/70 p-4 sm:items-center" role="presentation">
      <div
        className="owner-card w-full max-w-lg p-5 sm:p-6"
        role="dialog"
        aria-modal="true"
        aria-labelledby="toplu-duzenle-baslik"
        aria-busy={busy}
      >
        <h2 id="toplu-duzenle-baslik" className="text-xl font-bold text-[var(--owner-text)]">
          {seciliSayi} ürünü toplu düzenle
        </h2>
        <p className="mt-1 text-sm text-[var(--owner-muted)]">
          Yalnız seçtiğin alan değişir, diğer alanlara dokunulmaz.
        </p>

        <div className="mt-4 flex flex-wrap gap-2">
          {ALAN_ETIKETLERI.map((secim) => (
            <button
              key={secim.alan}
              type="button"
              onClick={() => { setAlan(secim.alan); setHata(""); }}
              disabled={busy}
              className={
                alan === secim.alan
                  ? "rounded-full border border-[var(--owner-primary)] bg-[var(--owner-primary)]/10 px-3 py-1.5 text-xs font-bold text-[var(--owner-primary)]"
                  : "rounded-full border border-[var(--owner-border)] px-3 py-1.5 text-xs text-[var(--owner-text-alt)] hover:border-[var(--owner-primary)]"
              }
            >
              {secim.etiket}
            </button>
          ))}
        </div>

        <div className="mt-4">
          {alan === "fiyat" ? (
            <div className="space-y-3">
              <label className="block space-y-2">
                <span className="owner-label">İşlem</span>
                <select
                  className="owner-input"
                  value={fiyatModu}
                  onChange={(e) => setFiyatModu(e.target.value as FiyatAyarModu)}
                  disabled={busy}
                >
                  {FIYAT_MODLLERI.map((mod) => (
                    <option key={mod.mod} value={mod.mod}>{mod.etiket}</option>
                  ))}
                </select>
              </label>
              <label className="block space-y-2">
                <span className="owner-label">{yuzdeModu ? "Yüzde (ör. 10)" : "Tutar (TL)"}</span>
                <input
                  className="owner-input"
                  value={fiyatDeger}
                  onChange={(e) => setFiyatDeger(e.target.value)}
                  inputMode="decimal"
                  disabled={busy}
                />
              </label>
              {fiyatModu !== "setExact" ? (
                <p className="text-xs text-[var(--owner-muted)]">
                  Fiyatı bir sayı olarak okunamayan ürünler değiştirilmeden atlanır.
                </p>
              ) : null}
            </div>
          ) : alan === "stok" ? (
            <label className="block space-y-2">
              <span className="owner-label">Yeni stok durumu</span>
              <select
                className="owner-input"
                value={stokDeger}
                onChange={(e) => setStokDeger(e.target.value)}
                disabled={busy}
              >
                {STOK_SECENEKLERI.map((durum) => (
                  <option key={durum} value={durum}>{durum}</option>
                ))}
              </select>
            </label>
          ) : kategoriler.length === 0 ? (
            <p className="text-sm text-[var(--owner-muted)]">
              Önce en az bir kategori oluşturman gerekiyor.
            </p>
          ) : (
            <label className="block space-y-2">
              <span className="owner-label">Yeni kategori</span>
              <select
                className="owner-input"
                value={kategoriId}
                onChange={(e) => setKategoriId(e.target.value)}
                disabled={busy}
              >
                {kategoriler.map((kategori) => (
                  <option key={kategori.id} value={kategori.id}>{kategori.name}</option>
                ))}
              </select>
            </label>
          )}
        </div>

        {hata ? <p className="owner-error mt-3 text-sm" role="alert">{hata}</p> : null}

        <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button type="button" className="owner-button-secondary" onClick={onKapat} disabled={busy}>
            Vazgeç
          </button>
          <button type="button" className="owner-button-primary" onClick={() => void uygula()} disabled={busy}>
            {busy ? "Uygulanıyor…" : "Uygula"}
          </button>
        </div>
      </div>
    </div>
  );
}
