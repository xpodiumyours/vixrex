import Image from "next/image";
import vixrexMascot from "../../../../../../assets/images/vixrex_v_crystal_mascot.png";

interface VixrexAvatarProps {
  size?: number;
  decorative?: boolean;
  halo?: boolean;
}

/**
 * Next.js sahip yüzeyindeki canonical Vixrex avatarı.
 *
 * Görsel kopyalanmaz; Flutter ile aynı repo asset'i statik import edilir.
 * Böylece iki platformun maskotu zamanla birbirinden ayrılamaz.
 */
export function VixrexAvatar({
  size = 28,
  decorative = false,
  halo = false,
}: VixrexAvatarProps) {
  const imageSize = Math.max(size - 4, 16);

  return (
    <span
      className={[
        "inline-flex shrink-0 items-center justify-center overflow-hidden rounded-full",
        "border border-sky-500/70 bg-[#0E1B2E]",
        halo ? "shadow-[0_0_8px_rgba(14,165,233,0.3)]" : "",
      ].join(" ")}
      style={{ width: size, height: size }}
      aria-hidden={decorative || undefined}
    >
      <Image
        src={vixrexMascot}
        alt={decorative ? "" : "Vixrex"}
        width={imageSize}
        height={imageSize}
        sizes={`${imageSize}px`}
        className="h-auto w-auto object-contain"
      />
    </span>
  );
}
