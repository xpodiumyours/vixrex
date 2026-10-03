"use client";

interface OwnerKatalogAsistaniProps {
  onFotografCikar: () => void;
  onFaturaCikar: () => void;
  onBaslikOnerileri: () => void;
  fotoYukleniyor?: boolean;
}

interface Kutucuk {
  anahtar: string;
  ikon: string;
  baslik: string;
  aciklama: string;
  tiklama: () => void;
}

export function OwnerKatalogAsistani({
  onFotografCikar,
  onFaturaCikar,
  onBaslikOnerileri,
  fotoYukleniyor = false,
}: OwnerKatalogAsistaniProps) {
  const kutucuklar: Kutucuk[] = [
    {
      anahtar: "fotograf",
      ikon: "📷",
      baslik: "Fotoğraftan çıkar",
      aciklama: "Fotoğraftan ad/kategori çıkar",
      tiklama: onFotografCikar,
    },
    {
      anahtar: "fatura",
      ikon: "🧾",
      baslik: "Faturadan çıkar",
      aciklama: "Faturayı güvenli taslak kataloğa çevir",
      tiklama: onFaturaCikar,
    },
    {
      anahtar: "oneri",
      ikon: "🤖",
      baslik: "Vixrex önerileri",
      aciklama: "Ürün başlıklarını iyileştir",
      tiklama: onBaslikOnerileri,
    },
  ];

  return (
    <section className="rounded-2xl border border-[var(--owner-primary)]/20 bg-[var(--owner-bg-soft)] p-3 shadow-sm">
      <div className="flex items-start gap-2">
        <span aria-hidden="true" className="text-base text-[var(--owner-primary)]">✨</span>
        <div>
          <p className="text-xs font-bold text-[var(--owner-text)]">Vixrex ile katalog oluştur</p>
          <p className="mt-0.5 text-[10px] leading-4 text-[var(--owner-muted)]">
            Fotoğraf, fatura veya Instagram ürünlerinden otomatik ürün kataloğu hazırlamaya yardımcı olacak.
          </p>
        </div>
      </div>
      <div className="mt-3 flex gap-2.5 overflow-x-auto pb-1">
        {kutucuklar.map((kutucuk) => (            <button
              key={kutucuk.anahtar}
              type="button"
              onClick={kutucuk.tiklama}
              disabled={kutucuk.anahtar === "fotograf" && fotoYukleniyor}
              className="w-40 shrink-0 rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg)] p-2.5 text-left transition-colors hover:border-[var(--owner-primary)] disabled:opacity-60"
            >
              <span aria-hidden="true" className="text-lg">{kutucuk.ikon}</span>
              <p className="mt-1.5 text-[11px] font-bold text-[var(--owner-text)]">{kutucuk.baslik}</p>
              <p className="mt-0.5 text-[10px] leading-4 text-[var(--owner-muted)]">
                {kutucuk.anahtar === "fotograf" && fotoYukleniyor ? "Fotoğraf okunuyor..." : kutucuk.aciklama}
              </p>
            </button>
        ))}
      </div>
    </section>
  );
}
