"use client";

import Link from "next/link";
import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import { OwnerAuthLayout } from "@/components/owner/OwnerAuthLayout";
import { guvenliDonusYolu } from "@/lib/guvenliDonus";

export const dynamic = "force-dynamic";

export default function KayitPage() {
  const [hata, setHata] = useState("");
  const [gonderiliyor, setGonderiliyor] = useState(false);
  const [sonrakiYol, setSonrakiYol] = useState("/app");

  useEffect(() => {
    const aday = new URLSearchParams(window.location.search).get("next");
    setSonrakiYol(guvenliDonusYolu(aday));
  }, []);

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
      title="Vixrex Hesabını Koru"
      description="Şifre oluşturmadan Google hesabınla kalıcı erişim kazan."
    >
      <div className="rounded-xl border border-[var(--owner-border)] bg-[var(--owner-bg-soft)] p-4 text-sm leading-6 text-[var(--owner-muted)]">
        <strong className="text-[var(--owner-text)]">Önce denemek istiyorsan Google zorunlu değil.</strong>
        <br />
        Kiralık vitrini 14 gün ücretsiz kullanabilir, beğendiğinde Google ile kalıcı hesabına bağlayabilirsin.
      </div>

      {hata ? <p className="owner-error mt-4 text-sm" role="alert">{hata}</p> : null}

      <button
        type="button"
        disabled={gonderiliyor}
        onClick={googleIleDevamEt}
        className="owner-button-primary mt-5 w-full"
      >
        {gonderiliyor ? "Google açılıyor…" : "Google ile Devam Et"}
      </button>

      <Link
        href="/kesfet?yalniz_kiralik=1"
        className="owner-button-secondary mt-3 flex w-full items-center justify-center"
      >
        Önce 14 Gün Ücretsiz Dene
      </Link>
    </OwnerAuthLayout>
  );
}
