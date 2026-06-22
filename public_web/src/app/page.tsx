import Link from "next/link";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";

// Anasayfa vitrin sayısını 10 dakikada bir yeniler (her istekte Supabase'i dökmez)
export const revalidate = 600;

const getStoreCount = unstable_cache(
  async () => {
    const { count } = await supabase
      .from("stores")
      .select("*", { count: "exact", head: true })
      .eq("is_published", true);
    return count || 0;
  },
  ["homepage-store-count"],
  { tags: ["homepage"], revalidate: 600 }
);

export default async function HomePage() {
  let displayCount = 0;
  try {
    displayCount = await getStoreCount();
  } catch (err) {
    console.error("Error fetching store count:", err);
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#FFFBF7] dark:bg-[#0B0F13] relative overflow-hidden">
      {/* Mesh Glow Backgrounds */}
      <div className="absolute top-[10%] left-[-10%] w-[300px] h-[300px] bg-[#10D8D8]/10 dark:bg-[#10D8D8]/5 rounded-full blur-[100px] pointer-events-none" />
      <div className="absolute bottom-[20%] right-[-10%] w-[400px] h-[400px] bg-[#38A0E4]/10 dark:bg-[#38A0E4]/5 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute top-[30%] right-[10%] w-[250px] h-[250px] bg-[#FB7185]/10 dark:bg-[#FB7185]/5 rounded-full blur-[90px] pointer-events-none" />

      {/* Header */}
      <header className="container py-6 flex items-center justify-between z-10 relative">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-[#10D8D8]/15 rounded-full text-[#10D8D8]">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/></svg>
          </div>
          <span className="text-xl font-extrabold tracking-tight text-[#182028] dark:text-white">VitrinX</span>
        </div>
        <Link href="https://app.vitrinx.app" className="btn-secondary px-5 py-2.5 text-sm rounded-xl">
          Yönetici Girişi
        </Link>
      </header>

      {/* Hero Section */}
      <main className="flex-1 flex flex-col justify-center py-12 md:py-20 z-10 relative">
        <div className="container grid md:grid-cols-2 gap-12 items-center">
          <div className="flex flex-col items-center md:items-start text-center md:text-left space-y-6">
            <span className="inline-flex px-4 py-1.5 bg-[#10D8D8]/15 dark:bg-[#10D8D8]/10 text-[#0EA8B0] dark:text-[#10D8D8] text-xs font-bold uppercase tracking-wider rounded-full border border-[#10D8D8]/20">
              ESNAF İÇİN DİJİTAL VİTRİN
            </span>
            <h1 className="text-4xl md:text-5xl lg:text-6xl font-extrabold text-[#182028] dark:text-white leading-[1.1] tracking-tight">
              Mağazanızın tek linkte <span className="bg-gradient-to-r from-[#10D8D8] to-[#38A0E4] bg-clip-text text-transparent">hazır vitrini</span>
            </h1>
            <p className="text-lg text-[#475569] dark:text-[#CBD5E1] max-w-lg leading-relaxed">
              Fotoğraflarınızı, online randevu sisteminizi, WhatsApp sipariş bilgilerinizi, pazaryeri linklerinizi ve Google yorum QR kodunuzu müşterilerinizle tek sayfada paylaşın.
            </p>

            {/* Social Proof */}
            <div className="flex items-center gap-3 py-1">
              <div className="flex text-amber-400">
                {"★★★★★".split("").map((s, i) => (
                  <span key={i} className="text-lg">★</span>
                ))}
              </div>
              <div className="text-xs font-semibold text-[#64748B] dark:text-[#94A3B8]">
                <strong className="text-[#182028] dark:text-white">{displayCount}</strong> aktif esnaf VitrinX kullanıyor
              </div>
            </div>

            {/* Claim Link Action */}
            <div className="w-full max-w-md pt-2">
              <form action="https://app.vitrinx.app" method="GET" className="flex flex-col sm:flex-row gap-3">
                <div className="flex-1 flex items-center bg-white dark:bg-[#1B242F] border border-[#D0E4E8] dark:border-[#243141] rounded-2xl px-4 py-3 shadow-sm focus-within:ring-2 focus-within:ring-[#10D8D8]/20 focus-within:border-[#10D8D8]">
                  <span className="text-[#64748B] dark:text-[#94A3B8] font-bold text-sm select-none">vitrinx.app/</span>
                  <input
                    type="text"
                    name="slug"
                    placeholder="magazaniz"
                    className="flex-1 ml-1 bg-transparent border-none outline-none font-bold text-sm text-[#182028] dark:text-white placeholder-slate-400"
                    required
                  />
                </div>
                <button type="submit" className="btn-primary px-6 py-3 rounded-2xl flex items-center justify-center font-bold">
                  Ücretsiz Oluştur
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="ml-1"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
                </button>
              </form>
            </div>

            {/* Trust Badges */}
            <div className="flex flex-wrap justify-center md:justify-start gap-2 pt-2">
              {["Kredi kartı gerekmez", "Dakikalar içinde hazır", "Mobil uyumlu paylaşım"].map((badge, idx) => (
                <div key={idx} className="flex items-center gap-1.5 px-3 py-1.5 bg-white/70 dark:bg-[#131A22]/70 border border-[#E2E8F0] dark:border-[#243141] rounded-full text-xs font-bold text-[#334155] dark:text-[#CBD5E1]">
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#10B981" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                  {badge}
                </div>
              ))}
            </div>
          </div>

          {/* Interactive Feature Cards */}
          <div className="grid grid-cols-2 gap-4">
            <div className="card flex flex-col p-6 space-y-3 bg-white dark:bg-[#131A22]">
              <div className="w-10 h-10 rounded-xl bg-[#10D8D8]/10 text-[#0EA8B0] flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M20.4 20.4L15 15l-4 4-5-5-3.4 3.4"/></svg>
              </div>
              <h3 className="font-bold text-base">Görsel Vitrin Galerisi</h3>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] leading-relaxed">
                Raf ve reyon görsellerinizi yüksek hızda mobil uyumlu sunun.
              </p>
            </div>

            <div className="card flex flex-col p-6 space-y-3 bg-white dark:bg-[#131A22]">
              <div className="w-10 h-10 rounded-xl bg-[#38A0E4]/10 text-[#38A0E4] flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
              </div>
              <h3 className="font-bold text-base">Online Randevu</h3>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] leading-relaxed">
                Müşterileriniz üye olmadan boş saatlerinizi seçip kolayca randevu talep etsin.
              </p>
            </div>

            <div className="card flex flex-col p-6 space-y-3 bg-white dark:bg-[#131A22]">
              <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/></svg>
              </div>
              <h3 className="font-bold text-base">WhatsApp Sipariş</h3>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] leading-relaxed">
                Müşterilerinizle doğrudan WhatsApp üzerinden hızlı iletişime geçin.
              </p>
            </div>

            <div className="card flex flex-col p-6 space-y-3 bg-white dark:bg-[#131A22]">
              <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-500 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
              </div>
              <h3 className="font-bold text-base">Google Yorum QR</h3>
              <p className="text-xs text-[#64748B] dark:text-[#94A3B8] leading-relaxed">
                Google harita yorumlarınızı artırmak için güvenli ve yönlendirici QR kodu alın.
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-[#D0E4E8] dark:border-[#243141] bg-white dark:bg-[#0B0F13] py-8 z-10 relative">
        <div className="container flex flex-col sm:flex-row justify-between items-center gap-4">
          <div className="text-sm text-[#64748B] dark:text-[#94A3B8]">
            &copy; {new Date().getFullYear()} VitrinX. Tüm hakları saklıdır.
          </div>
          <div className="flex gap-6 text-sm">
            <Link href="https://app.vitrinx.app" className="text-[#64748B] dark:text-[#94A3B8] hover:text-[#10D8D8]">
              Yönetici Paneli
            </Link>
            <Link href="https://app.vitrinx.app/kesfet" className="text-[#64748B] dark:text-[#94A3B8] hover:text-[#10D8D8]">
              Keşfet
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
