"use client";

// Rehberin sayfa üzerinde yürümesi (Faz 3b, 2026-08-22).
//
// NEDEN VAR: `scrollIntoView({behavior:"smooth"})` mesafeyi umursamaz —
// tarayıcı uzak hedefe de aynı kısa sürede gider, ekran "çakılıyor" gibi
// hissettirir (Casper, canlı test: "birden bire çok hızlı en alttaki
// bilgilere çakılıyor gibi"). Ayrıca durdurulamaz: esnaf parmağını
// sürerken kaydırma devam eder, sayfa kullanıcıyla kavga eder.
//
// Buradaki kaydırma mesafeye göre süre seçer, kullanıcı dokununca
// kendini iptal eder ve hareket azaltma tercihine uyar.

/** Yakın hedefe bu kadar sürede gidilir (ms). */
const EN_KISA_SURE = 320;
/** En uzak hedefe bu kadar sürede (ms) — daha uzunu tembellik hissettirir. */
const EN_UZUN_SURE = 900;
/** Bu mesafeden (piksel) sonrası "en uzak" sayılır. */
const UZAK_MESAFE = 2200;

export function hareketAzaltilsin(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

/** Mesafeye göre kaydırma süresi. */
export function kaydirmaSuresi(mesafe: number): number {
  const oran = Math.min(1, Math.abs(mesafe) / UZAK_MESAFE);
  return Math.round(EN_KISA_SURE + (EN_UZUN_SURE - EN_KISA_SURE) * oran);
}

/** Yumuşak giriş-çıkış: başta ve sonda yavaş, ortada hızlı. */
function yumusat(t: number): number {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
}

function enFazlaKaydirma(): number {
  return Math.max(
    0,
    document.documentElement.scrollHeight - window.innerHeight,
  );
}

/**
 * Sayfayı `hedefY`'ye yumuşakça kaydırır.
 *
 * Kullanıcı tekerlek/dokunma ile araya girerse kaydırma bırakılır —
 * sayfa esnafla kavga etmez. Hareket azaltma açıksa anında konumlanır.
 *
 * @returns kaydırma bitince (veya iptal edilince) çözülen söz.
 */
export function yumusakKaydir(hedefY: number, sure?: number): Promise<void> {
  if (typeof window === "undefined") return Promise.resolve();

  const baslangic = window.scrollY;
  const hedef = Math.max(0, Math.min(hedefY, enFazlaKaydirma()));
  const mesafe = hedef - baslangic;

  if (Math.abs(mesafe) < 2) return Promise.resolve();

  if (hareketAzaltilsin()) {
    window.scrollTo(0, hedef);
    return Promise.resolve();
  }

  const toplamSure = sure ?? kaydirmaSuresi(mesafe);

  return new Promise<void>((cozumle) => {
    let cerceve = 0;
    let iptal = false;

    const birak = () => {
      if (iptal) return;
      iptal = true;
      cancelAnimationFrame(cerceve);
      temizle();
      cozumle();
    };

    const temizle = () => {
      window.removeEventListener("wheel", birak);
      window.removeEventListener("touchstart", birak);
      window.removeEventListener("keydown", birak);
    };

    // Kullanıcı araya girerse bırak. `passive` — kaydırmayı yavaşlatmaz.
    window.addEventListener("wheel", birak, { passive: true });
    window.addEventListener("touchstart", birak, { passive: true });
    window.addEventListener("keydown", birak);

    const basladi = performance.now();
    const adim = () => {
      if (iptal) return;
      const gecen = performance.now() - basladi;
      const oran = Math.min(1, gecen / toplamSure);
      window.scrollTo(0, baslangic + mesafe * yumusat(oran));
      if (oran < 1) {
        cerceve = requestAnimationFrame(adim);
        return;
      }
      temizle();
      cozumle();
    };
    cerceve = requestAnimationFrame(adim);
  });
}

/** Belirtilen süre kadar bekler (bölüm başlığında kısa duraklama için). */
export function bekle(ms: number): Promise<void> {
  if (hareketAzaltilsin()) return Promise.resolve();
  return new Promise((cozumle) => window.setTimeout(cozumle, ms));
}

/**
 * Bir öğeyi ekranın ÜST kısmına oturtmak için gereken kaydırma konumu.
 *
 * Neden orta değil de üst: mobilde balon ve klavye alt yarıyı kaplıyor;
 * hedef ortada kalırsa altta kayboluyor. Üst üçte bir hem masaüstünde
 * hem mobilde güvenli.
 */
export function ogeIcinHedefY(oge: Element, ustBosluk: number): number {
  const kutu = oge.getBoundingClientRect();
  return window.scrollY + kutu.top - ustBosluk;
}

/**
 * Öğe zaten rahatça görünüyor mu? Görünüyorsa sayfayı hiç oynatmayız —
 * gereksiz hareket en çok rahatsız eden şey.
 */
export function rahatGorunuyorMu(
  oge: Element,
  ustSinir: number,
  altSinir: number,
): boolean {
  const kutu = oge.getBoundingClientRect();
  return kutu.top >= ustSinir && kutu.bottom <= altSinir;
}
