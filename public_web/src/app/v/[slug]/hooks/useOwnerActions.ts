"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { resolveVitrinProfile } from "@/lib/vitrinProfile";
import { taslakClientId } from "@/lib/canliVitrinSenkron";
import { FIELD_BY_KEY, type VitrinConcept, type VitrinField } from "@/lib/vitrinFieldSchema";
import { resolveVitrinConceptIntent, vitrinConceptPrompt } from "@/lib/vitrinConceptIntent";
import { serbestMetindenAlanlariCikar, type SerbestMetinSonuc } from "@/lib/serbestMetinCikarim";
import { handleVixrexNluMessage } from "@/lib/vixrexNluPipeline";
import { resolveVixrexIntentsAll } from "@/lib/vixrexIntentResolver";
import { VIXREX_NIYET_ALAN_BY_ANAHTAR } from "@/lib/vixrexNiyetSozlugu";
import { extractVixrexValue, digerAlanaAitIpucuVarMi } from "@/lib/vixrexValueExtractor";
import type { Mesaj } from "./useOwnerChat";

/** Hangi alan hangi tür hazır görsele karşılık geliyor. */
const GORSEL_TURU: Record<string, "cover" | "logo_placeholder" | "gallery" | "product"> = {
  kapakGorseli: "cover",
  logo: "logo_placeholder",
  hakkindaGorsel: "gallery",
  bantGorsel: "product",
};

/** globals.css'teki kısa "değişti" parıltısı. */
const PARLAMA_SINIFI = "vixrex-degisti";

export interface HazirGorsel {
  image_url: string;
  title?: string | null;
}

export interface OwnerActionsHook {
  kaydediliyor: boolean;
  yayinlaniyor: boolean;
  silmeOnayi: boolean;
  hazirGorseller: HazirGorsel[];
  hazirYukleniyor: boolean;
  gorselYukle: (dosya: File) => Promise<void>;
  hazirGorselleriAc: () => Promise<void>;
  hazirGorselSec: (url: string) => Promise<void>;
  gonder: () => Promise<void>;
  alanAtla: () => Promise<void>;
  yayinla: () => Promise<void>;
  silmeOnayla: () => void;
  sil: () => Promise<void>;
  setSilmeOnayi: (v: boolean) => void;
  onayVeriliyor: boolean;
  onayVer: () => Promise<void>;
}

interface Deps {
  slug: string;
  seciliAlan: VitrinField | null;
  giris: string;
  yerelTaslak: Record<string, unknown>;
  mesajEkle: (
    kimden: Mesaj["kimden"],
    metin: string,
    hizliCevaplar?: Mesaj["hizliCevaplar"],
    sistemIkon?: Mesaj["sistemIkon"]
  ) => void;
  setAlan: (kolon: string, deger: unknown) => void;
  setGiris: (v: string) => void;
  /** Akıllı motor alanı anladı ama değeri eksikse o alanı seçili yapar —
   * esnaf devamında yalnız değeri yazsın. */
  alanSec?: (anahtar: string) => void;
  kavramSec?: (kavram: VitrinConcept) => void;
  /** Kayıt (veya boş geçme) başarılı olunca çağrılır: sırada başka alan
   * varsa oraya geçer. */
  alanaGecVeyaBitir: (
    kaydedilenAnahtar: string,
    guncelTaslak?: Record<string, unknown>,
  ) => void;
  /** "Boş geç" kalıcı işaretlendiğinde yerel state'e yansıtır
   * (`useOwnerDraft.alanAtlandi`). */
  alanAtlandi: (anahtar: string) => void;
}

/**
 * Kaydedilen alanı sayfada kısa süre parlatır (Faz 2).
 *
 * Neden gerekli: değişiklik artık sayfaya anında yansıyor, ama esnaf
 * gözünü kutuya dikmişken vitrindeki yazının değiştiğini kaçırabiliyor.
 * Bu, "kaydettim" demenin sayfa üstündeki karşılığı.
 *
 * `router.refresh()` sunucudan gelen içerikle DOM'u yamalar, className'i
 * değiştirmez — bu yüzden sınıf tazeleme sırasında da yerinde kalır.
 */
function alaniParlat(anahtar: string) {
  if (typeof document === "undefined") return;
  const oge = document.querySelector(`[data-vixrex-editable="${anahtar}"]`);
  if (!oge) return;
  oge.classList.add(PARLAMA_SINIFI);
  window.setTimeout(() => oge.classList.remove(PARLAMA_SINIFI), 1400);
}

// Serbest metinden bonus alan çıkarımının VITRIN_FIELDS `anahtar`
// isimlerine eşlemesi.
const SERBEST_ANLATIM_ESLEME: ReadonlyArray<[keyof SerbestMetinSonuc, string]> = [
  ["whatsapp", "whatsapp"],
  ["kategoriEtiketi", "kategori"],
  ["calismaSaatleriMetni", "calismaSaatleri"],
  ["ilAdi", "il"],
  ["ilceAdi", "ilce"],
  ["adres", "adres"],
];

/**
 * Seçili bir kutuya (ör. "İşletme Adı") zengin bir cümle yazılınca, kutunun
 * KENDİ değerini cümleden temizce ayırmayı dener.
 *
 * 2026-09-03 (Casper canlıda buldu, kiralık-kafe vitrini): "işletme adım
 * Konak Kafe, whatsapp numaram 0542..." yazılınca eskiden TÜM cümle
 * olduğu gibi isim alanına kaydediliyordu ("KONAK KAFE 05421802573").
 * Whatsapp'ı `serbestMetindenAlanlariCikar` zaten AYRI ve doğru buluyordu
 * (regex kalıbı), ama isim kutusunun kendisi hiç ayrıştırılmıyordu.
 *
 * Üç adım, en güvenliden en riskliye:
 *  1) Seçili alan bonus'un kapsadığı (whatsapp/kategori/saat/il/ilçe/adres)
 *     kolonlardan biriyse, bonus'un kendi regex/sözlük tabanlı çıkarıcısı
 *     kullanılır — bu, anahtar kelime aramasından güçlüdür (ör. "whatsapp"
 *     kelimesi hiç geçmese de bir telefon kalıbını yakalar).
 *  2) Aksi hâlde 46 alanlık niyet motoru (hiçbir kutu seçili değilken zaten
 *     kullanılan aynı motor, `vixrexValueExtractor.ts`) cümlede bu alanın
 *     kendi anahtar kelimesini (ör. "işletme adı") arar ve ondan sonraki
 *     kısmı, BAŞKA bir alana ait ipucuna kadar (bkz. o dosyadaki sınır
 *     düzeltmesi) ayırır.
 *  3) İkisinden en az biri bir şey bulduysa, İKİSİ ARASINDA EN KISA OLAN
 *     kullanılır — bulaşma her zaman metni UZATIR, hiç kısaltmaz, o yüzden
 *     kısa olan daha temizdir (ör. adres bonus'u "adresimiz Atatürk Cad.
 *     No:24" döndürse de niyet motoru "Atatürk Cad. No:24" verir, ikincisi
 *     seçilir).
 *  4) İkisi de bir şey bulamadıysa: cümlede başka bir alana ait TANINAN bir
 *     ipucu var mı diye bakılır (`digerAlanaAitIpucuVarMi` — kelime sınırlı,
 *     kısa/genel eş-anlamları saymaz). Yoksa muhtemelen tek parça düz bir
 *     cevaptır (ör. uzun bir "hakkında" metni) — olduğu gibi kaydedilir.
 *     Varsa, hangi kısmın seçili alana ait olduğunu güvenle ayıramadık
 *     demektir — `null` döner, çağıran taraf ham metni YAZMAZ, dürüstçe
 *     sorar (bonus yine de diğer alanları ayrıca doğru kaydeder).
 */
export function temizlenmisSeciliDeger(metin: string, alan: VitrinField): string | null {
  const adaylar: string[] = [];

  const bonusAnahtari = SERBEST_ANLATIM_ESLEME.find(([, anahtar]) => anahtar === alan.anahtar)?.[0];
  if (bonusAnahtari) {
    const bonusDeger = serbestMetindenAlanlariCikar(metin)[bonusAnahtari];
    if (bonusDeger) adaylar.push(bonusDeger);
  }

  const niyetAlani = VIXREX_NIYET_ALAN_BY_ANAHTAR.get(alan.anahtar);
  if (niyetAlani) {
    const cikan = extractVixrexValue(metin, niyetAlani);
    if (cikan) adaylar.push(cikan);
  }

  if (adaylar.length > 0) {
    return adaylar.reduce((enKisa, aday) => (aday.length < enKisa.length ? aday : enKisa));
  }

  const baskaIpucuVarMi =
    Object.values(serbestMetindenAlanlariCikar(metin)).some(Boolean) ||
    digerAlanaAitIpucuVarMi(metin, alan.anahtar);
  return baskaIpucuVarMi ? null : metin;
}

/**
 * "Esnaf 46 alanı tek tek dolaşmasın" (2026-09-02) — YENİ bir ekran
 * elemanı EKLEMEDEN: esnaf zaten var olan bir soru kutusuna (ör.
 * "İşletme adın?") normalden uzun bir cümle yazarsa, aynı kutu üstünden
 * arka planda diğer alanları da doldurur (bkz. serbestMetinCikarim.ts).
 * Az önce doğrudan cevaplanan alan (`cevaplananKolon`) hariç tutulur —
 * o zaten kendi normal yoluyla (gonder() içinde) kaydedildi.
 *
 * Bonus, gönderimin ANA sonucunu asla etkilemez: hata olursa sessizce
 * yutulur, "işledim" gibi yanıltıcı bir mesaj da verilmez (bkz.
 * serbestMetinCikarim.ts dosya başı yorumu — dürüstlük kuralı aynı).
 *
 * Güvenlik: bonus alanlar da tek kullanıcı cümlesinden çıktığı için parçalı
 * kayıt YASAK. Tümü batch route üzerinden tek transaction'da doğrulanır ve
 * yazılır; bir alan geçersizse bonusların hiçbiri uygulanmaz.
 */
export async function bonusAlanlariCikarVeKaydet(
  metin: string,
  cevaplananKolon: string,
  slug: string,
  mesajEkle: Deps["mesajEkle"],
  setAlan: (kolon: string, deger: unknown) => void,
  routerRefresh: () => void,
) {
  const sonuc = serbestMetindenAlanlariCikar(metin);
  const bulunanlar = SERBEST_ANLATIM_ESLEME
    .map(([sonucAnahtari, anahtar]) => {
      const deger = sonuc[sonucAnahtari];
      const alan = FIELD_BY_KEY.get(anahtar);
      if (!deger || !alan || alan.kolon === cevaplananKolon) return null;
      return { anahtar, kolon: alan.kolon, etiket: alan.etiket, deger };
    })
    .filter((x): x is { anahtar: string; kolon: string; etiket: string; deger: string } => x !== null);

  if (bulunanlar.length === 0) return;

  try {
    const commandId = crypto.randomUUID();
    const yanit = await fetch("/api/owner-draft-batch", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        slug,
        commandId,
        degisiklikler: bulunanlar.map(({ anahtar, deger }) => ({ anahtar, deger })),
        clientId: taslakClientId(),
      }),
    });
    const govde = await yanit.json();
    if (!yanit.ok) return;
    if (typeof govde?.commandId !== "string" || govde.commandId !== commandId) {
      routerRefresh();
      return;
    }

    const kesinDegisiklikler = Array.isArray(govde?.degisiklikler)
      ? (govde.degisiklikler as Array<{
          anahtar?: unknown;
          kolon?: unknown;
          etiket?: unknown;
          deger?: unknown;
        }>)
      : [];
    const basarili: Array<{ etiket: string }> = [];

    for (const item of kesinDegisiklikler) {
      if (typeof item.anahtar !== "string" || typeof item.kolon !== "string") continue;
      const alan = FIELD_BY_KEY.get(item.anahtar);
      if (!alan || alan.kolon !== item.kolon) continue;
      setAlan(alan.kolon, item.deger);
      basarili.push({
        etiket: typeof item.etiket === "string" ? item.etiket : alan.etiket,
      });
    }

    if (basarili.length !== bulunanlar.length) {
      // Sunucu başarılı dediği halde ayrıntı eksikse yerel state tahmin edilmez.
      routerRefresh();
      return;
    }

    routerRefresh();
    const liste = basarili.map(({ etiket }) => `✓ ${etiket}`).join("\n");
    mesajEkle("asistan", `Yazdığından ayrıca şunları da anladım:\n${liste}`, undefined, "✨");
  } catch {
    // Bonus bir zenginleştirme — başarısız olursa asıl kaydı etkilemez.
  }
}

export function useOwnerActions({
  slug,
  seciliAlan,
  giris,
  yerelTaslak,
  mesajEkle,
  setAlan,
  setGiris,
  alanaGecVeyaBitir,
  alanAtlandi,
  alanSec,
  kavramSec,
}: Deps): OwnerActionsHook {
  const router = useRouter();
  const [kaydediliyor, setKaydediliyor] = useState(false);
  const [yayinlaniyor, setYayinlaniyor] = useState(false);
  const [silmeOnayi, setSilmeOnayi] = useState(false);
  const [onayVeriliyor, setOnayVeriliyor] = useState(false);
  const [hazirGorseller, setHazirGorseller] = useState<HazirGorsel[]>([]);
  const [hazirYukleniyor, setHazirYukleniyor] = useState(false);

  const _setHazirGorseller = useCallback(
    (g: HazirGorsel[]) => {
      setHazirGorseller(g);
    },
    []
  );

  // Görsel alanları: URL yazdırmak yerine dosya yükletiyoruz. Esnafın
  // elinde adres yok, telefonunda fotoğraf var.
  const gorselYukle = useCallback(
    async (dosya: File) => {
      if (!seciliAlan || seciliAlan.tip !== "gorsel") return;
      const alan = seciliAlan;

      mesajEkle("kullanici", `📷 ${dosya.name}`);
      setKaydediliyor(true);

      try {
        const form = new FormData();
        form.append("slug", slug);
        form.append("anahtar", alan.anahtar);
        form.append("dosya", dosya);

        const yukleme = await fetch("/api/owner-upload", {
          method: "POST",
          body: form,
        });
        const yuklemeGovde = await yukleme.json();

        if (!yukleme.ok) {
          mesajEkle("asistan", yuklemeGovde?.hata ?? "Görsel yüklenemedi.");
          return;
        }

        // Yükleme başarılı — adres NORMAL alan kayıt yolundan geçer. Böylece
        // doğrulama ve yetki kontrolü tek yerde kalır, ikinci kayıt yolu açılmaz.
        const kayit = await fetch("/api/owner-draft", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            slug,
            anahtar: alan.anahtar,
            deger: yuklemeGovde.url,
            clientId: taslakClientId(),
          }),
        });
        const kayitGovde = await kayit.json();

        if (!kayit.ok) {
          mesajEkle("asistan", kayitGovde?.hata ?? "Görsel kaydedilemedi.");
          return;
        }

        mesajEkle("asistan", `${alan.etiket} güncellendi.`);
        setAlan(alan.kolon, yuklemeGovde.url as unknown);
        // Sirali gecise TAZE taslak verilir: setAlan bu tepki turunda
        // henuz yansimadigi icin kaydedilen alan "bos" gorunurdu.
        const tazeTaslak = { ...yerelTaslak, [alan.kolon]: yuklemeGovde.url };
        // Sayfa sunucuda çizildiği için yeni değer ancak yeniden
        // okununca vitrine yansır — yoksa esnaf kaydeder, sayfada
        // eski yazı durmaya devam ederdi (Faz 2).
        router.refresh();
        alaniParlat(alan.anahtar);
        alanaGecVeyaBitir(alan.anahtar, tazeTaslak);
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
      } finally {
        setKaydediliyor(false);
      }
    },
    [seciliAlan, slug, mesajEkle, setAlan, alanaGecVeyaBitir, router, yerelTaslak]
  );

  // Kategorinin hazır görsellerini getirir. Kategori anahtarı
  // vitrinProfile'dan çözülür — veritabanındaki category_key ile birebir
  // aynı (butik, kuafor, kafe_lokanta ...). 19 kategori × 10 görsel.
  const hazirGorselleriAc = useCallback(async () => {
    if (!seciliAlan || seciliAlan.tip !== "gorsel") return;

    if (hazirGorseller.length > 0) {
      _setHazirGorseller([]); // ikinci tıklamada kapanır
      return;
    }

    setHazirYukleniyor(true);
    try {
      const profil = resolveVitrinProfile(
        (yerelTaslak.kategori as string) ?? null,
        (yerelTaslak.business_type as string) ?? null
      );
      const yanit = await fetch(
        `/api/category-images?category=${encodeURIComponent(profil.id)}`
      );
      const govde = await yanit.json();

      const tur = GORSEL_TURU[seciliAlan.anahtar] ?? "gallery";
      const liste: HazirGorsel[] = govde?.images?.[tur] ?? [];

      if (liste.length === 0) {
        mesajEkle(
          "asistan",
          `${profil.label} kategorisi için hazır görsel bulunamadı. Kendi fotoğrafını yükleyebilirsin.`
        );
        return;
      }
      _setHazirGorseller(liste);
    } catch {
      mesajEkle("asistan", "Hazır görseller getirilemedi. Tekrar dene.");
    } finally {
      setHazirYukleniyor(false);
    }
  }, [seciliAlan, hazirGorseller.length, yerelTaslak, mesajEkle, _setHazirGorseller]);

  // Seçilen hazır görsel NORMAL alan kayıt yolundan geçer — yükleme
  // yolundan değil. Doğrulama ve yetki tek yerde kalır.
  const hazirGorselSec = useCallback(
    async (url: string) => {
      if (!seciliAlan) return;
      const alan = seciliAlan;

      mesajEkle("kullanici", "🖼️ hazır görsel seçildi");
      setKaydediliyor(true);
      try {
        const yanit = await fetch("/api/owner-draft", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            slug,
            anahtar: alan.anahtar,
            deger: url,
            clientId: taslakClientId(),
          }),
        });
        const govde = await yanit.json();

        if (!yanit.ok) {
          mesajEkle("asistan", govde?.hata ?? "Görsel kaydedilemedi.");
          return;
        }

        mesajEkle("asistan", `${alan.etiket} güncellendi.`);
        _setHazirGorseller([]);
        setAlan(alan.kolon, url);
        const tazeTaslak = { ...yerelTaslak, [alan.kolon]: url };
        // Sayfa sunucuda çizildiği için yeni değer ancak yeniden
        // okununca vitrine yansır — yoksa esnaf kaydeder, sayfada
        // eski yazı durmaya devam ederdi (Faz 2).
        router.refresh();
        alaniParlat(alan.anahtar);
        alanaGecVeyaBitir(alan.anahtar, tazeTaslak);
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
      } finally {
        setKaydediliyor(false);
      }
    },
    [seciliAlan, slug, mesajEkle, setAlan, alanaGecVeyaBitir, _setHazirGorseller, router, yerelTaslak]
  );

  const gonder = useCallback(async () => {
    const metin = giris.trim();
    const kavramNiyeti = metin ? resolveVitrinConceptIntent(metin) : null;

    if (kavramNiyeti) {
      mesajEkle("kullanici", metin);
      setGiris("");
      kavramSec?.(kavramNiyeti.id);
      mesajEkle("asistan", vitrinConceptPrompt(kavramNiyeti));
      return;
    }

    let motorSonucu: Awaited<ReturnType<typeof handleVixrexNluMessage>> | null = null;
    if (metin && seciliAlan && resolveVixrexIntentsAll(metin).length > 0) {
      try {
        motorSonucu = await handleVixrexNluMessage(metin);
      } catch {
        motorSonucu = null;
      }
    }
    const motorCozdu =
      motorSonucu?.outcome === "handled" && (motorSonucu.tumu?.length ?? 0) > 0;

    if (!seciliAlan || motorCozdu) {
      if (!metin) return;
      mesajEkle("kullanici", metin);
      setGiris("");
      setKaydediliyor(true);
      try {
        const sonuc = motorSonucu ?? (await handleVixrexNluMessage(metin));
        const cozulen = sonuc.tumu ?? [];

        if (sonuc.outcome !== "handled" || cozulen.length === 0) {
          mesajEkle("asistan", sonuc.message);
          // Motor alani anladi ama degeri eksikse o alani secili hale getir:
          // esnaf devaminda sadece degeri yazsin, alani tekrar tarif etmesin.
          if (sonuc.anahtar) alanSec?.(sonuc.anahtar);
          return;
        }

        let tazeTaslak = { ...yerelTaslak };
        const kaydedilen: string[] = [];
        const kaydedilenSatirlar: string[] = [];
        const commandId = crypto.randomUUID();

        // Assistant serbest-metin yazımı TEK ALAN olsa bile aynı command
        // güvenlik kapısından geçer. Bir kullanıcı mesajı bir commandId alır;
        // retry aynı ID ile yeniden yazmaz, undo da yalnız bu command'a bağlıdır.
        const yanit = await fetch("/api/owner-draft-batch", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            slug,
            commandId,
            degisiklikler: cozulen.map(({ anahtar, deger }) => ({ anahtar, deger })),
            clientId: taslakClientId(),
          }),
        });
        const govde = await yanit.json();

        if (!yanit.ok) {
          mesajEkle("asistan", govde?.hata ?? "Değişiklikler kaydedilemedi.");
          return;
        }
        if (typeof govde?.commandId !== "string" || govde.commandId !== commandId) {
          router.refresh();
          mesajEkle(
            "asistan",
            "Kayıt tamamlandı ancak işlem kimliği doğrulanamadı. Vitrini yeniledim."
          );
          return;
        }

        const kesinDegisiklikler = Array.isArray(govde?.degisiklikler)
          ? (govde.degisiklikler as Array<{
              anahtar?: unknown;
              kolon?: unknown;
              etiket?: unknown;
              deger?: unknown;
            }>)
          : [];

        // Yerel görünümü yalnız sunucunun gerçekten kaydettiğini bildirdiği
        // normalize sonuçtan güncelle. Pipeline tahmini kayıt kanıtı değildir.
        for (const item of kesinDegisiklikler) {
          if (typeof item.anahtar !== "string" || typeof item.kolon !== "string") {
            continue;
          }
          const etiket =
            typeof item.etiket === "string"
              ? item.etiket
              : FIELD_BY_KEY.get(item.anahtar)?.etiket ?? item.anahtar;
          setAlan(item.kolon, item.deger);
          tazeTaslak = { ...tazeTaslak, [item.kolon]: item.deger };
          kaydedilen.push(item.anahtar);
          kaydedilenSatirlar.push(`Kaydettim: ${etiket} → ${String(item.deger)}`);
          alaniParlat(item.anahtar);
        }

        if (kaydedilen.length !== cozulen.length) {
          // Sunucu başarılı dediği halde sözleşme eksik cevap döndürürse
          // "hepsi kaydedildi" diye uydurmayız. Yeniden okuma gerçeği getirir.
          router.refresh();
          mesajEkle(
            "asistan",
            "Kayıt tamamlandı ancak sonuç ayrıntısı doğrulanamadı. Vitrini yeniledim."
          );
          return;
        }

        if (kaydedilen.length === 0) {
          mesajEkle("asistan", "Kaydedemedim, tekrar dener misin?");
          return;
        }

        // Motorun tahmini değil, gerçek kayıt sonucu gösterilir. Undo payload'ı
        // alan adı değil commandId taşır; eski kart yeni aynı-alan command'ını
        // geri alamaz.
        mesajEkle(
          "asistan",
          kaydedilenSatirlar.join("\n"),
          [
            { label: "Doğru", payload: "onay_tamam" },
            { label: "Geri al", payload: `geri_al:${commandId}` },
          ],
          "✅"
        );
        router.refresh();
        alanaGecVeyaBitir(kaydedilen[kaydedilen.length - 1], tazeTaslak);
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
      } finally {
        setKaydediliyor(false);
      }
      return;
    }

    const alan = seciliAlan;

    // Zengin cümle ayrıştırması (2026-09-03, bkz. temizlenmisSeciliDeger
    // yorumu): kısa girdilerde ve aç/kapa alanlarda davranış AYNI kalır —
    // ayrıştırma yalnız 15+ karakterlik metinlerde denenir (bonus'un
    // tetiklenme eşiğiyle aynı, aşağıda).
    let gonderilecek: string | boolean;
    if (alan.tip === "acikKapali") {
      gonderilecek = ["evet", "aç", "açık", "göster", "true"].includes(metin.toLowerCase());
    } else if (metin.length < 15) {
      gonderilecek = metin;
    } else {
      const temiz = temizlenmisSeciliDeger(metin, alan);
      if (temiz === null) {
        // Cümlede başka bir alana ait ipucu var ama seçili alanın kendi
        // değerini güvenle ayıramadık — ham metni YAZMAYIZ, dürüstçe
        // sorarız. Bonus yine de diğer alanları ayrıca doğru kaydeder.
        mesajEkle("kullanici", metin);
        mesajEkle(
          "asistan",
          `Bu cümlede birden fazla bilgi var gibi görünüyor. "${alan.etiket}" için sadece onu yazar mısın?`
        );
        setGiris("");
        return;
      }
      gonderilecek = temiz;
    }

    mesajEkle("kullanici", metin || "(boş bırak)");
    setKaydediliyor(true);

    try {
      const yanit = await fetch("/api/owner-draft", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug,
          anahtar: alan.anahtar,
          deger: gonderilecek,
          clientId: taslakClientId(),
        }),
      });
      const govde = await yanit.json();

      if (!yanit.ok) {
        mesajEkle("asistan", govde?.hata ?? "Kaydedilemedi.");
        return;
      }

      mesajEkle(
        "asistan",
        `${alan.etiket} güncellendi. Müşteriler yayınlayana kadar göremez.`
      );
      setGiris("");
      setAlan(alan.kolon, gonderilecek);
      const tazeTaslak = { ...yerelTaslak, [alan.kolon]: gonderilecek };
      // Sayfa sunucuda çizildiği için yeni değer ancak yeniden
      // okununca vitrine yansır — yoksa esnaf kaydeder, sayfada
      // eski yazı durmaya devam ederdi (Faz 2).
      router.refresh();
      alaniParlat(alan.anahtar);
      alanaGecVeyaBitir(alan.anahtar, tazeTaslak);

      // "Esnaf 46 alanı tek tek dolaşmasın" (2026-09-02) — bu KUTUYA
      // (ör. "İşletme adın?") normalden uzun bir cümle yazılırsa, arka
      // planda diğer alanları da doldurmayı dener. Yeni bir ekran
      // elemanı yok — yalnız zaten var olan bu giriş kutusu akıllanıyor.
      if (typeof gonderilecek === "string" && metin.length >= 15) {
        void bonusAlanlariCikarVeKaydet(
          metin,
          alan.kolon,
          slug,
          mesajEkle,
          setAlan,
          () => router.refresh()
        );
      }
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setKaydediliyor(false);
    }
  }, [giris, seciliAlan, slug, mesajEkle, setAlan, setGiris, alanaGecVeyaBitir, router, yerelTaslak, alanSec, kavramSec]);

  // Yalnız isteğe bağlı alanlarda gösterilen "Boş geç" (ADR 0002, 3. alt-faz).
  // Vitrin İÇERİĞİ yazmaz — /api/owner-draft'tan bağımsız, kendi dar
  // rotasından (/api/owner-draft-skip) geçer; kalıcı olsun diye.
  const alanAtla = useCallback(async () => {
    if (!seciliAlan) return;
    const alan = seciliAlan;

    mesajEkle("kullanici", "(boş geç)");
    setKaydediliyor(true);

    try {
      const yanit = await fetch("/api/owner-draft-skip", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, anahtar: alan.anahtar }),
      });
      const govde = await yanit.json();

      if (!yanit.ok) {
        mesajEkle("asistan", govde?.hata ?? "Kaydedilemedi.");
        return;
      }

      mesajEkle("asistan", `${alan.etiket} şimdilik boş geçildi.`);
      alanAtlandi(alan.anahtar);
      alanaGecVeyaBitir(alan.anahtar);
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setKaydediliyor(false);
    }
  }, [seciliAlan, slug, mesajEkle, alanAtlandi, alanaGecVeyaBitir]);

  const yayinla = useCallback(async () => {
    // Kutuda yazılıp "Gönder"e hiç basılmamış bir değer varken "Yayınla"
    // sessizce eski (kayıtlı) hâli yayınlıyordu — esnaf yazdığını sanıyor,
    // yayınlanan hiç değişmiyordu (canlıda bulundu, 2026-08-13: WhatsApp
    // numarası kutuya yazıldı, Gönder'e basılmadan Yayınla'ya basıldı,
    // eski/boş numara yayınlandı). metin/sayı/telefon/url gibi yazılabilir
    // tiplerde kutu, kayıtlı değerden farklıysa durdurup uyarır.
    if (
      seciliAlan &&
      seciliAlan.tip !== "acikKapali" &&
      seciliAlan.tip !== "gorsel" &&
      seciliAlan.tip !== "secim"
    ) {
      const kayitli = yerelTaslak[seciliAlan.kolon];
      const kayitliMetin =
        kayitli === null || kayitli === undefined ? "" : String(kayitli);
      if (giris !== kayitliMetin) {
        mesajEkle(
          "asistan",
          `"${seciliAlan.etiket}" için yazdığın değer henüz gönderilmedi. Önce "Gönder"e bas, sonra yayınla — yoksa eski hâli yayınlanır.`
        );
        return;
      }
    }

    mesajEkle("kullanici", "Yayınla");
    setYayinlaniyor(true);

    try {
      const yanit = await fetch("/api/owner-publish", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug }),
      });
      const govde = await yanit.json();

      if (!yanit.ok) {
        // Sunucunun mesajı OLDUĞU GİBİ gösterilir; kendi metnimiz uydurulmaz.
        mesajEkle("asistan", govde?.hata ?? "Yayınlanamadı. Lütfen tekrar dene.");
        return;
      }

      mesajEkle(
        "asistan",
        "Vitrinin yayınlandı. Müşterilerin artık yeni hâlini görüyor."
      );
      router.refresh();
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setYayinlaniyor(false);
    }
  }, [slug, mesajEkle, router, seciliAlan, giris, yerelTaslak]);

  // Yasal onay — accept_store_legal_consent RPC'sini çağırır (bkz.
  // supabase/migrations/20260820000000_accept_store_legal_consent.sql).
  // Başarıdan sonra router.refresh() gerekir: draftData sunucuda yeniden
  // okunmadan yerelTaslak'taki onay bayrakları güncellenmez, PublishBar
  // hâlâ "onaylanmadı" görür.
  const onayVer = useCallback(async () => {
    mesajEkle("kullanici", "Onaylıyorum");
    setOnayVeriliyor(true);

    try {
      const yanit = await fetch("/api/owner-accept-legal", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug }),
      });
      const govde = await yanit.json();

      if (!yanit.ok) {
        mesajEkle("asistan", govde?.hata ?? "Onay verilemedi. Lütfen tekrar dene.");
        return;
      }

      mesajEkle("asistan", "Onay kaydedildi. Artık yayınlayabilirsin.");
      router.refresh();
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setOnayVeriliyor(false);
    }
  }, [slug, mesajEkle, router]);

  // "Değişiklikleri bırak" TEK TIKLA silmez: önce onay istenir.
  // Bu düğme kullanıcının saatlerce yaptığı işi silebilir.
  const silmeOnayla = useCallback(() => {
    mesajEkle(
      "asistan",
      "Yaptığın tüm değişiklikler silinecek ve vitrin son yayınlanan hâline dönecek. Emin misin?"
    );
    setSilmeOnayi(true);
  }, [mesajEkle]);

  const sil = useCallback(async () => {
    setYayinlaniyor(true);

    try {
      const yanit = await fetch("/api/owner-discard", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug }),
      });
      const govde = await yanit.json();

      if (!yanit.ok) {
        mesajEkle("asistan", govde?.hata ?? "Değişiklikler geri alınamadı.");
        return;
      }

      setSilmeOnayi(false);
      mesajEkle(
        "asistan",
        "Değişiklikler silindi. Vitrin son yayınlanan hâlinde."
      );
      router.refresh();
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setYayinlaniyor(false);
    }
  }, [slug, mesajEkle, router]);

  return {
    kaydediliyor,
    yayinlaniyor,
    silmeOnayi,
    hazirGorseller,
    hazirYukleniyor,
    gorselYukle,
    hazirGorselleriAc,
    hazirGorselSec,
    gonder,
    alanAtla,
    yayinla,
    silmeOnayla,
    sil,
    setSilmeOnayi,
    onayVeriliyor,
    onayVer,
  };
}
