// ÜRETİLMİŞ – Kaynak: shared/vixrex_niyet_sozlugu.json
// Flutter lib/config/vixrex_niyet_sozlugu.g.dart ile aynı kaynak.
import sozluk from "../../../shared/vixrex_niyet_sozlugu.json";

export interface VixrexNiyetAlan {
  anahtar: string;
  etiket: string;
  tip: string;
  kolon: string;
  bolum: string;
  beklenenVeriTipi: string;
  esAnlamlar: string[];
  ornekIfadeler: string[];
}

export const VIXREX_NIYET_SOZLUGU: readonly VixrexNiyetAlan[] =
  (sozluk as { alanlar: VixrexNiyetAlan[] }).alanlar;

export const VIXREX_NIYET_ALAN_BY_ANAHTAR: ReadonlyMap<string, VixrexNiyetAlan> =
  new Map(VIXREX_NIYET_SOZLUGU.map((a) => [a.anahtar, a]));
