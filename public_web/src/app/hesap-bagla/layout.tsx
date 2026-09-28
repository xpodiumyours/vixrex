import type { Metadata } from "next";

// Hesap bağlama ekranı indekslenmesin — oturum açma yüzeyi (audit: SEO iç ekranlar).
export const metadata: Metadata = {
  robots: "noindex, nofollow",
};

export default function HesapBaglaLayout({ children }: { children: React.ReactNode }) {
  return children;
}
