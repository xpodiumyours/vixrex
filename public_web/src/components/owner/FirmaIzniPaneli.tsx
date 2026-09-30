"use client";

import { useCallback, useEffect, useState } from "react";

interface Talep {
  talepKimligi: string;
  durum: "hazirlandi" | "gonderim_bekliyor" | "gonderildi" | "cevaplandi" | "geri_cekildi";
  isteyen: "owner" | "vixrex";
  mesaj: string;
  ornekAdres: string;
  urunSayisi: number;
}

interface IzinYaniti {
  firmaAdi: string;
  etiket: string;
  izin: { durum: string; gecerli: boolean; gecerlilik: string | null };
  talep: Talep | null;
}

interface FirmaIzniPaneliProps {
  storeSlug: string;
  islemKimligi: string;
}

export default function FirmaIzniPaneli({ storeSlug, islemKimligi }: FirmaIzniPaneliProps) {
  const [veri, setVeri] = useState<IzinYaniti | null>(null);
  const [hata, setHata] = useState<string | null>(null);
  const [calisiyor, setCalisiyor] = useState(false);
  const [kopyalandi, setKopyalandi] = useState(false);

  const yukle = useCallback(async () => {
    try {
      const cevap = await fetch(
        `/api/firma-izni?slug=${encodeURIComponent(storeSlug)}&islemKimligi=${encodeURIComponent(islemKimligi)}`,
      );
      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        setHata(govde && typeof govde.hata === "string" ? govde.hata : "İzin durumu okunamadı.");
        return;
      }
      setHata(null);
      setVeri(govde as IzinYaniti);
    } catch {
      setHata("İzin durumu okunamadı.");
    }
  }, [islemKimligi, storeSlug]);

  useEffect(() => {
    void yukle();
  }, [yukle]);

  async function talepEt(secim: "owner" | "vixrex") {
    setCalisiyor(true);
    setHata(null);
    try {
      const cevap = await fetch("/api/firma-izni", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, islemKimligi, secim }),
      });
      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        throw new Error(govde && typeof govde.hata === "string" ? govde.hata : "Talep açılamadı.");
      }
      setVeri(govde as IzinYaniti);
    } catch (err) {
      setHata(err instanceof Error ? err.message : "Talep açılamadı.");
    }
    setCalisiyor(false);
  }

  async function gonderdimIsaretle(talepKimligi: string) {
    setCalisiyor(true);
    setHata(null);
    try {
      const cevap = await fetch("/api/firma-izni", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, talepKimligi, islem: "gonderildi" }),
      });
      if (!cevap.ok) throw new Error("Talep güncellenemedi.");
      await yukle();
    } catch (err) {
      setHata(err instanceof Error ? err.message : "Talep güncellenemedi.");
    }
    setCalisiyor(false);
  }

  async function metniKopyala(metin: string) {
    try {
      await navigator.clipboard.writeText(metin);
      setKopyalandi(true);
    } catch {
      setKopyalandi(false);
    }
  }

  if (!veri) {
    return hata ? <p className="fatura-hata">{hata}</p> : null;
  }

  const talep = veri.talep;
  const aktifTalepVar =
    talep !== null &&
    (talep.durum === "hazirlandi" || talep.durum === "gonderim_bekliyor" || talep.durum === "gonderildi");
  const izinVar = veri.izin.durum === "izin_verildi" && veri.izin.gecerli;
  const reddedildi = veri.izin.durum === "reddedildi" || veri.izin.durum === "geri_cekildi";

  return (
    <section className="fatura-izin">
      <h4>{veri.firmaAdi || "Firma"} için kullanım izni</h4>
      <p>
        <strong>{veri.etiket}</strong>
      </p>
      <p className="fatura-aciklama">
        Ürünler çalışan vitrininde şimdiden görünebilir. Firmadan veri ve görsel kullanım izni ayrıca
        istenir; senin talebin firma onayı yerine geçmez.
      </p>

      {hata && <p className="fatura-hata">{hata}</p>}

      {!izinVar && !reddedildi && !aktifTalepVar && (
        <div className="fatura-izin-secim">
          <button type="button" onClick={() => void talepEt("owner")} disabled={calisiyor}>
            Ben isteyeceğim
          </button>
          <button type="button" onClick={() => void talepEt("vixrex")} disabled={calisiyor}>
            Vixrex benim için istesin
          </button>
        </div>
      )}

      {aktifTalepVar && talep && talep.isteyen === "owner" && (
        <div className="fatura-izin-metin">
          <textarea readOnly value={talep.mesaj} rows={8} />
          <button type="button" onClick={() => void metniKopyala(talep.mesaj)}>
            {kopyalandi ? "Kopyalandı" : "Metni kopyala"}
          </button>
          {talep.durum === "hazirlandi" && (
            <button
              type="button"
              onClick={() => void gonderdimIsaretle(talep.talepKimligi)}
              disabled={calisiyor}
            >
              Firmaya gönderdim
            </button>
          )}
        </div>
      )}

      {aktifTalepVar && talep && talep.isteyen === "vixrex" && (
        <p className="fatura-aciklama">
          {talep.durum === "gonderim_bekliyor"
            ? "Talebin sıraya alındı. Firmaya gönderildiğinde burada “gönderildi” yazacak."
            : "Talep firmaya gönderildi. Cevap gelince burada görünecek."}
        </p>
      )}
    </section>
  );
}
