import type { Metadata } from "next";

// Sahip paneli arama motorlarına kapalı — giriş gerektiren iç ekran (audit: SEO).
export const metadata: Metadata = {
  robots: "noindex, nofollow",
};

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return children;
}
