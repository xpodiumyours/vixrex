"use client";

import { VixrexAvatar } from "@/app/v/[slug]/components/VixrexAvatar";

interface OwnerKatalogAsistaniProps {
  onFaturaCikar: () => void;
  onBaslikOnerileri: () => void;
}

export function OwnerKatalogAsistani({
  onFaturaCikar,
  onBaslikOnerileri,
}: OwnerKatalogAsistaniProps) {
  return (
    <section className="rounded-2xl border border-[var(--owner-primary)]/20 bg-[var(--owner-bg-soft)] p-3 shadow-sm">
      <div className="flex items-center gap-2">
        <VixrexAvatar size={42} decorative />
        <p className="text-[11px] leading-4 text-[var(--owner-muted)]">
          Fotoğrafı yükle. Kartlar hazırlanır. Satış fiyatını yazıp yayınlarsın.
        </p>
      </div>
      <button type="button" onClick={onFaturaCikar} className="owner-button-primary mt-3 w-full">
        Fatura fotoğrafını yükle
      </button>
      <button type="button" onClick={onBaslikOnerileri} className="mt-2 w-full text-xs font-bold text-[var(--owner-muted)]">
        Vixrex önerileri
      </button>
    </section>
  );
}
