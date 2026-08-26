import Link from "next/link";
import type { MockupProfili } from "./mockupProfilleri";
import { PhoneMockupSlaytlari } from "./PhoneMockupSlaytlari";

/**
 * Hero'nun telefon mockup'ı — envanter §2.3.
 *
 * Kabuk ve İLK slayt sunucuda çizilir: JavaScript hiç çalışmasa da (ve
 * arama motoru için) mockup dolu görünür. Slayt döngüsü tek küçük bir
 * istemci adasında yaşar.
 */
export function PhoneMockup({ profiller }: { profiller: MockupProfili[] }) {
  const ilk = profiller[0];
  if (!ilk) return null;

  return (
    <div className="relative w-full max-w-[320px] shrink-0">
      <div className="rounded-[38px] border border-white/10 bg-[#0A101C] p-3 shadow-lp-panel">
        <div className="overflow-hidden rounded-[28px] bg-lp-bg-editor">
          <PhoneMockupSlaytlari profiller={profiller} />
        </div>
      </div>

      {/* Mockup tıklanabilir: o kategorinin Keşfet sayfasına götürür. */}
      <Link
        href={ilk.hedefUrl}
        className="mt-4 flex items-center justify-center rounded-2xl border border-lp-border bg-lp-surface px-4 py-3 text-[13px] font-extrabold text-lp-text-alt transition-colors hover:bg-lp-surface-soft"
      >
        Hazır şablonlara göz at
      </Link>
    </div>
  );
}
