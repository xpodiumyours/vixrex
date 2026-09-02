"use client";

import { useEffect, useRef, useState } from "react";
import { useRecaptcha } from "@/components/recaptcha/RecaptchaProvider";
import { supabase } from "@/lib/supabase";

const RECAPTCHA_FALLBACK_TOKEN = "recaptcha-unavailable";
const RECAPTCHA_BEKLEME_MS = 3500;

export type KesfetKiralaDurum =
  | "kapali"
  | "kontrolEdiliyor"
  | "gonderiliyor"
  | "hata"
  | "zatenVitriniVar";

export interface KesfetKiralaState {
  durum: KesfetKiralaDurum;
  hataMesaji: string;
  mevcutSlug: string;
  token: string | null;
  formRef: React.RefObject<HTMLFormElement | null>;
  /** "Kirala" tıklanınca çağrılır — akışı başlatır. */
  baslat: () => void;
  /** Modal kapatılınca durumu sıfırlar (tekrar denenebilsin). */
  sifirla: () => void;
}

/**
 * "Kirala" düğmesinin Keşfet'te KALARAK çalışan hâli — Faz C3 (Tek
 * Asistan planı, 2026-09-02, kullanıcı kararıyla küçültüldü: giriş
 * ZORUNLU olmuyor, yalnız `/rent-demo`'nun ayrı-sayfa sıçraması Keşfet
 * içi bir deneyime çevriliyor).
 *
 * Mantık `RentDemoIcerik`in (app/rent-demo/page.tsx) misafir + hesaplı
 * dallarıyla BİREBİR aynı — session kontrolü, hesaplı kullanıcıda
 * `/api/rent-demo/hesap`, misafirde reCAPTCHA + native `<form>` POST.
 * `hesapliAkis && !kaliciHesapVar → /giris'e zorla yönlendir` dalı
 * KASITLI OLARAK yok: Kirala hiçbir zaman giriş zorlamaz, sadece zaten
 * girişliyse hesaba bağlı kiralar.
 *
 * KASITLI KOPYA, refactor DEĞİL: `/rent-demo/page.tsx`'i Flutter (harici
 * tarayıcı, `AppRouter.navigateToRentDemo`) ve eski APK'lar hâlâ doğrudan
 * kullanıyor — güvenlik kritik, çok tüketicili o dosyaya dokunmadım.
 * Reçete değişirse İKİSİ de güncellenmeli; bu bilinçli bir ödünleşim.
 */
export function useKesfetKirala(slug: string): KesfetKiralaState {
  const { executeRecaptcha, isReady } = useRecaptcha();
  const [durum, setDurum] = useState<KesfetKiralaDurum>("kapali");
  const [token, setToken] = useState<string | null>(null);
  const [hataMesaji, setHataMesaji] = useState("");
  const [mevcutSlug, setMevcutSlug] = useState("");
  const formRef = useRef<HTMLFormElement>(null);
  const denendiRef = useRef(false);

  function baslat() {
    if (!slug || durum !== "kapali") return;
    denendiRef.current = false;
    setDurum("kontrolEdiliyor");
  }

  function sifirla() {
    denendiRef.current = false;
    setToken(null);
    setHataMesaji("");
    setMevcutSlug("");
    setDurum("kapali");
  }

  useEffect(() => {
    if (durum !== "kontrolEdiliyor" || denendiRef.current) return;
    let iptalEdildi = false;

    async function kiralamayiBaslat() {
      const { data, error } = await supabase.auth.getSession();
      if (iptalEdildi || denendiRef.current) return;

      if (error) {
        denendiRef.current = true;
        setHataMesaji("Oturum bilgisi okunamadı. Lütfen tekrar dene.");
        setDurum("hata");
        return;
      }

      const session = data.session;
      const kaliciHesapVar = session?.user != null && !session.user.is_anonymous;

      if (kaliciHesapVar) {
        denendiRef.current = true;

        const kiralamaYaniti = await fetch("/api/rent-demo/hesap", {
          method: "POST",
          headers: {
            authorization: `Bearer ${session.access_token}`,
            "content-type": "application/json",
          },
          body: JSON.stringify({ slug }),
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

        window.location.assign(String(kiralamaSonucu.yonlendir));
        return;
      }

      // Misafir yolu: reCAPTCHA ek korumadır, Google betiği yüklenmezse
      // sonsuza kadar bekletilmez — sunucudaki HMAC + oran sınırı zaten var.
      if (!isReady) {
        await new Promise((resolve) => window.setTimeout(resolve, RECAPTCHA_BEKLEME_MS));
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
      setHataMesaji("Kiralama bağlantısı kurulamadı. Lütfen biraz sonra tekrar dene.");
      setDurum("hata");
    });

    return () => {
      iptalEdildi = true;
    };
  }, [durum, slug, isReady, executeRecaptcha]);

  // Misafir yolu: token gelince gerçek <form> POST edilir (bkz. çağıran
  // bileşendeki gizli form) — fetch/JS ile yönlendirme takip edilmez,
  // tarayıcı POST → 303 → GET /api/owner-session → 303 + Set-Cookie →
  // /v/:slug zincirini native izlesin diye (bkz. /rent-demo/page.tsx).
  useEffect(() => {
    if (durum === "gonderiliyor" && token && formRef.current) {
      formRef.current.submit();
    }
  }, [durum, token]);

  return { durum, hataMesaji, mevcutSlug, token, formRef, baslat, sifirla };
}
