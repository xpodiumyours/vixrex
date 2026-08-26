import { ImageResponse } from "next/og";

/**
 * Paylaşım görseli.
 *
 * 2026-08-26'ya kadar site genelinde hiç Open Graph görseli yoktu: link
 * WhatsApp'ta ya da sosyal medyada paylaşıldığında boş bir kart çıkıyordu.
 * Vitrin sayfaları kendi görsellerini zaten belirtiyor (`openGraph.images`),
 * bu dosya yalnız onu belirtmeyen platform sayfaları için devreye girer.
 *
 * Kart, diskten font okumadan üretiliyor — özel bir font dosyasını çalışma
 * zamanında okumak Turbopack kök ayarıyla kırılgan bir bağımlılık olurdu.
 */
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = "Vixrex — işletmenin dijital vitrini";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: 80,
          background: "linear-gradient(135deg, #050B1A 0%, #147DFF 160%)",
          color: "#F7FBFF",
        }}
      >
        <div
          style={{
            fontSize: 26,
            letterSpacing: 8,
            color: "#57B7FF",
            fontWeight: 700,
          }}
        >
          VIXREX
        </div>
        <div
          style={{
            marginTop: 28,
            fontSize: 68,
            lineHeight: 1.15,
            fontWeight: 800,
            maxWidth: 900,
          }}
        >
          İşletmenin dijital vitrini, tek linkte
        </div>
        <div
          style={{
            marginTop: 28,
            fontSize: 30,
            color: "#A9BBDA",
            maxWidth: 860,
          }}
        >
          Bilgilerin, ürünlerin, adresin ve WhatsApp iletişimin bir arada.
        </div>
      </div>
    ),
    size
  );
}
