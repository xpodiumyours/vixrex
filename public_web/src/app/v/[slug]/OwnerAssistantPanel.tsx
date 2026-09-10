"use client";

import { useEffect, useRef, useState } from "react";
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
// SAHİPLİK EKRANI — KALAN PLAN (Casper, 2026-09-03/04 konuşması)
// ============================================================================
// Bu blok, panelin görsel/etkileşim yeniden tasarımı için SIRADAKİ AJANIN
// nereden, nasıl ve NEDEN başlayacağını bilmesi için yazıldı. Aşağıdaki 5
// madde (eski numaralandırmayla 1, 2, 5, 6, 10) 2026-09-03'teki ilk
// incelemeden kalan, henüz UYGULANMAMIŞ maddelerdi. 2026-09-04'te Casper bir
// "3 modlu, tek elle kullanılabilen" bottom-sheet mockup'ı tarif etti; aynı
// gün MOD 2'nin (Asistan Modu, sheet açık) gerçek görseli de geldi — aşağıdaki
// tarif artık o görsele dayanıyor. MOD 1 (vitrin + kapalı asistan) ve MOD 3
// HÂLÂ GÖRÜLMEDİ — yalnız MOD 2'nin üstünde kesik/soluk görünen MOD 1 satırı
// var. Sıradaki ajan koda dökmeden önce Casper'dan MOD 1'in TAMAMINI ve
// MOD 3'ü istemeli.
//
// MOD 2 GÖRSELİNDEN DOĞRULANAN SOMUT DETAYLAR (2026-09-04):
//   - Sheet, vitrinin ÜSTÜNE yuvarlak köşeli bir kart olarak biner (tam ekranı
//     kaplamaz), üstte sürükleme çubuğu (drag handle) var.
//   - Sheet başlığı: robot avatar + "Vixrex Asistan" + yeşil nokta "Çevrimiçi"
//     solda; sağda "Aşama 2/3" (vurgulu) + küçük gri "15/46" (ham sayaç
//     TAMAMEN kalkmıyor, Aşama'nın yanında ikincil/küçük bilgi olarak kalıyor)
//     + kapatma X'i (X'e basınca muhtemelen MOD 1'e döner).
//   - Aksiyon butonlarında SÜRE TAHMİNİ var: "+ Hizmet & Fiyat Ekle" /
//     "~2 dakika" — büyük yeşil buton, altta küçük gri alt yazı.
//   - MOD 1→MOD 2 geçişi muhtemelen SWIPE değil DOKUNMA: MOD 2'nin üstünde
//     görünen kesik MOD 1 satırı "Asistan sağ altta, sadece dokunulduğunda
//     büyür" diyor — bu, koddaki MEVCUT yuvarlak Vixrex düğmesiyle
//     (`fixed bottom-5 right-5`, bu dosyada "Canonical Vixrex düğmesi" yorumu)
//     örtüşüyor; sıfırdan bir gesture sistemi kurmaya GEREK OLMAYABİLİR.
//
// MEVCUT SORUN → YENİ ÇÖZÜM (Casper'ın 2026-09-04 tarifi):
//   Sol editör + sağ chat dikkat dağıtıyor
//     → Bottom sheet asistan: yukarı kaydırınca açılır, aşağı kaydırınca
//       vitrin tam ekran. Şu anki "sağda sabit 460px panel" modelinin YERİNİ
//       ALIYOR — madde 10'un (mobil split-view) hem mobil hem masaüstü için
//       genelleşmiş hâli.
//   "23/46" korkutucu
//     → "Aşama 2/3": 3 aşamalı akış, her aşama bitince "Devam et / Şimdilik
//       yeter". Madde 1'in ("N/6 zorunlu" göstergesi) YERİNE GEÇİYOR — sayaç
//       değil, adım/aşama metaforu.
//   Asistan aynı mesajı tekrar ediyor
//     → Onay kartı: zaten VAR (bkz. useOwnerActions.gonder içindeki "Doğru/
//       Geri al" kartı, 2026-09-03). Mockup'ta buton adları "Onayla/Düzelt" —
//       küçük bir isimlendirme/UX cilası, mantık değişmiyor.
//   Karar noktalarında sadece metin
//     → Görsel karar kartları: "Hizmet ekle", "Yayınla" gibi büyük renkli
//       butonlar. Yayınla'nın YERİ zaten düzeltildi (bkz. PublishBar'ın artık
//       composer altında sabit şerit olması, 2026-09-03) — kalan iş yalnız
//       GÖRSEL ağırlık/stil.
//   Yayına alma dağınık
//     → Alt navigasyon: vitrin / düzenle / önizle (=müşteri modu) / ayarlar,
//       4 sekme. BU, önceki 10 maddede YOKTU — yeni bir yapısal öğe (kalıcı
//       bottom tab bar). İKONLAR EMOJİ OLMAYACAK (Casper, 2026-09-04) — gerçek
//       SVG/icon component (repoda zaten ikon kullanımı varsa onun deseniyle,
//       yoksa yeni eklenecek bir ikon seti). SpotlightGuide'ın "balonu
//       küçült" fikrini (eski madde 5) muhtemelen gereksiz kılıyor: balon
//       yerine zaten "düzenle" modunda esnaf tek bir aktif alanla baş başa
//       kalıyor.
//
// SONUÇ — ESKİ 5 MADDE NASIL DEĞİŞTİ:
//   Madde 1 (yüzde → N/6)         → YENİDEN ÇERÇEVELENDİ: "Aşama 2/3" stepper.
//   Madde 2 (SIRADA tek görev)    → KORUNUYOR, bottom-sheet içinde "düzenle"
//                                    modunun kendi ekranı olarak yaşıyor.
//   Madde 5 (Spotlight küçült)    → MUHTEMELEN GEREKSİZLEŞTİ — balon modeli
//                                    yerine ayrı bir "düzenle" tam-ekran modu
//                                    geliyor. Sıradaki ajan SpotlightGuide'ı
//                                    küçültmeden önce bunun hâlâ gerekip
//                                    gerekmediğini Casper'a sormalı.
//   Madde 6 (sohbet geçmişi kısa) → KORUNUYOR, bottom-sheet'in "sohbet" alt-
//                                    modunda hâlâ geçerli.
//   Madde 10 (mobil split-view)   → GENİŞLEDİ: yalnız mobil değil, masaüstü de
//                                    dahil "bottom sheet, 3 mod" modeline.
//   YENİ: alt navigasyon (vitrin/düzenle/önizle/ayarlar, emoji DEĞİL gerçek
//   ikon) — önceki plana hiç yoktu, eklendi.
//
// SIRADAKİ AJAN NEREDEN BAŞLAMALI (sıra önemli):
//   1) Casper'dan MOD 1'in TAMAMINI ve MOD 3'ü iste (yalnız MOD 2 görüldü,
//      2026-09-04) — sheet ne kadar açılıyor, "Aşama 2/3" hangi 3 aşama,
//      MOD 3 ne (muhtemelen ⚙️ ayarlar ya da 👁️ önizle modu) hâlâ belirsiz.
//   2) CLAUDE.md kuralı gereği: bu tamamen görsel/etkileşimsel bir değişiklik
//      — Browser pane / canlı önizleme ile GÖRÜP doğrulamadan "düzelttim"
//      DENMEZ. Sandbox'ta public_web/.env.local yoksa (2026-09-03'te öyleydi)
//      bunu açıkça söyle, kör tahminle commit atma.
//   3) Küçük, geri alınabilir adımlarla ilerle — örn. önce yalnız alt
//      navigasyonu (emoji DEĞİL, gerçek ikonlarla) ekle ve canlı doğrula,
//      SONRA bottom-sheet geçişine geç. Hepsini tek commit'te denemek,
//      ÖNCE SOR kuralını (bu dosyanın en üstündeki CLAUDE.md talimatı) ihlal
//      eder.
//   4) ÖNCE SOR: küçük görünse bile Casper'a sormadan hiçbir adımı uygulama
//      (bkz. CLAUDE.md, "Çalışma kuralı — ÖNCE SOR").
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
  /** Faz F: son 7 gün özeti — yalnız yayında olan vitrinde. */
  haftalikPerformans?: {
    goruntuleme: number;
    whatsapp_tiklama: number;
    telefon_tiklama: number;
    konum_tiklama: number;
    en_cok_goruntulenen_urun: string | null;
  } | null;
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
  haftalikPerformans = null,
  flowState = null,
  hesapBagliDegil = false,
  oturumSaniye = null,
  yayinlanmamisDegisiklik = false,
}: Props & { flowState?: Record<string, unknown> | null }) {
  const [acik, setAcik] = useState(true);
  // Harita = "Tüm alanlar" paneli. Faz 4 (Casper, 2026-08-22): mobilde
  // panel bütün sayfayı kapatıyordu — "sadece Vixrex maskotu olsun,
  // kutucuklarda zaten ne yapılacağı yazıyor". Artık alan seçilince
  // mobilde harita kapanır; sayfada yalnız sembol ve balon kalır.
  // Masaüstünde yer bol, harita açık durmaya devam eder.
  const [haritaAcik, setHaritaAcik] = useState(false);
  const [mesajBuyuk, setMesajBuyuk] = useState(false);
  const [mesajTasiyor, setMesajTasiyor] = useState(false);
  const [siradaki, setSiradaki] = useState<(() => void) | null>(null);
  const [tanisma, setTanisma] = useState(!assistantHandoff && !flowState);
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

  // Panel açıkken vitrindeki TÜM doldurulabilir yerler sürekli hafif ışıklı
  // dursun (Vixrex Asistan rehberli tamamlama, ADR 0002) — yalnız o an
  // seçili olan değil. Sınıf `body`'ye eklenir, gerçek stil globals.css'te
  // `[data-vixrex-editable]` üzerinden çalışır — bu öznitelik yalnız sahip
  // modunda DOM'a girdiği için müşteri görünümü hiç etkilenmez.
  useEffect(() => {
    document.body.classList.toggle("vixrex-asistan-acik", acik);
    return () => document.body.classList.remove("vixrex-asistan-acik");
  }, [acik]);

  const { yerelTaslak, setAlan, rapor, atlanmisAlanlar, alanAtlandi } = useOwnerDraft(
    slug,
    draftData,
    atlananAlanlar ?? []
  );
  const { mesajlar, mesajEkle, akisRef } = useOwnerChat(rapor, assistantHandoff, { slug });

  useEffect(() => {
    const element = akisRef.current;
    if (!element || !acik) return;
    const measure = () => setMesajTasiyor(element.scrollHeight > element.clientHeight + 2);
    const observer = new ResizeObserver(measure);
    observer.observe(element);
    for (const child of element.children) observer.observe(child);
    measure();
    return () => observer.disconnect();
  }, [mesajlar, acik, haritaAcik, mesajBuyuk, akisRef]);


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
        // Mobilde harita çekilir: esnaf düzenlediği yeri görsün.
        if (!window.matchMedia("(min-width: 640px)").matches) {
          setHaritaAcik(false);
        }
      },
    });

  // 2026-08-22: "sayfada dolaşan rehber" — panel ilk açıldığında henüz
  // hiçbir alan seçili değilse, sırayı elle aramaya gerek kalmadan ilk
  // eksik alanı (önce zorunlu, sonra kalite — sonrakiRehberAlan zaten bu
  // sırayı uyguluyor) otomatik seçer. Kullanıcı istediği alana da hâlâ
  // doğrudan tıklayabilir (useFieldSelection'daki global dinleyici).
  useEffect(() => {
    if (!acik || seciliAlan || tanisma) return;
    const ilkEksik = sonrakiRehberAlan(yerelTaslak, null, atlanmisAlanlar);
    if (ilkEksik) alanSec(ilkEksik.anahtar);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [acik]);

  // Faz C2/D3 polish: hızlı cevap düğmelerinin ilk gerçek kullanımı —
  // otomatik doldurma mesajındaki "Başlayalım" düğmesi, panel ilk
  // açıldığındaki otomatik-seçimle (yukarıdaki `acik`/`seciliAlan` efekti)
  // aynı mantığı kullanıcı isteğiyle tekrar tetikler.
  const handleHizliCevap = (payload: string) => {
    if (payload === "onay_tamam" && siradaki) {
      siradaki(); setSiradaki(null); return;
    }
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
    alanaGecVeyaBitir: (...args) => setSiradaki(() => () => alanaGecVeyaBitir(...args)),
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
        const liste = hazirlananEtiketler.map((etiket) => `✓ ${etiket}`).join("\n");
        mesajEkle(
          "asistan",
          `Vitrini kategorine göre uyarladım:\n${liste}\n\nŞimdi senden gerçek bilgiler almam gerekiyor: işletme adın, WhatsApp'ın, adresin ve çalışma saatlerin.`,
          [{ label: "Başlayalım", payload: "ilk_eksik_alana_git" }],
          "✨"
        );
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
  const yonetimOnerisiSoylendiRef = useRef(false);
  useEffect(() => {
    if (!acik || !yerelTaslak.is_published || yonetimOnerisiSoylendiRef.current) return;
    yonetimOnerisiSoylendiRef.current = true;

    // Faz F: performans varsa önce onu söyler.
    if (haftalikPerformans && haftalikPerformans.goruntuleme > 0) {
      const satirlar = [
        `Bu hafta ${haftalikPerformans.goruntuleme} kişi vitrinini gördü.`,
        haftalikPerformans.whatsapp_tiklama > 0
          ? `${haftalikPerformans.whatsapp_tiklama} kişi WhatsApp'a geçti.`
          : null,
        haftalikPerformans.en_cok_goruntulenen_urun
          ? `En çok görüntülenen ürün: ${haftalikPerformans.en_cok_goruntulenen_urun}.`
          : null,
      ].filter(Boolean);
      mesajEkle("asistan", satirlar.join(" "), undefined, "📊");
    }

    const oneriler = yonetimOnerileriUret(yerelTaslak, urunFiyatsizSayisi, urunAciklamasizSayisi);
    if (oneriler.length === 0) return;
    const baslik =
      oneriler.length === 1
        ? "Vitrininde bugün ilgilenmen gereken bir şey var:"
        : `Vitrininde bugün ilgilenmen gereken ${oneriler.length} şey var:`;
    mesajEkle(
      "asistan",
      `${baslik}\n${oneriler.map((o, i) => `${i + 1}. ${o.mesaj}`).join("\n")}`
    );
  }, [acik, yerelTaslak, urunFiyatsizSayisi, urunAciklamasizSayisi, haftalikPerformans, mesajEkle]);

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
      {/* Sayfada dolaşan rehber — panel açık ve bir alan seçiliyken,
       * hedef alanın üzerinde/yanında görünür (bkz. SpotlightGuide). */}
      {acik && haritaAcik && (
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

      {/* Canonical Vixrex düğmesi */}
      <button
        type="button"
        onClick={() => {
          const yeni = !acik;
          setAcik(yeni);
          // Harita açılmaz (Faz A, Tek Asistan planı, 2026-09-02): maskot
          // rehberi başlatır, aşağıdaki etki ilk eksik alanı seçer, sayfada
          // sembol ve balon görünür, vitrin görünür kalır. Harita yalnız
          // balondaki ☰ ile ("Tüm alanlar") elle açılır — masaüstünde de.
          //
          // Tek istisna: doldurulacak alan kalmadıysa seçilecek bir şey de
          // yok — o zaman harita otomatik açılır, yoksa asistan açılmış
          // ama ekranda hiçbir şey yokmuş gibi görünürdü.
          const yapilacakVar = Boolean(
            sonrakiRehberAlan(yerelTaslak, null, atlanmisAlanlar),
          );
          setHaritaAcik(yeni && !yapilacakVar);
        }}
        className={`${acik ? "hidden" : ""} fixed bottom-5 right-5 z-[75] flex h-14 w-14 items-center justify-center rounded-full bg-[#0B1730] text-[#F7FBFF] shadow-lg transition hover:bg-[#112448] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#57B7FF]`}
        aria-label="Vixrex Asistan"
        aria-expanded={acik}
      >
        <VixrexAvatar size={48} decorative />
      </button>

      {acik && (
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
        // düzeltmesi, iki turda): tuvalde asistan sağda 460px, EKRANIN
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
        <div data-owner-assistant="compact" data-expanded={haritaAcik} className="fixed inset-x-3 bottom-3 z-[75] flex max-h-[min(70dvh,640px)] flex-col overflow-y-auto rounded-3xl border border-sky-200/15 bg-[#101d29] text-slate-100 shadow-2xl sm:inset-x-auto sm:bottom-5 sm:right-5 sm:w-[400px]">
          <div className="flex shrink-0 items-center justify-between px-4 pt-2 text-xs text-slate-400">
            <button type="button" className="min-h-9 hover:text-white" onClick={() => setHaritaAcik(!haritaAcik)} aria-expanded={haritaAcik}>{haritaAcik ? "Ayrıntıları kapat" : "Menü · Vitrinini koru"}</button>
            <button type="button" aria-label="Asistanı küçült" className="h-9 w-9" onClick={() => setAcik(false)}>−</button>
          </div>
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
          {haritaAcik && <ChatTopBar
            rapor={rapor}
            onKapat={() => setHaritaAcik(false)}
          />}

          {haritaAcik && hesapBagliDegil ? <section aria-label="Vitrinini koru"><p className="px-4 pt-3 text-sm text-slate-300">Vitrinin kaybolmasın; hesabına bağlayarak başka cihazlardan da ulaş.</p><HesapBaglaSeridi slug={slug} /></section> : null}

          {oturumSaniye !== null && oturumSaniye < 300 ? (
            <p className="border-b border-white/10 px-4 py-2 text-[11px] font-semibold text-amber-400">
              Oturunun bitmesine az kaldı — değişikliklerin kayıtlı.
            </p>
          ) : null}

          {haritaAcik && <UpNextList
            yerelTaslak={yerelTaslak}
            suankiAnahtar={seciliAlan?.anahtar ?? null}
            atlanmisAlanlar={atlanmisAlanlar}
            alanSec={alanSec}
            alanAtla={alanAtlandi}
          />}

          {haritaAcik && (
            <div className="min-h-0 flex-1 overflow-y-auto">
                {/* Bölüm listesi ekranın yarısını kaplıyordu; artık kapalı
                 * duran bir açılırın içinde — isteyen açar. */}
                <details className="border-b border-white/10">
                  <summary className="cursor-pointer list-none px-4 py-2.5 text-[11px] font-black uppercase tracking-[0.14em] text-slate-400 hover:text-slate-200">
                    Tüm bölümler
                  </summary>
                  <SectionProgressList yerelTaslak={yerelTaslak} alanSec={alanSec} />
                </details>

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

                {/* Hakkımızda / SSS / Kampanya / Galeri / Pazaryeri düzenleme kartları */}
                <div className="border-t border-white/10 px-4 py-3 space-y-1">
                  <p className="mb-1 text-[11px] font-semibold text-white/40 uppercase tracking-wider">İçerik Düzenleme</p>
                  <button
                    type="button"
                    onClick={() => setAboutAcik(true)}
                    className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-sm text-white/70 hover:bg-white/5 transition text-left"
                  >
                    <span>ℹ️</span>
                    <span className="flex-1 font-medium text-[13px]">Hakkımızda</span>
                    <span className="text-[10px] text-white/30">{aboutSection?.title ? "Dolu" : "Boş"}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setGaleriAcik(true)}
                    className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-sm text-white/70 hover:bg-white/5 transition text-left"
                  >
                    <span>🖼️</span>
                    <span className="flex-1 font-medium text-[13px]">Galeri</span>
                    <span className="text-[10px] text-white/30">{galleryItems && galleryItems.length > 0 ? `${galleryItems.length} görsel` : "Boş"}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setMarketplaceAcik(true)}
                    className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-sm text-white/70 hover:bg-white/5 transition text-left"
                  >
                    <span>🛒</span>
                    <span className="flex-1 font-medium text-[13px]">Pazaryeri Bağlantıları</span>
                    <span className="text-[10px] text-white/30">{marketplaceLinks && marketplaceLinks.length > 0 ? `${marketplaceLinks.length} link` : "Boş"}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setFaqAcik(true)}
                    className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-sm text-white/70 hover:bg-white/5 transition text-left"
                  >
                    <span>❓</span>
                    <span className="flex-1 font-medium text-[13px]">Sık Sorulan Sorular</span>
                    <span className="text-[10px] text-white/30">{faqItems && faqItems.length > 0 ? `${faqItems.length} soru` : "Boş"}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setKampanyaAcik(true)}
                    className="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-sm text-white/70 hover:bg-white/5 transition text-left"
                  >
                    <span>🎯</span>
                    <span className="flex-1 font-medium text-[13px]">Öne Çıkan Kampanya</span>
                    <span className="text-[10px] text-white/30">{campaignBanner?.title ? "Dolu" : "Boş"}</span>
                  </button>
                </div>
            </div>
          )}

          {/* Sohbet akışı — kendi kaydırma alanında, kendi otomatik-aşağı-
           * kaydırma mantığı (useOwnerChat.akisRef) değişmedi.
           *
           * 2026-09-03 ölçüm düzenlemesi (2. tur): "Faz G3.1: ÇIKAR sohbet
           * akışının paneli kaplaması" kararıyla bu kutu `max-h-40` (sonra
           * `max-h-[20vh]/[32vh]`) gibi SABİT bir tavana bağlanmıştı — o
           * zamanki panel tasarımında sohbet büyüyüp paneli kaplıyordu.
           * Ama şimdiki panel (Faz C) `flex flex-col` ve TOPLAM yüksekliği
           * zaten sabit (sm:top-9 sm:bottom-5) — başlık/SIRADA/yazı kutusu
           * kendi boylarını koruyor. Sabit tavan burada paneli kaplama
           * riskini önlemiyordu, tam tersi bir kusur yaratıyordu: harita
           * kapalıyken (varsayılan) hiçbir kardeş öge büyüyüp boşluğu
           * doldurmadığından tavanın altındaki alan boş kalıyor, yazı kutusu
           * panelin ortasında asılı kalıyordu (Casper canlıda gördü, ekran
           * görüntüsüyle işaretledi). `min-h-0 flex-1` — haritaAcik dolgu
           * kutusunun (yukarıda, satır ~643) zaten kullandığı desen — kalan
           * boşluğu doldurur, yazı kutusu panelin dibine yapışır; panel
           * yüksekliği sabit olduğu için taşıp "kaplama" riski yok.
           * Kaydırma şeridi ince, koyu panele uyumlu kalmaya devam ediyor
           * (bkz. .vixrex-panel-kaydirici, globals.css). */}
          <div
            ref={akisRef}
            data-message-expanded={mesajBuyuk}
            data-message-resizable={mesajTasiyor || mesajBuyuk}
            style={mesajBuyuk ? { height: "42dvh", maxHeight: "42dvh" } : undefined}
            className="vixrex-panel-kaydirici min-h-0 max-h-[32dvh] space-y-2 overflow-y-auto px-3 py-2"
          >
            {tanisma && !seciliAlan ? <p className="rounded-2xl bg-sky-100/5 px-3 py-2 text-sm">Biraz işletmenden bahseder misin?</p> : (haritaAcik ? mesajlar : mesajlar.slice(-1)).map((m) => (
              <ChatBubble key={m.id} mesaj={{ ...m, hizliCevaplar: m.hizliCevaplar?.filter(c => c.payload !== "onay_tamam").map(c => ({ ...c, label: c.payload === "onay_tamam" ? "Devam et" : c.payload.startsWith("geri_al:") ? "Yayındaki hâline döndür" : c.label })) }} onHizliCevap={handleHizliCevap} />
            ))}
          </div>

          {!haritaAcik && (mesajTasiyor || mesajBuyuk) && (
            <button type="button" aria-expanded={mesajBuyuk} onClick={() => setMesajBuyuk(!mesajBuyuk)}>
              {mesajBuyuk ? "Mesajı küçült" : "Mesajı büyüt"}
            </button>
          )}
          {siradaki && <button type="button" className="mx-3 mb-2 min-h-10 rounded-xl bg-sky-200/10 text-sm text-sky-100" onClick={() => { siradaki(); setSiradaki(null); }}>Devam et</button>}
          {actions.kaydediliyor && <p role="status" className="px-4 py-2 text-sm text-sky-200">Düzenleniyor…</p>}
          {/* HEP AÇIK giriş şeridi (Faz 3). Eskiden yazı kutusu yalnız bir
           * alana tıklanınca (SpotlightGuide balonunda) açılıyordu; tıklamayan
           * esnaf "hangi alanı değiştireceğini bilmiyorum" cevabını alıyordu.
           * Artık buraya her zaman yazılabilir: alan seçiliyse o alana
           * kaydeder, seçili değilse akıllı motor cümleden alanı kendi bulur
           * (useOwnerActions.gonder). TEK giriş bileşeni — StepCard'ın da
           * kullandığı FieldInputArea, ikinci bir kopyası değil; görsel/
           * seçim/il-ilçe/GPS için gereken özel kutuları da o çizer. */}
          <div hidden={actions.kaydediliyor} className="shrink-0 border-t border-white/10 px-3 py-2">
            <FieldInputArea
              compact
              trailing={<button type="button" aria-label="Vixrex Asistan ayrıntıları" aria-expanded={haritaAcik} onClick={() => setHaritaAcik(!haritaAcik)} className="h-12 w-12 shrink-0 rounded-full focus-visible:outline focus-visible:outline-sky-300"><VixrexAvatar size={44} decorative /></button>}
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
              gonder={async () => { if (giris.trim()) setTanisma(false); setSiradaki(null); await actions.gonder(); }}
              alanAtla={actions.alanAtla}
              canliyaDondur={fieldRestore.canliyaDondur}
              sonrayaBirak={sonrayaBirak}
              onIlDegisti={handleIlDegisti}
              onIlceDegisti={handleIlceDegisti}
              onGpsKonumAl={handleGpsKonumAl}
              gpsLoading={gpsLoading}
            />
          </div>

          {/* Adım 9 (sahiplik ekranı gözden geçirme, 2026-09-03): Yayınla
           * eskiden yalnız "Tüm alanlar" (haritaAcik) açıkken görünen ikincil
           * bir bölümün içindeydi — panelin asıl SONUCU ikinci sekmede
           * saklanıyordu. Artık composer'ın hemen altında, harita açık
           * olsun olmasın hep görünen sabit bir şerit. */}
          <div hidden={!haritaAcik} className="shrink-0 border-t border-white/10 px-4 py-3">
            <p className="pb-2 text-[11px] font-semibold text-slate-400">
              {yayinlanmamisDegisiklik
                ? "Yayınlanmamış değişikliklerin var — hazır olduğunda yayınla."
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
            />
          </div>
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
