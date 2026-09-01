"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

export default function HesapBaglaPage() {
  const router = useRouter();
  const [hata, setHata] = useState("");

  useEffect(() => {
    let iptal = false;

    async function tamamla() {
      const slug = new URLSearchParams(window.location.search)
        .get("slug")
        ?.trim();
      if (!slug) {
        setHata("Vitrin bilgisi eksik.");
        return;
      }

      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (iptal) return;
      if (!session || session.user.is_anonymous) {
        setHata("Google hesabı bağlanamadı. Lütfen vitrinden tekrar dene.");
        return;
      }

      const yanit = await fetch("/api/account/link-store", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ slug }),
      });
      const sonuc = await yanit.json();
      if (iptal) return;
      if (!yanit.ok) {
        setHata(sonuc.hata || "Vitrin hesabına bağlanamadı.");
        return;
      }

      router.replace(`/v/${encodeURIComponent(slug)}?owner=true`);
    }

    void tamamla();
    return () => {
      iptal = true;
    };
  }, [router]);

  return (
    <main className="grid min-h-screen place-items-center bg-[#071126] px-6 text-white">
      <div className="w-full max-w-md rounded-2xl border border-blue-400/30 bg-[#0d1b38] p-6 text-center">
        <p className="text-lg font-black">
          {hata ? "Hesap bağlantısı tamamlanamadı" : "Vitrinin hesabına bağlanıyor…"}
        </p>
        {hata ? (
          <>
            <p className="mt-3 text-sm leading-6 text-white/70" role="alert">
              {hata}
            </p>
            <Link href="/" className="mt-5 inline-flex rounded-xl bg-blue-500 px-5 py-3 font-bold">
              Ana sayfaya dön
            </Link>
          </>
        ) : null}
      </div>
    </main>
  );
}
