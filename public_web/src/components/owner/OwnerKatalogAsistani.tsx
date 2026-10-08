"use client";

import { VixrexAvatar } from "@/app/v/[slug]/components/VixrexAvatar";

interface OwnerKatalogAsistaniProps {
  onFaturaCikar: () => void;
  onBaslikOnerileri: () => void;
}

interface Kutucuk {
  anahtar: string;
  baslik: string;
  aciklama: string;
  tiklama: () => void;
}

export function OwnerKatalogAsistani({
  onFaturaCikar,
  onBaslikOnerileri,
}: OwnerKatalogAsistaniProps) {
  const kutucuklar: Kutucuk[] = [
    {
      anahtar: "fatura",
      baslik: "Faturadan çıkar",
      aciklama: "Faturayı güvenli taslak kataloğa çevir",
      tiklama: onFaturaCikar,
    },
    {
      anahtar: "oneri",
      baslik: "Vixrex önerileri",
      aciklama: "Ürün başlıklarını iyileştir",
      tiklama: onBaslikOnerileri,
    },
  ];

  return (
    <section className="rounded-2xl border border-[var(--owner-primary)]/20 bg-[var(--owner-bg-soft)] p-3 shadow-sm">
      <div className="flex items-center gap-2">
        <VixrexAvatar size={42} decorative />
        <div>
          <p className="text-xs font-bold text-[var(--owner-text)]">Vixrex ile katalog oluştur</p>
          <p className="mt-0.5 text-[10px] leading-4 text-[var(--owner-muted)]">
            Fatura fotoğrafından ürün kartı hazırlamaya yardımcı olacak.
          </p>
        </div>
      </div>
      <div className="mt-3 flex gap-2.5 overflow-x-auto pb-1">
        {kutucuklar.map((kutucuk) => (
          <button
              key={kutucuk.anahtar}
              type="button"
              onClick={kutucuk.tiklama}
              className="w-40 shrink-0 rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg)] p-2.5 text-left transition-colors hover:border-[var(--owner-primary)]"
            >
              <p className="text-[11px] font-bold text-[var(--owner-text)]">{kutucuk.baslik}</p>
              <p className="mt-0.5 text-[10px] leading-4 text-[var(--owner-muted)]">
                {kutucuk.aciklama}
              </p>
            </button>
        ))}
      </div>
    </section>
  );
}
