"use client";

import { useState, useCallback, type ReactNode } from "react";
import { BottomCta } from "./BottomCta";
import { MascotFab } from "./MascotFab";
import { HeroSection } from "./HeroSection";
import type { MockupProfili } from "./mockupProfilleri";

/**
 * Landing sayfasının client tarafı state yönetimi.
 *
 * Flutter'daki akışı taklit eder:
 *  1. Maskot tıklanır → telefon mockup'ının içinde asistan sohbeti açılır.
 *  2. Sohbet "Kapat" denilirse slaytlar geri döner.
 *
 * Bu wrapper, server component olan page.tsx ile client component olan
 * MascotFab/PhoneMockup arasındaki köprüdür.
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

  const handleStartAssistant = useCallback((initialName = "") => {
    const temizAd = initialName.trim();
    if (temizAd) setInitialAssistantName(temizAd);
    setIsChatOpen(true);
    window.requestAnimationFrame(() => {
      document.getElementById("vixrex-hero")?.scrollIntoView({
        behavior: "smooth",
        block: "start",
      });
    });
  }, []);

  const handleToggle = useCallback(() => {
    setIsChatOpen((onceki) => !onceki);
  }, []);

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
