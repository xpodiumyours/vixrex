import Image from "next/image";
import type { BlogListeYazisi } from "@/data/blogYazilari";

export function BlogKapak({
  yazi,
  oncelikli = false,
}: {
  yazi: Pick<BlogListeYazisi, "kapak" | "kapakAlt" | "baslik" | "kategori">;
  oncelikli?: boolean;
}) {
  if (yazi.kapak)
    return (
      <div className="relative aspect-[16/9] overflow-hidden rounded-2xl">
        <Image
          src={yazi.kapak}
          alt={yazi.kapakAlt || yazi.baslik}
          fill
          preload={oncelikli}
          sizes="(max-width: 768px) 100vw, 600px"
          className="object-cover"
        />
      </div>
    );
  const kamera = yazi.baslik.includes("fotoğraf");
  const kafe = yazi.baslik.includes("Kafe");
  const kuafor = yazi.baslik.includes("Kuaför");
  const iletisim = yazi.kategori === "Müşteri İletişimi";
  const google = yazi.kategori === "Google ve Keşfedilme";
  const vurgu = iletisim
    ? "#8bd5bb"
    : google
      ? "#f0c98a"
      : kamera
        ? "#b8b0ef"
        : kafe
          ? "#efb896"
          : kuafor
            ? "#d2b6dc"
            : "#91c9ff";
  return (
    <div
      aria-hidden="true"
      className="relative aspect-[16/9] overflow-hidden rounded-2xl border border-white/10 bg-[#102344]"
    >
      <svg viewBox="0 0 640 360" className="h-full w-full" fill="none">
        <path
          d="M0 90H640M0 180H640M0 270H640M160 0V360M320 0V360M480 0V360"
          stroke="white"
          strokeOpacity=".045"
        />
        <circle cx="488" cy="108" r="122" fill={vurgu} fillOpacity=".09" />
        <circle cx="488" cy="108" r="153" stroke={vurgu} strokeOpacity=".18" />
        <rect
          x="204"
          y="59"
          width="238"
          height="270"
          rx="15"
          fill="#06152f"
          stroke={vurgu}
          strokeOpacity=".4"
          transform="rotate(-6 204 59)"
        />
        <rect
          x="237"
          y="56"
          width="234"
          height="274"
          rx="14"
          fill="#eff5fa"
          transform="rotate(5 237 56)"
        />
        <rect
          x="257"
          y="79"
          width="190"
          height="104"
          rx="8"
          fill={vurgu}
          transform="rotate(5 257 79)"
        />
        {kamera ? (
          <g stroke="#102344" strokeWidth="6" strokeLinejoin="round">
            <rect x="304" y="118" width="76" height="49" rx="8" />
            <path d="m320 118 7-12h24l8 12" />
            <circle cx="342" cy="143" r="13" />
          </g>
        ) : kafe ? (
          <g stroke="#102344" strokeWidth="6" strokeLinecap="round">
            <path d="M310 124h54v22a24 24 0 0 1-48 0v-22m48 3h9a12 12 0 0 1 0 24h-10M308 178h65M325 103v7m16-11v11" />
          </g>
        ) : kuafor ? (
          <g stroke="#102344" strokeWidth="6" strokeLinecap="round">
            <circle cx="322" cy="151" r="13" />
            <circle cx="358" cy="151" r="13" />
            <path d="m331 140 31-38m-13 38-31-38" />
          </g>
        ) : google ? (
          <g stroke="#102344" strokeWidth="8">
            <circle cx="344" cy="133" r="22" />
            <path d="m362 151 22 22" strokeLinecap="round" />
          </g>
        ) : iletisim ? (
          <g>
            <rect
              x="303"
              y="109"
              width="79"
              height="46"
              rx="12"
              fill="#102344"
            />
            <path d="m320 151-5 15 22-13" fill="#102344" />
            <path
              d="M320 127h44M320 139h29"
              stroke={vurgu}
              strokeWidth="4"
              strokeLinecap="round"
            />
          </g>
        ) : (
          <g stroke="#102344" strokeWidth="6" strokeLinejoin="round">
            <path d="M312 132h66v39h-66zM304 130l10-24h54l12 24z" />
            <path d="M337 171v-24h17v24" />
          </g>
        )}
        <path
          d="m251 205 130 11m-132 6 91 8m-93 22 173 15m-175 3 151 13"
          stroke="#7c91a8"
          strokeWidth="7"
          strokeLinecap="round"
        />
        <rect
          x="76"
          y="231"
          width="140"
          height="59"
          rx="13"
          fill="#18365a"
          stroke={vurgu}
          strokeOpacity=".5"
        />
        <circle cx="105" cy="260" r="13" fill={vurgu} />
        <path
          d="m99 260 4 4 8-9"
          stroke="#102344"
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M128 253h63m-63 14h43"
          stroke={vurgu}
          strokeWidth="5"
          strokeLinecap="round"
        />
      </svg>
      <span className="absolute left-5 top-5 text-[11px] font-bold uppercase tracking-[.18em] text-white/75">
        Vixrex / Rehber
      </span>
    </div>
  );
}
