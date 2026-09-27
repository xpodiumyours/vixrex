import type { Metadata } from "next";

// Instagram bağlantı ekranı indekslenmesin — oturum açma yüzeyi (audit: SEO iç ekranlar).
export const metadata: Metadata = {
  robots: "noindex, nofollow",
};

export default function InstagramBaglantiLayout({ children }: { children: React.ReactNode }) {
  return children;
}
