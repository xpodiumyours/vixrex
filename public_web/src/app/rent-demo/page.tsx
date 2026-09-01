"use client";

// "Bu vitrini kirala" güvenli köprü sayfası (2026-08-15, güvenlik açığı
// kapatılırken eklendi).
//
// Buraya iki yerden gelinir:
//   - Web CTA'sı (VitrinProfileView.tsx): düz <a href="/rent-demo?slug=x">.
//   - Flutter (AppRouter.navigateToRentDemo, harici tarayıcı): aynı URL.
//   - Eski (güncellenmemiş) Flutter APK'ları: /api/rent-demo GET → buraya
//     303 ile yönlendirilir (bkz. api/rent-demo/route.ts).
//
// Görevi TEK şey: reCAPTCHA v3 token'ı al, gerçek <form method="POST">
// gönder. Fetch/JS ile yönlendirme takip ETMİYORUZ — tarayıcının kendisi
// POST → 303 → GET /api/owner-session → 303 + Set-Cookie → /v/:slug
// zincirini native olarak izlesin, çerez/yönlendirme davranışı sunucu
// tarafındaki mevcut akışla birebir aynı kalsın.
//
// HOTFIX (2026-08-15): useSearchParams() App Router'da bir <Suspense>
// sınırı içinde olmak ZORUNDA — yoksa `next build` prerender aşamasında
// çöküyor ("should be wrapped in a suspense boundary"). Bu PR2'de (main'e
// zaten inmişti) atlanmıştı, main'in build'i kırıktı. Mantık taşınmadı,
// yalnız useSearchParams kullanan kısım ayrı bir bileşene çıkarılıp
// Suspense ile sarıldı.

import { Suspense, useEffect, useRef, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useRecaptcha } from "@/components/recaptcha/RecaptchaProvider";
import { supabase } from "@/lib/supabase";

type Durum = "kontrolEdiliyor" | "gonderiliyor" | "hata" | "zatenVitriniVar";

const RECAPTCHA_FALLBACK_TOKEN = "recaptcha-unavailable";
const RECAPTCHA_BEKLEME_MS = 3500;

function HataSayfasi({ mesaj }: { mesaj: string }) {
  return (
    <main
      style={{
        display: "grid",
        placeItems: "center",
        minHeight: "100vh",
        background: "#0B1120",
        color: "#fff",
        fontFamily: "system-ui, -apple-system, sans-serif",
      }}
    >
      <div style={{ maxWidth: 420, padding: 24, textAlign: "center" }}>
        <h1 style={{ fontSize: 20 }}>Vitrin Açılamadı</h1>
        <p style={{ color: "rgba(255,255,255,0.7)", lineHeight: 1.6 }}>{mesaj}</p>
      </div>
    </main>
  );
}

function BekleniyorSayfasi() {
  return (
    <main
      style={{
        display: "grid",
        placeItems: "center",
        minHeight: "100vh",
        background: "#0B1120",
        color: "#fff",
        fontFamily: "system-ui, -apple-system, sans-serif",
      }}
    >
      <p style={{ color: "rgba(255,255,255,0.7)" }}>Vitrin hazırlanıyor…</p>
    </main>
  );
}

function MevcutVitrinSayfasi({ slug }: { slug: string }) {
  return (
    <main
      style={{
        display: "grid",
        placeItems: "center",
        minHeight: "100vh",
        background: "#0B1120",
        color: "#fff",
        fontFamily: "system-ui, -apple-system, sans-serif",
      }}
    >
      <div style={{ maxWidth: 420, padding: 24, textAlign: "center" }}>
        <h1 style={{ fontSize: 20 }}>Zaten bir vitrinin var</h1>
        <p style={{ color: "rgba(255,255,255,0.7)", lineHeight: 1.6 }}>
          Bu hesapla ikinci bir vitrin kiralanamaz.
        </p>
        {slug ? (
          <a
            href={`/v/${encodeURIComponent(slug)}`}
            style={{ color: "#fff", fontWeight: 700 }}
          >
            Mevcut vitrinine git
          </a>
        ) : null}
      </div>
    </main>
  );
}

function RentDemoIcerik() {
  const searchParams = useSearchParams();
  const demoSlug = (searchParams.get("slug") ?? "").trim();
  const hesapliAkis = searchParams.get("hesap") === "1";
  const { executeRecaptcha, isReady } = useRecaptcha();
  const [durum, setDurum] = useState<Durum>("kontrolEdiliyor");
  const [token, setToken] = useState<string | null>(null);
  const [hataMesaji, setHataMesaji] = useState("");
  const [mevcutSlug, setMevcutSlug] = useState("");
  const formRef = useRef<HTMLFormElement>(null);
  const denendiRef = useRef(false);

  useEffect(() => {
    if (!demoSlug || denendiRef.current) return;
    let iptalEdildi = false;

    async function kiralamayiBaslat() {
      const { data, error } = await supabase.auth.getSession();
      if (iptalEdildi || denendiRef.current) return;

      if (error) {
        denendiRef.current = true;
        setHataMesaji("Oturum bilgisi okunamadı. Lütfen sayfayı yenileyip tekrar dene.");
        setDurum("hata");
        return;
      }

      const session = data.session;
      const kaliciHesapVar = session?.user != null && !session.user.is_anonymous;

      if (hesapliAkis && !kaliciHesapVar) {
        denendiRef.current = true;
        const geriDonus = `/rent-demo?slug=${encodeURIComponent(demoSlug)}&hesap=1`;
        window.location.replace(`/giris?next=${encodeURIComponent(geriDonus)}`);
        return;
      }

      if (kaliciHesapVar) {
        denendiRef.current = true;

        const kiralamaYaniti = await fetch("/api/rent-demo/hesap", {
          method: "POST",
          headers: {
            authorization: `Bearer ${session.access_token}`,
            "content-type": "application/json",
          },
          body: JSON.stringify({ slug: demoSlug }),
        });
        const kiralamaSonucu = await kiralamaYaniti.json().catch(() => ({}));

        if (iptalEdildi) return;

        if (kiralamaYaniti.status === 409) {
          setMevcutSlug(String(kiralamaSonucu.slug ?? ""));
          setDurum("zatenVitriniVar");
          return;
        }

        if (!kiralamaYaniti.ok) {
          setHataMesaji(
            String(kiralamaSonucu.hata ?? "Vitrin şu anda kiralanamıyor. Lütfen tekrar dene.")
          );
          setDurum("hata");
          return;
        }

        if (!kiralamaSonucu.yonlendir) {
          setHataMesaji(
            "Vitrin hesabına bağlandı ancak sahip ekranı açılamadı. Vitrinine hesabından ulaşabilirsin."
          );
          setDurum("hata");
          return;
        }

        // API, Flutter'daki gibi kiralama + sahip oturumu zincirini tek
        // işlemde tamamladı. Tarayıcı yalnız tek kullanımlık giriş adresine
        // gider; edit_token istemciye taşınmaz.
        window.location.assign(String(kiralamaSonucu.yonlendir));
        return;
      }

      // Misafir yolu: reCAPTCHA ek korumadır fakat Google betiği mobil ağda
      // yüklenmezse kullanıcı sonsuza kadar bekletilmez. Sunucudaki zorunlu
      // HMAC + üç katmanlı oran sınırı her durumda çalışmaya devam eder.
      if (!isReady) {
        await new Promise((resolve) =>
          window.setTimeout(resolve, RECAPTCHA_BEKLEME_MS)
        );
        if (iptalEdildi || denendiRef.current) return;
        denendiRef.current = true;
        setToken(RECAPTCHA_FALLBACK_TOKEN);
        setDurum("gonderiliyor");
        return;
      }

      denendiRef.current = true;
      const recaptchaToken = await executeRecaptcha("rent_demo");
      if (iptalEdildi) return;
      setToken(recaptchaToken || RECAPTCHA_FALLBACK_TOKEN);
      setDurum("gonderiliyor");
    }

    void kiralamayiBaslat().catch(() => {
      if (iptalEdildi) return;
      denendiRef.current = true;
      setHataMesaji(
        "Kiralama bağlantısı kurulamadı. Lütfen biraz sonra tekrar dene."
      );
      setDurum("hata");
    });
    return () => {
      iptalEdildi = true;
    };
  }, [demoSlug, hesapliAkis, isReady, executeRecaptcha]);

  useEffect(() => {
    if (durum === "gonderiliyor" && token && formRef.current) {
      formRef.current.submit();
    }
  }, [durum, token]);

  if (!demoSlug) {
    return <HataSayfasi mesaj="Kiralama bağlantısında vitrin bilgisi eksik." />;
  }

  if (durum === "hata") {
    return <HataSayfasi mesaj={hataMesaji} />;
  }

  if (durum === "zatenVitriniVar") {
    return <MevcutVitrinSayfasi slug={mevcutSlug} />;
  }

  return (
    <main
      style={{
        display: "grid",
        placeItems: "center",
        minHeight: "100vh",
        background: "#0B1120",
        color: "#fff",
        fontFamily: "system-ui, -apple-system, sans-serif",
      }}
    >
      <div style={{ maxWidth: 420, padding: 24, textAlign: "center" }}>
        <p style={{ color: "rgba(255,255,255,0.7)" }}>Vitrin hazırlanıyor…</p>
        <div
          style={{
            marginTop: 24,
            padding: 16,
            borderRadius: 12,
            background: "rgba(251, 191, 36, 0.15)",
            border: "1px solid rgba(251, 191, 36, 0.3)",
            textAlign: "left",
            fontSize: 13,
            lineHeight: 1.6,
          }}
        >
          <p style={{ margin: 0, fontWeight: 700, color: "#FBBF24" }}>
            ⚠️ Deneme sürümü — yalnız bu cihazda
          </p>
          <p style={{ margin: "8px 0 0", color: "rgba(255,255,255,0.8)" }}>
            Vitrinin 14 gün boyunca ücretsiz. Fakat şu an erişimi yalnız bu
            cihaza özeldir. Vitrini kalıcı olarak hesabına bağlamak için
            vitrin yönetim ekranından Google ile giriş yapman yeterli.
          </p>
        </div>
      </div>
      {/* JS'siz/gövde-parse edilemeyen ortamlarda bile POST'un native form
          davranışıyla gitmesi için gerçek bir <form>; action route.ts'in
          POST handler'ına gider, JSON değil form-encoded veri okunur. */}
      <form ref={formRef} method="POST" action="/api/rent-demo" hidden>
        <input type="hidden" name="slug" value={demoSlug} />
        <input type="hidden" name="recaptchaToken" value={token ?? ""} />
      </form>
    </main>
  );
}

export default function RentDemoPage() {
  return (
    <Suspense fallback={<BekleniyorSayfasi />}>
      <RentDemoIcerik />
    </Suspense>
  );
}
