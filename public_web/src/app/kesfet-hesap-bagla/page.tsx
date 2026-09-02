"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

/**
 * Google linkIdentity() dönüş noktası — Keşfet'teki "Kirala" akışının
 * hesap gerektiren dalı (UI/UX görünüm fazı, 2026-09-02). `/hesap-bagla`
 * ile aynı desen (bkz. o dosya), yalnız hedef RPC farklı: burada
 * mevcut bir taslağı hesaba bağlamıyoruz, `/api/rent-demo/hesap`
 * (rent_demo_canonical) ile YENİ bir kiralama oluşturuyoruz.
 */
export default function KesfetHesapBaglaPage() {
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
        setHata("Google hesabı bağlanamadı. Lütfen Keşfet'ten tekrar dene.");
        return;
      }

      const yanit = await fetch("/api/rent-demo/hesap", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ slug }),
      });
      const sonuc = await yanit.json().catch(() => ({}));
      if (iptal) return;

      if (yanit.status === 409) {
        const mevcutSlug = String(sonuc.slug ?? "").trim();
        if (mevcutSlug) {
          router.replace(`/v/${encodeURIComponent(mevcutSlug)}`);
          return;
        }
        setHata("Bu hesapla ikinci bir vitrin kiralanamaz — zaten bir vitrinin var.");
        return;
      }

      if (!yanit.ok || !sonuc.yonlendir) {
        setHata(sonuc.hata || "Vitrin şu anda kiralanamıyor.");
        return;
      }

      // Tek kullanımlık sahip kodunu tüketip HttpOnly sahip çerezini kur
      // (bkz. /hesap-bagla ve landing yayinla() — aynı desen).
      await fetch(String(sonuc.yonlendir), {
        redirect: "manual",
        credentials: "same-origin",
      });
      router.replace(`/v/${encodeURIComponent(String(sonuc.slug))}?owner=true`);
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
          {hata ? "Kiralama tamamlanamadı" : "Vitrin sana ayarlanıyor…"}
        </p>
        {hata ? (
          <>
            <p className="mt-3 text-sm leading-6 text-white/70" role="alert">
              {hata}
            </p>
            <Link href="/kesfet" className="mt-5 inline-flex rounded-xl bg-blue-500 px-5 py-3 font-bold">
              Keşfet&apos;e dön
            </Link>
          </>
        ) : null}
      </div>
    </main>
  );
}
