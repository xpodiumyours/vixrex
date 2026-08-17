import type { EksikOnem, OnemDolulugu } from "@/lib/vitrinReadiness";

interface Props {
  dolulugu: Record<EksikOnem, OnemDolulugu>;
  temelTamam: boolean;
  eksikTemelSayisi: number;
}

const ASAMALAR: ReadonlyArray<{
  onem: EksikOnem;
  renk: string;
  /** Şeritteki genişlik oranı — plan G3.1: 4/7/32 alan sayısı orantısı
   * okunmaz olurdu, son sütun bilinçli sıkıştırıldı. */
  flex: number;
}> = [
  { onem: "temel", renk: "bg-red-300", flex: 4 },
  { onem: "kalite", renk: "bg-sky-400", flex: 7 },
  { onem: "istege-bagli", renk: "bg-slate-400", flex: 5 },
];

// Faz G3 (Tek Asistan planı, G3.1): üç önem sınıfını üç görünür aşamaya
// çeviren şerit. Esnaf "bitti mi?" sorusunu buna bakarak yanıtlayabilsin
// diye — eskiden 43 alan tek bir hap yığınında duruyordu, sıra da kaç
// adım kaldığı da belli değildi.
export function StageMeter({ dolulugu, temelTamam, eksikTemelSayisi }: Props) {
  return (
    <div className="border-b border-white/10 px-4 py-3">
      <div className="flex h-1.5 gap-1 overflow-hidden rounded-full">
        {ASAMALAR.map(({ onem, renk, flex }) => {
          const { dolu, toplam } = dolulugu[onem];
          const oran = toplam > 0 ? dolu / toplam : 1;
          return (
            <div
              key={onem}
              style={{ flex }}
              className="relative overflow-hidden rounded-full bg-white/10"
            >
              <div
                className={`h-full ${renk} transition-all`}
                style={{ width: `${Math.round(oran * 100)}%` }}
              />
            </div>
          );
        })}
      </div>
      <p className="mt-2 text-[11px] leading-relaxed text-slate-400">
        {temelTamam
          ? "Vitrinin yayına hazır. Buradan sonrası onu güzelleştirmek."
          : `Yayınlamak için ${eksikTemelSayisi} zorunlu alan daha gerekiyor.`}
      </p>
    </div>
  );
}
