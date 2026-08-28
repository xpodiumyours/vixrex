"use client";

import Link from "next/link";
import { useState } from "react";
import {
  ASISTAN_ADIMLARI,
  ASISTAN_BITIS,
  ASISTAN_KARSILAMA,
  asistanHandoffOlustur,
  taslagiKaydet,
  type AsistanCevaplari,
} from "@/lib/landingAsistanAkisi";
import { validateField } from "@/lib/vitrinFieldValidation";

/**
 * Ana sayfadaki Vixrex Asistan — telefon mockup'ının içinde çalışır.
 *
 * DEMO KİPİ: hiçbir şey veritabanına yazılmaz. Ziyaretçi giriş yapmamıştır;
 * burada kayıt oluşturmak çöp veri üretirdi. Cevaplar tarayıcı oturumunda
 * tutulur ve kayıttan sonra vitrin kurulumuna taşınır.
 *
 * NEDEN GERÇEK, NEDEN MAKET DEĞİL: buradaki sohbet önceden sabit metinli
 * bir resimdi ve "senin işletmen için de 2 dakikada beraber hazırlayalım
 * mı?" diyordu — kullanıcı yazamıyordu. Tam ikna anında tutulmayan bir
 * sözdü. Artık gerçekten soruyor ve cevabı alıyor.
 *
 * TEK KAYNAK: tek bir kullanıcı metni burada yazılı değil. Hepsi
 * `shared/vixrex_mesajlar.json` katalogundan geliyor — Flutter da aynı
 * dosyayı okuyor. Bu dosyaya elle metin eklemek "tek beyin" iddiasını
 * bozar ve sözleşme testi bunu kırmızıya düşürür.
 */
export function LandingAsistanSohbeti({
  initialName = "",
  onClose,
}: {
  initialName?: string;
  onClose?: () => void;
}) {
  const tasinanIsletmeAdi = initialName.trim();
  const [adim, setAdim] = useState(tasinanIsletmeAdi ? 1 : -1); // -1: karşılama
  const [girdi, setGirdi] = useState("");
  const [cevaplar, setCevaplar] = useState<AsistanCevaplari>(() => {
    if (!tasinanIsletmeAdi) return {};
    const baslangic = { name: initialName.trim() };
    taslagiKaydet(baslangic);
    return baslangic;
  });
  const [il, setIl] = useState("");
  const [ilce, setIlce] = useState("");
  const [adres, setAdres] = useState("");
  const [hata, setHata] = useState("");
  const [gpsBekleniyor, setGpsBekleniyor] = useState(false);

  const bitti = adim >= ASISTAN_ADIMLARI.length;
  const aktif = bitti ? null : ASISTAN_ADIMLARI[adim];

  function ilerle(deger: string) {
    if (!aktif || !aktif.cevapAnahtari) return;
    const semaAnahtari = aktif.kolonlar[0] === "name" ? "isletmeAdi" : aktif.kolonlar[0];
    const sonuc = validateField(semaAnahtari, deger);
    if (!sonuc.ok || sonuc.deger === null) {
      setHata(sonuc.ok ? "Bu alan zorunlu." : sonuc.hata);
      return;
    }

    const yeni = { ...cevaplar, [aktif.cevapAnahtari]: String(sonuc.deger) };
    setCevaplar(yeni);
    taslagiKaydet(yeni);
    setGirdi("");
    setHata("");
    setAdim(adim + 1);
  }

  function konumuKaydet() {
    if (il.trim().length < 2 || ilce.trim().length < 2 || adres.trim().length < 5) {
      setHata("İl, ilçe ve açık adresi tamamla.");
      return;
    }
    const konumluCevaplar: AsistanCevaplari = {
      ...cevaplar,
      province_name: il.trim(),
      district_name: ilce.trim(),
      address: adres.trim(),
      location_source: cevaplar.latitude == null ? "manual" : "browser_gps",
    };
    const yeni: AsistanCevaplari = {
      ...konumluCevaplar,
      assistant_handoff: asistanHandoffOlustur(konumluCevaplar),
    };
    setCevaplar(yeni);
    taslagiKaydet(yeni);
    setHata("");
    setAdim(adim + 1);
  }

  function gpsKonumuAl() {
    if (!navigator.geolocation) {
      setHata("Bu tarayıcı GPS konumunu desteklemiyor; adresi elle yazabilirsin.");
      return;
    }
    setGpsBekleniyor(true);
    navigator.geolocation.getCurrentPosition(
      (konum) => {
        const yeni = {
          ...cevaplar,
          latitude: konum.coords.latitude,
          longitude: konum.coords.longitude,
          location_accuracy_meters: konum.coords.accuracy,
          location_source: "browser_gps" as const,
        };
        setCevaplar(yeni);
        taslagiKaydet(yeni);
        setGpsBekleniyor(false);
        setHata("");
      },
      () => {
        setGpsBekleniyor(false);
        setHata("Konum izni alınamadı; il, ilçe ve adresi elle yazabilirsin.");
      },
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  function cevapOzeti(alan: (typeof ASISTAN_ADIMLARI)[number]) {
    if (alan.alan === "location") {
      return [cevaplar.district_name, cevaplar.province_name, cevaplar.address]
        .filter(Boolean)
        .join(" — ");
    }
    return alan.cevapAnahtari ? String(cevaplar[alan.cevapAnahtari] ?? "") : "";
  }

  return (
    <div className="flex h-full flex-col bg-lp-bg-editor">
      {/* Başlık çubuğu */}
      <div className="flex items-center justify-between border-b border-lp-border/60 px-3 py-2">
        <div className="flex items-center gap-2">
          <div className="flex h-7 w-7 items-center justify-center overflow-hidden rounded-full bg-lp-primary/20">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/images/vixrex_v_crystal_mascot.png"
              alt=""
              width={20}
              height={20}
              className="h-5 w-5 object-contain"
            />
          </div>
          <div>
            <p className="text-[11px] font-bold text-lp-text">Vixrex</p>
            <p className="text-[9px] text-lp-muted">Dijital vitrin asistanı</p>
          </div>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="text-[11px] font-bold text-lp-muted hover:text-lp-text"
        >
          Kapat
        </button>
      </div>

      {/* Konuşma */}
      <div className="flex-1 space-y-2.5 overflow-y-auto px-3 py-3">
        <Balon>
          <p className="font-bold">{ASISTAN_KARSILAMA.baslik}</p>
          <p className="mt-1 text-lp-text-alt">{ASISTAN_KARSILAMA.aciklama}</p>
        </Balon>

        {ASISTAN_ADIMLARI.slice(0, Math.max(adim, 0)).map((gecmis) => (
          <div key={gecmis.alan} className="space-y-2.5">
            <Balon>
              <p className="font-bold">{gecmis.baslik}</p>
            </Balon>
            <p className="ml-auto max-w-[80%] rounded-xl rounded-tr-sm bg-lp-surface px-3 py-2 text-right text-[11px] text-lp-text">
              {cevapOzeti(gecmis) || "—"}
            </p>
          </div>
        ))}

        {aktif ? (
          <Balon>
            <p className="font-bold">{aktif.baslik}</p>
            <p className="mt-1 text-lp-text-alt">{aktif.aciklama}</p>
          </Balon>
        ) : null}

        {bitti ? (
          <Balon>
            <p className="font-bold">{ASISTAN_BITIS.baslik}</p>
            <p className="mt-1 text-lp-text-alt">{ASISTAN_BITIS.aciklama}</p>
          </Balon>
        ) : null}
      </div>

      {/* Girdi alanı */}
      <div className="border-t border-lp-border/60 p-3">
        {adim === -1 ? (
          <button
            type="button"
            onClick={() => setAdim(0)}
            className="w-full rounded-xl bg-lp-primary px-3 py-2.5 text-[12px] font-black text-lp-on-primary"
          >
            {ASISTAN_KARSILAMA.dugme}
          </button>
        ) : null}

        {aktif?.girdi === "konum" ? (
          <div className="space-y-2">
            <button
              type="button"
              onClick={gpsKonumuAl}
              disabled={gpsBekleniyor}
              className="w-full rounded-xl border border-lp-primary px-3 py-2 text-[11px] font-bold text-lp-text"
            >
              {gpsBekleniyor ? "Konum alınıyor…" : cevaplar.latitude == null ? "GPS ile konumumu al" : "GPS konumu alındı ✓"}
            </button>
            <div className="grid grid-cols-2 gap-1.5">
              <input value={il} onChange={(e) => setIl(e.target.value)} placeholder="İl" className="rounded-xl border border-lp-border bg-lp-surface px-3 py-2 text-[11px] text-lp-text" />
              <input value={ilce} onChange={(e) => setIlce(e.target.value)} placeholder="İlçe" className="rounded-xl border border-lp-border bg-lp-surface px-3 py-2 text-[11px] text-lp-text" />
            </div>
            <input value={adres} onChange={(e) => setAdres(e.target.value)} placeholder={aktif.yerTutucu} className="w-full rounded-xl border border-lp-border bg-lp-surface px-3 py-2 text-[11px] text-lp-text" />
            <button type="button" onClick={konumuKaydet} className="w-full rounded-xl bg-lp-primary px-3 py-2 text-[11px] font-black text-lp-on-primary">
              {aktif.dugme}
            </button>
          </div>
        ) : aktif ? (
          <form
            onSubmit={(e) => {
              e.preventDefault();
              ilerle(girdi);
            }}
            className="flex gap-1.5"
          >
            <label className="sr-only" htmlFor={`asistan-${aktif.alan}`}>
              {aktif.baslik}
            </label>
            {aktif.girdi === "secim" ? (
              <select id={`asistan-${aktif.alan}`} value={girdi} onChange={(e) => setGirdi(e.target.value)} className="flex-1 rounded-xl border border-lp-border bg-lp-surface px-3 py-2 text-[11px] text-lp-text">
                <option value="">{aktif.yerTutucu}</option>
                {aktif.secenekler.map((secenek) => <option key={secenek} value={secenek}>{secenek}</option>)}
              </select>
            ) : (
              <input
                id={`asistan-${aktif.alan}`}
                value={girdi}
                onChange={(e) => setGirdi(e.target.value)}
                placeholder={aktif.yerTutucu}
                className="flex-1 rounded-xl border border-lp-border bg-lp-surface px-3 py-2 text-[11px] text-lp-text outline-none placeholder:text-lp-muted"
              />
            )}
            <button
              type="submit"
              className="rounded-xl bg-lp-primary px-3 py-2 text-[11px] font-black text-lp-on-primary disabled:opacity-50"
              disabled={!girdi.trim()}
            >
              {aktif.dugme}
            </button>
          </form>
        ) : null}

        {hata ? <p className="mt-2 text-[10px] font-bold text-red-500" role="alert">{hata}</p> : null}

        {bitti ? (
          <Link
            href="/kayit"
            className="flex w-full items-center justify-center rounded-xl bg-lp-primary px-3 py-2.5 text-[12px] font-black text-lp-on-primary"
          >
            {ASISTAN_BITIS.dugme}
          </Link>
        ) : null}
      </div>
    </div>
  );
}

function Balon({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex gap-2">
      <div className="flex h-6 w-6 shrink-0 items-center justify-center overflow-hidden rounded-full bg-lp-primary/20">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/images/vixrex_v_crystal_mascot.png"
          alt=""
          width={18}
          height={18}
          className="h-[18px] w-[18px] object-contain"
        />
      </div>
      <div className="max-w-[220px] rounded-xl rounded-tl-sm border border-lp-primary/20 bg-lp-primary/[0.08] px-3 py-2 text-[11px] leading-relaxed text-lp-text">
        {children}
      </div>
    </div>
  );
}
