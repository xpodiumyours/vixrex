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
  | "hesapGerekli"
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
  /** hesapGerekli durumunda: Google ile bağlanıp gerçek hesaba kiralar. */
  hesapaBaglaVeKirala: () => void;
  /** hesapGerekli durumunda: kullanıcı bilinçli olarak misafir kalmayı seçer. */
  misafirDevamEt: () => void;
  hesapBaglaniyor: boolean;
  hesapBaglaHata: string;
}

/**
 * "Kirala" düğmesinin Keşfet'te KALARAK çalışan hâli.
 *
 * Faz C3 (2026-09-02): `/rent-demo`'nun ayrı-sayfa sıçraması Keşfet içi
 * bir deneyime çevrildi. UI/UX görünüm fazı (2026-09-02, kullanıcı
 * kararı): "uyarla" anı artık ÖNCELİKLE hesap istiyor — hesabı olmayan
 * ziyaretçi artık otomatik misafir kiralamıyor, "Google ile devam et"
 * teklifi görüyor (`hesapGerekli` durumu). Google linkIdentity() sonucu
 * `/kesfet-hesap-bagla` sayfası üzerinden `/api/rent-demo/hesap`'a
 * (rent_demo_canonical — hesap zorunlu, is_permanent_user ile korunur)
 * bağlanır. Faz C3'ün "giriş asla zorlanmaz" ilkesi tamamen atılmadı:
 * kullanıcı `misafirDevamEt()` ile eski otomatik misafir yolunu (reCAPTCHA
 * + native form POST) bilinçli olarak hâlâ seçebilir — güvenlik ağı
 * kalsın diye kaldırılmadı, yalnız artık varsayılan değil.
 *
 * Mantık `RentDemoIcerik`in (app/rent-demo/page.tsx) misafir + hesaplı
 * dallarıyla aynı kökten geliyor — session kontrolü, hesaplı kullanıcıda
 * `/api/rent-demo/hesap`, misafirde reCAPTCHA + native `<form>` POST.
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
  const [hesapBaglaniyor, setHesapBaglaniyor] = useState(false);
  const [hesapBaglaHata, setHesapBaglaHata] = useState("");
  const formRef = useRef<HTMLFormElement>(null);
  const denendiRef = useRef(false);
  const misafirZorlaRef = useRef(false);

  function baslat() {
    if (!slug || durum !== "kapali") return;
    denendiRef.current = false;
    misafirZorlaRef.current = false;
    setDurum("kontrolEdiliyor");
  }

  function sifirla() {
    denendiRef.current = false;
    misafirZorlaRef.current = false;
    setToken(null);
    setHataMesaji("");
    setMevcutSlug("");
    setHesapBaglaniyor(false);
    setHesapBaglaHata("");
    setDurum("kapali");
  }

  async function hesapaBaglaVeKirala() {
    setHesapBaglaHata("");
    setHesapBaglaniyor(true);
    // Bu cihazda hiç oturum yoksa linkIdentity'nin bağlanacağı bir kimlik
    // gerekir — OwnerWorkspaceShell'deki "hesabına bağla" ile aynı desen.
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      const { error: anonHata } = await supabase.auth.signInAnonymously();
      if (anonHata) {
        setHesapBaglaHata("Bağlantı kurulamadı. Lütfen tekrar dene.");
        setHesapBaglaniyor(false);
        return;
      }
    }
    const { error } = await supabase.auth.linkIdentity({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/kesfet-hesap-bagla?slug=${encodeURIComponent(slug)}`,
      },
    });
    if (error) {
      setHesapBaglaHata(error.message || "Google hesabı bağlanamadı.");
      setHesapBaglaniyor(false);
    }
    // Başarılıysa tarayıcı Google'a yönlenir; bu bileşen zaten terk edilir.
  }

  function misafirDevamEt() {
    misafirZorlaRef.current = true;
    denendiRef.current = false;
    setDurum("kontrolEdiliyor");
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

      // Hesabı olmayan ziyaretçi: artık otomatik misafir kiralaması
      // yapılmaz — önce hesap teklif edilir (bkz. hesapaBaglaVeKirala).
      // Kullanıcı misafirDevamEt() ile bilinçli olarak bu duvarı aşarsa
      // misafirZorlaRef true olur ve aşağıdaki eski akış çalışır.
      if (!misafirZorlaRef.current) {
        denendiRef.current = true;
        setDurum("hesapGerekli");
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

  return {
    durum,
    hataMesaji,
    mevcutSlug,
    token,
    formRef,
    baslat,
    sifirla,
    hesapaBaglaVeKirala,
    misafirDevamEt,
    hesapBaglaniyor,
    hesapBaglaHata,
  };
}
