interface FaturaAkisBasligiProps {
  adim: "sec" | "okunuyor" | "urunler" | "yaziliyor" | "bitti";
  baslik: string;
  aciklama: string;
  yayinDogrulandi?: boolean;
}

const ADIMLAR = ["Fatura", "Hazırlama", "Kontrol", "Yayın"];

export function FaturaAkisBasligi({ adim, baslik, aciklama, yayinDogrulandi = false }: FaturaAkisBasligiProps) {
  const aktif = adim === "sec" ? 0 : adim === "okunuyor" ? 1 : adim === "bitti" ? 3 : 2;
  return (
    <header className="fatura-akis-basligi">
      <ol className="fatura-ilerleme" aria-label="Faturadan vitrine adımları">
        {ADIMLAR.map((etiket, index) => (
          <li key={etiket} className={index < aktif || yayinDogrulandi ? "tamam" : index === aktif ? "aktif" : undefined}
            aria-current={index === aktif ? "step" : undefined}>
            <span aria-hidden="true">{index < aktif || yayinDogrulandi ? "✓" : index + 1}</span>
            {etiket}
          </li>
        ))}
      </ol>
      <div className="fatura-asistan">
        <Image src="/images/vixrex_v_crystal_mascot.webp" alt="" width={20} height={20} />
        <div>
          <span className="fatura-asistan-adi">Vixrex Asistan</span>
          <h3>{baslik}</h3>
          <p className="fatura-aciklama">{aciklama}</p>
        </div>
      </div>
    </header>
  );
}
import Image from "next/image";
