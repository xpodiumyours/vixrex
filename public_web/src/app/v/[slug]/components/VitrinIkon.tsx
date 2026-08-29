/**
 * Vitrin ikonları — tek kaynak.
 *
 * NEDEN BU DOSYA VAR
 * 2026-08-29'a kadar vitrindeki her ikon emojiydi: 📍 🏠 📞 💬 ✉️ 🌐 🕐
 * 🛒 🗺️ 📱 🔗. Emoji her işletim sisteminde başka çizilir (Android'de
 * yuvarlak, iOS'ta parlak, Windows'ta düz), boyutu satır yüksekliğine
 * göre kayar ve renk alamaz — koyu temada renkli emoji hep "yapıştırılmış"
 * durur. Casper ChatGPT mockup'ı ile karşılaştırınca aradaki "ucuz duruyor"
 * hissinin somut kaynaklarından biri buydu.
 *
 * Paket kurulmadı: projede lucide-react / react-icons yok ve vitrin sıkı
 * bir CSP altında çalışıyor. Satır içi SVG hem bağımlılık getirmiyor hem
 * de currentColor ile temanın rengini alıyor.
 *
 * Hepsi 24x24 kutuda, 2px kontur, yuvarlatılmış uç — tek bir çizim dili.
 */

export type VitrinIkonAdi =
  | "konum"
  | "ev"
  | "telefon"
  | "mesaj"
  | "zarf"
  | "kure"
  | "saat"
  | "sepet"
  | "bina"
  | "rehber"
  | "harita"
  | "cihaz"
  | "baglanti"
  | "yildiz";

const CIZIMLER: Record<VitrinIkonAdi, React.ReactNode> = {
  konum: (
    <>
      <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
      <circle cx="12" cy="10" r="3" />
    </>
  ),
  ev: (
    <>
      <path d="M3 10.5 12 3l9 7.5" />
      <path d="M5 9.5V21h14V9.5" />
      <path d="M9.5 21v-6h5v6" />
    </>
  ),
  telefon: (
    <path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.2a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2Z" />
  ),
  mesaj: (
    <path d="M21 11.5a8.4 8.4 0 0 1-9 8.4 8.5 8.5 0 0 1-3.8-.9L3 21l2-4.9A8.4 8.4 0 0 1 12 3a8.4 8.4 0 0 1 9 8.5Z" />
  ),
  zarf: (
    <>
      <rect x="2.5" y="5" width="19" height="14" rx="2" />
      <path d="m3 7 9 6 9-6" />
    </>
  ),
  kure: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M3.5 9h17M3.5 15h17" />
      <path d="M12 3a14 14 0 0 1 0 18 14 14 0 0 1 0-18Z" />
    </>
  ),
  saat: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5.2l3.2 1.9" />
    </>
  ),
  sepet: (
    <>
      <path d="M2.5 3.5h2.2l2.3 11.3a2 2 0 0 0 2 1.6h7.6a2 2 0 0 0 2-1.5l1.6-6.4H6" />
      <circle cx="9.5" cy="20" r="1.4" />
      <circle cx="17.5" cy="20" r="1.4" />
    </>
  ),
  bina: (
    <>
      <rect x="4" y="3" width="16" height="18" rx="1.5" />
      <path d="M8.5 7h1.5M14 7h1.5M8.5 11h1.5M14 11h1.5M8.5 15h1.5M14 15h1.5" />
      <path d="M10.5 21v-3h3v3" />
    </>
  ),
  rehber: (
    <>
      <rect x="3.5" y="4" width="17" height="16" rx="2" />
      <path d="M3.5 9h3M3.5 15h3" />
      <circle cx="13.5" cy="10.5" r="2" />
      <path d="M10 16.5a3.5 3.5 0 0 1 7 0" />
    </>
  ),
  harita: (
    <>
      <path d="m9 4.5-6 2.2V20l6-2.2 6 2.2 6-2.2V4.5L15 6.7Z" />
      <path d="M9 4.5v13.3M15 6.7V20" />
    </>
  ),
  cihaz: (
    <>
      <rect x="6.5" y="2.5" width="11" height="19" rx="2.5" />
      <path d="M11 18.5h2" />
    </>
  ),
  baglanti: (
    <>
      <path d="M10 13.5a4 4 0 0 0 5.7.3l2.8-2.8a4 4 0 0 0-5.6-5.6l-1.6 1.6" />
      <path d="M14 10.5a4 4 0 0 0-5.7-.3l-2.8 2.8a4 4 0 0 0 5.6 5.6l1.6-1.6" />
    </>
  ),
  yildiz: (
    <path d="m12 3.5 2.6 5.4 5.9.8-4.3 4.1 1 5.9-5.2-2.8-5.2 2.8 1-5.9L3.5 9.7l5.9-.8Z" />
  ),
};

export function VitrinIkon({
  ad,
  className = "h-5 w-5",
}: {
  ad: VitrinIkonAdi;
  className?: string;
}) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      {CIZIMLER[ad]}
    </svg>
  );
}
