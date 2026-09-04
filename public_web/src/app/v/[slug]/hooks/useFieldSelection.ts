"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  FIELD_BY_KEY,
  SECTION_DOM_ID,
  SECTION_LABELS,
  type VitrinField,
  type VitrinSection,
} from "@/lib/vitrinFieldSchema";
import { bolumdeKalanSayisi, sonrakiRehberAlan } from "@/lib/vitrinReadiness";
import { digerAlanaAitIpucuVarMi } from "@/lib/vixrexValueExtractor";
import {
  bekle,
  ogeIcinHedefY,
  rahatGorunuyorMu,
  yumusakKaydir,
} from "@/lib/sayfaKaydirma";
import type { Mesaj } from "./useOwnerChat";

const VURGU_SINIFI = "vixrex-secili-alan";

export interface FieldSelectionHook {
  seciliAlan: VitrinField | null;
  giris: string;
  girisRef: React.RefObject<HTMLTextAreaElement | null>;
  setGiris: (v: string) => void;
  setSeciliAlan: (alan: VitrinField | null) => void;
  alanSec: (anahtar: string, oge?: Element | null) => void;
  vurguyuTemizle: () => void;
  /** Rehber şu an bir hedefe yürüyor mu — balon yolda kapalı durur. */
  gecisSuruyor: boolean;
  /** Bir alan kaydedildikten SONRA çağrılır: sırada başka alan varsa oraya
   * geçer, yoksa akışı bitirir. `useOwnerActions`'ın kaydetme yolları da
   * eski `setSeciliAlan(null)` yerine bunu çağırır. */
  alanaGecVeyaBitir: (
    kaydedilenAnahtar: string,
    guncelTaslak?: Record<string, unknown>,
  ) => void;
}

interface Deps {
  yerelTaslak: Record<string, unknown>;
  /** "Boş geç" denen isteğe bağlı alanlar — sunucudan kalıcı gelir
   * (`useOwnerDraft`), burada yalnız sıradaki alanı bulmak için okunur. */
  atlanmisAlanlar: ReadonlySet<string>;
  mesajEkle: (kimden: Mesaj["kimden"], metin: string) => void;
  /**
   * Vitrinde bir alana tıklanınca çağrılır. Panel kapalıyken vitrinden
   * seçim yapmak paneli de açmalı — aksi halde esnaf tıklar, hiçbir şey
   * açılmamış gibi görünür (regresyon, code-review 2026-08-10: refactor
   * sırasında orijinal `setAcik(true)` çağrısı kaybolmuştu).
   */
  onAlanSecildi?: () => void;
}

/**
 * Rehber bir alanı otomatik seçmiş olsa bile esnaf başka bir alanı açıkça
 * tarif etmeye başlarsa seçili alan artık mesajı kilitlememeli. Bu durumda
 * seçim temizlenir; gönderim `useOwnerActions` içindeki 46 alanlık NLU
 * yoluna düşer. Kısa/genel kelimeler `digerAlanaAitIpucuVarMi` tarafından
 * zaten filtrelenir, yani düz bir alan cevabı serbest mesaja dönüşmez.
 */
export function seciliAlaniBirakmaliMi(
  metin: string,
  seciliAlan: VitrinField | null,
): boolean {
  if (!seciliAlan || !metin.trim()) return false;
  return digerAlanaAitIpucuVarMi(metin, seciliAlan.anahtar);
}

export function useFieldSelection({
  yerelTaslak,
  atlanmisAlanlar,
  mesajEkle,
  onAlanSecildi,
}: Deps): FieldSelectionHook {
  const [seciliAlan, setSeciliAlan] = useState<VitrinField | null>(null);
  const [giris, setGirisState] = useState("");
  const girisRef = useRef<HTMLTextAreaElement>(null);
  const vurguluRef = useRef<Element | null>(null);
  // Her geçişe artan numara: yolda yeni bir alan seçilirse eskisi susar.
  const gecisRef = useRef(0);
  const oncekiBolumRef = useRef<VitrinSection | null>(null);
  const [gecisSuruyor, setGecisSuruyor] = useState(false);

  const vurguyuTemizle = useCallback(() => {
    vurguluRef.current?.classList.remove(VURGU_SINIFI);
    vurguluRef.current = null;
  }, []);

  /**
   * Kullanıcı serbestçe başka bir alanı tarif etmeye başladığında otomatik
   * rehber seçimini bırak. Böylece `gonder()` anında `seciliAlan === null`
   * olur ve mesaj gerçek akıllı motora gider. Seçili alanın kendi düz cevabı
   * ise aynen mevcut alan düzenleme yolunda kalır.
   */
  const setGiris = useCallback(
    (v: string) => {
      setGirisState(v);
      if (!seciliAlaniBirakmaliMi(v, seciliAlan)) return;
      vurguyuTemizle();
      setSeciliAlan(null);
    },
    [seciliAlan, vurguyuTemizle],
  );

  /**
   * Rehberin hedefe YÜRÜMESİ (Faz 3b).
   *
   * Eskiden tarayıcının kendi yumuşak kaydırması kullanılıyordu. Uzak
   * hedefte tarayıcı aynı kısa sürede gidiyor, ekran "çakılıyor" gibi
   * hissettiriyordu (Casper, canlı test). Artık:
   *   - hedef zaten rahat görünüyorsa sayfa HİÇ oynamaz,
   *   - bölüm değişiyorsa önce bölümün başına inilir, kısa durulur,
   *     sonra alana yaklaşılır — esnaf nereye gittiğini görür,
   *   - mesafeye göre süre seçilir (bkz. sayfaKaydirma.ts).
   *
   * Yazma alanı ancak VARINCA odaklanır: mobilde klavye yol ortasında
   * açılırsa kaydırma hesabı bozuluyor.
   */
  const hedefeGit = useCallback(async (hedef: Element, bolum: VitrinSection) => {
    const numara = ++gecisRef.current;
    const gecerli = () => numara === gecisRef.current;

    const bitir = () => {
      if (!gecerli()) return;
      setGecisSuruyor(false);
      oncekiBolumRef.current = bolum;
      window.setTimeout(() => {
        if (gecerli()) girisRef.current?.focus();
      }, 40);
    };

    if (rahatGorunuyorMu(hedef, 88, window.innerHeight * 0.62)) {
      bitir();
      return;
    }

    setGecisSuruyor(true);

    const oncekiBolum = oncekiBolumRef.current;
    if (oncekiBolum && oncekiBolum !== bolum) {
      const bolumOgesi = document.getElementById(SECTION_DOM_ID[bolum]);
      if (bolumOgesi) {
        await yumusakKaydir(ogeIcinHedefY(bolumOgesi, 90));
        if (!gecerli()) return;
        await bekle(300);
        if (!gecerli()) return;
      }
    }

    await yumusakKaydir(
      ogeIcinHedefY(hedef, Math.round(window.innerHeight * 0.28))
    );
    bitir();
  }, []);

  const alanSec = useCallback(
    (anahtar: string, oge?: Element | null) => {
      const alan = FIELD_BY_KEY.get(anahtar);
      if (!alan) return;

      vurguyuTemizle();
      const hedef =
        oge ?? document.querySelector(`[data-vixrex-editable="${anahtar}"]`);
      if (hedef) {
        hedef.classList.add(VURGU_SINIFI);
        vurguluRef.current = hedef;
        void hedefeGit(hedef, alan.bolum);
      }

      onAlanSecildi?.();
      setSeciliAlan(alan);
      const mevcut = yerelTaslak[alan.kolon];
      // Mevcut alan değeri programa bağlı olarak yüklenirken akıllı `setGiris`
      // kullanılmaz; aksi halde içeriğinde başka bir alan kelimesi geçen eski
      // metin seçimi yanlışlıkla bırakabilirdi.
      setGirisState(
        alan.tip === "acikKapali"
          ? ""
          : mevcut === null || mevcut === undefined
          ? ""
          : String(mevcut)
      );
      mesajEkle(
        "asistan",
        `"${alan.etiket}" alanını seçtin. Yeni değeri yaz ve gönder.${
          alan.ipucu ? ` (${alan.ipucu})` : ""
        }`
      );
    },
    [yerelTaslak, mesajEkle, vurguyuTemizle, onAlanSecildi, hedefeGit]
  );

  const alanaGecVeyaBitir = useCallback(
    (kaydedilenAnahtar: string, guncelTaslak?: Record<string, unknown>) => {
      // `yerelTaslak` bu tepki turunda henüz tazelenmemiş olabilir —
      // `setAlan` ile `alanaGecVeyaBitir` aynı anda çağrılıyor. Kaydeden
      // taraf yeni hâli verirse onu kullanırız; yoksa (ör. "boş geç")
      // eldeki taslak zaten doğrudur.
      const taslak = guncelTaslak ?? yerelTaslak;

      const sonraki = sonrakiRehberAlan(
        taslak,
        kaydedilenAnahtar,
        atlanmisAlanlar
      );

      if (sonraki) {
        // Bölüm değişiyorsa esnaf nereye gittiğini bilsin — sayfa sırası
        // düzeldi ama geçişin kendisi de anlatılmalı (Casper, 2026-08-22:
        // "yumuşak bir şekilde gezerek, sert inmesin").
        const kaydedilen = FIELD_BY_KEY.get(kaydedilenAnahtar);
        if (kaydedilen && kaydedilen.bolum !== sonraki.bolum) {
          const oncekiKalan = bolumdeKalanSayisi(
            taslak,
            kaydedilen.bolum,
            atlanmisAlanlar
          );
          const sonrakiKalan = bolumdeKalanSayisi(
            taslak,
            sonraki.bolum,
            atlanmisAlanlar
          );
          const bas =
            oncekiKalan === 0
              ? `${SECTION_LABELS[kaydedilen.bolum]} tamam ✓ — şimdi`
              : "Şimdi";
          const kuyruk = sonrakiKalan > 1 ? ` (${sonrakiKalan} alan)` : "";
          mesajEkle(
            "asistan",
            `${bas} ${SECTION_LABELS[sonraki.bolum]} bölümüne bakıyoruz${kuyruk}.`
          );
        }
        alanSec(sonraki.anahtar);
        return;
      }

      vurguyuTemizle();
      setSeciliAlan(null);
      mesajEkle("asistan", "Harika, şu an eklenecek başka bir şey yok! 🎉");
    },
    [yerelTaslak, atlanmisAlanlar, alanSec, vurguyuTemizle, mesajEkle]
  );

  // Vitrindeki işaretli öğeler için tek dinleyici.
  useEffect(() => {
    const tiklama = (e: MouseEvent) => {
      const hedef = (e.target as HTMLElement | null)?.closest(
        "[data-vixrex-editable]"
      );
      if (!hedef) return;
      const anahtar = hedef.getAttribute("data-vixrex-editable");
      if (!anahtar) return;
      e.preventDefault();
      alanSec(anahtar, hedef);
    };
    document.addEventListener("click", tiklama);
    return () => document.removeEventListener("click", tiklama);
  }, [alanSec]);

  useEffect(() => vurguyuTemizle, [vurguyuTemizle]);

  return {
    seciliAlan,
    giris,
    girisRef,
    setGiris,
    setSeciliAlan,
    alanSec,
    vurguyuTemizle,
    alanaGecVeyaBitir,
    gecisSuruyor,
  };
}
