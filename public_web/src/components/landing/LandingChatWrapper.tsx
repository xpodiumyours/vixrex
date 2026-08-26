"use client";

import { useState, useCallback } from "react";
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
  profiller,
}: {
  profiller: MockupProfili[];
}) {
  const [isChatOpen, setIsChatOpen] = useState(false);

  const handleToggle = useCallback(() => {
    setIsChatOpen((onceki) => !onceki);
  }, []);

  const handleChatClose = useCallback(() => {
    setIsChatOpen(false);
  }, []);

  return (
    <>
      <HeroSection profiller={profiller} isChatOpen={isChatOpen} onChatClose={handleChatClose} />
      <MascotFab onToggle={handleToggle} />
    </>
  );
}
