// Tıkla-düzenle işaretleri (implementation_plan.md Commit 9).
//
// Vitrindeki bir öğeye şu etiketleri koyar:
//   data-vixrex-editable="<anahtar>"            → hangi alan
//   data-vixrex-label="<Türkçe ad>"             → kullanıcıya ne denecek
//   data-vixrex-onem="<temel|kalite|istege-bagli>" → alan önemi (CSS renk kaynağı)
//   data-vixrex-bolum="<hero|contact|...|blog|faq|about>" → bölüm (CSS renk kaynağı)
//
// Değerler vitrinFieldSchema.ts'ten gelir; elle yazılmaz. Yeni alan
// eklendiğinde bu dosya değişmez.
//
// MÜŞTERİ GÖRÜNÜMÜ HİÇ DEĞİŞMEZ: sahip modu kapalıyken boş nesne döner,
// yani DOM'a tek bir öznitelik bile eklenmez. Koruma sınırı 3
// (sahip araçları müşteri yanıtına sızmaz).

import { FIELD_BY_KEY } from "./vitrinFieldSchema";

export type EditableProps = Record<string, string>;

export function editableProps(
  anahtar: string,
  ownerMode: boolean | undefined
): EditableProps {
  if (!ownerMode) return {};

  const alan = FIELD_BY_KEY.get(anahtar);
  if (!alan) {
    // Şemada olmayan bir anahtar işaretlenmeye çalışılmış. Sessizce
    // yok sayılır; testler bunu ayrıca yakalar.
    return {};
  }

  return {
    "data-vixrex-editable": alan.anahtar,
    "data-vixrex-label": alan.etiket,
    "data-vixrex-onem": alan.zorunlu ? "temel" : alan.kalite ? "kalite" : "istege-bagli",
    "data-vixrex-bolum": alan.bolum,
  };
}
