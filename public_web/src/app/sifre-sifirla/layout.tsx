import type { Metadata } from "next";

// Şifre sıfırlama ekranı indekslenmesin — oturum açma yüzeyi (audit: SEO iç ekranlar).
export const metadata: Metadata = {
  robots: "noindex, nofollow",
};

export default function SifreSifirlaLayout({ children }: { children: React.ReactNode }) {
  return children;
}
