"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { resolveVitrinProfile } from "@/lib/vitrinProfile";
import { taslakClientId } from "@/lib/canliVitrinSenkron";
import type { VitrinField } from "@/lib/vitrinFieldSchema";
import type { Mesaj } from "./useOwnerChat";

/** Hangi alan hangi tür hazır görsele karşılık geliyor. */
const GORSEL_TURU: Record<string, "cover" | "logo_placeholder" | "gallery" | "product"> = {
  kapakGorseli: "cover",
  logo: "logo_placeholder",
  hakkindaGorsel: "gallery",
  bantGorsel: "product",
};

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
  mesajEkle: (kimden: Mesaj["kimden"], metin: string) => void;
  setAlan: (kolon: string, deger: unknown) => void;
  setGiris: (v: string) => void;
  /** Kayıt (veya boş geçme) başarılı olunca çağrılır: sırada başka alan
   * varsa oraya geçer. */
  alanaGecVeyaBitir: (kaydedilenAnahtar: string) => void;
  /** "Boş geç" kalıcı işaretlendiğinde yerel state'e yansıtır
   * (`useOwnerDraft.alanAtlandi`). */
  alanAtlandi: (anahtar: string) => void;
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
        alanaGecVeyaBitir(alan.anahtar);
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
      } finally {
        setKaydediliyor(false);
      }
    },
    [seciliAlan, slug, mesajEkle, setAlan, alanaGecVeyaBitir]
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
        alanaGecVeyaBitir(alan.anahtar);
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
      } finally {
        setKaydediliyor(false);
      }
    },
    [seciliAlan, slug, mesajEkle, setAlan, alanaGecVeyaBitir, _setHazirGorseller]
  );

  const gonder = useCallback(async () => {
    const metin = giris.trim();

    if (!seciliAlan) {
      // Anlamadığımızı dürüstçe söyleriz.
      if (metin) mesajEkle("kullanici", metin);
      mesajEkle(
        "asistan",
        "Hangi alanı değiştireceğini bilmiyorum. Vitrinde düzenlemek istediğin yazıya tıkla, sonra yeni değeri yaz."
      );
      setGiris("");
      return;
    }

    const alan = seciliAlan;
    const gonderilecek: string | boolean =
      alan.tip === "acikKapali"
        ? ["evet", "aç", "açık", "göster", "true"].includes(metin.toLowerCase())
        : metin;

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
      alanaGecVeyaBitir(alan.anahtar);
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setKaydediliyor(false);
    }
  }, [giris, seciliAlan, slug, mesajEkle, setAlan, setGiris, alanaGecVeyaBitir]);

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
