"use client";

import {
  createContext,
  useContext,
  useCallback,
  useState,
  useEffect,
  type ReactNode,
} from "react";
import Script from "next/script";

// Audit (26): Google betiği 346KB ve SİTESİ GENELİNDİKİ HER sayfada
// yükleniyordu — oysa yalnızca rent-demo + randevu akışları kullanır.
// Yükleme artık talep olduğunda başlar: sayfa mount'ta script yok,
// "Randevu Al"/"Kirala" akışına giren kullanıcıda yüklenir.
const GERCEK_EYLEMLER = new Set(["rent_demo", "booking_create", "booking_track"]);

const SITE_KEY = process.env.NEXT_PUBLIC_RECAPTCHA_SITE_KEY || "";

interface RecaptchaContextValue {
  executeRecaptcha: (action?: string) => Promise<string | null>;
  isReady: boolean;
  /** Google betiğini önden başlatır (yalnız onu gerçekten kullanan sayfalar çağırır). */
  hazirla: () => void;
}

const RecaptchaContext = createContext<RecaptchaContextValue>({
  executeRecaptcha: async () => null,
  isReady: false,
  hazirla: () => {},
});

export function useRecaptcha() {
  return useContext(RecaptchaContext);
}

declare global {
  interface Window {
    grecaptcha?: {
      ready: (cb: () => void) => void;
      execute: (siteKey: string, options: { action: string }) => Promise<string>;
    };
  }
}

export function RecaptchaProvider({ children }: { children: ReactNode }) {
  const [isReady, setIsReady] = useState(false);
  const [scriptEklendi, setScriptEklendi] = useState(false);

  // Betiği talep üzerine yükler. executeRecaptcha çağrıldığında tetiklenir;
  // rent-demo ayrıca mount'ta hazırlığı başlatmak için hazirla()'yı çağırır.
  const hazirla = useCallback(() => {
    setScriptEklendi(true);
  }, []);

  useEffect(() => {
    if (!SITE_KEY || !scriptEklendi) return;

    const checkReady = setInterval(() => {
      if (window.grecaptcha && typeof window.grecaptcha.execute === "function") {
        setIsReady(true);
        clearInterval(checkReady);
      }
    }, 200);

    return () => clearInterval(checkReady);
  }, [scriptEklendi]);

  const executeRecaptcha = useCallback(
    async (action: string = "submit"): Promise<string | null> => {
      if (!SITE_KEY) return null;
      // Gerçek eylem adları betiği talep üzerine başlatır; site genelinde
      // önden yükleme yok. Betik hazır olana kadar await edilir.
      if (GERCEK_EYLEMLER.has(action)) {
        setScriptEklendi(true);
      }
      if (!window.grecaptcha) {
        const hazirMi = await new Promise<boolean>((resolve) => {
          let deneme = 0;
          const kontrol = setInterval(() => {
            deneme += 1;
            if (window.grecaptcha && typeof window.grecaptcha.execute === "function") {
              clearInterval(kontrol);
              resolve(true);
            } else if (deneme > 150) {
              clearInterval(kontrol);
              resolve(false);
            }
          }, 200);
        });
        if (!hazirMi) return null;
      }

      try {
        return await new Promise<string>((resolve, reject) => {
          window.grecaptcha!.ready(() => {
            window
              .grecaptcha!.execute(SITE_KEY, { action })
              .then(resolve)
              .catch(reject);
          });
        });
      } catch (err) {
        console.error("[reCAPTCHA] Execute error:", err);
        return null;
      }
    },
    [],
  );

  if (!SITE_KEY) {
    return <>{children}</>;
  }

  return (
    <RecaptchaContext.Provider value={{ executeRecaptcha, isReady, hazirla }}>
      {scriptEklendi ? (
        <Script
          src={`https://www.google.com/recaptcha/api.js?render=${SITE_KEY}`}
          strategy="afterInteractive"
        />
      ) : null}
      {children}
    </RecaptchaContext.Provider>
  );
}
