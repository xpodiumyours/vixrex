"use client";

import { LandingAsistanSohbeti } from "./LandingAsistanSohbeti";

/**
 * Landing telefon mockup'ındaki Vixrex Asistan yüzeyi.
 *
 * Flutter referansı `LandingHeroMockup` içinde doğrudan
 * `VixRexOnboardingChatScreen(compact: true)` çalıştırır. Web tarafında da
 * ayrı bir karşılama/ad toplama state makinesi tutulmaz; mevcut gerçek
 * landing onboarding yüzeyi doğrudan kullanılır.
 */
export function LandingApkAssistant({
  initialName = "",
  onClose,
}: {
  initialName?: string;
  onClose?: () => void;
}) {
  return <LandingAsistanSohbeti initialName={initialName} onClose={onClose} />;
}
