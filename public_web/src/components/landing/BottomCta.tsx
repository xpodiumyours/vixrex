/**
 * Flutter `landing_bottom_cta.dart` ölçü karşılığı.
 *
 * Renklerde tek kontrollü web istisnası korunur: Flutter başlıkta
 * `surfaceSoft`, açıklamada `border` kullanıyor. Bu iki renk koyu/mavi
 * gradient üzerinde web metin kontrastını düşürdüğü için web yüzeyi
 * WCAG 2.2 1.4.3 uyumlu açık metin renklerini korur; yerleşim, ölçü ve
 * eylem Flutter referansıyla aynıdır.
 */
export function BottomCta({ onStartAssistant }: { onStartAssistant: () => void }) {
  return (
    <section
      id="basla"
      className="bg-gradient-to-br from-lp-bg-editor via-lp-turquoise-surface to-lp-primary px-6 py-[88px]"
    >
      <div className="mx-auto w-full max-w-[800px] text-center">
        <h2 className="text-[36px] font-black leading-[1.2] tracking-normal text-lp-text">
          İşletmenizi tek linkte müşterilerinizle buluşturun
        </h2>
        <p className="mx-auto mt-6 text-[18px] leading-[1.5] text-lp-text-alt">
          Vixrex’ini oluştur; linkini, QR kodunu ve WhatsApp iletişimini paylaşmaya başla.
        </p>
        <button
          type="button"
          onClick={onStartAssistant}
          className="mt-12 inline-flex items-center justify-center rounded-3xl bg-lp-primary px-10 py-6 text-[18px] font-black text-white shadow-[0_10px_20px_rgba(0,0,0,0.24)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary"
        >
          Vixrex Oluştur
        </button>
      </div>
    </section>
  );
}
