"use client";

import { useState } from "react";

/**
 * Yüzen maskot — envanter §2.12.
 *
 * Flutter'da bu düğme sohbet motorunu (VixRexSessionController) açıyor;
 * web'de öyle bir motor yok. Burada sayfanın kurulum çağrısına kaydırır —
 * #344 planının (docs/agents/344-demosuz-landing-plani.md §1) öngördüğü
 * davranış budur.
 *
 * Ana sayfadaki iki istemci adasından ikincisi.
 */
export function MascotFab() {
  const [balonAcik, setBalonAcik] = useState(false);

  function basla() {
    const hedef = document.getElementById("basla");
    hedef?.scrollIntoView({ behavior: "smooth", block: "center" });
  }

  return (
    <div className="pointer-events-none fixed bottom-5 right-5 z-40 flex flex-col items-end gap-2">
      {balonAcik ? (
        <p className="pointer-events-auto max-w-[230px] rounded-2xl border border-lp-border bg-lp-surface px-4 py-3 text-[13px] font-semibold text-lp-text-alt shadow-lp-card">
          Vitrinini birlikte kuralım — başlamak için dokun.
        </p>
      ) : null}

      <button
        type="button"
        onClick={() => {
          if (balonAcik) basla();
          else setBalonAcik(true);
        }}
        onMouseEnter={() => setBalonAcik(true)}
        className="pointer-events-auto flex h-[60px] w-[60px] items-center justify-center rounded-full border border-lp-primary/40 bg-lp-surface shadow-lp-panel"
        aria-label="Vitrin kurulumuna git"
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/images/vixrex_v_crystal_mascot.png"
          alt=""
          width={44}
          height={44}
          className="h-11 w-11 object-contain"
        />
      </button>
    </div>
  );
}
