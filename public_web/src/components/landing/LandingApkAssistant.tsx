"use client";

import { LandingAsistanSohbeti } from "./LandingAsistanSohbeti";

/**
 * Landing telefon maketindeki asistan yüzeyi.
 *
 * Flutter referansı tek onboarding ekranını kullanıyor; web de ikinci bir
 * karşılama/quick-action katmanı üretmez. Böylece Hızlı Seçenekler,
 * karşılama metni ve sonraki adımlar doğrudan ortak LandingAsistanSohbeti
 * motorundan gelir.
 */
export function LandingApkAssistant({
  initialName = "",
  onClose,
}: {
  initialName?: string;
  onClose?: () => void;
}) {
  return (
    <LandingAsistanSohbeti initialName={initialName} onClose={onClose} />
  );
}
