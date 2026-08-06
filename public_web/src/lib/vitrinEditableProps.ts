// Tıkla-düzenle işaretleri (implementation_plan.md Commit 9).
//
// Vitrindeki bir öğeye şu iki etiketi koyar:
//   data-vixrex-editable="<anahtar>"   → hangi alan
//   data-vixrex-label="<Türkçe ad>"    → kullanıcıya ne denecek
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
  };
}
