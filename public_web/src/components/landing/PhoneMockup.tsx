import type { MockupProfili } from "./mockupProfilleri";
import { PhoneMockupSlaytlari } from "./PhoneMockupSlaytlari";
import { LandingApkAssistant } from "./LandingApkAssistant";

/**
 * Hero'nun telefon mockup'ı — envanter §2.3.
 *
 * Flutter'daki phone_mockup.dart ile birebir aynı:
 *  - 325×640 sabit boyut (LayoutBuilder ile dikey ölçekleme)
 *  - 40px köşe yuvarlatması
 *  - 2.5px kenarlık, beyaz %18
 *  - 3 katmanlı gölge (mavi parıltı + siyah + mavi glow)
 *  - Dynamic Island notch (96×22)
 *  - Home indicator (110×4)
 *
 * Maskot tıklanınca slaytlar yerini APK karşılama yüzüne bırakır;
 * "Evet, Oluşturalım" sonrasında mevcut gerçek kurulum motoruna delege edilir.
 */
export function PhoneMockup({
  profiller,
  isChatOpen = false,
  initialAssistantName = "",
  onChatClose,
}: {
  profiller: MockupProfili[];
  isChatOpen?: boolean;
  initialAssistantName?: string;
  onChatClose?: () => void;
}) {
  const ilk = profiller[0];
  if (!ilk) return null;

  return (
    <div className="relative mx-auto w-[325px] shrink-0">
      {!isChatOpen && (
        <>
          <div className="absolute -right-6 top-[90px] z-20 flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.92] px-3 py-2 shadow-[0_8px_24px_rgba(0,0,0,0.12)] backdrop-blur-sm">
            <div className="flex h-[22px] w-[22px] items-center justify-center rounded-full" style={{ backgroundColor: ilk.uStRozet.renk }}>
              <span className="text-[10px]">{ilk.uStRozet.simge}</span>
            </div>
            <span className="text-[11px] font-extrabold text-gray-800">{ilk.uStRozet.renk === "#FF5A1F" ? "Galeri" : ilk.uStRozet.renk === "#EA580C" ? "Menü" : ilk.uStRozet.renk === "#DB2777" ? "Randevu" : "WhatsApp"}</span>
          </div>
          <div className="absolute -left-6 top-[72px] z-20 flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.92] px-3 py-2 shadow-[0_8px_24px_rgba(0,0,0,0.12)] backdrop-blur-sm">
            <div className="flex h-[22px] w-[22px] items-center justify-center rounded-full" style={{ backgroundColor: ilk.altRozet.renk }}>
              <span className="text-[10px]">{ilk.altRozet.simge}</span>
            </div>
            <span className="text-[11px] font-extrabold text-gray-800">{ilk.altRozet.renk === "#FF5A1F" ? "QR kod" : ilk.altRozet.renk === "#EA580C" ? "Yol tarifi" : ilk.altRozet.renk === "#DB2777" ? "Instagram" : "Konum"}</span>
          </div>
        </>
      )}

      <div
        className="relative overflow-hidden rounded-[40px] border-[2.5px] border-white/[0.18] bg-[#0A101C] p-[8px]"
        style={{
          boxShadow: [
            "0 0 0 1.5px rgba(14, 165, 233, 0.3)",
            "0 25px 50px rgba(0, 0, 0, 0.55)",
            "0 16px 36px rgba(14, 165, 233, 0.22)",
          ].join(", "),
        }}
      >
        <div className="h-[640px] overflow-hidden rounded-[34px] border border-[#25415F] bg-[#050B1A]">
          <div className="absolute left-1/2 top-[10px] z-10 -translate-x-1/2">
            <div className="flex h-[22px] w-[96px] items-center justify-between rounded-[20px] bg-black px-[10px] shadow-[0_2px_8px_rgba(0,0,0,0.55)]">
              <div className="h-[10px] w-[10px] rounded-full border border-white/10 bg-[#0D131F]" />
              <div className="h-[6px] w-[6px] rounded-full bg-[#0A2540]" />
            </div>
          </div>

          <div className="h-full">
            {isChatOpen ? (
              <LandingApkAssistant
                initialName={initialAssistantName}
                onClose={onChatClose}
              />
            ) : (
              <PhoneMockupSlaytlari profiller={profiller} />
            )}
          </div>

          <div className="absolute bottom-[8px] left-1/2 z-10 -translate-x-1/2">
            <div className="h-[4px] w-[110px] rounded-[10px] bg-white/30" />
          </div>
        </div>
      </div>
    </div>
  );
}
