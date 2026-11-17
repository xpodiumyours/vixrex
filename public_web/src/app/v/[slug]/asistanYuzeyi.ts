export type AsistanYuzeyGirdisi = {
  masaustu: boolean;
  genisEkran: boolean;
  acik: boolean;
  haritaAcik: boolean;
  mobilGecmisAcik: boolean;
};

export type AsistanYuzeyi = {
  telefonCubugu: boolean;
  panelKutusu: boolean;
  govde: "sohbet";
  detayAcik: boolean;
};

export function alanSecimiPaneliAcarMi(): boolean {
  return false;
}

export function asistanYuzeyi(girdi: AsistanYuzeyGirdisi): AsistanYuzeyi {
  const panelAcik = girdi.masaustu ? girdi.acik : girdi.mobilGecmisAcik;

  return {
    telefonCubugu: !girdi.masaustu && !girdi.genisEkran,
    panelKutusu: panelAcik && (girdi.masaustu || girdi.genisEkran),
    govde: "sohbet",
    detayAcik: girdi.haritaAcik,
  };
}
