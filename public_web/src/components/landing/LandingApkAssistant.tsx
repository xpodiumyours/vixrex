"use client";

import { LandingAsistanSohbeti } from "./LandingAsistanSohbeti";

/**
 * Telefon mockup'ı için ayrı onboarding/adım makinesi üretme.
 * Flutter Web referansına uyarlanan tek Next.js asistan yüzü
 * `LandingAsistanSohbeti`dir; bu bileşen yalnız telefon kabuğuna bağlar.
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
