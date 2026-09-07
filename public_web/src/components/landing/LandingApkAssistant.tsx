"use client";

import { LandingAsistanSohbeti } from "./LandingAsistanSohbeti";

/**
 * Telefon mockup'ında ayrı bir onboarding akışı YOK.
 *
 * Flutter Web referansının Next.js karşılığı tek uygulamadır:
 * `LandingAsistanSohbeti`. Bu kabuk yalnız mevcut motora delege eder.
 * Buraya bağımsız state, buton metni veya akış eklemek parite kapısını kırar.
 */
export function LandingApkAssistant({
  initialName = "",
  onClose,
}: {
  initialName?: string;
  onClose?: () => void;
}) {
  return (
    <LandingAsistanSohbeti
      initialName={initialName}
      onClose={onClose}
    />
  );
}
