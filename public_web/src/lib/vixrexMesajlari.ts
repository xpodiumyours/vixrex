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

interface VixRexMesajKatalogu {
  intentler: VixRexIntentSemasi[];
  mesajlar: VixRexMesajSemasi[];
}

const katalog = vixrexMesajlariJson as VixRexMesajKatalogu;

export const vixRexIntentSemasi: VixRexIntentSemasi[] = katalog.intentler;

export const vixRexMesajlari: Record<string, string> = Object.fromEntries(
  katalog.mesajlar.map((m) => [m.anahtar, m.metin]),
);
