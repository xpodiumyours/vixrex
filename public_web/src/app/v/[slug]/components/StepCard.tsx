import type { OwnerActionLifecycleResult } from "@/lib/ownerActionLifecycle";
import type { VitrinField } from "@/lib/vitrinFieldSchema";
import { SECTION_LABELS } from "@/lib/vitrinFieldSchema";
import { alanOnemi, type EksikOnem } from "@/lib/vitrinReadiness";
import { FieldInputArea } from "./FieldInputArea";
import type { HazirGorsel } from "../hooks/useOwnerActions";

const ONEM_ETIKETI: Record<EksikOnem, { yazi: string; sinif: string }> = {
  temel: { yazi: "Zorunlu", sinif: "bg-red-500/15 text-red-300" },
  kalite: { yazi: "Kalite", sinif: "bg-sky-500/15 text-sky-300" },
  "istege-bagli": { yazi: "İsteğe bağlı", sinif: "bg-white/10 text-slate-400" },
};

interface Props {
  seciliAlan: VitrinField | null;
  giris: string;
  girisRef: React.RefObject<HTMLTextAreaElement | null>;
  kaydediliyor: boolean;
  geriAliniyor: boolean;
  hazirGorseller: HazirGorsel[];
  hazirYukleniyor: boolean;
  setGiris: (v: string) => void;
  gorselYukle: (dosya: File) => Promise<void>;
  hazirGorselleriAc: () => Promise<void>;
  hazirGorselSec: (url: string) => Promise<void>;
  // Akıllı Motor sonrası: gönderim artık sessizce bitmiyor, yaşam döngüsü
  // sonucu (başarılı/kuyruğa alındı/hata) döndürüyor — FieldInputArea bu
  // sonucu kullanıyor, StepCard da aynı sözleşmeyi taşımak zorunda.
  gonder: () => Promise<OwnerActionLifecycleResult>;
  alanAtla: () => Promise<void>;
  canliyaDondur: () => Promise<void>;
  sonrayaBirak?: () => void;
}

// Faz G3 (Tek Asistan planı, G3.1) — panelin ana işi: önem etiketi + bölüm
// adı + alan adı + ne işe yaradığı + giriş. `FieldInputArea`'yı sarar,
// girişin kendi mantığına dokunmaz.
//
// DÜRÜSTLÜK NOTU: "ne işe yaradığı" cümlesi şemadaki `ipucu`'dan gelir.
// Plan bunun her alan için yazılmasını istiyor (bugün 43 alanın 4'ünde
// dolu) — bu içerik yazımı ayrı bir iş; burada uydurma metin ÜRETİLMEDİ,
// `ipucu` boşsa satır hiç çizilmez.
export function StepCard(props: Props) {
  const { seciliAlan } = props;
  const onem = seciliAlan ? alanOnemi(seciliAlan) : null;

  return (
    <div className="border-b border-white/10 bg-sky-500/[0.04] px-4 py-3">
      {seciliAlan && onem && (
        <div className="mb-2">
          <div className="mb-1 flex items-center gap-2">
            <span
              className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide ${ONEM_ETIKETI[onem].sinif}`}
            >
              {ONEM_ETIKETI[onem].yazi}
            </span>
            <span className="text-[11px] text-slate-500">
              {SECTION_LABELS[seciliAlan.bolum]}
            </span>
          </div>
          <p className="text-[17px] font-extrabold text-white">{seciliAlan.etiket}</p>
          {seciliAlan.ipucu && (
            <p className="mt-1 text-[13px] leading-relaxed text-slate-400">
              {seciliAlan.ipucu}
            </p>
          )}
        </div>
      )}
      <FieldInputArea {...props} />
    </div>
  );
}
