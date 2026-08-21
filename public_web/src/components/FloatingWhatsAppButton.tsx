"use client";

import { useEffect, useState } from "react";
import {
  TrackedWhatsAppLink,
  type WhatsAppClickLocation,
} from "./TrackedWhatsAppLink";
import { WhatsAppIcon } from "@/lib/vitrinBrandIcons";

interface FloatingWhatsAppButtonProps {
  whatsappUrl: string | null;
  storeSlug: string;
  /** Sahip modunda buton gösterilmez — tıkla-düzenle kancası değil, gerçek dış link. */
  ownerMode?: boolean;
}

/**
 * Mobilde ekranın sağ alt köşesinde sabit duran WhatsApp butonu.
 * Yalnızca `whatsappUrl` doluysa görünür (issue #294).
 *
 * Tasarım kararları:
 * - sm breakpoint'in (640px) altında sabit (fixed) konumda;
 *   masaüstünde hero'daki WhatsApp butonu zaten yeterli.
 * - Safest inline style ile temizlenir: `bottom: max(env(safe-area-inset-bottom), 1rem)`.
 * - z-50: navbar'ın (z-50) hizasında ama vitrin içeriğinin üstünde.
 */
export default function FloatingWhatsAppButton({
  whatsappUrl,
  storeSlug,
  ownerMode = false,
}: FloatingWhatsAppButtonProps) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    /* İlk 1.2sn'de belirsin — hero'daki buton hâlâ görünürken göz konfetisi yapmasın. */
    const timer = setTimeout(() => setVisible(true), 1200);
    return () => clearTimeout(timer);
  }, []);

  if (ownerMode || !whatsappUrl) return null;

  return (
    <div
      className="fixed z-50 bottom-6 right-4 sm:hidden transition-opacity duration-500"
      style={{
        opacity: visible ? 1 : 0,
        pointerEvents: visible ? "auto" : "none",
        bottom: "max(env(safe-area-inset-bottom, 0px), 1rem)",
      }}
    >
      <TrackedWhatsAppLink
        href={whatsappUrl}
        storeSlug={storeSlug}
        clickLocation={"storefront_floating" as WhatsAppClickLocation}
        target="_blank"
        rel="noopener noreferrer"
        className="flex items-center justify-center w-14 h-14 rounded-full bg-[#25D366] shadow-lg shadow-black/30 hover:scale-110 active:scale-95 transition-transform"
        aria-label="WhatsApp ile iletişime geç"
      >
        <WhatsAppIcon size={28} className="text-white" />
      </TrackedWhatsAppLink>
    </div>
  );
}
