import type { Metadata } from "next";

// Kayıt ekranı indekslenmesin — oturum açma yüzeyi (audit: SEO iç ekranlar).
export const metadata: Metadata = {
  robots: "noindex, nofollow",
};

export default function KayitLayout({ children }: { children: React.ReactNode }) {
  return children;
}
