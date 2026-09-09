import { readFileSync, readdirSync, statSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";

/**
 * İletişim alanları — TEK KAYNAK kilidi.
 *
 * Bu dosya eskiden "iletişim paritesi" adıyla şunu yapıyordu: Flutter'ın
 * ESNAF İLETİŞİM BİLGİSİ DÜZENLEME formunu (`form_contact_info.dart`),
 * web'in HALKA AÇIK DESTEK SAYFASIYLA (`/iletisim`, destek@vixrex.com)
 * karşılaştırıyordu. İki tamamen farklı yüzey.
 *
 * Dört testin üçü yalnız Flutter dosyasına bakıyordu; dördüncüsü web
 * dosyasında "iletisim" ve "destek" kelimelerini arıyordu. İkisi de geçtiği
 * için test yeşil yanıyor, matriste "✓ eşit" yazıyordu. O satır hiç
 * ölçülmemişti (2026-09-09 denetimi).
 *
 * Yerine geçen kontrol: iletişim alanlarının tanımı tek kaynakta yaşar ve
 * hiçbir istemci etiketi elle yazmaz. Karşılaştırma yok — ayrışma imkânı yok.
 * Flutter aynası: `test/vitrin_alan_tek_kaynak_test.dart`.
 */

const ILETISIM_ALANLARI = ["whatsapp", "telefon", "eposta", "instagram"];

/**
 * Tek dosyaya bakmıyoruz: Flutter iletişim alanlarını iki ayrı ekrana
 * bölmüş (`form_contact_info.dart` → whatsapp/telefon,
 * `sections/iletisim_bolumu.dart` → whatsapp/telefon/e-posta). Eski test
 * bunlardan yalnız birine bakıyordu — dosya adına bağlı test, ayrışmayı
 * gizleyen şeyin ta kendisi.
 */
const DUZENLEYICI_DIZINI = resolve(__dirname, "../../lib/widgets/editor");

function dartDosyalari(dizin: string): string[] {
  const cikti: string[] = [];
  for (const ad of readdirSync(dizin)) {
    const tam = resolve(dizin, ad);
    if (statSync(tam).isDirectory()) cikti.push(...dartDosyalari(tam));
    else if (ad.endsWith(".dart")) cikti.push(tam);
  }
  return cikti;
}

const flutterDuzenleyiciler = dartDosyalari(DUZENLEYICI_DIZINI).map((p) => ({
  ad: p,
  govde: readFileSync(p, "utf8"),
}));

describe("iletişim alanları — tek kaynak", () => {
  it("iletişim alanları ortak şemada tanımlı", () => {
    for (const anahtar of ILETISIM_ALANLARI) {
      const alan = FIELD_BY_KEY.get(anahtar);
      expect(alan, `şemada yok: ${anahtar}`).toBeTruthy();
      expect(alan!.etiket.length).toBeGreaterThan(0);
      expect(alan!.kolon.length).toBeGreaterThan(0);
    }
  });

  it("hiçbir Flutter düzenleme ekranı iletişim etiketini elle yazmıyor", () => {
    const suclular: string[] = [];
    for (const anahtar of ILETISIM_ALANLARI) {
      const etiket = FIELD_BY_KEY.get(anahtar)!.etiket;
      for (const dosya of flutterDuzenleyiciler) {
        if (dosya.govde.includes(`'${etiket}'`)) {
          suclular.push(`${dosya.ad} → ${etiket}`);
        }
      }
    }
    expect(
      suclular,
      "vitrinAlanEtiketi('<anahtar>') kullanılmalı — elle yazılan etiket " +
        "şema değiştiğinde eski kalır ve web ile ayrışır."
    ).toEqual([]);
  });

  it("iletişim alanları Flutter düzenleme ekranlarında hâlâ var", () => {
    // Yüzeyin var olduğunun kontrolü — parite iddiası değil.
    for (const anahtar of ILETISIM_ALANLARI) {
      const kolon = FIELD_BY_KEY.get(anahtar)!.kolon;
      const bulundu = flutterDuzenleyiciler.some(
        (d) => d.govde.includes(anahtar) || d.govde.includes(kolon)
      );
      expect(bulundu, `${anahtar} artık hiçbir düzenleme ekranında yok`).toBe(true);
    }
  });
});
