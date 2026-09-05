"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { resolveVitrinProfile } from "@/lib/vitrinProfile";
import { taslakClientId } from "@/lib/canliVitrinSenkron";
import { FIELD_BY_KEY, type VitrinField } from "@/lib/vitrinFieldSchema";
import { serbestMetindenAlanlariCikar, type SerbestMetinSonuc } from "@/lib/serbestMetinCikarim";
import { handleVixrexNluMessage } from "@/lib/vixrexNluPipeline";
import { VIXREX_NIYET_ALAN_BY_ANAHTAR } from "@/lib/vixrexNiyetSozlugu";
import { extractVixrexValue, digerAlanaAitIpucuVarMi } from "@/lib/vixrexValueExtractor";
import { SMART_ENGINE_DISABLED_MESSAGE } from "@/lib/smartEngineFlags";
import { executeSmartEngineCommand } from "@/lib/smartEngineCommandClient";
import {
  ownerLifecycleFromCommand,
  type OwnerActionLifecycleResult,
} from "@/lib/ownerActionLifecycle";
import {
  markSmartEngineStorefrontDisabled,
  smartEngineStorefrontClientEnabled,
} from "@/lib/smartEngineFlagsClient";
import { useOwnerDraftVersion } from "../OwnerDraftVersionContext";
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
  gonder: () => Promise<OwnerActionLifecycleResult>;
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

interface BonusAlan {
  anahtar: string;
  kolon: string;
  etiket: string;
  deger: string;
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
 * Serbest metindeki güvenli, bağımsız bonus alanları hazırlar.
 * Çalışma saatleri coupled/special-flow olduğu için generic command'a
 * bilinçli olarak girmez; 5.9 özel akışına bırakılır.
 */
function bonusAlanlariniHazirla(metin: string, cevaplananKolon: string): BonusAlan[] {
  const sonuc = serbestMetindenAlanlariCikar(metin);
  return SERBEST_ANLATIM_ESLEME
    .map(([sonucAnahtari, anahtar]) => {
      if (anahtar === "calismaSaatleri") return null;
      const deger = sonuc[sonucAnahtari];
      const alan = FIELD_BY_KEY.get(anahtar);
      if (!deger || !alan || alan.kolon === cevaplananKolon) return null;
      return { anahtar, kolon: alan.kolon, etiket: alan.etiket, deger };
    })
    .filter((x): x is BonusAlan => x !== null);
}

/**
 * "Esnaf 46 alanı tek tek dolaşmasın" (2026-09-02) — YENİ bir ekran
 * elemanı EKLEMEDEN: esnaf zaten var olan bir soru kutusuna normalden uzun
 * bir cümle yazarsa, güvenle ayrıştırılan ek alanları authoritative command
 * üzerinden kaydeder.
 *
 * 5.6: Legacy `/api/owner-draft` assistant yolu artık kullanılmaz. Bonus
 * alanların tamamı tek commandId altında actionId/version/audit/Undo zincirine
 * girer. `initialDraftVersion` ekranda gösterilen server snapshot'tan gelir.
 */
export async function bonusAlanlariCikarVeKaydet(
  metin: string,
  cevaplananKolon: string,
  slug: string,
  mesajEkle: Deps["mesajEkle"],
  setAlan: (kolon: string, deger: unknown) => void,
  routerRefresh: () => void,
  initialDraftVersion: number,
  onDraftVersion: (version: number) => void,
) {
  if (!(await smartEngineStorefrontClientEnabled(slug))) return;

  const bulunanlar = bonusAlanlariniHazirla(metin, cevaplananKolon);
  if (bulunanlar.length === 0) return;

  try {
    const commandResult = await executeSmartEngineCommand({
      slug,
      initialDraftVersion,
      actions: bulunanlar.map(({ anahtar, deger }) => ({ anahtar, deger })),
      clientId: taslakClientId(),
    });
    onDraftVersion(commandResult.draftVersion);

    if (commandResult.failed.some((item) => item.code === "SMART_ENGINE_DISABLED")) {
      markSmartEngineStorefrontDisabled(slug);
    }

    const basarili = commandResult.succeeded
      .map((item) => {
        const alan = FIELD_BY_KEY.get(item.anahtar);
        return alan
          ? { anahtar: item.anahtar, kolon: alan.kolon, etiket: alan.etiket, deger: item.deger }
          : null;
      })
      .filter(
        (item): item is { anahtar: string; kolon: string; etiket: string; deger: unknown } =>
          item !== null,
      );

    if (basarili.length === 0) return;

    basarili.forEach(({ kolon, deger, anahtar }) => {
      setAlan(kolon, deger);
      alaniParlat(anahtar);
    });
    routerRefresh();
    const liste = basarili.map(({ etiket }) => `✓ ${etiket}`).join("\n");
    mesajEkle(
      "asistan",
      `Yazdığından ayrıca şunları da anladım:\n${liste}`,
      [
        { label: "Doğru", payload: "onay_tamam" },
        { label: "Geri al", payload: `geri_al:command:${commandResult.commandId}` },
      ],
      "✨",
    );
  } catch {
    // Bonus bir zenginleştirme — başarısız olursa asıl akışı etkilemez.
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
}: Deps): OwnerActionsHook {
  const router = useRouter();
  const { draftVersion, setDraftVersion } = useOwnerDraftVersion();
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
        const tazeTaslak = { ...yerelTaslak, [alan.kolon]: yuklemeGovde.url };
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

  const hazirGorselleriAc = useCallback(async () => {
    if (!seciliAlan || seciliAlan.tip !== "gorsel") return;

    if (hazirGorseller.length > 0) {
      _setHazirGorseller([]);
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

  const gonder = useCallback(async (): Promise<OwnerActionLifecycleResult> => {
    const metin = giris.trim();

    if (!seciliAlan) {
      if (!metin) return { status: "no_op" };
      mesajEkle("kullanici", metin);
      setGiris("");

      try {
        if (!(await smartEngineStorefrontClientEnabled(slug))) {
          mesajEkle("asistan", SMART_ENGINE_DISABLED_MESSAGE);
          return { status: "failed", code: "SMART_ENGINE_DISABLED" };
        }

        const sonuc = await handleVixrexNluMessage(metin);
        const cozulen = sonuc.tumu ?? [];

        if (sonuc.outcome !== "handled" || cozulen.length === 0) {
          mesajEkle("asistan", sonuc.message);
          if (sonuc.anahtar) alanSec?.(sonuc.anahtar);
          return { status: "needs_input" };
        }

        setKaydediliyor(true);
        try {
          const commandResult = await executeSmartEngineCommand({
            slug,
            initialDraftVersion: draftVersion,
            actions: cozulen.map(({ anahtar, deger }) => ({ anahtar, deger })),
            clientId: taslakClientId(),
          });
          setDraftVersion(commandResult.draftVersion);

          if (commandResult.failed.some((item) => item.code === "SMART_ENGINE_DISABLED")) {
            markSmartEngineStorefrontDisabled(slug);
          }

          let tazeTaslak = { ...yerelTaslak };
          const kaydedilen = commandResult.succeeded.map((item) => item.anahtar);
          const kaydedilenSatirlar: string[] = [];

          for (const item of commandResult.succeeded) {
            const alan = FIELD_BY_KEY.get(item.anahtar);
            if (alan) {
              setAlan(alan.kolon, item.deger);
              tazeTaslak = { ...tazeTaslak, [alan.kolon]: item.deger };
            }
            kaydedilenSatirlar.push(
              `Kaydettim: ${alan?.etiket ?? item.anahtar} → ${String(item.deger)}`
            );
            alaniParlat(item.anahtar);
          }

          const basarisizSatirlar = commandResult.failed.map((item) => {
            const alan = FIELD_BY_KEY.get(item.anahtar);
            return `Kaydedemedim: ${alan?.etiket ?? item.anahtar} — ${item.message}`;
          });
          const durdurulanEtiketler = commandResult.stopped.map(
            (item) => FIELD_BY_KEY.get(item.anahtar)?.etiket ?? item.anahtar
          );

          if (kaydedilen.length === 0) {
            const ilkHata = commandResult.failed[0]?.message ?? "Kaydedemedim, tekrar dener misin?";
            const durdurmaNotu =
              durdurulanEtiketler.length > 0
                ? `\nKalan alanları güvenlik için göndermedim: ${durdurulanEtiketler.join(", ")}`
                : "";
            mesajEkle("asistan", `${ilkHata}${durdurmaNotu}`);
            if (commandResult.stopped.length > 0) router.refresh();
            return ownerLifecycleFromCommand(commandResult);
          }

          const mesajParcalari = [...kaydedilenSatirlar, ...basarisizSatirlar];
          if (durdurulanEtiketler.length > 0) {
            mesajParcalari.push(
              `Göndermedim: ${durdurulanEtiketler.join(", ")} — önce güncel taslağı al.`
            );
          }

          mesajEkle(
            "asistan",
            mesajParcalari.join("\n"),
            [
              { label: "Doğru", payload: "onay_tamam" },
              { label: "Geri al", payload: `geri_al:command:${commandResult.commandId}` },
            ],
            commandResult.status === "succeeded" ? "✅" : "⚠️"
          );
          router.refresh();
          alanaGecVeyaBitir(kaydedilen[kaydedilen.length - 1], tazeTaslak);
          return ownerLifecycleFromCommand(commandResult);
        } finally {
          setKaydediliyor(false);
        }
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Değişikliğin sonucunu doğrulayamadım.");
        return { status: "failed", code: "NETWORK_ERROR" };
      }
    }

    const alan = seciliAlan;
    const richTextMotorEnabled =
      alan.tip !== "acikKapali" &&
      alan.anahtar !== "calismaSaatleri" &&
      metin.length >= 15
        ? await smartEngineStorefrontClientEnabled(slug)
        : false;

    let gonderilecek: string | boolean;
    if (alan.tip === "acikKapali") {
      gonderilecek = ["evet", "aç", "açık", "göster", "true"].includes(metin.toLowerCase());
    } else if (metin.length < 15 || !richTextMotorEnabled) {
      gonderilecek = metin;
    } else {
      const temiz = temizlenmisSeciliDeger(metin, alan);
      if (temiz === null) {
        mesajEkle("kullanici", metin);
        mesajEkle(
          "asistan",
          `Bu cümlede birden fazla bilgi var gibi görünüyor. "${alan.etiket}" için sadece onu yazar mısın?`
        );
        setGiris("");

        const bonusHazir = bonusAlanlariniHazirla(metin, "");
        if (bonusHazir.length > 0) {
          setKaydediliyor(true);
          try {
            await bonusAlanlariCikarVeKaydet(
              metin,
              "",
              slug,
              mesajEkle,
              setAlan,
              () => router.refresh(),
              draftVersion,
              setDraftVersion,
            );
          } finally {
            setKaydediliyor(false);
          }
        }
        return { status: "needs_input" };
      }
      gonderilecek = temiz;
    }

    mesajEkle("kullanici", metin || "(boş bırak)");
    setKaydediliyor(true);

    try {
      if (richTextMotorEnabled) {
        const bonusAlanlar = bonusAlanlariniHazirla(metin, alan.kolon);
        const commandResult = await executeSmartEngineCommand({
          slug,
          initialDraftVersion: draftVersion,
          actions: [
            { anahtar: alan.anahtar, deger: gonderilecek },
            ...bonusAlanlar.map(({ anahtar, deger }) => ({ anahtar, deger })),
          ],
          clientId: taslakClientId(),
        });
        setDraftVersion(commandResult.draftVersion);

        if (commandResult.failed.some((item) => item.code === "SMART_ENGINE_DISABLED")) {
          markSmartEngineStorefrontDisabled(slug);
        }

        const anaKayit = commandResult.succeeded.find((item) => item.anahtar === alan.anahtar);
        if (!anaKayit) {
          const hata = commandResult.failed.find((item) => item.anahtar === alan.anahtar);
          const basariliDigerler = commandResult.succeeded
            .map((item) => FIELD_BY_KEY.get(item.anahtar)?.etiket ?? item.anahtar);
          const satirlar = [
            hata?.message ?? "Bu değişikliği güvenle kaydedemedim.",
            basariliDigerler.length > 0
              ? `Kaydedildi: ${basariliDigerler.join(", ")}.`
              : null,
          ].filter((item): item is string => Boolean(item));
          mesajEkle("asistan", satirlar.join("\n"), undefined, "⚠️");
          if (commandResult.stopped.length > 0 || commandResult.succeeded.length > 0) {
            router.refresh();
          }
          return ownerLifecycleFromCommand(commandResult);
        }

        let tazeTaslak = { ...yerelTaslak };
        const kaydedilenEtiketler: string[] = [];
        for (const item of commandResult.succeeded) {
          const kayitAlani = FIELD_BY_KEY.get(item.anahtar);
          if (!kayitAlani) continue;
          setAlan(kayitAlani.kolon, item.deger);
          tazeTaslak = { ...tazeTaslak, [kayitAlani.kolon]: item.deger };
          kaydedilenEtiketler.push(kayitAlani.etiket);
          alaniParlat(item.anahtar);
        }

        const sorunlar = commandResult.failed
          .filter((item) => item.anahtar !== alan.anahtar)
          .map((item) => FIELD_BY_KEY.get(item.anahtar)?.etiket ?? item.anahtar);
        const durdurulan = commandResult.stopped.map(
          (item) => FIELD_BY_KEY.get(item.anahtar)?.etiket ?? item.anahtar,
        );

        const satirlar = [`${alan.etiket} güncellendi. Müşteriler yayınlayana kadar göremez.`];
        const bonusBasarili = kaydedilenEtiketler.filter((etiket) => etiket !== alan.etiket);
        if (bonusBasarili.length > 0) {
          satirlar.push(`Ayrıca kaydettim: ${bonusBasarili.join(", ")}.`);
        }
        if (sorunlar.length > 0) {
          satirlar.push(`Kaydedemedim: ${sorunlar.join(", ")}.`);
        }
        if (durdurulan.length > 0) {
          satirlar.push(`Güvenlik için göndermedim: ${durdurulan.join(", ")}.`);
        }

        mesajEkle(
          "asistan",
          satirlar.join("\n"),
          [
            { label: "Doğru", payload: "onay_tamam" },
            { label: "Geri al", payload: `geri_al:command:${commandResult.commandId}` },
          ],
          commandResult.status === "succeeded" ? "✅" : "⚠️",
        );
        setGiris("");
        router.refresh();
        alanaGecVeyaBitir(alan.anahtar, tazeTaslak);
        return ownerLifecycleFromCommand(commandResult);
      }

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
        return {
          status: "failed",
          code: typeof govde?.kod === "string" ? govde.kod : `HTTP_${yanit.status}`,
        };
      }

      mesajEkle(
        "asistan",
        `${alan.etiket} güncellendi. Müşteriler yayınlayana kadar göremez.`
      );
      setGiris("");
      setAlan(alan.kolon, gonderilecek);
      const tazeTaslak = { ...yerelTaslak, [alan.kolon]: gonderilecek };
      router.refresh();
      alaniParlat(alan.anahtar);
      alanaGecVeyaBitir(alan.anahtar, tazeTaslak);
      return { status: "succeeded" };
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Değişikliğin sonucunu doğrulayamadım.");
      return { status: "failed", code: "NETWORK_ERROR" };
    } finally {
      setKaydediliyor(false);
    }
  }, [giris, seciliAlan, slug, mesajEkle, setAlan, setGiris, alanaGecVeyaBitir, router, yerelTaslak, alanSec, draftVersion, setDraftVersion]);

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
