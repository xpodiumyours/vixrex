import type { Metadata } from "next";
import { BottomCta } from "@/components/landing/BottomCta";
import { ComparisonSection } from "@/components/landing/ComparisonSection";
import { FeaturesSection } from "@/components/landing/FeaturesSection";
import { HeroSection } from "@/components/landing/HeroSection";
import { MascotFab } from "@/components/landing/MascotFab";
import { StepsSection } from "@/components/landing/StepsSection";
import { TemplateCatalog } from "@/components/landing/TemplateCatalog";
import { TrustBand } from "@/components/landing/TrustBand";
import { ValueBand } from "@/components/landing/ValueBand";
import { mockupProfilleriniGetir } from "@/components/landing/mockupProfilleri";

// Kök sayfa, 2026-08-26'ya kadar yalnızca uygulamaya yönlendiriyordu:
// adrese giren herkes Flutter uygulamasına atılıyor, Google'ın okuyabileceği
// hiçbir platform sayfası bulunmuyordu (#344). Yönlendirme hem burada hem de
// `next.config.ts`'in `redirects()` bloğunda iki kez tanımlıydı.
//
// Bu dosya SİLİNMEMELİ: gerçek bir App Router sayfası kökü sahiplenmezse
// eski, statik Flutter `index.html` çıktısı `/` adresini kapabiliyor.
//
// Bölümlerin metinleri ve ölçüleri, Flutter landing'inden çıkarılan
// envanterden birebir alınmıştır:
// docs/research/landing-port-envanteri-2026-08-25.md §2 ve §6.

export const revalidate = 300;

export const metadata: Metadata = {
  title: "Vixrex — İşletmenin dijital vitrini, dakikalar içinde",
  description:
    "İşletme bilgilerini, fotoğraflarını, ürün ve hizmetlerini, adresini ve WhatsApp iletişimini tek vitrin linkinde topla. Kredi kartı gerekmez, komisyon yok.",
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    siteName: "Vixrex",
    locale: "tr_TR",
    title: "Vixrex — İşletmenin dijital vitrini",
    description:
      "Tek linkte işletme bilgilerin, ürünlerin, adresin ve WhatsApp iletişimin.",
    url: "/",
  },
};

export default async function HomePage() {
  const profiller = await mockupProfilleriniGetir();

  return (
    <>
      <HeroSection profiller={profiller} />
      <ValueBand />
      <FeaturesSection />
      <ComparisonSection />
      <TrustBand />
      <StepsSection />
      <TemplateCatalog />
      <BottomCta />
      <MascotFab />
    </>
  );
}
