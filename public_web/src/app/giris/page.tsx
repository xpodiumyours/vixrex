"use client";

import Link from "next/link";
import { useState, useSyncExternalStore } from "react";
import { supabase } from "@/lib/supabase";
import { OwnerAuthLayout } from "@/components/owner/OwnerAuthLayout";
import { guvenliDonusYolu } from "@/lib/guvenliDonus";

export const dynamic = "force-dynamic";

const donusYoluDegisikligiYok = () => () => {};
const varsayilanDonusYolu = () => "/app";

function mevcutDonusYolu() {
  const aday = new URLSearchParams(window.location.search).get("next");
  return guvenliDonusYolu(aday);
}

export default function GirisPage() {
  const [hata, setHata] = useState("");
  const [gonderiliyor, setGonderiliyor] = useState(false);
  const sonrakiYol = useSyncExternalStore(
    donusYoluDegisikligiYok,
    mevcutDonusYolu,
    varsayilanDonusYolu,
  );

  async function googleIleDevamEt() {
    setHata("");
    setGonderiliyor(true);
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}${sonrakiYol}` },
    });
    setGonderiliyor(false);
    if (error) setHata(error.message || "Google ile giriş başarısız.");
  }

  return (
    <OwnerAuthLayout
      title="Google ile Devam Et"
      description="Kalıcı Vixrex hesabı ve cihazlar arası erişim için Google kullanılır."
    >
      <div className="rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg-soft)] p-4 text-sm leading-6 text-[var(--owner-muted)]">
        <strong className="text-[var(--owner-text)]">14 günlük ücretsiz deneme için hesap gerekmez.</strong>
        <br />
        Hazır vitrini seçip hemen özelleştirebilirsin. Google yalnız vitrini kalıcı hesabına bağlamak için gerekir.
      </div>

      {hata ? (
        <p role="alert" className="mt-4 rounded-xl border border-[var(--owner-error)]/40 bg-[var(--owner-error)]/10 px-3 py-2.5 text-[13px] font-semibold text-[#FCA5A5]">
          {hata}
        </p>
      ) : null}

      <button
        type="button"
        disabled={gonderiliyor}
        onClick={googleIleDevamEt}
        className="owner-button-primary mt-5 flex w-full items-center justify-center gap-2.5"
      >
        {gonderiliyor ? "Google açılıyor…" : "Google ile Devam Et"}
      </button>

      <Link
        href="/kesfet?yalniz_kiralik=1"
        className="owner-button-secondary mt-3 flex w-full items-center justify-center"
      >
        14 Gün Ücretsiz Vitrin Dene
      </Link>
    </OwnerAuthLayout>
  );
}
