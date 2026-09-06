"use client";

import { useState, useCallback, type ReactNode } from "react";
import { BottomCta } from "./BottomCta";
import { MascotFab } from "./MascotFab";
import { HeroSection } from "./HeroSection";
import type { MockupProfili } from "./mockupProfilleri";

/**
 * Landing sayfasının client tarafı state yönetimi.
 *
 * Flutter / APK sözleşmesi:
 *  1. Maskot veya landing CTA tıklanır → telefon mockup'ının içinde asistan açılır.
 *  2. Mobilde landing 560px konumuna 450ms easeOutCubic ile kayar.
 *  3. Masaüstünde hero başlangıcına (0px) kayar.
 *  4. Sohbet "Kapat" denilirse mockup slaytları geri döner.
 */
export function LandingChatWrapper({
  children,
  profiller,
}: {
  children: ReactNode;
  profiller: MockupProfili[];
}) {
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [initialAssistantName, setInitialAssistantName] = useState("");

  const mockupKonumunaKaydir = useCallback(() => {
    const hedef = window.innerWidth <= 768 ? 560 : 0;
    const maxKaydirma = Math.max(
      0,
      document.documentElement.scrollHeight - window.innerHeight,
    );
    const bitis = Math.min(Math.max(hedef, 0), maxKaydirma);
    const baslangic = window.scrollY;
    const fark = bitis - baslangic;

    if (Math.abs(fark) < 1) return;

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      window.scrollTo(0, bitis);
      return;
    }

    const sure = 450;
    const baslangicAni = performance.now();

    const adim = (simdi: number) => {
      const oran = Math.min(1, (simdi - baslangicAni) / sure);
      const easeOutCubic = 1 - Math.pow(1 - oran, 3);
      window.scrollTo(0, baslangic + fark * easeOutCubic);
      if (oran < 1) window.requestAnimationFrame(adim);
    };

    window.requestAnimationFrame(adim);
  }, []);

  const asistaniAc = useCallback(
    (initialName = "") => {
      const temizAd = initialName.trim();
      if (temizAd) setInitialAssistantName(temizAd);
      setIsChatOpen(true);
      window.requestAnimationFrame(mockupKonumunaKaydir);
    },
    [mockupKonumunaKaydir],
  );

  const handleStartAssistant = useCallback(
    (initialName = "") => {
      asistaniAc(initialName);
    },
    [asistaniAc],
  );

  const handleToggle = useCallback(() => {
    if (isChatOpen) {
      setIsChatOpen(false);
      return;
    }
    asistaniAc();
  }, [asistaniAc, isChatOpen]);

  const handleChatClose = useCallback(() => {
    setIsChatOpen(false);
  }, []);

  return (
    <>
      <HeroSection
        profiller={profiller}
        isChatOpen={isChatOpen}
        initialAssistantName={initialAssistantName}
        onStartAssistant={handleStartAssistant}
        onChatClose={handleChatClose}
      />
      {children}
      <BottomCta onStartAssistant={() => handleStartAssistant()} />
      <MascotFab onToggle={handleToggle} />
    </>
  );
}
