// shared/vixrex_mesajlar.json — Vixrex sohbet asistanının tek metin
// kaynağı. Flutter tarafı aynı JSON'dan lib/config/vixrex_mesajlar.g.dart
// üretir (tool/mesaj_semasi_uret.dart). Bu dosya JSON'u tipli okur;
// CI sapma kontrolü ikisinin ayrışmasını yakalar.
//
// Kapsam: yalnız sabit metin gövdesi. Dinamik olarak birleştirilen
// mesajlar ve hızlı yanıtların aksiyon bağlantıları burada değil.
//
// Henüz hiçbir Next.js ekranı bu kataloğu render etmiyor — tüketici
// Faz G'nin (OwnerAssistantPanel) işi. Bu dosya yalnız kaynağı okunabilir
// kılar.
import vixrexMesajlariJson from "../../../shared/vixrex_mesajlar.json";

export interface VixRexIntentSemasi {
  payload: string;
  anahtarKelimeler: string[];
}

export interface VixRexMesajSemasi {
  anahtar: string;
  metin: string;
}

export interface VixRexAsistanAkisAdimi {
  id: "name" | "category" | "whatsapp" | "location" | "legal" | "publish" | "share";
  alanlar: string[];
  mesaj: string;
  girdi: "metin" | "secim" | "telefon" | "konum" | "onay" | "eylem";
  yerTutucu: string | null;
}

export interface VixRexHizliSecenek {
  id: "hazir_vitrin_sec" | "sifirdan_olustur" | "bakiniyorum";
  etiket: string;
  ikon: string;
}

interface VixRexMesajKatalogu {
  akis: VixRexAsistanAkisAdimi[];
  intentler: VixRexIntentSemasi[];
  mesajlar: VixRexMesajSemasi[];
  hizliSecenekler: VixRexHizliSecenek[];
}

const katalog = vixrexMesajlariJson as VixRexMesajKatalogu;

export const vixRexIntentSemasi: VixRexIntentSemasi[] = katalog.intentler;

/** APK, landing ve sahip panelinin tek kurulum sırası. */
export const vixRexAsistanAkisi: readonly VixRexAsistanAkisAdimi[] =
  katalog.akis;

export function vixRexAsistanAdimiForAlan(
  anahtar: string,
): VixRexAsistanAkisAdimi | null {
  return vixRexAsistanAkisi.find((adim) => adim.alanlar.includes(anahtar)) ?? null;
}

export const vixRexMesajlari: Record<string, string> = Object.fromEntries(
  katalog.mesajlar.map((m) => [m.anahtar, m.metin]),
);

export const vixRexHizliSecenekler: readonly VixRexHizliSecenek[] =
  katalog.hizliSecenekler;

/**
 * Hızlı seçenek etiketi — TEK KAYNAK.
 *
 * Etiketler `shared/vixrex_mesajlar.json` içinde yaşar; hiçbir ekran bu
 * yazıları elle yazmaz. Elle yazıldığında kaynak değişse bile o ekran
 * eskisini göstermeye devam eder — kayıt sayfasında tam bu yüzden
 * "Bakiniyorum" diye hatalı bir yazı aylarca canlıda durdu.
 *
 * `landing-hizli-secenek-tek-kaynak.test.ts` bu dosyanın dışında literal
 * etiket yazılmasını engeller.
 */
export function hizliSecenekEtiketi(id: string): string {
  const secenek = vixRexHizliSecenekler.find((item) => item.id === id);
  if (!secenek) {
    throw new Error(`Hızlı seçenek katalogda yok: ${id}`);
  }
  return secenek.etiket;
}
