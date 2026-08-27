import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import katalog from "../../shared/vixrex_mesajlar.json";

/**
 * LANDING ASİSTANI — TEK KAYNAK BEKÇİSİ (2026-08-27).
 *
 * NEDEN VAR
 * Ana sayfadaki asistan önce sabit metinli bir maketti; sonra gerçekten
 * çalışır hâle getirildi. Karar şuydu: yeni bir "beyin" doğmayacak,
 * asistan iki yüzeyde de AYNI sözlükten konuşacak —
 * `shared/vixrex_mesajlar.json`. Flutter da o dosyayı okuyor
 * (`lib/config/vixrex_mesajlar.g.dart`).
 *
 * Bu kolayca bozulur: biri bileşene "Merhaba, ben Vixrex" diye tek satır
 * yazar ve o cümle artık yalnız webde yaşar. Bir süre sonra iki asistan
 * farklı konuşmaya başlar ve kimse fark etmez.
 *
 * Aşağıdaki iddialar o kaymayı imkânsız kılar.
 */

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const akis = oku("src/lib/landingAsistanAkisi.ts");
const bilesen = oku("src/components/landing/LandingAsistanSohbeti.tsx");

const mesajAnahtarlari = new Set(
  (katalog.mesajlar as { anahtar: string }[]).map((m) => m.anahtar)
);

describe("landing asistanı tek kaynaktan konuşuyor", () => {
  it("akış dosyasının kullandığı her anahtar katalogda var", () => {
    const kullanilan = [...akis.matchAll(/metin\("([^"]+)"\)/g)].map(
      (m) => m[1]
    );

    // Çıkarıcı bozulursa test sessizce yeşile döner: hiç anahtar
    // bulamayan bir tarama hiçbir eksiği yakalayamaz.
    expect(kullanilan.length).toBeGreaterThan(10);

    const eksik = kullanilan.filter((a) => !mesajAnahtarlari.has(a));
    expect(
      eksik,
      "Bu anahtarlar shared/vixrex_mesajlar.json içinde yok. " +
        "Metni bileşene yazmak yerine kataloğa ekleyin ve " +
        "`dart run tool/mesaj_semasi_uret.dart` ile Flutter tarafını tazeleyin."
    ).toEqual([]);
  });

  it("bileşende elle yazılmış kullanıcı cümlesi yok", () => {
    // JSX metin düğümlerindeki uzun Türkçe cümleleri ara. Kısa etiketler
    // (Kapat, Vixrex) ve teknik dizeler kapsam dışı — aranan şey
    // katalogdan gelmesi gereken KONUŞMA metni.
    const jsxMetinleri = [...bilesen.matchAll(/>([^<>{}\n]{25,})</g)]
      .map((m) => m[1].trim())
      .filter((t) => /[a-zçğıöşü]/i.test(t));

    expect(
      jsxMetinleri,
      "Bu cümleler bileşene elle yazılmış. Asistanın sözleri " +
        "shared/vixrex_mesajlar.json'dan gelmeli — yoksa Flutter ile " +
        "web ayrışır ve kimse fark etmez."
    ).toEqual([]);
  });

  it("landing kapanış mesajları katalogda tanımlı", () => {
    // Sohbetin son adımı kayıt akışına devrediyor. O cümleler de
    // paylaşılan katalogda olmalı ki Flutter da aynısını kullanabilsin.
    for (const anahtar of [
      "landing_finish_baslik",
      "landing_finish_aciklama",
      "landing_finish_buton",
    ]) {
      expect(mesajAnahtarlari.has(anahtar), `${anahtar} katalogda yok`).toBe(
        true
      );
    }
  });
});
