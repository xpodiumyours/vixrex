"use client";

import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from "react";
import { useOwnerDraft } from "./hooks/useOwnerDraft";
import { useOwnerChat } from "./hooks/useOwnerChat";
import { useFieldSelection } from "./hooks/useFieldSelection";
import { useOwnerActions, bonusAlanlariCikarVeKaydet } from "./hooks/useOwnerActions";
import { useFieldRestore } from "./hooks/useFieldRestore";
import { ChatBubble } from "./components/ChatBubble";
import { ChatTopBar } from "./components/ChatTopBar";
import { HesapBaglaSeridi } from "./components/HesapBaglaSeridi";
import { UpNextList } from "./components/UpNextList";
import { SectionProgressList } from "./components/SectionProgressList";
import { SectionVisibilityToggle } from "./components/SectionVisibilityToggle";
import { BookingSettingsPanel } from "./components/BookingSettingsPanel";
import { AboutEditor } from "./components/AboutEditor";
import { FaqEditor } from "./components/FaqEditor";
import { CampaignEditor } from "./components/CampaignEditor";
import { MarketplaceEditor } from "./components/MarketplaceEditor";
import { GalleryEditor } from "./components/GalleryEditor";
import { PublishBar } from "./components/PublishBar";
import { VixrexAvatar } from "./components/VixrexAvatar";
import { SpotlightGuide } from "./components/SpotlightGuide";
import { FieldInputArea } from "./components/FieldInputArea";
import { alanOnemi, sonrakiRehberAlan } from "@/lib/vitrinReadiness";
import type { AssistantHandoffV1 } from "@/lib/assistantHandoff";
import { taslakClientId } from "@/lib/canliVitrinSenkron";
import { useRouter } from "next/navigation";
import { gpsAdresiniCoz } from "@/lib/konumCozumleme";
import { VITRIN_FIELDS } from "@/lib/vitrinFieldSchema";
import { otomatikDeger } from "@/lib/otomatikVitrinIcerik";
import { yonetimOnerileriUret } from "@/lib/yonetimOnerileri";
import { supabase } from "@/lib/supabase";
import { ensureAnonymousSession } from "@/lib/assistantConversation";
import OwnerEditorBar from "./components/OwnerEditorBar";

// Vixrex Asistan — sahip paneli (implementation_plan.md Commit 9;
// yeniden dizilim Faz G3 (Tek Asistan planı), G3.1).
//
// TEK PANEL, İKİ YOL:
//   1. Vitrindeki alana tıkla → asistan o alanı seçer, kutuya yazarsın
//   2. Rehberden seç (Sırada / bölümler) → aynı yere gelir
//
// Alan başına bileşen veya dallanma YOKTUR: hangi kutunun çizileceğine
// şemadaki `tip` karar verir. Yeni alan eklemek bu dosyayı değiştirmez.
//
// DÜRÜSTLÜK KURALI: asistan anlamadığı bir şeyi "işledim" diye geçiştirmez.
// Yayınla düğmesi de yalan söylemez — temel alan eksikken pasif ve nedenini
// yazar (bkz. PublishBar).

// ============================================================================
// SAHİPLİK EKRANI — GÜNCEL GÖRSEL SÖZLEŞME (2026-09-21)
// ============================================================================
// TELEFON (<640px): PR #545 ile onaylandı. Altta sürekli compact mesaj kutusu,
// küçük gönder düğmesi ve SAĞDA canonical Vixrex maskotu bulunur; yukarı
// çekilince sohbet geçmişi açılır. Masaüstü çalışmaları bu yüzeyi değiştirmez.
//
// TABLET (640–1023px): mevcut yüzen panel davranışı korunur.
//
// MASAÜSTÜ (>=1024px): üstte OwnerEditorBar + solda gerçek vitrin + sağda
// yerleşik Vixrex Asistan sütunu. Sütun genişliği tek kaynaktan
// --owner-rail-w ile gelir. İçerik üç çalışma alanına ayrılır:
//   - Sohbet: yalnız konuşma + sade compact composer.
//   - Alanlar: 46 alan, seçili alan ve özel düzenleme araçları.
//   - Eksikler: zorunlu eksikler, kalite önerileri, hesap/yasal hazırlık.
// Yayın ana eylemi OwnerEditorBar'da TEK yerde kalır. PublishBar'ın güvenlik
// mantığı (yasal onay, premium, taslağı bırakma) kaybolmaz; Eksikler içinde
// gerektiğinde yalnız hazırlık kontrolleri gösterilir.
//
// Veri/iş mantığı değişmez: useOwnerChat, useOwnerActions, NLU, 46 alan şeması,
// store_working_drafts ve Supabase aynı kaynak olmaya devam eder.
// ============================================================================

interface Props {
  slug: string;
  /** Vitrin bir hesaba bağlı değil — cihaz belleğinde duruyor. Uyarı şeridi
   * eskiden "Sahip Çalışma Alanı" çekmecesindeydi; çekmece kalkınca buraya
   * taşındı (Çalışma masası / Yön C). */
  hesapBagliDegil?: boolean;
  /** Sahip önizleme oturumundan kalan saniye; yalnız son 5 dakikada gösterilir. */
  oturumSaniye?: number | null;
  /** Taslak sürümü canlıdan ileride mi — "yayınlanmamış değişiklik var". */
  yayinlanmamisDegisiklik?: boolean;
  draftData: Record<string, unknown>;
  assistantHandoff?: AssistantHandoffV1 | null;
  /** "Boş geç" denen isteğe bağlı alanlar — sunucudan kalıcı gelir (ADR 0002,
   * 3. alt-faz). */
  atlananAlanlar?: readonly string[] | null;
  /** Kiralık şablon vitrinin premium süresi aktif mi — sunucuda hesaplanır
   * (page.tsx getWorkingDraft). Yalnız PublishBar düğmesinin dürüst
   * etiketidir; güvenlik katmanı RPC'dedir (PREMIUM_REQUIRED). */
  premiumAktifMi?: boolean;
  bookingSettings?: Record<string, unknown> | null;
  aboutSection?: { kicker: string; title: string; body: string; imageUrl: string; imageCaption: string; values: Array<{ id: string; title: string; description: string }> } | null;
  faqItems?: Array<{ id: string; question: string; answer: string }> | null;
  campaignBanner?: { label: string; title: string; description: string; priceText: string; imageUrl: string } | null;
  marketplaceLinks?: Array<{ id: string; platform: string; url: string; subtitle?: string }> | null;
  galleryItems?: Array<{ id?: string; imageUrl: string; title?: string }> | null;
  /** Faz D3 (Tek Asistan planı): get_working_draft_for_session'ın `created`
   * alanı — bu taslak İLK KEZ şu çağrıda oluşturulduysa true. Kiralanan bir
   * şablonda kategori zaten dolu gelir; bu ikisi birlikteyken otomatik
   * doldurma tek seferlik tetiklenir (bkz. aşağıdaki useEffect). Sıfırdan
   * kurulumda da true gelir ama kategori henüz seçilmediği için hiçbir şey
   * yapmaz — otomatikDeger() kategori olmadan null döner. */
  draftYeniOlusturuldu?: boolean;
  /** Faz E: yönetim modu önerileri için — sayfa server'da zaten hesaplıyor. */
  urunFiyatsizSayisi?: number;
  urunAciklamasizSayisi?: number;
}

export default function OwnerAssistantPanel({
  slug,
  draftData,
  assistantHandoff = null,
  atlananAlanlar = null,
  premiumAktifMi = false,
  bookingSettings = null,
  aboutSection = null,
  faqItems = null,
  campaignBanner = null,
  marketplaceLinks = null,
  galleryItems = null,
  draftYeniOlusturuldu = false,
  urunFiyatsizSayisi = 0,
  urunAciklamasizSayisi = 0,
  flowState = null,
  hesapBagliDegil = false,
  oturumSaniye = null,
  yayinlanmamisDegisiklik = false,
}: Props & { flowState?: Record<string, unknown> | null }) {
  const [acik, setAcik] = useState(() => Boolean(flowState && typeof flowState === "object" && (flowState as { current_step?: string }).current_step));
  // Harita = "Tüm alanlar" paneli. Faz 4 (Casper, 2026-08-22): mobilde
  // panel bütün sayfayı kapatıyordu — "sadece Vixrex maskotu olsun,
  // kutucuklarda zaten ne yapılacağı yazıyor". Artık alan seçilince
  // mobilde harita kapanır; sayfada yalnız sembol ve balon kalır.
  // Masaüstünde yer bol, harita açık durmaya devam eder.
  const [sekme, setSekme] = useState<"sohbet" | "alanlar" | "eksikler">("sohbet");
  const [haritaAcik, setHaritaAcik] = useState(false);
  // Mobil hedef (2026-09-21): mesaj kutusu her zaman altta görünür;
  // yalnız sohbet geçmişi yukarı çekildiğinde büyüyen çekmece açılır.
  // Masaüstü panel state'i bundan tamamen ayrıdır.
  const [mobilGecmisAcik, setMobilGecmisAcik] = useState(false);
  const mobilTutamakRef = useRef<{ baslangicY: number } | null>(null);
  const [masaustu, setMasaustu] = useState(false);

  useEffect(() => {
    const sorgu = window.matchMedia("(min-width: 640px)");
    const guncelle = () => setMasaustu(sorgu.matches);
    guncelle();
    sorgu.addEventListener("change", guncelle);
    return () => sorgu.removeEventListener("change", guncelle);
  }, []);

  // Adım 4 (2026-09-03): pending slot ve sohbet geçmişi artık kalıcı
  // `assistant_conversations` tablosuna (auth.uid() ile) yazılıyor —
  // localStorage değil. Panel açılır açılmaz (hesap bağlı olsun olmasın)
  // anonim bir Supabase Auth oturumu garanti eder; zaten oturum varsa
  // (landing'den taşınmış veya gerçek hesap) hiçbir şey değişmez. Hata
  // sessizce yutulur — akışı bloklamaz, yalnız kalıcılık o oturumda
  // devreye girmez (bkz. vixrexNluPipeline.ts, useOwnerChat.ts).
  useEffect(() => {
    void ensureAnonymousSession();
  }, []);

  // 2026-09-03 (Casper'ın onayladığı "C" tasarımına sadakat): tuvalde
  // asistan masaüstünde HEP AÇIK, kapanmayan bir panel olarak tasarlanmıştı
  // — esnaf ekranı açar açmaz oradaydı. Yalnız BİR KEZ, masaüstü ilk fark
  // edildiğinde otomatik açar; esnaf sonradan elle kapatırsa (ör. vitrini
  // engelsiz görmek için) bir daha kendiliğinden açılıp üstüne binmez.
  // Mobilde dokunulmadı — Faz 4'ün "sadece maskot" kararı geçerli kalır.
  const masaustuIlkAcilisRef = useRef(false);
  useEffect(() => {
    if (masaustu && !masaustuIlkAcilisRef.current) {
      masaustuIlkAcilisRef.current = true;
      setAcik(true);
    }
  }, [masaustu]);

  // PR4-C14: aktif kurulum/kiralama akışı varsa asistan açık ve sıradaki alan odaklı başlar.
  // Faz A (Tek Asistan planı, 2026-09-02): harita artık burada otomatik açılmıyor —
  // SpotlightGuide varsayılan yol, harita yalnız "Tüm alanlar" (☰) ile elle açılır.
  //
  // Effect değil, render-zamanında ayarlama (react-hooks/set-state-in-effect,
  // 2026-09-02): flowState prop'u değiştiğinde acik'i güncellemek için
  // https://react.dev/learn/you-might-not-need-an-effect#adjusting-some-state-when-a-prop-changes
  // deseni — bir önceki flowState ile karşılaştırıp farklıysa aynı render
  // içinde setState çağır, ekstra bir paint/effect turu gerekmiyor.
  const [prevFlowState, setPrevFlowState] = useState(flowState);
  if (flowState !== prevFlowState) {
    setPrevFlowState(flowState);
    if (flowState && typeof flowState === "object" && (flowState as { current_step?: string }).current_step) {
      setAcik(true);
    }
  }

  // Panel açık/kapalı durumunu body sınıfında tut. Bu sınıf artık vitrindeki
  // bütün düzenlenebilir alanları topluca ışıklandırmaz; masaüstü/tablet
  // kabuğundaki panel davranışları için korunur. Tuval vurgusu yalnız hover
  // ve seçili tek alan üzerinden globals.css'te yönetilir.
  useEffect(() => {
    document.body.classList.toggle("vixrex-asistan-acik", acik);
    return () => document.body.classList.remove("vixrex-asistan-acik");
  }, [acik]);

  const mobilGecmisiAc = () => {
    setHaritaAcik(false);
    setSekme("sohbet");
    setMobilGecmisAcik(true);
  };

  const mobilTutamakBasla = (olay: ReactPointerEvent<HTMLDivElement>) => {
    if (window.matchMedia("(min-width: 640px)").matches) return;
    mobilTutamakRef.current = { baslangicY: olay.clientY };
    olay.currentTarget.setPointerCapture?.(olay.pointerId);
  };

  const mobilTutamakBitir = (olay: ReactPointerEvent<HTMLDivElement>) => {
    const baslangic = mobilTutamakRef.current;
    mobilTutamakRef.current = null;
    if (!baslangic) return;
    const fark = baslangic.baslangicY - olay.clientY;
    if (fark > 28) {
      mobilGecmisiAc();
    } else if (fark < -28) {
      setMobilGecmisAcik(false);
    }
    if (olay.currentTarget.hasPointerCapture?.(olay.pointerId)) {
      olay.currentTarget.releasePointerCapture?.(olay.pointerId);
    }
  };

  const { yerelTaslak, setAlan, rapor, atlanmisAlanlar, alanAtlandi } = useOwnerDraft(
    slug,
    draftData,
    atlananAlanlar ?? []
  );
  const { mesajlar, mesajEkle, akisRef } = useOwnerChat(rapor, assistantHandoff, { slug });

  const {
    seciliAlan,
    giris,
    girisRef,
    setGiris,
    setSeciliAlan,
    alanSec,
    alanaGecVeyaBitir,
    vurguyuTemizle,
    gecisSuruyor,
  } = useFieldSelection({
      yerelTaslak,
      atlanmisAlanlar,
      mesajEkle,
      onAlanSecildi: () => {
        setAcik(true);
        if (window.matchMedia("(min-width: 640px)").matches) {
          // Masaüstü/tablet: vitrindeki bir alana tıklamak doğrudan o alanın
          // araçlarını gösterir. Sohbetin içine kart yığmak yerine "Alanlar"
          // sekmesi tek düzenleme yüzeyi olur.
          setSekme("alanlar");
          setHaritaAcik(true);
        } else {
          // Telefon: onaylanan compact composer davranışı korunur.
          setHaritaAcik(false);
          setMobilGecmisAcik(false);
        }
      },
    });

  // 2026-08-22: "sayfada dolaşan rehber" — panel ilk açıldığında henüz
  // hiçbir alan seçili değilse, sırayı elle aramaya gerek kalmadan ilk
  // eksik alanı (önce zorunlu, sonra kalite — sonrakiRehberAlan zaten bu
  // sırayı uyguluyor) otomatik seçer. Kullanıcı istediği alana da hâlâ
  // doğrudan tıklayabilir (useFieldSelection'daki global dinleyici).
  useEffect(() => {
    if (!acik || seciliAlan) return;
    const ilkEksik = sonrakiRehberAlan(yerelTaslak, null, atlanmisAlanlar);
    if (ilkEksik) alanSec(ilkEksik.anahtar);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [acik]);

  // Faz C2/D3 polish: hızlı cevap düğmelerinin ilk gerçek kullanımı —
  // otomatik doldurma mesajındaki "Başlayalım" düğmesi, panel ilk
  // açıldığındaki otomatik-seçimle (yukarıdaki `acik`/`seciliAlan` efekti)
  // aynı mantığı kullanıcı isteğiyle tekrar tetikler.
  const handleHizliCevap = (payload: string) => {
    if (payload === "ilk_eksik_alana_git") {
      const ilkEksik = sonrakiRehberAlan(yerelTaslak, null, atlanmisAlanlar);
      if (ilkEksik) alanSec(ilkEksik.anahtar);
      return;
    }
    // Faz 5 (Çalışma masası / Yön C): onay kartındaki "Geri al" —
    // motorun tek cümleden doldurduğu tüm alanları birden canlı hâline
    // döndürür (bkz. useOwnerActions.gonder, useFieldRestore.coklaCanliyaDondur).
    // "Doğru" için ayrı bir dal YOK — kayıt zaten olmuş, düğme yalnız
    // onayı görünür kılar.
    if (payload.startsWith("geri_al:")) {
      const anahtarlar = payload
        .slice("geri_al:".length)
        .split(",")
        .filter(Boolean);
      if (anahtarlar.length > 0) void fieldRestore.coklaCanliyaDondur(anahtarlar);
    }
  };

  const actions = useOwnerActions({
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
  });

  const fieldRestore = useFieldRestore({
    slug,
    seciliAlan,
    mesajEkle,
    setAlan,
    setGiris,
  });

  // Faz 2: kayıt sürerken seçili alan sayfada hafifçe nefes alsın —
  // esnaf "gitti mi, gitmedi mi" diye beklemesin. Gerçek stil
  // globals.css'te (`body.vixrex-kaydediliyor .vixrex-secili-alan`).
  useEffect(() => {
    document.body.classList.toggle("vixrex-kaydediliyor", actions.kaydediliyor);
    return () => document.body.classList.remove("vixrex-kaydediliyor");
  }, [actions.kaydediliyor]);

  const eksikTemelSayisi = rapor.eksikler.filter((e) => e.onem === "temel").length;

  // Kiralık şablon vitrin mi (cloned_from_slug dolu) + premium aktif mi.
  // draftData stores satırının tam kopyasıdır — cloned_from_slug ve
  // premium_expires_at orada durur (owner_forbidden_draft_keys bunların
  // DRAFT'A YAZILMASINI engeller, okunmasını değil). Premium kapısı
  // güvenlik katmanı RPC'de (publish_working_draft → PREMIUM_REQUIRED);
  // buradaki bilgi yalnız düğmenin dürüst etiketidir.
  const kiralikVitrinMi = Boolean(
    (yerelTaslak.cloned_from_slug as string | null | undefined)?.trim()
  );

  // Düzenleme modalleri için state
  const [aboutAcik, setAboutAcik] = useState(false);
  const [faqAcik, setFaqAcik] = useState(false);
  const [kampanyaAcik, setKampanyaAcik] = useState(false);
  const [marketplaceAcik, setMarketplaceAcik] = useState(false);
  const [galeriAcik, setGaleriAcik] = useState(false);
  const [gpsLoading, setGpsLoading] = useState(false);
  const router = useRouter();

  // Faz D3 (Tek Asistan planı, 2026-09-02): kiralanan bir şablon ilk kez
  // açıldığında (draftYeniOlusturuldu) ve kategori zaten doluysa, yapısal/
  // kozmetik alanları (otomatikDoldurulabilir) kategoriye göre otomatik
  // doldurur — GERÇEK işletme kimliğine hiç dokunmaz (o alanlar zaten
  // clone_demo_store_as_draft'ta boş geliyor, bkz. Faz D2 migration).
  // Sıfırdan kurulumda da draftYeniOlusturuldu true gelir ama kategori
  // henüz seçilmediği için otomatikDeger() null döner, hiçbir şey olmaz.
  const otomatikDoldurmaBasladiRef = useRef(false);
  useEffect(() => {
    if (!draftYeniOlusturuldu || otomatikDoldurmaBasladiRef.current) return;
    const kategoriEtiketi =
      typeof yerelTaslak.kategori === "string" ? yerelTaslak.kategori : null;
    if (!kategoriEtiketi) return;
    otomatikDoldurmaBasladiRef.current = true;

    const otomatikAlanlar = VITRIN_FIELDS.filter(
      (alan) => alan.otomatikDoldurulabilir && alan.tip !== "gorsel"
    );

    (async () => {
      const hazirlananEtiketler: string[] = [];
      for (const alan of otomatikAlanlar) {
        // Zaten doluysa üzerine yazma — yalnız boşu doldur.
        const mevcut = yerelTaslak[alan.kolon];
        if (typeof mevcut === "string" && mevcut.trim().length > 0) continue;

        const deger = otomatikDeger(alan, kategoriEtiketi);
        if (!deger) continue;

        try {
          const yanit = await fetch("/api/owner-draft", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              slug,
              anahtar: alan.anahtar,
              deger,
              clientId: taslakClientId(),
            }),
          });
          if (yanit.ok) {
            setAlan(alan.kolon, deger);
            hazirlananEtiketler.push(alan.etiket);
          }
        } catch {
          // Tek alan başarısız olursa akışı durdurmaz, kalanlarla devam eder.
        }
      }

      if (hazirlananEtiketler.length > 0) {
        router.refresh();
      }
    })();
  }, [draftYeniOlusturuldu, yerelTaslak, slug, setAlan, mesajEkle, router]);

  // Landing'de anlatılanın panele taşınması (2026-09-02) — "kullanıcı
  // landing'de yazdığı bilgilerle vitrin doldurulmaya başlasın" isteği.
  // Faz G1'in tek konuşma köprüsü landing'in niyet akışını zaten
  // assistant_conversations'a yazıyordu; eksik olan tek parça, o
  // konuşmanın panelde OKUNMASIYDI. Burada: taze bir taslakta (kiralık ya
  // da sıfırdan, aynı draftYeniOlusturuldu sinyali) landing'de
  // NIYET_SERBEST_METIN_ANAHTARI ile işaretlenmiş bir mesaj varsa, aynı
  // motoru (bonusAlanlariCikarVeKaydet — panelin kendi soru kutusunun da
  // kullandığı fonksiyon) o metin üzerinde çalıştırır. İkinci argüman
  // ("") hariç tutulacak bir kolon olmadığını belirtir — burada "az önce
  // cevaplanan alan" diye bir şey yok, hepsi adaydır.
  const landingNiyetIslendiRef = useRef(false);
  useEffect(() => {
    if (!draftYeniOlusturuldu || landingNiyetIslendiRef.current) return;
    landingNiyetIslendiRef.current = true;
    (async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) return;
        const { data, error } = await supabase.rpc("get_assistant_conversation");
        if (error || !data) return;
        const conv = data as {
          messages?: Array<{ role: string; message_text: string; message_key?: string | null }>;
        };
        const niyetMesaji = (conv.messages ?? []).find(
          (m) => m.message_key === "niyet_serbest_metin" && m.role === "user"
        );
        if (!niyetMesaji?.message_text) return;
        await bonusAlanlariCikarVeKaydet(
          niyetMesaji.message_text,
          "",
          slug,
          mesajEkle,
          setAlan,
          () => router.refresh()
        );
      } catch {
        // Köprü opsiyonel bir zenginleştirme — bulunamazsa/başarısız
        // olursa normal tek-tek soru akışı hiç etkilenmeden devam eder.
      }
    })();
  }, [draftYeniOlusturuldu, slug, mesajEkle, setAlan, router]);

  // Faz E (Tek Asistan planı, 2026-09-02): yönetim modu — vitrin yayında
  // ise kurulum rehberi yerine "bugün ilgilenmen gereken şey" önerisi.
  // Panel her açılışta bir kez söyler (gün takibi yok — kapsam bilerek
  // küçük tutuldu, gerçek ihtiyaç görülürse eklenir).
  // Yasal onay üçü birden — aynı desen, aynı yorum: draftData stores
  // satırının tam kopyası, owner_forbidden_draft_keys yalnız YAZMAYI
  // engeller (bkz. accept_store_legal_consent RPC'si, /api/owner-accept-legal).
  const yasalOnayli = Boolean(
    yerelTaslak.privacy_notice_acknowledged &&
      yerelTaslak.terms_accepted &&
      yerelTaslak.publication_consent_accepted
  );

  // Kalite alanında "Sonra": sırayı ilerletir, atlanmislar'a YAZMAZ (ADR
  // 0002 — "boş geç" yalnız isteğe bağlıda). Yalnız seçili alan gerçekten
  // kalite ise anlamlı; StepCard/FieldInputArea zaten yalnız o durumda çizer.
  const sonrayaBirak =
    seciliAlan && alanOnemi(seciliAlan) === "kalite"
      ? () => {
          mesajEkle("kullanici", "(sonra)");
          alanaGecVeyaBitir(seciliAlan.anahtar);
        }
      : undefined;

  // Rehber balonundaki ✕: yalnız o alanın vurgusunu/balonunu kapatır,
  // panelin kendisine ya da "sonraki alana geç" akışına dokunmaz — esnaf
  // rehberi susturup istediği zaman elle devam edebilsin.
  const rehberiKapat = () => {
    vurguyuTemizle();
    setSeciliAlan(null);
  };

  // İl/ilçe dropdown state — mevcut taslak değerlerinden yüklenir
  const mevcutIl = String(yerelTaslak.province_name ?? "");
  const mevcutIlce = String(yerelTaslak.district_name ?? "");

  const handleIlDegisti = (il: string) => {
    setAlan("province_name", il);
    setAlan("district_name", ""); // il değişince ilçe temizlenir
    setGiris(il);
  };

  const handleIlceDegisti = (ilce: string) => {
    setAlan("district_name", ilce);
    setGiris(ilce);
  };

  const handleGpsKonumAl = () => {
    if (!navigator.geolocation) {
      mesajEkle("asistan", "Bu tarayıcı GPS konumunu desteklemiyor; adresi elle yazabilirsin.");
      return;
    }
    setGpsLoading(true);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        const accuracy = pos.coords.accuracy;
        try {
          const cozulen = await gpsAdresiniCoz(lat, lng);
          const alanlar = [
            { anahtar: "enlem", deger: lat },
            { anahtar: "boylam", deger: lng },
            { anahtar: "adres", deger: cozulen.address },
            { anahtar: "il", deger: cozulen.provinceName },
            { anahtar: "ilce", deger: cozulen.districtName },
          ] as const;
          const clientId = taslakClientId();
          const saves = await Promise.all(
            alanlar.map(({ anahtar, deger }) => fetch("/api/owner-draft", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ slug, anahtar, deger, clientId }),
            })),
          );
          if (saves.some((r) => !r.ok)) {
            const firstErr = await saves.find((r) => !r.ok)?.json().catch(() => null);
            mesajEkle("asistan", firstErr?.hata ?? "Konum kaydedilemedi.");
            setGpsLoading(false);
            return;
          }
          setAlan("latitude", lat);
          setAlan("longitude", lng);
          setAlan("address", cozulen.address);
          setAlan("province_name", cozulen.provinceName);
          setAlan("district_name", cozulen.districtName);
          (setAlan as unknown as (k: string, v: unknown) => void)("location_accuracy_meters", accuracy);
          (setAlan as unknown as (k: string, v: unknown) => void)("location_source", "browser_gps");
          mesajEkle("asistan", `${cozulen.districtName}, ${cozulen.provinceName} adresi GPS ile dolduruldu (±${Math.round(accuracy)}m).`);
          router.refresh();
        } catch (error) {
          mesajEkle(
            "asistan",
            error instanceof Error ? error.message : "Adres çözümlenemedi. Tekrar dene.",
          );
        } finally {
          setGpsLoading(false);
        }
      },
      () => {
        mesajEkle("asistan", "Konum izni alınamadı; il, ilçe ve adresi elle yazabilirsin.");
        setGpsLoading(false);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  return (
    <>
      <OwnerEditorBar
        kaydediliyor={actions.kaydediliyor}
        panelAcik={acik}
        yayinlaniyor={actions.yayinlaniyor}
        yasalOnayli={yasalOnayli}
        onOnizleme={() => setAcik((onceki) => !onceki)}
        onAyarlar={() => {
          setAcik(true);
          setSekme("alanlar");
          setHaritaAcik(true);
        }}
        onYayinla={
          rapor.temelTamam
            ? actions.yayinla
            : async () => {
                setAcik(true);
                setSekme("eksikler");
                setHaritaAcik(false);
              }
        }
        onYasalOnayGerek={() => {
          setAcik(true);
          setSekme("eksikler");
          setHaritaAcik(false);
        }}
      />

      {/* Sayfada dolaşan rehber — panel açık ve bir alan seçiliyken,
       * hedef alanın üzerinde/yanında görünür (bkz. SpotlightGuide). */}
      {acik && !(!masaustu && haritaAcik) && (
        <SpotlightGuide
          seciliAlan={seciliAlan}
          geriAliniyor={fieldRestore.geriAliniyor}
          canliyaDondur={fieldRestore.canliyaDondur}
          onKapat={rehberiKapat}
          olcumTetikleyici={yerelTaslak}
          gecisSuruyor={gecisSuruyor}
          onHaritaAc={() => setHaritaAcik(true)}
        />
      )}

      {/* Mobil: compact mesaj dock'u. Mesaj kutusu ana öğedir; canonical
       * Vixrex maskotu SAĞDA kalır. Sayaç/aşama/eksik bilgi bu dar yüzde
       * gösterilmez. Yukarı sürükleme veya maskota dokunma geçmişi açar. */}
      {!masaustu && !haritaAcik ? (
        <div
          data-vixrex-mobile-dock="true"
          className="fixed inset-x-3 z-[76] rounded-[1.35rem] border border-sky-200/20 bg-[#081422]/[0.98] px-2.5 pb-2.5 pt-1.5 shadow-2xl backdrop-blur-xl sm:hidden"
          style={{ bottom: "max(0.75rem, env(safe-area-inset-bottom))" }}
        >
          <div
            role="separator"
            aria-orientation="horizontal"
            aria-label="Sohbet geçmişini açmak için yukarı çek"
            onPointerDown={mobilTutamakBasla}
            onPointerUp={mobilTutamakBitir}
            onPointerCancel={() => {
              mobilTutamakRef.current = null;
            }}
            onDoubleClick={mobilGecmisiAc}
            className="flex h-5 touch-none select-none items-center justify-center"
          >
            <span className="h-1 w-10 rounded-full bg-slate-400/70" />
          </div>

          <FieldInputArea
            compact
            trailing={
              <button
                type="button"
                aria-label="Sohbet geçmişini aç"
                onClick={mobilGecmisiAc}
                className="grid h-11 w-11 shrink-0 place-items-center rounded-full border border-sky-400/45 bg-[#0D1B2D] shadow-[0_0_16px_rgba(14,165,233,0.20)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sky-400/70"
              >
                <VixrexAvatar size={44} decorative />
              </button>
            }
            seciliAlan={seciliAlan}
            giris={giris}
            girisRef={girisRef}
            kaydediliyor={actions.kaydediliyor}
            geriAliniyor={fieldRestore.geriAliniyor}
            hazirGorseller={actions.hazirGorseller}
            hazirYukleniyor={actions.hazirYukleniyor}
            mevcutIl={mevcutIl}
            mevcutIlce={mevcutIlce}
            setGiris={setGiris}
            gorselYukle={actions.gorselYukle}
            hazirGorselleriAc={actions.hazirGorselleriAc}
            hazirGorselSec={actions.hazirGorselSec}
            gonder={actions.gonder}
            alanAtla={actions.alanAtla}
            canliyaDondur={fieldRestore.canliyaDondur}
            sonrayaBirak={sonrayaBirak}
            onIlDegisti={handleIlDegisti}
            onIlceDegisti={handleIlceDegisti}
            onGpsKonumAl={handleGpsKonumAl}
            gpsLoading={gpsLoading}
          />
        </div>
      ) : null}

      {(masaustu ? acik : mobilGecmisAcik || haritaAcik) && (
        // 2026-09-03 (Çalışma masası / Yön C, Faz 3) — Casper'ın kararı:
        // yazma yeri panelin ALT ŞERİDİNDE ve asistan açıkken HEP açık,
        // "Tüm alanlar" (☰) kapalıyken de. Önceki hâlde bu kutu yalnız
        // SpotlightGuide'ın balonundaydı; balon her alanda yeniden
        // konumlanınca göz sıçrıyordu.
        //
        // 2026-08-22 mobil uyum düzeltmesi: eski className yalnız
        // `bottom-24 right-5` idi (üst sınır YOKTU) — 9 bölümlük
        // SectionProgressList tamamen açıldığında panel içeriği ekranın
        // üstünden taşıp kayboluyordu. `top-16` sabitiyle çözülmüştü; artık
        // kutu içeriğe göre büyüyor (`max-h`, sabit `top` YOK) — kapalıyken
        // (yalnız sohbet+giriş) ekranın dibine yaslanır, açıkken yukarı
        // doğru büyür. Ortadaki gövde tek kaydırma alanı, başlık sabit kalır.
        // Mobilde bu hâliyle KALIR (Faz 4, 2026-08-22 — Casper: "sadece
        // maskot olsun", tam ekran kaplayan bir panel mobilde istenmedi).
        //
        // 2026-09-03 (Casper'ın onayladığı "C" tasarım tuvaline sadakat
        // düzeltmesi, iki turda): tuvalde asistan sağda rail tokenı kadar, EKRANIN
        // TAMAMI kadar yükseklikte, başlığı/SIRADA'sı HER ZAMAN görünen,
        // hep açık bir panel olarak tasarlanmıştı — burada (Faz 1-5
        // yazılırken) sessizce alt köşede kapalı-varsayılan, başlıksız
        // küçük bir karta dönüşmüştü, Casper'a hiç sorulmadan. Masaüstünde
        // (`sm:`) artık sağa sabitlenmiş, taslak şeridinin (36px — navbar'ın
        // DEĞİL: sahip modunda navbar'ın sağ tarafı zaten hep boş, bkz.
        // VitrinProfileView.tsx `{!ownerMode && whatsappUrl && ...}`, o
        // yüzden üstüne binmesi sorun değil) altından ekranın dibine kadar
        // uzanan kalıcı bir sütun; `acik` masaüstünde ilk açılışta otomatik
        // true olur (aşağı bkz. masaustuIlkAcilisRef). Başlık (ChatTopBar) +
        // SIRADA artık `haritaAcik`ten bağımsız, panel açıkken hep çizilir
        // (aşağıda). Mobil davranış hiç değişmedi.
        <div data-vixrex-mobile-details={haritaAcik ? "true" : "false"} className="vixrex-owner-assistant-shell fixed inset-x-3 bottom-24 z-[75] flex max-h-[calc(100vh-8rem)] flex-col overflow-hidden rounded-2xl border border-white/10 bg-[#0B1120] shadow-2xl lg:bg-[#0E1729] sm:inset-x-auto sm:inset-y-auto sm:top-9 sm:bottom-5 sm:right-5 sm:max-h-none sm:w-[460px] lg:bottom-0 lg:right-0 lg:top-[var(--owner-bar-h)] lg:w-[var(--owner-rail-w)] lg:rounded-none lg:border-y-0 lg:border-r-0 lg:shadow-none">
          {/* 2026-09-03 (Casper'ın onayladığı "C" tasarımına sadakat, ikinci
           * tur): tuvalde maskot+"Vixrex Asistan"+%hazır başlığı ve SIRADA
           * listesi panel her açıldığında GÖRÜNÜRDÜ — "☰ Tüm alanlar" gibi
           * bir gizleme yoktu. Burada ikisi de yanlışlıkla `haritaAcik`
           * (yalnız "☰" ile açılan DETAY görünümü) koşuluna bağlanmıştı;
           * panel `acik` olsa bile `haritaAcik` false olduğu sürece boş/
           * başsız görünüyordu. Şimdi ikisi de `acik`e taşındı — yalnız
           * gerçekten İKİNCİL olan detaylar (Tüm bölümler, rezervasyon
           * ayarları, içerik düzenleme kısayolları, yayınla çubuğu)
           * `haritaAcik`'in ardında kalmaya devam ediyor (Faz 2'nin
           * "sihirbaz kalabalığı kalksın" kararı bunlar için hâlâ geçerli). */}
          <ChatTopBar
            rapor={rapor}
            onKapat={() => (masaustu ? setAcik(false) : haritaAcik ? setHaritaAcik(false) : setMobilGecmisAcik(false))}
          />

          {/* Telefon geçmişi: mobil PR #545'in onaylanan davranışı.
           * Masaüstü yeniden düzeni bu kola dokunmaz. */}
          {!masaustu && mobilGecmisAcik && !haritaAcik ? (
            <div
              ref={akisRef}
              className="vixrex-panel-kaydirici min-h-0 flex-1 space-y-2 overflow-y-auto px-4 py-3"
            >
              {mesajlar.map((m) => (
                <ChatBubble key={m.id} mesaj={m} onHizliCevap={handleHizliCevap} />
              ))}
            </div>
          ) : null}

          {/* Telefonda "Tüm alanlar" ayrıntı yüzeyi eski araçları korur.
           * Compact composer / sohbet geçmişi sözleşmesi değişmez. */}
          {!masaustu && haritaAcik ? (
            <>
              <div className="min-h-0 flex-1 overflow-y-auto">
                <UpNextList
                  yerelTaslak={yerelTaslak}
                  suankiAnahtar={seciliAlan?.anahtar ?? null}
                  atlanmisAlanlar={atlanmisAlanlar}
                  alanSec={alanSec}
                  alanAtla={alanAtlandi}
                />
                <SectionProgressList yerelTaslak={yerelTaslak} alanSec={alanSec} />
                <SectionVisibilityToggle
                  slug={slug}
                  visibility={yerelTaslak.section_visibility as Record<string, boolean> | null}
                  setAlan={setAlan}
                  mesajEkle={mesajEkle}
                />
                <BookingSettingsPanel
                  slug={slug}
                  mevcutAyarlar={bookingSettings as { is_enabled: boolean; capacity: number; working_hours: Record<string, { start: string; end: string; active: boolean }>; lunch_break: { start: string; end: string; active: boolean } } | null}
                />
              </div>
              <div className="shrink-0 border-t border-white/10 px-3 py-2">
                <FieldInputArea
                  seciliAlan={seciliAlan}
                  giris={giris}
                  girisRef={girisRef}
                  kaydediliyor={actions.kaydediliyor}
                  geriAliniyor={fieldRestore.geriAliniyor}
                  hazirGorseller={actions.hazirGorseller}
                  hazirYukleniyor={actions.hazirYukleniyor}
                  mevcutIl={mevcutIl}
                  mevcutIlce={mevcutIlce}
                  setGiris={setGiris}
                  gorselYukle={actions.gorselYukle}
                  hazirGorselleriAc={actions.hazirGorselleriAc}
                  hazirGorselSec={actions.hazirGorselSec}
                  gonder={actions.gonder}
                  alanAtla={actions.alanAtla}
                  canliyaDondur={fieldRestore.canliyaDondur}
                  sonrayaBirak={sonrayaBirak}
                  onIlDegisti={handleIlDegisti}
                  onIlceDegisti={handleIlceDegisti}
                  onGpsKonumAl={handleGpsKonumAl}
                  gpsLoading={gpsLoading}
                />
              </div>
              <div className="shrink-0 border-t border-white/10 px-4 py-3">
                <PublishBar
                  yayinlaniyor={actions.yayinlaniyor}
                  silmeOnayi={actions.silmeOnayi}
                  yayinla={actions.yayinla}
                  silmeOnayla={actions.silmeOnayla}
                  sil={actions.sil}
                  setSilmeOnayi={actions.setSilmeOnayi}
                  temelTamam={rapor.temelTamam}
                  eksikTemelSayisi={eksikTemelSayisi}
                  kiralikVitrinMi={kiralikVitrinMi}
                  premiumAktifMi={premiumAktifMi}
                  yasalOnayli={yasalOnayli}
                  onayVeriliyor={actions.onayVeriliyor}
                  onayVer={actions.onayVer}
                />
              </div>
            </>
          ) : null}

          {/* Masaüstü/tablet: sohbet, alanlar ve eksikler birbirinden ayrılır.
           * Aynı veri/aynı NLU/aynı yazma fonksiyonları kullanılır; yalnız
           * çalışan araçların ekrandaki yeri değişir. */}
          {masaustu ? (
            <>
              <div
                data-vixrex-desktop-tabs="true"
                className="grid shrink-0 grid-cols-3 border-b border-white/10"
              >
                {([
                  ["sohbet", "Sohbet"],
                  ["alanlar", "Alanlar"],
                  ["eksikler", "Eksikler"],
                ] as const).map(([deger, etiket]) => (
                  <button
                    key={deger}
                    type="button"
                    onClick={() => {
                      setSekme(deger);
                      setHaritaAcik(deger === "alanlar");
                    }}
                    className={`border-b-2 px-3 py-3 text-[11px] font-black transition ${
                      sekme === deger
                        ? "border-sky-400 bg-white/[0.035] text-white"
                        : "border-transparent text-slate-500 hover:text-slate-200"
                    }`}
                  >
                    {etiket}
                    {deger === "eksikler" && eksikTemelSayisi > 0 ? (
                      <span className="ml-1.5 rounded-full bg-amber-400/15 px-1.5 py-0.5 text-[9px] text-amber-300">
                        {eksikTemelSayisi}
                      </span>
                    ) : null}
                  </button>
                ))}
              </div>

              {sekme === "sohbet" ? (
                <>
                  <div
                    ref={akisRef}
                    className="vixrex-panel-kaydirici min-h-0 flex-1 space-y-2 overflow-y-auto px-4 py-3"
                  >
                    {mesajlar.map((m) => (
                      <ChatBubble key={m.id} mesaj={m} onHizliCevap={handleHizliCevap} />
                    ))}
                  </div>
                  <div className="shrink-0 border-t border-white/10 px-3 py-2.5">
                    <FieldInputArea
                      compact
                      seciliAlan={seciliAlan}
                      giris={giris}
                      girisRef={girisRef}
                      kaydediliyor={actions.kaydediliyor}
                      geriAliniyor={fieldRestore.geriAliniyor}
                      hazirGorseller={actions.hazirGorseller}
                      hazirYukleniyor={actions.hazirYukleniyor}
                      mevcutIl={mevcutIl}
                      mevcutIlce={mevcutIlce}
                      setGiris={setGiris}
                      gorselYukle={actions.gorselYukle}
                      hazirGorselleriAc={actions.hazirGorselleriAc}
                      hazirGorselSec={actions.hazirGorselSec}
                      gonder={actions.gonder}
                      alanAtla={actions.alanAtla}
                      canliyaDondur={fieldRestore.canliyaDondur}
                      sonrayaBirak={sonrayaBirak}
                      onIlDegisti={handleIlDegisti}
                      onIlceDegisti={handleIlceDegisti}
                      onGpsKonumAl={handleGpsKonumAl}
                      gpsLoading={gpsLoading}
                    />
                    <div className="mt-1.5 flex items-center justify-between px-1 text-[9px] font-medium text-slate-600">
                      <span>Enter gönderir · Shift+Enter yeni satır</span>
                      <span>Tek mesajla birden fazla alan</span>
                    </div>
                  </div>
                </>
              ) : null}

              {sekme === "alanlar" ? (
                <>
                  <div className="vixrex-panel-kaydirici min-h-0 flex-1 overflow-y-auto">
                    {seciliAlan ? (
                      <div className="border-b border-white/10 px-4 py-3">
                        <div className="rounded-xl border border-sky-400/25 bg-sky-500/[0.07] px-3 py-2.5">
                          <p className="text-[11px] font-black uppercase tracking-[0.08em] text-sky-300">
                            Seçili alan
                          </p>
                          <p className="mt-1 text-[13px] font-bold text-white">
                            {seciliAlan.etiket}
                          </p>
                          {seciliAlan.neden ? (
                            <p className="mt-1 text-[10px] leading-relaxed text-slate-400">
                              {seciliAlan.neden}
                            </p>
                          ) : null}
                        </div>
                      </div>
                    ) : null}

                    <SectionProgressList yerelTaslak={yerelTaslak} alanSec={alanSec} />

                    <SectionVisibilityToggle
                      slug={slug}
                      visibility={yerelTaslak.section_visibility as Record<string, boolean> | null}
                      setAlan={setAlan}
                      mesajEkle={mesajEkle}
                    />

                    <BookingSettingsPanel
                      slug={slug}
                      mevcutAyarlar={bookingSettings as { is_enabled: boolean; capacity: number; working_hours: Record<string, { start: string; end: string; active: boolean }>; lunch_break: { start: string; end: string; active: boolean } } | null}
                    />

                    <div className="border-t border-white/10 px-4 py-3">
                      <p className="mb-2 text-[10px] font-black uppercase tracking-[0.12em] text-slate-500">
                        İçerik düzenleme
                      </p>
                      <div className="space-y-1">
                        <button type="button" onClick={() => setAboutAcik(true)} className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-[12px] font-semibold text-slate-300 hover:bg-white/5">
                          <span className="flex-1">Hakkımızda</span>
                          <span className="text-[9px] text-slate-600">{aboutSection?.title ? "Dolu" : "Boş"}</span>
                        </button>
                        <button type="button" onClick={() => setGaleriAcik(true)} className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-[12px] font-semibold text-slate-300 hover:bg-white/5">
                          <span className="flex-1">Galeri</span>
                          <span className="text-[9px] text-slate-600">{galleryItems && galleryItems.length > 0 ? `${galleryItems.length} görsel` : "Boş"}</span>
                        </button>
                        <button type="button" onClick={() => setMarketplaceAcik(true)} className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-[12px] font-semibold text-slate-300 hover:bg-white/5">
                          <span className="flex-1">Pazaryeri bağlantıları</span>
                          <span className="text-[9px] text-slate-600">{marketplaceLinks && marketplaceLinks.length > 0 ? `${marketplaceLinks.length} link` : "Boş"}</span>
                        </button>
                        <button type="button" onClick={() => setFaqAcik(true)} className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-[12px] font-semibold text-slate-300 hover:bg-white/5">
                          <span className="flex-1">Sık Sorulan Sorular</span>
                          <span className="text-[9px] text-slate-600">{faqItems && faqItems.length > 0 ? `${faqItems.length} soru` : "Boş"}</span>
                        </button>
                        <button type="button" onClick={() => setKampanyaAcik(true)} className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-[12px] font-semibold text-slate-300 hover:bg-white/5">
                          <span className="flex-1">Öne Çıkan Kampanya</span>
                          <span className="text-[9px] text-slate-600">{campaignBanner?.title ? "Dolu" : "Boş"}</span>
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="shrink-0 border-t border-white/10 px-3 py-2.5">
                    <FieldInputArea
                      seciliAlan={seciliAlan}
                      giris={giris}
                      girisRef={girisRef}
                      kaydediliyor={actions.kaydediliyor}
                      geriAliniyor={fieldRestore.geriAliniyor}
                      hazirGorseller={actions.hazirGorseller}
                      hazirYukleniyor={actions.hazirYukleniyor}
                      mevcutIl={mevcutIl}
                      mevcutIlce={mevcutIlce}
                      setGiris={setGiris}
                      gorselYukle={actions.gorselYukle}
                      hazirGorselleriAc={actions.hazirGorselleriAc}
                      hazirGorselSec={actions.hazirGorselSec}
                      gonder={actions.gonder}
                      alanAtla={actions.alanAtla}
                      canliyaDondur={fieldRestore.canliyaDondur}
                      sonrayaBirak={sonrayaBirak}
                      onIlDegisti={handleIlDegisti}
                      onIlceDegisti={handleIlceDegisti}
                      onGpsKonumAl={handleGpsKonumAl}
                      gpsLoading={gpsLoading}
                    />
                  </div>
                </>
              ) : null}

              {sekme === "eksikler" ? (
                <div className="vixrex-panel-kaydirici min-h-0 flex-1 overflow-y-auto">
                  {hesapBagliDegil ? <HesapBaglaSeridi slug={slug} /> : null}

                  {oturumSaniye !== null && oturumSaniye < 300 ? (
                    <p className="border-b border-white/10 px-4 py-2 text-[10px] font-semibold text-amber-400">
                      Oturumunun bitmesine az kaldı — değişikliklerin kayıtlı.
                    </p>
                  ) : null}

                  <UpNextList
                    yerelTaslak={yerelTaslak}
                    suankiAnahtar={seciliAlan?.anahtar ?? null}
                    atlanmisAlanlar={atlanmisAlanlar}
                    alanSec={(anahtar) => {
                      setSekme("alanlar");
                      setHaritaAcik(true);
                      alanSec(anahtar);
                    }}
                    alanAtla={alanAtlandi}
                  />

                  <div className="border-b border-white/10 px-4 py-3">
                    <p className="mb-2 text-[10px] font-black uppercase tracking-[0.12em] text-slate-500">
                      Yayın için gerekli
                    </p>
                    <div className="space-y-1.5">
                      {rapor.eksikler.filter((e) => e.onem === "temel").map((eksik) => (
                        <button
                          key={eksik.anahtar}
                          type="button"
                          onClick={() => {
                            setSekme("alanlar");
                            setHaritaAcik(true);
                            alanSec(eksik.anahtar);
                          }}
                          className="flex w-full items-center gap-3 rounded-xl border border-amber-400/20 bg-amber-500/[0.07] px-3 py-2.5 text-left hover:bg-amber-500/[0.12]"
                        >
                          <span className="grid h-6 w-6 shrink-0 place-items-center rounded-full bg-amber-400/15 text-[11px] font-black text-amber-300">!</span>
                          <span className="min-w-0 flex-1">
                            <span className="block truncate text-[11px] font-bold text-white">{eksik.etiket}</span>
                            <span className="mt-0.5 block text-[9px] text-slate-500">Tamamlamak için aç</span>
                          </span>
                          <span className="text-slate-600">›</span>
                        </button>
                      ))}
                      {eksikTemelSayisi === 0 ? (
                        <div className="rounded-xl border border-emerald-400/15 bg-emerald-500/[0.06] px-3 py-2.5 text-[11px] font-semibold text-emerald-300">
                          Zorunlu bilgiler tamam.
                        </div>
                      ) : null}
                    </div>
                  </div>

                  <div className="border-b border-white/10 px-4 py-3">
                    <p className="mb-2 text-[10px] font-black uppercase tracking-[0.12em] text-slate-500">
                      Kalite önerileri
                    </p>
                    <div className="space-y-1.5">
                      {rapor.eksikler.filter((e) => e.onem === "kalite").map((eksik) => (
                        <button
                          key={eksik.anahtar}
                          type="button"
                          onClick={() => {
                            setSekme("alanlar");
                            setHaritaAcik(true);
                            alanSec(eksik.anahtar);
                          }}
                          className="flex w-full items-center gap-3 rounded-xl border border-white/10 bg-white/[0.035] px-3 py-2.5 text-left hover:bg-white/[0.06]"
                        >
                          <span className="grid h-6 w-6 shrink-0 place-items-center rounded-full bg-sky-400/10 text-[11px] font-black text-sky-300">+</span>
                          <span className="min-w-0 flex-1">
                            <span className="block truncate text-[11px] font-bold text-white">{eksik.etiket}</span>
                            <span className="mt-0.5 block text-[9px] text-slate-500">Vitrini güçlendirir</span>
                          </span>
                          <span className="text-slate-600">›</span>
                        </button>
                      ))}

                      {yonetimOnerileriUret(
                        yerelTaslak,
                        urunFiyatsizSayisi,
                        urunAciklamasizSayisi
                      ).map((oneri) => (
                        <div
                          key={oneri.id}
                          className="rounded-xl border border-white/10 bg-white/[0.035] px-3 py-2.5 text-[10px] leading-relaxed text-slate-300"
                        >
                          {oneri.mesaj}
                        </div>
                      ))}

                      {rapor.eksikler.filter((e) => e.onem === "kalite").length === 0 &&
                      yonetimOnerileriUret(
                        yerelTaslak,
                        urunFiyatsizSayisi,
                        urunAciklamasizSayisi
                      ).length === 0 ? (
                        <p className="py-3 text-center text-[10px] font-medium text-slate-600">
                          Şu an bekleyen bir kalite önerisi yok.
                        </p>
                      ) : null}
                    </div>
                  </div>

                  <div className="px-4 py-3">
                    <p className="pb-2 text-[10px] font-semibold text-slate-500">
                      {yayinlanmamisDegisiklik
                        ? "Yayınlanmamış değişikliklerin var."
                        : "Vitrinin yayındaki hâliyle aynı."}
                    </p>
                    <PublishBar
                      yayinlaniyor={actions.yayinlaniyor}
                      silmeOnayi={actions.silmeOnayi}
                      yayinla={actions.yayinla}
                      silmeOnayla={actions.silmeOnayla}
                      sil={actions.sil}
                      setSilmeOnayi={actions.setSilmeOnayi}
                      temelTamam={rapor.temelTamam}
                      eksikTemelSayisi={eksikTemelSayisi}
                      kiralikVitrinMi={kiralikVitrinMi}
                      premiumAktifMi={premiumAktifMi}
                      yasalOnayli={yasalOnayli}
                      onayVeriliyor={actions.onayVeriliyor}
                      onayVer={actions.onayVer}
                      showPublishButton={false}
                    />
                  </div>
                </div>
              ) : null}
            </>
          ) : null}
        </div>
      )}
      {/* Hakkımızda / SSS / Kampanya düzenleme modalleri */}
      {aboutAcik && aboutSection && (
        <AboutEditor
          slug={slug}
          mevcut={aboutSection}
          onClose={() => setAboutAcik(false)}
        />
      )}
      {faqAcik && (
        <FaqEditor
          slug={slug}
          items={faqItems ?? []}
          onClose={() => setFaqAcik(false)}
        />
      )}
      {kampanyaAcik && (
        <CampaignEditor
          slug={slug}
          mevcut={campaignBanner ?? { label: "", title: "", description: "", priceText: "", imageUrl: "" }}
          onClose={() => setKampanyaAcik(false)}
        />
      )}
      {marketplaceAcik && (
        <MarketplaceEditor
          slug={slug}
          links={(marketplaceLinks ?? []).map((l, i) => ({ id: l.id || `ml-${i}`, platform: l.platform || "", url: l.url || "", subtitle: l.subtitle || "" }))}
          onClose={() => setMarketplaceAcik(false)}
        />
      )}
      {galeriAcik && (
        <GalleryEditor
          slug={slug}
          items={(galleryItems ?? []).map((g) => ({ id: g.id || "", imageUrl: g.imageUrl || "", title: g.title || "" }))}
          onClose={() => setGaleriAcik(false)}
        />
      )}
    </>
  );
}
