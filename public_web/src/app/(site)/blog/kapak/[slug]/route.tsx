import { ImageResponse } from "next/og";
import { blogYayindaMi, yaziyiBul } from "@/data/blogYazilari";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ slug: string }> },
) {
  const { slug } = await params;
  const yazi = yaziyiBul(slug);
  if (!yazi && (slug !== "blog" || !blogYayindaMi()))
    return new Response("Bulunamadı", { status: 404 });
  return new ImageResponse(
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        justifyContent: "space-between",
        width: "100%",
        height: "100%",
        padding: "68px 76px",
        background: "#071426",
        color: "#f7fbff",
        borderBottom: "16px solid #57b7ff",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          fontSize: 26,
          color: "#91c9ff",
        }}
      >
        <span>VIXREX BLOG</span>
        <span>{yazi?.kategori || "İşletme rehberleri"}</span>
      </div>
      <div
        style={{
          display: "flex",
          fontSize: 62,
          lineHeight: 1.16,
          fontWeight: 700,
          letterSpacing: -2,
        }}
      >
        {yazi?.baslik || "İşletmen için işe yarayan bilgiler."}
      </div>
      <div style={{ display: "flex", fontSize: 25, color: "#a9bbda" }}>
        vixrex.com/blog
      </div>
    </div>,
    { width: 1200, height: 630 },
  );
}
