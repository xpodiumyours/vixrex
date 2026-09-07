"use client";

import { FlutterReferenceOnboarding } from "./FlutterReferenceOnboarding";

/**
 * Telefon mockup'ında ayrı bir onboarding akışı YOK.
 * Flutter Web referansının Next.js karşılığı tek canonical yüzdür:
 * `FlutterReferenceOnboarding`.
 */
export function LandingApkAssistant({
  initialName = "",
  onClose,
}: {
  initialName?: string;
  onClose?: () => void;
}) {
  return (
    <FlutterReferenceOnboarding
      initialName={initialName}
      onClose={onClose}
    />
  );
}
