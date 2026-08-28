/**
 * Alt çağrı — envanter §2.10.
 *
 * İKİ BİLİNÇLİ SAPMA (2026-08-26, tarayıcıda ölçülerek bulundu):
 *
 * 1. Gradient'e ara durak eklendi. Envanterdeki iki duraklı gradient
 *    (bgEditor → primary) Flutter'ın uzun, dar bölümünde metni karanlık
 *    tarafta bırakıyor; webin geniş ve kısa bölümünde ise metin doğrudan
 *    parlak mavinin üstüne düşüyordu.
 *
 * 2. Alt metin `border` (#294D88) yerine `darkTextAlt` (#D9E7FF).
 *    Ölçüldü: #294D88 bu zeminde okunmuyordu. İkisi de envanterdeki
 *    palet renkleri; okunabilirlik tercih edildi.
 *
 * BAŞLIK RENGİ NEDEN SINIFLA VERİLMİYOR: `globals.css:100`'deki
 * `h1,h2,...{color:var(--text-dark)}` kuralı bir Tailwind KATMANINDA
 * değil, bu yüzden başlıklara verilen `text-*` yardımcı sınıflarını
 * eziyor. Sınıf yazmak yanıltıcı olurdu — başlık her hâlükârda
 * `--text-dark` (#F8FAFC) çiziliyor ve bu zeminde doğru olan da o.
 */
export function BottomCta({
  onStartAssistant,
}: {
  onStartAssistant: () => void;
}) {
  return (
    <section
      id="basla"
      className="bg-gradient-to-br from-lp-bg-editor via-lp-turquoise-surface to-lp-primary px-6 py-[88px]"
    >
      <div className="mx-auto w-full max-w-[800px] text-center">
        <h2 className="text-[36px] font-black leading-[1.2]">
          İşletmenizi tek linkte müşterilerinizle buluşturun
        </h2>
        <p className="mx-auto mt-5 max-w-[640px] text-[18px] leading-[1.5] text-lp-text-alt">
          Vixrex’ini oluştur; linkini, QR kodunu ve WhatsApp iletişimini
          paylaşmaya başla.
        </p>
        <button
          type="button"
          onClick={onStartAssistant}
          className="mt-9 inline-flex items-center justify-center rounded-3xl bg-lp-primary px-10 py-6 text-[18px] font-black text-white shadow-lp-panel transition-transform hover:-translate-y-0.5"
        >
          Vixrex Oluştur
        </button>
      </div>
    </section>
  );
}
