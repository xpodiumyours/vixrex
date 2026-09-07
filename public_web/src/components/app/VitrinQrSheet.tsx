"use client";

export function VitrinQrSheet({
  slug,
  acik,
  kapat,
}: {
  slug: string | null;
  acik: boolean;
  kapat: () => void;
}) {
  if (!acik || !slug) return null;

  const link = `${window.location.origin}/v/${slug}`;

  return (
    <div className="fixed inset-0 z-[70] flex items-end bg-black/60" onClick={kapat}>
      <div
        className="w-full rounded-t-3xl border-t border-lp-border bg-lp-surface px-6 pb-8 pt-3"
        role="dialog"
        aria-modal="true"
        aria-label="Vitrin QR Kodunuz"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="mx-auto h-1 w-10 rounded-full bg-lp-border" />
        <h2 className="mt-4 text-center text-[24px] font-black leading-[1.2] text-lp-text">Vitrin QR Kodunuz</h2>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={`https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(link)}`}
          alt="Vitrin QR kodu"
          className="mx-auto mt-4 h-[220px] w-[220px] rounded-[20px] border border-lp-border bg-white p-4"
        />
        <p className="mx-auto mt-3 max-w-[520px] truncate text-center text-[12px] font-semibold text-lp-muted">{link}</p>
      </div>
    </div>
  );
}
