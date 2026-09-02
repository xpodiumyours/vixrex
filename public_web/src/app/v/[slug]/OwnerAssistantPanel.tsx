"use client";

import { useEffect, useState } from "react";
import { useOwnerDraft } from "./hooks/useOwnerDraft";
import { useOwnerChat } from "./hooks/useOwnerChat";
import { useFieldSelection } from "./hooks/useFieldSelection";
import { useOwnerActions } from "./hooks/useOwnerActions";
import { useFieldRestore } from "./hooks/useFieldRestore";
import { ChatBubble } from "./components/ChatBubble";
import { ChatTopBar } from "./components/ChatTopBar";
import { StageMeter } from "./components/StageMeter";
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
import { alanOnemi, asamaDolulugu, sonrakiRehberAlan } from "@/lib/vitrinReadiness";
import type { AssistantHandoffV1 } from "@/lib/assistantHandoff";
import { taslakClientId } from "@/lib/canliVitrinSenkron";
import { useRouter } from "next/navigation";
import { gpsAdresiniCoz } from "@/lib/konumCozumleme";

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

interface Props {
  slug: string;
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
  flowState = null,
}: Props & { flowState?: Record<string, unknown> | null }) {
  const [acik, setAcik] = useState(() => Boolean(flowState && typeof flowState === "object" && (flowState as { current_step?: string }).current_step));
  // Harita = "Tüm alanlar" paneli. Faz 4 (Casper, 2026-08-22): mobilde
  // panel bütün sayfayı kapatıyordu — "sadece Vixrex maskotu olsun,
  // kutucuklarda zaten ne yapılacağı yazıyor". Artık alan seçilince
  // mobilde harita kapanır; sayfada yalnız sembol ve balon kalır.
  // Masaüstünde yer bol, harita açık durmaya devam eder.
  const [haritaAcik, setHaritaAcik] = useState(false);
  const [masaustu, setMasaustu] = useState(false);

  useEffect(() => {
    const sorgu = window.matchMedia("(min-width: 640px)");
    const guncelle = () => setMasaustu(sorgu.matches);
    guncelle();
    sorgu.addEventListener("change", guncelle);
    return () => sorgu.removeEventListener("change", guncelle);
  }, []);

  // PR4-C14: aktif kurulum/kiralama akışı varsa asistan açık ve sıradaki alan odaklı başlar
  useEffect(() => {
    if (flowState && typeof flowState === "object" && (flowState as { current_step?: string }).current_step) {
      setAcik(true);
      const isDesktop = window.matchMedia("(min-width: 640px)").matches;
      setHaritaAcik(isDesktop);
    }
  }, [flowState]);

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
    if (!acik || seciliAlan) return;
    const ilkEksik = sonrakiRehberAlan(yerelTaslak, null, atlanmisAlanlar);
    if (ilkEksik) alanSec(ilkEksik.anahtar);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [acik]);

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

  // Faz G3 (Tek Asistan planı, G3.1): üç aşamalı ilerleme şeridi için
  // önem başına dolu/toplam — şemadan hesaplanır, elle sayılmaz.
  const dolulugu = asamaDolulugu(yerelTaslak, atlanmisAlanlar);
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
      {acik && !(!masaustu && haritaAcik) && (
        <SpotlightGuide
          seciliAlan={seciliAlan}
          giris={giris}
          girisRef={girisRef}
          kaydediliyor={actions.kaydediliyor}
          geriAliniyor={fieldRestore.geriAliniyor}
          hazirGorseller={actions.hazirGorseller}
          hazirYukleniyor={actions.hazirYukleniyor}
          setGiris={setGiris}
          gorselYukle={actions.gorselYukle}
          hazirGorselleriAc={actions.hazirGorselleriAc}
          hazirGorselSec={actions.hazirGorselSec}
          gonder={actions.gonder}
          alanAtla={actions.alanAtla}
          canliyaDondur={fieldRestore.canliyaDondur}
          sonrayaBirak={sonrayaBirak}
          onKapat={rehberiKapat}
          olcumTetikleyici={yerelTaslak}
          gecisSuruyor={gecisSuruyor}
          onHaritaAc={() => setHaritaAcik(true)}
          mevcutIl={mevcutIl}
          mevcutIlce={mevcutIlce}
          onIlDegisti={handleIlDegisti}
          onIlceDegisti={handleIlceDegisti}
          onGpsKonumAl={handleGpsKonumAl}
          gpsLoading={gpsLoading}
        />
      )}

      {/* Canonical Vixrex düğmesi */}
      <button
        type="button"
        onClick={() => {
          const yeni = !acik;
          setAcik(yeni);
          // MOBİLDE harita açılmaz (Casper, 2026-08-22: "asistan maskotuna
          // tıklayınca yine sayfa kapanıyor"). Maskot rehberi başlatır:
          // aşağıdaki etki ilk eksik alanı seçer, sayfada sembol ve balon
          // görünür, vitrin görünür kalır. Harita yalnız balondaki ☰ ile
          // açılır. Masaüstünde harita yan panel, sayfayı kapatmıyor.
          //
          // Tek istisna: doldurulacak alan kalmadıysa seçilecek bir şey de
          // yok — o zaman mobilde de harita açılır, yoksa asistan açılmış
          // ama ekranda hiçbir şey yokmuş gibi görünürdü.
          const yapilacakVar = Boolean(
            sonrakiRehberAlan(yerelTaslak, null, atlanmisAlanlar),
          );
          setHaritaAcik(yeni && (masaustu || !yapilacakVar));
        }}
        className="fixed bottom-5 right-5 z-[75] flex items-center gap-2 rounded-full bg-gradient-to-r from-blue-600 to-blue-700 px-4 py-3 text-white shadow-lg shadow-blue-500/30 hover:shadow-blue-500/50 transition"
        aria-label="Vixrex Asistan"
        aria-expanded={acik}
      >
        <VixrexAvatar size={28} decorative />
        <span className="text-sm font-semibold hidden sm:inline">Vixrex Asistan</span>
        {!rapor.temelTamam && (
          <span className="ml-1 rounded-full bg-amber-400 px-2 py-0.5 text-[10px] font-bold text-slate-900">
            %{rapor.yuzde}
          </span>
        )}
      </button>

      {acik && haritaAcik && (
        // 2026-08-22 mobil/masaüstü uyum düzeltmesi: eski className yalnız
        // `bottom-24 right-5` idi (üst sınır YOKTU) — 9 bölümlük
        // SectionProgressList tamamen açıldığında panel içeriği ekranın
        // üstünden taşıp kayboluyordu, hiçbir yerde tek bir kaydırma alanı
        // içermediği için o kısma ulaşmanın yolu yoktu (canlıda görüldü).
        // Artık mobilde (sm altı) üst+alt sınır birlikte sabit — yükseklik
        // otomatik hesaplanır; masaüstünde eski konum korunur ama
        // max-h ile aynı taşma bir daha olamaz. Ortadaki gövde tek kaydırma
        // alanı, başlık sabit kalır.
        <div className="fixed inset-x-3 top-16 bottom-24 z-[75] flex flex-col overflow-hidden rounded-2xl border border-white/10 bg-[#0B1120] shadow-2xl sm:inset-x-auto sm:top-auto sm:right-5 sm:w-[min(24rem,calc(100vw-2.5rem))] sm:max-h-[calc(100vh-8rem)]">
          <ChatTopBar
            rapor={rapor}
            onKapat={() => (masaustu ? setAcik(false) : setHaritaAcik(false))}
          />

          <div className="min-h-0 flex-1 overflow-y-auto">
            <StageMeter
              dolulugu={dolulugu}
              temelTamam={rapor.temelTamam}
              eksikTemelSayisi={eksikTemelSayisi}
            />

            {/* StepCard/FieldInputArea artık burada YOK — 2026-08-22:
             * kullanıcı test etti, panelin tepesindeki sabit kutu spot
             * ışığının gösterdiği alandan görsel olarak kopuk kalıyordu
             * ("kutucuklar açılıyor ama içine yazılmıyor" geri bildirimi).
             * Gerçek giriş alanı artık yalnız SpotlightGuide'ın balonunda —
             * ikinci bir kopyası yok. */}

            <UpNextList
              yerelTaslak={yerelTaslak}
              suankiAnahtar={seciliAlan?.anahtar ?? null}
              atlanmisAlanlar={atlanmisAlanlar}
              alanSec={alanSec}
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

          {/* Sohbet akışı — kendi kaydırma alanında sabit yükseklik kalır
           * (Faz G3, G3.1: "ÇIKAR: sohbet akışının paneli kaplaması") —
           * yukarıdaki gövdeden bağımsız, kendi otomatik-aşağı-kaydırma
           * mantığı (useOwnerChat.akisRef) değişmedi. */}
          <div
            ref={akisRef}
            className="max-h-40 shrink-0 space-y-2 overflow-y-auto border-t border-white/10 px-4 py-3"
          >
            {mesajlar.map((m) => (
              <ChatBubble key={m.id} mesaj={m} />
            ))}
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
