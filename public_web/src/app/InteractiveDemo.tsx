"use client";

import { useState } from "react";

type TabKey = "whatsapp" | "instagram" | "google" | "qr";

interface TabConfig {
  title: string;
  description: string;
  mockTitle: string;
  mockUrl: string;
  mockBadge: string;
  mockButtonText: string;
  mockItems: Array<{ name: string; price: string }>;
}

const tabData: Record<TabKey, TabConfig> = {
  whatsapp: {
    title: "Müşterileriniz doğrudan WhatsApp'tan sipariş ve bilgi alsın.",
    description: "Telefon rehberi kaydetme veya arama zahmetine girmeden tek dokunuşla WhatsApp mesajı başlasın, siparişler doğrudan cebinize gelsin.",
    mockTitle: "Lezzet Durağı",
    mockUrl: "vitrinx.app/lezzet-duragi",
    mockBadge: "Restoran & Kafe",
    mockButtonText: "WhatsApp'tan Sipariş Ver",
    mockItems: [
      { name: "Karışık Kebap Menü", price: "₺340" },
      { name: "Özel Soslu Lahmacun", price: "₺80" },
    ],
  },
  instagram: {
    title: "Instagram biyografiniz için mükemmel bir mini internet sitesi.",
    description: "Instagram biyografinizdeki tek linkle müşterilerinize tüm ürünlerinizi, fiyatlarınızı, adresinizi ve WhatsApp hattınızı tek sayfada gösterin.",
    mockTitle: "Özen Butik",
    mockUrl: "vitrinx.app/ozen-butik",
    mockBadge: "Moda & Giyim",
    mockButtonText: "Koleksiyonu İncele",
    mockItems: [
      { name: "Yazlık Keten Elbise", price: "₺850" },
      { name: "Örgü Hasır Şapka", price: "₺320" },
    ],
  },
  google: {
    title: "Google Haritalar ve Arama sonuçlarında öne çıkın.",
    description: "Google İşletme profilinize ekleyeceğiniz vitrin linki ile müşterileriniz mağazanıza gelmeden önce güncel ürün, hizmet ve fiyatlarınızı incelesin.",
    mockTitle: "TeknoFix",
    mockUrl: "vitrinx.app/teknofix",
    mockBadge: "Teknik Servis",
    mockButtonText: "Yol Tarifi Al & Konum",
    mockItems: [
      { name: "Ekran Değişimi (Orijinal)", price: "₺1.800" },
      { name: "Batarya Değişimi", price: "₺750" },
    ],
  },
  qr: {
    title: "Masa, paket veya broşürleriniz için anında QR kod üretimi.",
    description: "Otomatik oluşturulan QR kodunuzu dükkan vitrinine veya paket servis kutularına yerleştirin. Müşterileriniz okutup anında vitrininize ulaşsın.",
    mockTitle: "Coffee Lab",
    mockUrl: "vitrinx.app/coffee-lab",
    mockBadge: "Yeni Nesil Kahve",
    mockButtonText: "Menüyü QR ile Gör",
    mockItems: [
      { name: "Latte Art Premium", price: "₺95" },
      { name: "Ev Yapımı San Sebastian", price: "₺140" },
    ],
  },
};

export default function InteractiveDemo() {
  const [activeTab, setActiveTab] = useState<TabKey>("whatsapp");
  const data = tabData[activeTab];

  return (
    <div className="mx-auto w-full max-w-6xl px-5 py-16 sm:px-8">
      {/* Taba Dayalı Başlık Grubu */}
      <div className="text-center max-w-3xl mx-auto">
        <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Müşteri sizi nereden bulursa bulsun, tek linkten ulaşır.
        </h2>
        <p className="mt-3 text-base text-[#64748B] dark:text-[#94A3B8]">
          WhatsApp, Instagram, Google İşletme veya paket üstü QR kod. İşletmenizi her mecrada modern bir şekilde sergileyin.
        </p>
      </div>

      {/* Sekmeler */}
      <div className="mt-8 flex flex-wrap justify-center gap-2.5">
        {(Object.keys(tabData) as TabKey[]).map((key) => (
          <button
            key={key}
            onClick={() => setActiveTab(key)}
            className={`px-5 py-3 text-sm font-semibold rounded-2xl transition-all duration-200 ${
              activeTab === key
                ? "bg-[#10D8D8] text-white shadow-[0_8px_20px_rgba(16,216,216,0.25)]"
                : "bg-white border border-[#E2E8F0] text-[#334155] hover:bg-[#F8FAFC] dark:bg-[#131A22] dark:border-[#243141] dark:text-[#CBD5E1]"
            }`}
          >
            {key === "whatsapp" && "WhatsApp Mesajı"}
            {key === "instagram" && "Instagram Biyosu"}
            {key === "google" && "Google İşletme"}
            {key === "qr" && "Paket Üstü QR"}
          </button>
        ))}
      </div>

      {/* Önizleme & Açıklama Alanı */}
      <div className="mt-12 grid gap-10 lg:grid-cols-2 items-center">
        {/* Sol Taraf: Açıklama ve Call to Action */}
        <div className="flex flex-col items-center lg:items-start text-center lg:text-left">
          <span className="mb-4 inline-flex rounded-full bg-[#10D8D8]/10 px-3 py-1.5 text-xs font-bold text-[#0EA8B0] dark:text-[#10D8D8]">
            {data.mockBadge}
          </span>
          <h3 className="text-2xl font-bold tracking-tight sm:text-3xl">
            {data.title}
          </h3>
          <p className="mt-4 text-base leading-7 text-[#64748B] dark:text-[#94A3B8]">
            {data.description}
          </p>
          <div className="mt-6 flex items-center gap-3">
            <span className="h-2 w-2 rounded-full bg-[#10B981]" />
            <span className="text-xs font-bold text-[#334155] dark:text-[#CBD5E1]">Kurulum Yok, Sunucu Gideri Yok</span>
          </div>
        </div>

        {/* Sağ Taraf: Telefon Görünümünde Canlı Vitrin Önizleme Modeli */}
        <div className="relative mx-auto w-full max-w-sm">
          {/* Neon Glow Efekti */}
          <div className="absolute inset-8 rounded-[40px] bg-gradient-to-br from-[#10D8D8]/20 to-[#38A0E4]/15 blur-2xl" />

          {/* Telefon Çerçevesi */}
          <div className="relative mx-auto rounded-[38px] border-4 border-[#1E293B] bg-[#0F172A] p-3 shadow-2xl">
            <div className="rounded-[30px] bg-white dark:bg-[#0B0F13] p-4 text-[#182028] dark:text-[#F1F5F9] min-h-[360px] flex flex-col">
              {/* Telefon Durum Çubuğu */}
              <div className="flex items-center justify-between text-[10px] opacity-60 mb-3 px-1">
                <span>09:41</span>
                <span className="font-semibold">{data.mockTitle}</span>
                <div className="flex gap-1.5">
                  <span>📶</span>
                  <span>🔋</span>
                </div>
              </div>

              {/* Mağaza Detayları */}
              <div className="text-center mt-2 flex-1">
                <div className="mx-auto w-12 h-12 rounded-full bg-[#10D8D8]/15 text-[#0EA8B0] flex items-center justify-center font-bold text-lg mb-2">
                  {data.mockTitle.charAt(0)}
                </div>
                <h4 className="text-base font-bold">{data.mockTitle}</h4>
                <p className="text-[10px] text-[#0EA8B0] mt-0.5">{data.mockUrl}</p>

                {/* Buton */}
                <div className="mt-4 px-2">
                  <div className="w-full bg-[#10B981] text-white text-xs font-semibold py-2 rounded-xl shadow-sm text-center">
                    {data.mockButtonText}
                  </div>
                </div>

                {/* Ürün Listesi */}
                <div className="mt-5 text-left">
                  <p className="text-[10px] font-bold uppercase tracking-wider opacity-60 px-1 mb-2">Öne Çıkanlar</p>
                  <div className="space-y-2">
                    {data.mockItems.map((item, idx) => (
                      <div key={idx} className="flex justify-between items-center bg-[#F8FAFC] dark:bg-[#1B242F] p-2.5 rounded-xl border border-[#E2E8F0] dark:border-[#243141]">
                        <span className="text-xs font-bold">{item.name}</span>
                        <span className="text-xs font-semibold text-[#10D8D8]">{item.price}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Alt Skor Çubuğu */}
              <div className="mt-4 border-t border-[#E2E8F0] dark:border-[#243141] pt-2 flex items-center justify-between text-[10px] opacity-70">
                <span>⭐ 4.9 Skoru</span>
                <span className="font-bold text-[#10B981]">Vitrin Skoru Aktif</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
