import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "VitrinX - Küçük İşletmeler İçin Dijital Vitrin",
  description: "İşletmenizin ürünlerini sergileyin, online randevu alın ve Google görünürlüğünüzü artırın.",
  metadataBase: new URL("https://vitrinx.app"),
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr" className="h-full antialiased font-outfit">
      <body className="min-h-full flex flex-col bg-[#F4F5F8] dark:bg-[#0B0F13] text-[#182028] dark:text-[#F1F5F9]">
        {children}
      </body>
    </html>
  );
}
