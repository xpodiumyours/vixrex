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

const SITE_KEY = process.env.NEXT_PUBLIC_RECAPTCHA_SITE_KEY || "";

interface RecaptchaContextValue {
  executeRecaptcha: (action?: string) => Promise<string | null>;
  isReady: boolean;
}

const RecaptchaContext = createContext<RecaptchaContextValue>({
  executeRecaptcha: async () => null,
  isReady: false,
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

  useEffect(() => {
    if (!SITE_KEY) return;

    const checkReady = setInterval(() => {
      if (window.grecaptcha && typeof window.grecaptcha.execute === "function") {
        setIsReady(true);
        clearInterval(checkReady);
      }
    }, 200);

    return () => clearInterval(checkReady);
  }, []);

  const executeRecaptcha = useCallback(
    async (action: string = "submit"): Promise<string | null> => {
      if (!SITE_KEY || !window.grecaptcha) return null;

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
    <RecaptchaContext.Provider value={{ executeRecaptcha, isReady }}>
      <Script
        src={`https://www.google.com/recaptcha/api.js?render=${SITE_KEY}`}
        strategy="afterInteractive"
      />
      {children}
    </RecaptchaContext.Provider>
  );
}
