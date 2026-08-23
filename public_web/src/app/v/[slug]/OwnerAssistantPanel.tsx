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
import { PublishBar } from "./components/PublishBar";
import { VixrexAvatar } from "./components/VixrexAvatar";
import { SpotlightGuide } from "./components/SpotlightGuide";
import { alanOnemi, asamaDolulugu, sonrakiRehberAlan } from "@/lib/vitrinReadiness";
import type { AssistantHandoffV1 } from "@/lib/assistantHandoff";

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
}

export default function OwnerAssistantPanel({
  slug,
  draftData,
  assistantHandoff = null,
  atlananAlanlar = null,
  premiumAktifMi = false,
}: Props) {
  const [acik, setAcik] = useState(false);

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
  const { mesajlar, mesajEkle, akisRef } = useOwnerChat(rapor, assistantHandoff);

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
      onAlanSecildi: () => setAcik(true),
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

  return (
    <>
      {/* Sayfada dolaşan rehber — panel açık ve bir alan seçiliyken,
       * hedef alanın üzerinde/yanında görünür (bkz. SpotlightGuide). */}
      {acik && (
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
          // Taslak değişti = sayfa da değişmiş olabilir (kaydetme artık
          // sunucudan tazeliyor, Faz 2) → balon konumunu yeniden ölç.
          olcumTetikleyici={yerelTaslak}
          gecisSuruyor={gecisSuruyor}
        />
      )}

      {/* Canonical Vixrex düğmesi */}
      <button
        type="button"
        onClick={() => setAcik((v) => !v)}
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

      {acik && (
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
          <ChatTopBar rapor={rapor} onKapat={() => setAcik(false)} />

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
    </>
  );
}
