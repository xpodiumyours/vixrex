import Image from "next/image";

interface VixrexAvatarProps {
  size?: number;
  decorative?: boolean;
  halo?: boolean;
  variant?: "organic" | "fab";
  className?: string;
  priority?: boolean;
}

/**
 * Next.js ve tüm VixRex yüzeylerindeki canonical Vixrex avatarı.
 *
 * Public dosyanın Flutter asset'iyle bayt eşitliği sözleşme testinde
 * doğrulanır; iki platformun maskotu sessizce ayrışamaz.
 */
export function VixrexAvatar({
  size = 28,
  decorative = false,
  halo = false,
  variant = "organic",
  className = "",
  priority = false,
}: VixrexAvatarProps) {
  if (variant === "fab") {
    return (
      <span
        className={`inline-flex shrink-0 items-center justify-center transition-transform duration-300 ${className}`}
        style={{ width: size, height: size }}
        aria-hidden={decorative || undefined}
      >
        <Image
          src="/images/vixrex_v_crystal_mascot.webp"
          alt={decorative ? "" : "Vixrex"}
          width={size}
          height={size}
          priority={priority || true}
          className="h-full w-full object-contain drop-shadow-[0_0_16px_rgba(20,125,255,0.65)] transition-all duration-300 group-hover:drop-shadow-[0_0_24px_rgba(20,125,255,0.95)]"
        />
      </span>
    );
  }

  return (
    <span
      className={`inline-flex shrink-0 items-center justify-center relative ${className}`}
      style={{ width: size, height: size }}
      aria-hidden={decorative || undefined}
    >
      <Image
        src="/images/vixrex_v_crystal_mascot.webp"
        alt={decorative ? "" : "Vixrex"}
        width={size}
        height={size}
        sizes={`${size}px`}
        priority={priority}
        className={`h-full w-full object-contain ${
          halo
            ? "drop-shadow-[0_0_10px_rgba(20,125,255,0.6)]"
            : "drop-shadow-[0_0_6px_rgba(20,125,255,0.35)]"
        }`}
      />
    </span>
  );
}
