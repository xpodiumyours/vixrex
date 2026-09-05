import { useEffect, useRef, useState } from "react";
import type { VitrinField } from "@/lib/vitrinFieldSchema";
import { alanOnemi } from "@/lib/vitrinReadiness";
import {
  ownerLifecycleStatusText,
  type OwnerActionLifecycleResult,
} from "@/lib/ownerActionLifecycle";
import { ImagePickerPanel } from "./ImagePickerPanel";
import { turkeyProvinces, getDistrictsForProvince } from "@/lib/turkeyCities";
import type { HazirGorsel } from "../hooks/useOwnerActions";

// TEK giriş bileşeni — metin/uzunMetin/görsel/seçim/il/ilçe/GPS hepsi
// burada, `seciliAlan.tip`e göre dallanır. 2026-09-03'ten (Çalışma masası
// / Yön C, Faz 3) beri panelin ALT ŞERİDİNDE render edilir — sayfada
// dolaşan balonun (SpotlightGuide) içinde DEĞİL; balon yeniden konumlanınca
// yazma yeri artık sıçramıyor, sabit kalıyor. `seciliAlan` boşken de
// (özgür yazım, NLU motoru cümleden alanı kendi bulur) aynı kutu çalışır.

interface Props {
  seciliAlan: VitrinField | null;
  giris: string;
  girisRef: React.RefObject<HTMLTextAreaElement | null>;
  mevcutIl?: string;
  mevcutIlce?: string;
  onIlDegisti?: (il: string) => void;
  onIlceDegisti?: (ilce: string) => void;
  kaydediliyor: boolean;
  geriAliniyor: boolean;
  hazirGorseller: HazirGorsel[];
  hazirYukleniyor: boolean;
  setGiris: (v: string) => void;
  gorselYukle: (dosya: File) => Promise<void>;
  hazirGorselleriAc: () => Promise<void>;
  hazirGorselSec: (url: string) => Promise<void>;
  gonder: () => Promise<OwnerActionLifecycleResult>;
  onGonderSonucu?: (sonuc: OwnerActionLifecycleResult) => void;
  alanAtla: () => Promise<void>;
  canliyaDondur: () => Promise<void>;
  sonrayaBirak?: () => void;
  onGpsKonumAl?: () => void;
  gpsLoading?: boolean;
}

export function FieldInputArea({
  seciliAlan,
  giris,
  girisRef,
  kaydediliyor,
  geriAliniyor,
  hazirGorseller,
  hazirYukleniyor,
  mevcutIl = "",
  mevcutIlce = "",
  setGiris,
  gorselYukle,
  hazirGorselleriAc,
  hazirGorselSec,
  gonder,
  onGonderSonucu,
  alanAtla,
  canliyaDondur,
  onIlDegisti,
  onIlceDegisti,
  sonrayaBirak,
  onGpsKonumAl,
  gpsLoading = false,
}: Props) {
  const istegeBagliMi = seciliAlan ? alanOnemi(seciliAlan) === "istege-bagli" : false;
  const kaliteMi = seciliAlan ? alanOnemi(seciliAlan) === "kalite" : false;
  const gonderRef = useRef(false);
  const [gonderKilitli, setGonderKilitli] = useState(false);
  const [sonGonderSonucu, setSonGonderSonucu] = useState<OwnerActionLifecycleResult | null>(null);
  const gonderEngelli = kaydediliyor || gonderKilitli;

  // 5.7: Bu body class artık tüm decision süresini değil yalnız gerçek
  // persistence/execution süresini temsil eder. useFieldSelection başarı
  // sonrasında sıradaki alanı seçerken bu state sayesinde mobil sheet'i
  // yeniden açmaz; storefront görünür kalır.
  useEffect(() => {
    document.body.classList.toggle("vixrex-asistan-isliyor", kaydediliyor);
    return () => document.body.classList.remove("vixrex-asistan-isliyor");
  }, [kaydediliyor]);

  // Mobil ilk davranış korunur: Gönder anında sheet kapanır ve vitrin görünür.
  // İşlem sonundaki yeniden-açma kararı CSS/mesaj tahminiyle değil, gonder()'ın
  // açık lifecycle sonucuyla üst bileşene iletilir.
  const gonderVeVitriniGoster = async () => {
    if (gonderRef.current) return;
    gonderRef.current = true;
    setGonderKilitli(true);

    try {
      const mobil =
        typeof window !== "undefined" &&
        !window.matchMedia("(min-width: 640px)").matches;
      const girdiVar = Boolean(giris.trim()) || seciliAlan?.tip === "acikKapali";

      if (mobil && girdiVar) {
        document
          .querySelector<HTMLButtonElement>(
            'button[aria-label="Vixrex Asistan"][aria-expanded="true"]'
          )
          ?.click();
      }

      const sonuc = await gonder();
      setSonGonderSonucu(sonuc);
      onGonderSonucu?.(sonuc);
    } finally {
      gonderRef.current = false;
      setGonderKilitli(false);
    }
  };

  return (
    <div>
      <p className="sr-only" role="status" aria-live="polite">
        {kaydediliyor
          ? "Vixrex Asistan değişikliği kaydediyor."
          : ownerLifecycleStatusText(sonGonderSonucu)}
      </p>

      {seciliAlan && (
        <p className="mb-2 flex items-center justify-end gap-2 text-[11px] text-slate-400">
          <button
            type="button"
            onClick={() => void canliyaDondur()}
            disabled={kaydediliyor || geriAliniyor}
            className="mr-auto shrink-0 text-blue-300 underline decoration-dotted hover:text-blue-200 disabled:opacity-50"
          >
            {geriAliniyor ? "Döndürülüyor…" : "Canlı hâline döndür"}
          </button>
          {seciliAlan.maxUzunluk && (
            <span>
              {giris.length}/{seciliAlan.maxUzunluk}
            </span>
          )}
          {istegeBagliMi && (
            <button
              type="button"
              onClick={() => void alanAtla()}
              disabled={kaydediliyor}
              className="shrink-0 text-slate-400 underline decoration-dotted hover:text-slate-200 disabled:opacity-50"
            >
              Boş geç
            </button>
          )}
          {kaliteMi && sonrayaBirak && (
            <button
              type="button"
              onClick={sonrayaBirak}
              disabled={kaydediliyor}
              className="shrink-0 text-slate-400 underline decoration-dotted hover:text-slate-200 disabled:opacity-50"
            >
              Sonra
            </button>
          )}
        </p>
      )}
      {seciliAlan?.tip === "gorsel" ? (
        <div>
          <label
            className={`flex w-full cursor-pointer items-center justify-center gap-2 rounded-lg border border-dashed border-blue-500/40 bg-blue-500/[0.06] px-4 py-4 text-xs font-semibold text-blue-300 transition hover:bg-blue-500/10 ${
              kaydediliyor ? "pointer-events-none opacity-50" : ""
            }`}
          >
            <span className="text-base">📷</span>
            {kaydediliyor ? "Yükleniyor…" : "Fotoğraf Seç"}
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              disabled={kaydediliyor}
              className="hidden"
              onChange={(e) => {
                const dosya = e.target.files?.[0];
                e.target.value = "";
                if (dosya) void gorselYukle(dosya);
              }}
            />
          </label>
          <ImagePickerPanel
            hazirGorseller={hazirGorseller}
            hazirYukleniyor={hazirYukleniyor}
            kaydediliyor={kaydediliyor}
            hazirGorselleriAc={hazirGorselleriAc}
            hazirGorselSec={hazirGorselSec}
          />
          <p className="mt-2 text-center text-[11px] text-slate-500">
            JPG, PNG veya WebP · en fazla 5 MB
          </p>
        </div>
      ) : seciliAlan?.anahtar === "il" ? (
        <div className="flex items-end gap-2">
          <select
            value={mevcutIl}
            onChange={(e) => {
              const secilen = e.target.value;
              setGiris(secilen);
              onIlDegisti?.(secilen);
            }}
            disabled={kaydediliyor}
            className="h-12 flex-1 rounded-lg border border-white/10 bg-slate-900/70 px-3.5 text-sm text-white outline-none focus:border-blue-500/60"
          >
            <option value="" disabled>İl seçin…</option>
            {turkeyProvinces.map((p) => (
              <option key={p.code} value={p.name}>{p.name}</option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => void gonderVeVitriniGoster()}
            disabled={gonderEngelli || !mevcutIl}
            aria-busy={kaydediliyor}
            className="h-12 rounded-lg bg-blue-600 px-4 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {kaydediliyor ? "Düzenleniyor…" : "Gönder"}
          </button>
        </div>
      ) : seciliAlan?.anahtar === "ilce" ? (
        <div className="flex items-end gap-2">
          <select
            value={mevcutIlce}
            onChange={(e) => {
              const secilen = e.target.value;
              setGiris(secilen);
              onIlceDegisti?.(secilen);
            }}
            disabled={kaydediliyor || !mevcutIl}
            className="h-12 flex-1 rounded-lg border border-white/10 bg-slate-900/70 px-3.5 text-sm text-white outline-none focus:border-blue-500/60 disabled:opacity-50"
          >
            <option value="" disabled>{mevcutIl ? "İlçe seçin…" : "Önce il seçin"}</option>
            {getDistrictsForProvince(mevcutIl).map((d) => (
              <option key={d} value={d}>{d}</option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => void gonderVeVitriniGoster()}
            disabled={gonderEngelli || !mevcutIlce}
            aria-busy={kaydediliyor}
            className="h-12 rounded-lg bg-blue-600 px-4 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {kaydediliyor ? "Düzenleniyor…" : "Gönder"}
          </button>
        </div>
      ) : seciliAlan?.tip === "secim" && seciliAlan.secenekler ? (
        <div className="flex items-end gap-2">
          <select
            value={giris}
            onChange={(e) => setGiris(e.target.value)}
            disabled={kaydediliyor}
            className="h-12 flex-1 rounded-lg border border-white/10 bg-slate-900/70 px-3.5 text-sm text-white outline-none focus:border-blue-500/60"
          >
            <option value="" disabled>Kategori seçin…</option>
            {seciliAlan.secenekler.map((secenek) => (
              <option key={secenek} value={secenek}>
                {secenek}
              </option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => void gonderVeVitriniGoster()}
            disabled={gonderEngelli || !giris}
            aria-busy={kaydediliyor}
            className="h-12 rounded-lg bg-blue-600 px-4 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {kaydediliyor ? "Düzenleniyor…" : "Gönder"}
          </button>
        </div>
      ) : (
        <div className="space-y-2">
          {seciliAlan && ["adres", "enlem", "boylam"].includes(seciliAlan.anahtar) && onGpsKonumAl && (
            <button
              type="button"
              onClick={onGpsKonumAl}
              disabled={gpsLoading || kaydediliyor}
              className="w-full rounded-lg border border-blue-500/30 bg-blue-500/10 px-3 py-1.5 text-[11px] font-bold text-blue-300 hover:bg-blue-500/20 disabled:opacity-50"
            >
              {gpsLoading ? "Konum alınıyor…" : "📍 GPS ile konumumu al"}
            </button>
          )}
          <div className="flex items-end gap-2">
            <textarea
              ref={girisRef}
              value={giris}
              onChange={(e) => setGiris(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  if (!gonderEngelli) void gonderVeVitriniGoster();
                }
              }}
              rows={seciliAlan?.tip === "uzunMetin" ? 3 : 1}
              disabled={gonderEngelli}
              aria-label="Vixrex Asistan'a yaz"
              placeholder={
                seciliAlan
                  ? `${seciliAlan.etiket} için yaz…`
                  : "Yaz, ben hallederim. Örn: işletme adım Öz Kardeşler"
              }
              className={`flex-1 resize-none rounded-lg border border-white/10 bg-slate-900/70 px-3.5 text-sm text-white outline-none focus:border-blue-500/60 ${
                seciliAlan?.tip === "uzunMetin" ? "py-3" : "h-12 py-3"
              }`}
            />
            <button
              type="button"
              onClick={() => void gonderVeVitriniGoster()}
              disabled={gonderEngelli}
              aria-busy={kaydediliyor}
              className="h-12 rounded-lg bg-blue-600 px-4 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
            >
              {kaydediliyor ? "Düzenleniyor…" : "Gönder"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
