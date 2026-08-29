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
  const [kayiyor, setKayiyor] = useState(false);

  useEffect(() => {
    /* İlk 1.2sn'de belirsin — hero'daki buton hâlâ görünürken göz konfetisi yapmasın. */
    const timer = setTimeout(() => setVisible(true), 1200);
    return () => clearTimeout(timer);
  }, []);

  /* Buton sabit durdugu icin okunan metnin uzerine biniyordu: telefonda
     cekilen dokuz ekranin sekizinde bir fiyati ya da bir cumleyi
     kapatiyordu (Casper, 2026-08-29). Tamamen gizlemek WhatsApp'i
     ulasilmaz yapardi — bunun yerine kaydirirken kuculup soluklasiyor,
     el durunca geri geliyor. */
  useEffect(() => {
    let zamanlayici: ReturnType<typeof setTimeout>;
    const kontrol = () => {
      setKayiyor(true);
      clearTimeout(zamanlayici);
      zamanlayici = setTimeout(() => setKayiyor(false), 450);
    };
    window.addEventListener("scroll", kontrol, { passive: true });
    return () => {
      window.removeEventListener("scroll", kontrol);
      clearTimeout(zamanlayici);
    };
  }, []);

  if (ownerMode || !whatsappUrl) return null;

  return (
    <div
      className="fixed z-50 bottom-6 right-4 sm:hidden transition-all duration-300"
      style={{
        opacity: visible ? (kayiyor ? 0.35 : 1) : 0,
        transform: kayiyor ? "scale(0.8)" : "scale(1)",
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
