"use client";

import { useEffect, useState } from "react";
import { useOwnerDraft } from "./hooks/useOwnerDraft";
import { useOwnerChat } from "./hooks/useOwnerChat";
import { useFieldSelection } from "./hooks/useFieldSelection";
import { useOwnerActions } from "./hooks/useOwnerActions";
import { ChatBubble } from "./components/ChatBubble";
import { ChatTopBar } from "./components/ChatTopBar";
import { StageMeter } from "./components/StageMeter";
import { StepCard } from "./components/StepCard";
import { UpNextList } from "./components/UpNextList";
import { SectionProgressList } from "./components/SectionProgressList";
import { PublishBar } from "./components/PublishBar";
import { VixrexAvatar } from "./components/VixrexAvatar";
import { alanOnemi, asamaDolulugu } from "@/lib/vitrinReadiness";
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
}

export default function OwnerAssistantPanel({
  slug,
  draftData,
  assistantHandoff = null,
  atlananAlanlar = null,
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

  const { seciliAlan, giris, girisRef, setGiris, alanSec, alanaGecVeyaBitir } =
    useFieldSelection({
      yerelTaslak,
      atlanmisAlanlar,
      mesajEkle,
      onAlanSecildi: () => setAcik(true),
    });

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

  // Faz G3 (Tek Asistan planı, G3.1): üç aşamalı ilerleme şeridi için
  // önem başına dolu/toplam — şemadan hesaplanır, elle sayılmaz.
  const dolulugu = asamaDolulugu(yerelTaslak, atlanmisAlanlar);
  const eksikTemelSayisi = rapor.eksikler.filter((e) => e.onem === "temel").length;

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

  return (
    <>
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
        <div className="fixed bottom-24 right-5 z-[75] flex w-[min(24rem,calc(100vw-2.5rem))] flex-col rounded-2xl border border-white/10 bg-[#0B1120] shadow-2xl">
          <ChatTopBar rapor={rapor} onKapat={() => setAcik(false)} />

          <StageMeter
            dolulugu={dolulugu}
            temelTamam={rapor.temelTamam}
            eksikTemelSayisi={eksikTemelSayisi}
          />

          <StepCard
            seciliAlan={seciliAlan}
            giris={giris}
            girisRef={girisRef}
            kaydediliyor={actions.kaydediliyor}
            hazirGorseller={actions.hazirGorseller}
            hazirYukleniyor={actions.hazirYukleniyor}
            setGiris={setGiris}
            gorselYukle={actions.gorselYukle}
            hazirGorselleriAc={actions.hazirGorselleriAc}
            hazirGorselSec={actions.hazirGorselSec}
            gonder={actions.gonder}
            alanAtla={actions.alanAtla}
            sonrayaBirak={sonrayaBirak}
          />

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
          />

          {/* Sohbet akışı — kayıt olarak durur, panelin ortasını kaplamaz
           * (Faz G3, G3.1: "ÇIKAR: sohbet akışının paneli kaplaması"). */}
          <div ref={akisRef} className="max-h-40 space-y-2 overflow-y-auto px-4 py-3">
            {mesajlar.map((m) => (
              <ChatBubble key={m.id} mesaj={m} />
            ))}
          </div>
        </div>
      )}
    </>
  );
}
