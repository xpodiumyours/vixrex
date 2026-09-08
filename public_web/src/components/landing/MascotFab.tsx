"use client";

import { useEffect, useState, useSyncExternalStore } from "react";
import {
  parseConsentSnapshot,
  readConsentSnapshot,
  subscribeToConsent,
} from "@/lib/cookieConsent";
import styles from "./landingFlutterParity.module.css";

/** Flutter `chatbot_badge.dart` landing davranışının web karşılığı. */
export function MascotFab({
  onToggle,
  mesajGoster = true,
}: {
  onToggle: () => void;
  mesajGoster?: boolean;
}) {
  const consentSnapshot = useSyncExternalStore(
    subscribeToConsent,
    readConsentSnapshot,
    () => null,
  );
  const [balonAcik, setBalonAcik] = useState(true);

  useEffect(() => {
    if (!mesajGoster) return;
    setBalonAcik(true);
    const timer = window.setTimeout(() => setBalonAcik(false), 6000);
    return () => window.clearTimeout(timer);
  }, [mesajGoster]);

  // Çerez bildirimi açıkken düğmeyi erişilemez bir katmanın altında bırakma.
  if (!parseConsentSnapshot(consentSnapshot)) return null;

  return (
    <div className="pointer-events-none fixed bottom-4 right-4 z-40 flex flex-col items-end">
      {mesajGoster && balonAcik ? (
        <button
          type="button"
          onClick={() => setBalonAcik(false)}
          className={`${styles.mascotBubble} pointer-events-auto mb-1.5 max-w-[220px] cursor-pointer rounded-[14px] rounded-br-[3px] border-[1.2px] border-[#0EA5E9]/70 bg-[#0E1B2E]/[0.93] px-3 py-[7px] text-left text-[11.5px] font-bold text-white shadow-[0_3px_10px_rgba(14,165,233,0.27)]`}
          aria-label="Vixrex Asistan mesajını kapat"
        >
          👋 Dijital vitrinini hazırlayayım mı?
        </button>
      ) : null}

      <button
        type="button"
        onClick={onToggle}
        className="pointer-events-auto flex h-[60px] w-[60px] items-center justify-center overflow-hidden rounded-full border-[1.5px] border-[#38A0E4]/60 bg-[#0E1B2E]/80 animate-mascot-pulse focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary"
        aria-label="Vixrex Asistan'ı aç"
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/images/vixrex_v_crystal_mascot.png"
          alt=""
          width={60}
          height={60}
          className="h-full w-full object-contain p-1"
        />
      </button>
    </div>
  );
}
