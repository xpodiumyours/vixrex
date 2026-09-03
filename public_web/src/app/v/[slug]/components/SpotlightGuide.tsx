"use client";

import { useCallback, useLayoutEffect, useRef, useState } from "react";
import type { VitrinField } from "@/lib/vitrinFieldSchema";
import { SECTION_LABELS } from "@/lib/vitrinFieldSchema";
import { alanOnemi, type EksikOnem } from "@/lib/vitrinReadiness";
import { VixrexAvatar } from "./VixrexAvatar";

// 2026-08-22: "esnaf tıkladığında yan panelde form açılmasın, oyunlardaki
// gibi ok/spot ışığıyla sayfada dolaşsın" isteği — sıralama mantığı
// (önce zorunlu, sonra kalite alanları) zaten vitrinReadiness.ts'te vardı
// (tumAlanlarSirali/sonrakiRehberAlanlar), alan seçme/vurgulama/kaydırma
// zaten useFieldSelection'da vardı. Burada yalnız eksik olan görsel katman
// eklendi: seçili alanın sayfadaki gerçek konumunu bulup etrafına spot
// ışığı çizer. Hiçbir seçim/sıralama mantığı burada tekrar yazılmadı.
//
// 2026-08-22 DÜZELTME: ilk sürüm balonda yalnız bilgi gösterip "Buraya
// yaz" ile panelin tepesindeki sabit kutuyu odaklıyordu — kullanıcı test
// edip "kutucuklar açılıyor ama içine yazılmıyor, hep aynı yere yazılıyor"
// dedi (gözün balon → panel tepesi arası zıplaması kafa karıştırıyordu).
// Artık gerçek giriş alanı (FieldInputArea) balonun içindeydi.
//
// 2026-09-03 (Çalışma masası / Yön C, Faz 3) — Casper canlıda test etti:
// "kutucuklar açılıyor ama panel her tıklamada zıplıyor" geri bildirimi
// bu sefer TERSİNDEN geldi — balon her alanda yeniden konumlanınca giriş
// kutusu da yeniden çiziliyor, yazarken göz sıçrıyordu. Karar (AskUser):
// yazma yeri artık panelin ALT ŞERİDİNDE, asistan açıkken HEP açık ve
// SABİT — hangi alan seçilirse seçilsin yeri değişmez. FieldInputArea o
// şeride taşındı (bkz. OwnerAssistantPanel), silinmedi. Balon artık
// yalnız BİLGİ verir: alanın ne olduğu + "Canlı hâline döndür".

interface Rect {
  top: number;
  left: number;
  width: number;
  height: number;
}

// `kural` = alanın YAYIN karşısındaki durumu (zorunlu mu, değil mi).
// Alanın kendi "bu ne işe yarar" cümlesi bu tablodan DEĞİL, şemadaki
// `neden` alanından gelir (vitrinFieldSchema.ts) — ikisi ayrı şeydir ve
// balonda ayrı satırlarda durur.
const ONEM_METNI: Record<EksikOnem, { yazi: string; sinif: string; kural: string }> = {
  temel: {
    yazi: "Zorunlu",
    sinif: "bg-red-500/15 text-red-300 border-red-400/30",
    kural: "Bu alan dolmadan vitrinin yayınlanamaz.",
  },
  kalite: {
    yazi: "Kalite",
    sinif: "bg-sky-500/15 text-sky-300 border-sky-400/30",
    kural: "Zorunlu değil ama vitrinini daha güçlü gösterir.",
  },
  "istege-bagli": {
    yazi: "İsteğe bağlı",
    sinif: "bg-white/10 text-slate-400 border-white/15",
    kural: "İstersen boş bırakabilirsin.",
  },
};

interface Props {
  seciliAlan: VitrinField | null;
  geriAliniyor: boolean;
  /** Seçili alanı canlıdaki değerine döndürür — balonun tek eylemi. */
  canliyaDondur: () => Promise<void>;
  onKapat: () => void;
  /**
   * Değeri değiştiğinde balonun konumu yeniden ölçülür (Faz 2).
   *
   * Kaydetme artık sayfayı sunucudan tazeliyor; hedefin yazısı uzayıp
   * kısaldıkça yeri ve boyu değişiyor. Ölçüm yalnız `seciliAlan`
   * değişince tetiklenseydi balon eski yerinde kalırdı. Panel buraya
   * yerel taslağı geçirir — o değişti demek "sayfa da değişmiş olabilir"
   * demektir.
   */
  olcumTetikleyici?: unknown;
  /**
   * Rehber hedefe yürüyor mu (Faz 3b). Yolda balon kapalı durur; ekranda
   * uçuşan bir kutu yerine yalnız Vixrex sembolü hedefe kayar.
   */
  gecisSuruyor?: boolean;
  /**
   * "Tüm alanlar" haritasını açar (Faz 4). Mobilde alan seçilince harita
   * kapanıyor — geri dönmenin yolu balondaki bu düğme.
   */
  onHaritaAc?: () => void;
}

/** Sayfada gezen spot ışığı — panel açıkken, bir alan seçiliyken görünür.
 * Yalnız bilgi verir (etiket, önem, "bu ne işe yarar", "Canlı hâline
 * döndür"); giriş kutusu YOK — o panelin alt şeridinde, sabit (Faz 3). */
export function SpotlightGuide(props: Props) {
  const {
    seciliAlan,
    geriAliniyor,
    canliyaDondur,
    onKapat,
    olcumTetikleyici,
    gecisSuruyor = false,
    onHaritaAc,
  } = props;
  const [rect, setRect] = useState<Rect | null>(null);
  const [viewport, setViewport] = useState<{
    w: number;
    h: number;
    /** Görünen bandın sayfa içindeki kayması (klavye açıkken artar). */
    ust: number;
  } | null>(null);
  // Balonun gerçek yüksekliği — konumu buna göre seçilir, tahmine göre değil.
  const balonRef = useRef<HTMLDivElement>(null);
  const [balonYukseklik, setBalonYukseklik] = useState(0);

  const konumuGuncelle = useCallback(() => {
    if (!seciliAlan) {
      setRect(null);
      return;
    }
    const hedef = document.querySelector(
      `[data-vixrex-editable="${seciliAlan.anahtar}"]`,
    );
    if (!hedef) {
      setRect(null);
      return;
    }
    const r = hedef.getBoundingClientRect();
    // Ölçüm artık her karede yapılıyor (aşağıdaki rAF döngüsü). Değer
    // gerçekten değişmediyse state'e yazmıyoruz — yoksa saniyede ~60
    // boş yeniden çizim olurdu.
    setRect((onceki) =>
      onceki &&
      onceki.top === r.top &&
      onceki.left === r.left &&
      onceki.width === r.width &&
      onceki.height === r.height
        ? onceki
        : { top: r.top, left: r.left, width: r.width, height: r.height },
    );
    // GÖRÜNEN alan ölçülür, pencere değil (Faz 4).
    //
    // Mobilde klavye açılınca pencere küçülmez — üstüne biner. Sadece
    // `innerHeight` bakılırsa balon klavyenin altında kalır ve esnaf ne
    // yazdığını göremez. `visualViewport` gerçekten görünen bandı verir;
    // `offsetTop` o bandın sayfa içindeki kayması.
    const gv = window.visualViewport;
    const w = gv?.width ?? window.innerWidth;
    const h = gv?.height ?? window.innerHeight;
    const ust = gv?.offsetTop ?? 0;
    setViewport((onceki) =>
      onceki && onceki.w === w && onceki.h === h && onceki.ust === ust
        ? onceki
        : { w, h, ust },
    );
  }, [seciliAlan]);

  // useLayoutEffect: hedefin gerçek DOM konumunu ölçüp boyayamadan önce
  // state'e yazmak için. useOwnerDraft.ts'teki "render sırasında ayarla"
  // deseni burada UYGULANAMAZ — bu React prop'undan değil, gerçek DOM
  // layout'undan (getBoundingClientRect) türetilen bir değer; DOM önce
  // commit edilmeden ölçülemez. React'in kendi dokümanı useLayoutEffect'i
  // tam bu senaryo için önerir ("measure a DOM node before the browser
  // repaints"), bu yüzden kural burada bilerek atlanıyor.
  useLayoutEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    konumuGuncelle();
    window.addEventListener("scroll", konumuGuncelle, true);
    window.addEventListener("resize", konumuGuncelle);
    // Klavye açılıp kapanınca pencere boyutu değişmez, yalnız görünen
    // alan değişir — bu olaylar olmadan balon klavyenin altında kalır.
    window.visualViewport?.addEventListener("resize", konumuGuncelle);
    window.visualViewport?.addEventListener("scroll", konumuGuncelle);

    // Hedef yerine oturana kadar her karede yeniden ölç.
    //
    // Eskiden bu 120 ms'lik sabit bir `setInterval`'dı: kayma sürerken
    // balon adım adım sıçrıyordu ("sert iniş"). Artık ekranın kendi
    // çizim ritminde (requestAnimationFrame) ölçülüyor — hem daha
    // yumuşak hem de kayma erken biterse boşuna dönmüyor.
    //
    // Süre 700 ms'den 1200 ms'ye çıkarıldı: kaydetme sonrası sayfa
    // sunucudan tazeleniyor (Faz 2), içerik yerine oturması yumuşak
    // kaymadan uzun sürebiliyor.
    let cerceve = 0;
    const basla = performance.now();
    const dur = () => {
      konumuGuncelle();
      if (performance.now() - basla < 1200) {
        cerceve = requestAnimationFrame(dur);
      }
    };
    cerceve = requestAnimationFrame(dur);

    // Sayfa içeriği büyüyüp küçüldüğünde (tazeleme sonrası yeni metin,
    // yüklenen görsel) hedefin yeri kayar. Kaydırma olayı çıkmadığı için
    // yukarıdaki dinleyiciler bunu yakalamaz.
    const govdeIzleyici =
      typeof ResizeObserver === "undefined"
        ? null
        : new ResizeObserver(() => konumuGuncelle());
    govdeIzleyici?.observe(document.body);

    // Balonun kendi boyu da izlenir: içeriği (hazır görsel ızgarası, uzun
    // metin) büyüyünce konum yeniden seçilmeli.
    const balonIzleyici =
      typeof ResizeObserver === "undefined"
        ? null
        : new ResizeObserver(() => {
            const y = balonRef.current?.offsetHeight ?? 0;
            setBalonYukseklik((onceki) => (onceki === y ? onceki : y));
          });
    if (balonRef.current) balonIzleyici?.observe(balonRef.current);

    return () => {
      window.removeEventListener("scroll", konumuGuncelle, true);
      window.removeEventListener("resize", konumuGuncelle);
      window.visualViewport?.removeEventListener("resize", konumuGuncelle);
      window.visualViewport?.removeEventListener("scroll", konumuGuncelle);
      cancelAnimationFrame(cerceve);
      govdeIzleyici?.disconnect();
      balonIzleyici?.disconnect();
    };
  }, [konumuGuncelle, olcumTetikleyici]);

  if (!seciliAlan || !rect || !viewport) return null;

  const onem = alanOnemi(seciliAlan);
  const bilgi = ONEM_METNI[onem];
  const balonGenislik = Math.min(340, viewport.w - 32);
  const balonSol = Math.min(
    Math.max(rect.left, 16),
    viewport.w - balonGenislik - 16,
  );

  // Balonun yeri GÖRÜNEN banda göre seçilir (Faz 4).
  //
  // Bant = klavyenin üstünde kalan gerçek alan. Sırayla denenir:
  //   1. hedefin altına sığıyor mu,
  //   2. üstüne sığıyor mu,
  //   3. hiçbiri olmuyorsa bandın dibine sabitlenir — klavye açıkken
  //      küçük ekranlarda tek çıkar yol budur, balon yine de tam görünür.
  const BOSLUK = 18;
  const bandUst = viewport.ust;
  const bandAlt = viewport.ust + viewport.h;
  const enFazlaYukseklik = Math.max(160, Math.min(416, viewport.h - 32));
  const yukseklik = balonYukseklik
    ? Math.min(balonYukseklik, enFazlaYukseklik)
    : enFazlaYukseklik;

  const altaSigar = rect.top + rect.height + BOSLUK + yukseklik <= bandAlt - 8;
  const usteSigar = rect.top - BOSLUK - yukseklik >= bandUst + 8;

  let balonUst: number;
  if (altaSigar) balonUst = rect.top + rect.height + BOSLUK;
  else if (usteSigar) balonUst = rect.top - BOSLUK - yukseklik;
  else balonUst = bandAlt - 8 - yukseklik;
  balonUst = Math.max(bandUst + 8, balonUst);

  // Ok yalnız balon gerçekten hedefe komşuysa çizilir; dibe sabitlenmiş
  // balonda ok yanlış yeri gösterir, hiç çizmemek daha dürüst.
  const okYukari = altaSigar;
  const okGorunur = altaSigar || usteSigar;

  return (
    <div className="pointer-events-none fixed inset-0 z-[80]" aria-hidden={false}>
      {/* Hedef halkası — vitrin ARTIK KARARMIYOR (Faz 4, Çalışma masası /
       * Yön C, 2026-09-03). Eskiden dışı `boxShadow: 0 0 0 9999px rgba(...)`
       * ile karartılıyordu; esnaf neyi değiştirdiğini vitrinin geri kalanına
       * bakmadan göremiyordu. Artık yalnız halka + hafif dış parıltı: hedef
       * hâlâ göze çarpıyor, vitrinin geri kalanı gerçek rengiyle görünür. */}
      <div
        className="pointer-events-none absolute rounded-2xl ring-2 ring-blue-400/70 transition-all duration-300 ease-out"
        style={{
          top: rect.top - 8,
          left: rect.left - 8,
          width: rect.width + 16,
          height: rect.height + 16,
          boxShadow: "0 0 0 4px rgba(56, 189, 248, 0.18), 0 0 28px 6px rgba(56, 189, 248, 0.25)",
        }}
      />

      {/* Yürüyen Vixrex sembolü (Faz 3b).
       *
       * Casper: "dolaşan ve kutucukların boyutları ve vixrex asistanın
       * dolaşması önemli". Balon yolda kapalı durduğu için hedefe ne
       * gittiğini gösteren tek şey bu: sembol hedefin köşesine kayar,
       * CSS geçişiyle yürür gibi görünür. Varınca balon açılır. */}
      <div
        className="pointer-events-none absolute flex h-8 w-8 items-center justify-center rounded-full border border-blue-400/40 bg-[#0B1120] shadow-lg transition-all duration-500 ease-out"
        style={{ top: rect.top - 22, left: Math.max(8, rect.left - 14) }}
      >
        <VixrexAvatar size={22} decorative />
      </div>

      {/* Ok + balon.
       * 2026-08-22 mobil/masaüstü uyum düzeltmesi: balonun kendisi
       * yükseklik sınırı taşımıyordu — uzun açıklama metni kısa/mobil
       * ekranlarda balonu viewport dışına taşırabiliyordu. Ok işareti
       * kutunun kenarından taşarak çizildiği için (negatif top/bottom)
       * kaydırma yalnız İÇ gövdeye uygulanır — dış kutuya overflow
       * verilirse ok kırpılır. */}
      <div
        // Yolda balon kapalı: ekranda uçan bir kutu yerine, yürüyen bir
        // sembol görünür (Faz 3b). Varınca açılır.
        aria-hidden={gecisSuruyor}
        className={`absolute flex flex-col rounded-2xl border border-blue-400/30 bg-[#0B1120] shadow-2xl transition-all duration-300 ease-out ${
          gecisSuruyor
            ? "pointer-events-none scale-95 opacity-0"
            : "pointer-events-auto scale-100 opacity-100"
        }`}
        ref={balonRef}
        style={{
          width: balonGenislik,
          left: balonSol,
          top: balonUst,
          maxHeight: enFazlaYukseklik,
        }}
      >
        {/* Hedefi gösteren ok — balon hedefe komşu değilse çizilmez. */}
        {okGorunur && (
          <div
            className={`absolute h-3 w-3 rotate-45 border border-blue-400/30 bg-[#0B1120] ${
              okYukari
                ? "-top-1.5 border-b-0 border-r-0"
                : "-bottom-1.5 border-t-0 border-l-0"
            }`}
            style={{
              left: Math.min(
                Math.max(rect.left - balonSol + rect.width / 2 - 6, 12),
                balonGenislik - 24,
              ),
            }}
          />
        )}

        <div className="flex flex-col gap-3 overflow-y-auto p-4">
          <div className="flex items-start gap-2.5">
            <VixrexAvatar size={26} decorative />
            <div className="flex-1">
              <div className="mb-1 flex items-center gap-2">
                <span
                  className={`rounded-full border px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide ${bilgi.sinif}`}
                >
                  {bilgi.yazi}
                </span>
                <span className="text-[11px] text-slate-500">
                  {SECTION_LABELS[seciliAlan.bolum]}
                </span>
              </div>
              <p className="text-[15px] font-extrabold text-white">
                {seciliAlan.etiket}
              </p>
              {/* Önce "bu ne işe yarar" (şemadaki `neden`) — esnaf alanı
               * doldurmadan önce niye doldurduğunu bilsin. Altında, daha
               * soluk: yayın kuralı ve nasıl yazılacağı (`ipucu`). */}
              {seciliAlan.neden && (
                <p className="mt-1 text-[13px] leading-relaxed text-slate-300">
                  {seciliAlan.neden}
                </p>
              )}
              <p className="mt-1 text-[12px] leading-relaxed text-slate-500">
                {bilgi.kural}
                {seciliAlan.ipucu ? ` ${seciliAlan.ipucu}` : ""}
              </p>
            </div>
            <div className="flex shrink-0 items-center gap-0.5">
              {onHaritaAc && (
                <button
                  type="button"
                  onClick={onHaritaAc}
                  aria-label="Tüm alanlar"
                  title="Tüm alanlar"
                  className="rounded-full p-1 text-slate-500 hover:bg-white/5 hover:text-slate-300"
                >
                  ☰
                </button>
              )}
              <button
                type="button"
                onClick={onKapat}
                aria-label="Rehberi kapat"
                className="rounded-full p-1 text-slate-500 hover:bg-white/5 hover:text-slate-300"
              >
                ✕
              </button>
            </div>
          </div>

          {/* Balonun tek eylemi. Yazma/seçme artık burada DEĞİL — panelin
           * alt şeridinde, sabit (Faz 3, Çalışma masası / Yön C). */}
          <button
            type="button"
            onClick={() => void canliyaDondur()}
            disabled={geriAliniyor}
            className="self-start text-[12px] font-bold text-blue-300 underline decoration-dotted hover:text-blue-200 disabled:opacity-50"
          >
            {geriAliniyor ? "Döndürülüyor…" : "Canlı hâline döndür"}
          </button>
        </div>
      </div>
    </div>
  );
}
