import type { Metadata } from "next";

// Giriş ekranı indekslenmesin — oturum açma yüzeyi (audit: SEO iç ekranlar).
export const metadata: Metadata = {
  robots: "noindex, nofollow",
};

export default function GirisLayout({ children }: { children: React.ReactNode }) {
  return children;
}
