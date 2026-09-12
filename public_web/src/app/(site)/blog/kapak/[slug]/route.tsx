import { ImageResponse } from "next/og";
import { blogYayindaMi, yaziyiBul } from "@/data/blogYazilari";

export const revalidate = 3600;

export async function GET(
  _istek: Request,
  { params }: { params: Promise<{ slug: string }> },
) {
  if (!blogYayindaMi()) {
    return new Response("Bulunamadı", { status: 404 });
  }

  const { slug } = await params;
  const genelKapak = slug === "blog";
  const yazi = genelKapak ? undefined : yaziyiBul(slug);

  if (!genelKapak && !yazi) {
    return new Response("Bulunamadı", { status: 404 });
  }

  const baslik = yazi?.baslik || "İşletmen için işe yarayan bilgiler.";
  const ustEtiket = yazi?.kategori || "İşletme rehberleri";
  const tur = yazi
    ? yazi.icerikTuru === "rehber"
      ? "Rehber"
      : yazi.icerikTuru === "urun_guncellemesi"
        ? "Ürün güncellemesi"
        : yazi.icerikTuru === "isletme_hikayesi"
          ? "İşletme hikâyesi"
          : "Haber"
    : "Vixrex Blog";

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          position: "relative",
          overflow: "hidden",
          background: "#050B1A",
          color: "#F7FAFF",
          padding: "64px 72px",
          fontFamily: "Arial, sans-serif",
        }}
      >
        <div
          style={{
            position: "absolute",
            width: 330,
            height: 330,
            borderRadius: 999,
            border: "2px solid rgba(20,125,255,0.30)",
            right: -70,
            top: -80,
          }}
        />
        <div
          style={{
            position: "absolute",
            width: 170,
            height: 170,
            borderRadius: 999,
            border: "2px solid rgba(87,183,255,0.28)",
            right: 170,
            bottom: -25,
          }}
        />

        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", width: "100%" }}>
          <div style={{ display: "flex", fontSize: 28, fontWeight: 800, color: "#57B7FF", letterSpacing: 1 }}>
            VIXREX BLOG
          </div>
          <div
            style={{
              display: "flex",
              border: "1px solid rgba(255,255,255,0.18)",
              borderRadius: 999,
              padding: "12px 20px",
              fontSize: 22,
              fontWeight: 700,
              color: "#B8C6DF",
            }}
          >
            {tur}
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", maxWidth: 940 }}>
          <div style={{ display: "flex", fontSize: 24, fontWeight: 800, color: "#57B7FF", marginBottom: 20 }}>
            {ustEtiket}
          </div>
          <div style={{ display: "flex", fontSize: baslik.length > 62 ? 52 : 62, lineHeight: 1.08, fontWeight: 800, letterSpacing: -2 }}>
            {baslik}
          </div>
        </div>

        <div style={{ display: "flex", fontSize: 22, fontWeight: 700, color: "#B8C6DF" }}>
          vixrex.com/blog
        </div>
      </div>
    ),
    { width: 1200, height: 630 },
  );
}
