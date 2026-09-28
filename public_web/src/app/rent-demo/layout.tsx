import type { Metadata } from "next";

// Kiralama köprü ekranı indekslenmesin — oturum açma/kiralama yüzeyi (audit: SEO iç ekranlar).
export const metadata: Metadata = {
  robots: "noindex, nofollow",
};

export default function RentDemoLayout({ children }: { children: React.ReactNode }) {
  return children;
}
