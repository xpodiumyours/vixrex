"use client";

import { Suspense, useEffect, useRef, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useRecaptcha } from "@/components/recaptcha/RecaptchaProvider";

type Durum = "kontrolEdiliyor" | "gonderiliyor" | "hata";

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

function RentDemoPageInner() {
  const searchParams = useSearchParams();
  const demoSlug = (searchParams.get("slug") ?? "").trim();
  const { executeRecaptcha, isReady } = useRecaptcha();
  const [durum, setDurum] = useState<Durum>("kontrolEdiliyor");
  const [token, setToken] = useState<string | null>(null);
  const formRef = useRef<HTMLFormElement>(null);
  const denendiRef = useRef(false);

  useEffect(() => {
    if (!demoSlug || !isReady || denendiRef.current) return;
    denendiRef.current = true;

    executeRecaptcha("rent_demo").then((t) => {
      if (!t) {
        setDurum("hata");
        return;
      }
      setToken(t);
      setDurum("gonderiliyor");
    });
  }, [demoSlug, isReady, executeRecaptcha]);

  useEffect(() => {
    if (durum === "gonderiliyor" && token && formRef.current) {
      formRef.current.submit();
    }
  }, [durum, token]);

  if (!demoSlug) {
    return <HataSayfasi mesaj="Kiralama bağlantısında vitrin bilgisi eksik." />;
  }

  if (durum === "hata") {
    return (
      <HataSayfasi mesaj="Güvenlik doğrulaması başarısız. Lütfen sayfayı yenileyip tekrar dene." />
    );
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
      <div style={{ textAlign: "center" }}>
        <p style={{ color: "rgba(255,255,255,0.7)" }}>Vitrin hazırlanıyor…</p>
      </div>
      <form ref={formRef} method="POST" action="/api/rent-demo" hidden>
        <input type="hidden" name="slug" value={demoSlug} />
        <input type="hidden" name="recaptchaToken" value={token ?? ""} />
      </form>
    </main>
  );
}

export default function RentDemoPage() {
  return (
    <Suspense fallback={<div style={{ display: "grid", placeItems: "center", minHeight: "100vh", background: "#0B1120", color: "#fff", fontFamily: "system-ui, -apple-system, sans-serif" }}>Vitrin hazırlanıyor…</div>}>
      <RentDemoPageInner />
    </Suspense>
  );
}
