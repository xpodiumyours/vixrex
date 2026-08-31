"use client";

import Link from "next/link";
import { useState, useCallback } from "react";
import {
  ASISTAN_ADIMLARI,
  ASISTAN_BITIS,
  ASISTAN_KARSILAMA,
  asistanHandoffOlustur,
  taslagiKaydet,
  type AsistanCevaplari,
} from "@/lib/landingAsistanAkisi";
import { vixRexHizliSecenekler, vixRexMesajlari } from "@/lib/vixrexMesajlari";
import { validateField } from "@/lib/vitrinFieldValidation";

/**
 * Yayınlama sonrası bitiş metinleri — Flutter Web'deki "İşte bu kadar!" 
 * ve "Artık dijitalde varsın..." karşılığı. Katalogda `all_done_*` 
 * anahtarları farklı metin içeriyor ("Tebrikler!"), bu yüzden 
 * Flutter Web referansına göre burada tanımlı.
 */
const BITIS_BASLIK = "İşte bu kadar!";
const BITIS_ACKLAMA = "Artık dijitalde varsın. İşletme adına özel vitrinin hazır.";
const HATA_VITRIN_OLUSTURULAMADI = "Vitrin oluşturulamadı.";
const HATA_TEKRAR_DENE = "Bir hata oluştu. Lütfen tekrar dene.";
const HATA_GPS_DESTEKLEMIYOR = "Bu tarayıcı GPS konumunu desteklemiyor; adresi elle yazabilirsin.";
const HATA_KONUM_IZNI = "Konum izni alınamadı; il, ilçe ve adresi elle yazabilirsin.";
const HATA_YASAL_ONAY = "Yayın için yasal onayları işaretlemeniz gerekiyor.";
import {
  turkeyProvinces,
  getDistrictsForProvince,
} from "@/lib/turkeyCities";
import { addressHataMesaji } from "@/lib/addressValidator";

/**
 * Ana sayfadaki Vixrex Asistan — telefon mockup'ının içinde çalışır.
 *
 * Flutter'daki VixRexOnboardingChatScreen ile birebir aynı akış:
 *   welcome → name → category → whatsapp → location → legal → publish → done
 *
 * Legal ve publish adımları demo kipinden çıkar —真正 hesap oluşturma ve
 * vitrin publish işlemi yapılır.
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
  const [yayinliyor, setYayinliyor] = useState(false);
  const [yayinTamamlandi, setYayinTamamlandi] = useState(false);
  const [olusturulanSlug, setOlusturulanSlug] = useState<string | null>(null);

  // Legal onay durumları — Flutter'daki LegalConsentSection ile birebir
  const [aydinlatmaOnay, setAydinlatmaOnay] = useState(false);
  const [sartlarOnay, setSartlarOnay] = useState(false);
  const [acikRizaOnay, setAcikRizaOnay] = useState(false);

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

  function konumEksigi(): string | null {
    if (il.trim().length === 0) return "İl seç";
    if (ilce.trim().length === 0) return "İlçe seç";
    const hata = addressHataMesaji(adres);
    if (hata) return "Açık adresi yaz";
    return null;
  }

  function konumuKaydet() {
    if (il.trim().length === 0 || ilce.trim().length === 0) {
      setHata("İl ve ilçe gerekli. GPS ile bul ya da listeden seç.");
      return;
    }
    const adresHatasi = addressHataMesaji(adres);
    if (adresHatasi) {
      setHata(adresHatasi);
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
      setHata(HATA_GPS_DESTEKLEMIYOR);
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
        setHata(HATA_KONUM_IZNI);
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

  const yasalOnayVerildi = aydinlatmaOnay && sartlarOnay && acikRizaOnay;

  const yayinla = useCallback(async () => {
    if (!yasalOnayVerildi || yayinliyor) return;

    setYayinliyor(true);
    setHata("");

    try {
      // Supabase auth session kontrolü
      const { createClient } = await import("@supabase/supabase-js");
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
      const supabaseAnon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";
      const supabase = createClient(supabaseUrl, supabaseAnon);

      const { data: { session } } = await supabase.auth.getSession();

      if (!session) {
        // Giriş yapılmamış → /kayit sayfasına yönlendir
        taslagiKaydet({ ...cevaplar, legal_consent: true });
        window.location.href = "/kayit";
        return;
      }

      // API'yi çağır — vitrin oluştur ve yayınla
      const res = await fetch("/api/create-store", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({
          ...cevaplar,
          legal_consent: true,
          is_published: true,
        }),
      });

      const sonuc = await res.json();

      if (!res.ok) {
        setHata(sonuc.hata || HATA_VITRIN_OLUSTURULAMADI);
        setYayinliyor(false);
        return;
      }

      // Başarılı — slug'ı kaydet, bitiş ekranını göster
      setOlusturulanSlug(sonuc.slug);
      setYayinTamamlandi(true);
      setAdim(ASISTAN_ADIMLARI.length); // bitti = true yapar
      taslagiKaydet({ ...cevaplar, legal_consent: true });
    } catch (e) {
      setHata(HATA_TEKRAR_DENE);
      console.error("[landing-asistan] publish error:", e);
    } finally {
      setYayinliyor(false);
    }
  }, [cevaplar, yasalOnayVerildi, yayinliyor]);

  return (
    <div className="flex h-full flex-col bg-lp-bg-editor">
      {/* Başlık çubuğu — Flutter ChatTopBar ile parite: 40px avatar, 13px başlık */}
      <div className="flex items-center justify-between border-b border-lp-border/60 px-3.5 py-3">
        <div className="flex items-center gap-2.5">
          <div className="flex h-8 w-8 items-center justify-center overflow-hidden rounded-full bg-lp-primary/20">
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
            <p className="text-[13px] font-black text-lp-text">Vixrex</p>
            <p className="text-[11px] font-medium text-lp-muted">Dijital vitrin asistanı</p>
          </div>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="text-[13px] font-bold text-lp-muted hover:text-lp-text"
        >
          Kapat
        </button>
      </div>

      {/* Konuşma */}
      <div className="flex-1 space-y-3 overflow-y-auto px-3.5 py-4">
        <Balon>
          <p className="font-bold">{ASISTAN_KARSILAMA.baslik}</p>
          <p className="mt-1 text-lp-text-alt">{ASISTAN_KARSILAMA.aciklama}</p>
        </Balon>

        {ASISTAN_ADIMLARI.slice(0, Math.max(adim, 0)).map((gecmis) => (
          <div key={gecmis.alan} className="space-y-3">
            <Balon>
              <p className="font-bold">{gecmis.baslik}</p>
            </Balon>
            <p className="ml-auto max-w-[80%] rounded-xl rounded-tr-sm bg-lp-surface px-3 py-2.5 text-right text-[13px] font-semibold text-lp-text">
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

        {bitti && !yayinTamamlandi ? (
          <Balon>
            <p className="font-bold">{ASISTAN_BITIS.baslik}</p>
            <p className="mt-1 text-lp-text-alt">{ASISTAN_BITIS.aciklama}</p>
          </Balon>
        ) : null}

        {yayinTamamlandi ? (
          <Balon>
            <p className="font-bold">{BITIS_BASLIK}</p>
            <p className="mt-1 text-lp-text-alt">
              {BITIS_ACKLAMA}
            </p>
          </Balon>
        ) : null}
      </div>

      {/* Girdi alanı */}
      <div className="border-t border-lp-border/60 p-3">
        {/* Karşılama — hızlı seçenekler tek katalogdan (PR2-C6) */}
        {adim === -1 ? (
          <div className="space-y-2">
            <p className="text-center text-[11px] font-bold text-lp-muted">Hızlı Seçenekler</p>
            <Link
              href="/kesfet?yalniz_kiralik=1"
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-lp-primary px-3 py-2.5 text-[12px] font-black text-lp-on-primary"
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <path d="M3 10.5 12 4l9 6.5V20H3z" />
                <path d="M8 20v-6h8v6" />
              </svg>
              {vixRexHizliSecenekler.find((h) => h.id === "hazir_vitrin_sec")?.etiket ?? "Hazır Vitrin Seç"}
            </Link>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => { setGirdi(''); setAdim(0); }}
                className="flex items-center justify-center gap-1.5 rounded-xl border border-lp-border bg-lp-surface px-3 py-2.5 text-[11px] font-bold text-lp-text"
              >
                <span className="text-[12px]">✨</span>
                {vixRexHizliSecenekler.find((h) => h.id === "sifirdan_olustur")?.etiket ?? "Sıfırdan Oluştur"}
              </button>
              <button
                type="button"
                onClick={onClose}
                className="flex items-center justify-center gap-1.5 rounded-xl border border-lp-border bg-lp-surface px-3 py-2.5 text-[11px] font-bold text-lp-text"
              >
                <span className="text-[12px]">👁️</span>
                {vixRexHizliSecenekler.find((h) => h.id === "bakiniyorum")?.etiket ?? "Bakınıyorum"}
              </button>
            </div>
          </div>
        ) : null}

        {/* Konum adımı — Flutter FormLocationInfo ile parite */}
        {aktif?.girdi === "konum" ? (
          <div className="space-y-3">
            <div>
              <label htmlFor="asistan-il" className="flex items-center text-[13px] font-bold text-lp-text">
                İl <span className="ml-0.5 text-red-500" aria-hidden="true"> *</span>
              </label>
              <select
                id="asistan-il"
                aria-required="true"
                aria-describedby={hata ? "asistan-konum-hata" : undefined}
                value={il}
                onChange={(e) => { setIl(e.target.value); setIlce(""); setHata(""); }}
                className="mt-1.5 w-full rounded-xl border border-lp-border bg-lp-surface px-3 py-3 text-[13px] font-semibold text-lp-text"
              >
                <option value="">İl seçiniz</option>
                {turkeyProvinces.map((p) => (
                  <option key={p.code} value={p.name}>{p.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="asistan-ilce" className="flex items-center text-[13px] font-bold text-lp-text">
                İlçe <span className="ml-0.5 text-red-500" aria-hidden="true"> *</span>
              </label>
              <select
                id="asistan-ilce"
                aria-required="true"
                aria-describedby={hata ? "asistan-konum-hata" : undefined}
                value={ilce}
                onChange={(e) => { setIlce(e.target.value); setHata(""); }}
                disabled={!il}
                className="mt-1.5 w-full rounded-xl border border-lp-border bg-lp-surface px-3 py-3 text-[13px] font-semibold text-lp-text disabled:opacity-50"
              >
                <option value="">{il ? "İlçe seçiniz" : "Önce il seçiniz"}</option>
                {getDistrictsForProvince(il).map((d) => (
                  <option key={d} value={d}>{d}</option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="asistan-adres" className="flex items-center text-[13px] font-bold text-lp-text">
                Açık Adres (Mahalle, Cadde, Sokak, No) <span className="ml-0.5 text-red-500" aria-hidden="true"> *</span>
              </label>
              <input
                id="asistan-adres"
                aria-required="true"
                aria-describedby={hata ? "asistan-konum-hata" : "asistan-adres-ipucu"}
                value={adres}
                onChange={(e) => { setAdres(e.target.value); if (hata) setHata(""); }}
                placeholder="Örn: Çatalmeşe Mah. 207. Sokak No: 12"
                className="mt-1.5 w-full rounded-xl border border-lp-border bg-lp-surface px-3 py-3 text-[13px] font-semibold text-lp-text outline-none placeholder:text-white/40"
              />
              <p id="asistan-adres-ipucu" className="sr-only">Örnek adres</p>
            </div>
            <button
              type="button"
              onClick={gpsKonumuAl}
              disabled={gpsBekleniyor}
              className="flex h-[42px] w-full items-center justify-center gap-2 rounded-xl border border-lp-primary bg-white/[0.04] px-3 text-[13px] font-bold text-lp-primary disabled:opacity-50"
            >
              <span aria-hidden="true">◎</span>
              {gpsBekleniyor ? "GPS Taranıyor..." : cevaplar.latitude == null ? "GPS ile Konumumu Al" : "GPS konumu alındı ✓"}
            </button>
            <button
              type="button"
              onClick={konumuKaydet}
              disabled={!!konumEksigi()}
              aria-describedby={konumEksigi() ? "asistan-konum-yardim" : undefined}
              className="flex h-12 w-full items-center justify-center rounded-xl bg-lp-primary px-3 text-[13px] font-black text-lp-on-primary disabled:opacity-50"
            >
              Konumu onayla, devam
            </button>
            {konumEksigi() ? (
              <p id="asistan-konum-yardim" className="text-center text-[11px] font-semibold text-lp-muted">
                Devam etmek için: {konumEksigi()}
              </p>
            ) : null}
          </div>
        ) : aktif?.girdi === "onay" ? (
          /* Yasal onay adımı — Flutter'daki LegalConsentSection ile birebir */
          <div className="space-y-3">
            <p className="text-[13px] font-black text-lp-text">{vixRexMesajlari["setup_legal_baslik"]}</p>
            <p className="text-[11px] leading-[1.4] text-lp-muted">{vixRexMesajlari["setup_legal_aciklama"]}</p>
            <label className="flex items-start gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={aydinlatmaOnay}
                onChange={(e) => setAydinlatmaOnay(e.target.checked)}
                className="mt-0.5 h-4 w-4 rounded border-lp-border text-lp-primary focus:ring-lp-primary"
              />
              <span className="text-[13px] text-lp-text">
                <Link href="/legal/privacy" className="text-lp-primary underline" target="_blank">Aydınlatma Metni</Link>
                ni okudum ve kabul ediyorum.
              </span>
            </label>
            <label className="flex items-start gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={sartlarOnay}
                onChange={(e) => setSartlarOnay(e.target.checked)}
                className="mt-0.5 h-4 w-4 rounded border-lp-border text-lp-primary focus:ring-lp-primary"
              />
              <span className="text-[13px] text-lp-text">
                <Link href="/legal/terms" className="text-lp-primary underline" target="_blank">Kullanım Şartları</Link>
                nı okudum ve kabul ediyorum.
              </span>
            </label>
            <label className="flex items-start gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={acikRizaOnay}
                onChange={(e) => setAcikRizaOnay(e.target.checked)}
                className="mt-0.5 h-4 w-4 rounded border-lp-border text-lp-primary focus:ring-lp-primary"
              />
              <span className="text-[13px] text-lp-text">
                <Link href="/legal/consent" className="text-lp-primary underline" target="_blank">Açık Rıza Beyanı</Link>
                nı okudum, anladım ve kabul ediyorum.
              </span>
            </label>
            <button
              type="button"
              onClick={() => {
                if (!yasalOnayVerildi) {
                  setHata(HATA_YASAL_ONAY);
                  return;
                }
                setCevaplar({ ...cevaplar, legal_consent: true, aydinlatma_onay: aydinlatmaOnay, sartlar_onay: sartlarOnay, acik_riza_onay: acikRizaOnay });
                setHata("");
                setAdim(adim + 1);
              }}
              disabled={!yasalOnayVerildi}
              className="flex h-12 w-full items-center justify-center rounded-xl bg-lp-primary px-3 text-[13px] font-black text-lp-on-primary disabled:opacity-50"
            >
              {aktif.dugme}
            </button>
          </div>
        ) : aktif?.girdi === "eylem" ? (
          /* Yayın adımı */
          <div className="space-y-2">
            <button
              type="button"
              onClick={yayinla}
              disabled={yayinliyor}
              className="w-full rounded-xl bg-lp-primary px-3 py-2.5 text-[12px] font-black text-lp-on-primary disabled:opacity-50"
            >
              {yayinliyor ? "Yayınlanıyor…" : "Yayınla"}
            </button>
          </div>
        ) : aktif ? (
          /* Metin/Seçim girdisi */
          <form
            onSubmit={(e) => {
              e.preventDefault();
              ilerle(girdi);
            }}
            className="flex gap-2"
          >
            <label className="sr-only" htmlFor={`asistan-${aktif.alan}`}>
              {aktif.baslik}
            </label>
            {aktif.girdi === "secim" ? (
              <KategoriGrid secenekler={aktif.secenekler} secilen={girdi} onSelect={(v) => { setGirdi(v); ilerle(v); }} />
            ) : (
              <input
                id={`asistan-${aktif.alan}`}
                value={girdi}
                onChange={(e) => setGirdi(e.target.value)}
                placeholder={aktif.yerTutucu}
                className="flex h-12 min-w-0 flex-1 rounded-xl border border-lp-border bg-lp-surface px-3.5 text-[13px] font-semibold text-lp-text outline-none placeholder:text-lp-muted"
              />
            )}
            <button
              type="submit"
              className="flex h-12 shrink-0 items-center justify-center whitespace-nowrap rounded-xl bg-lp-primary px-3 text-[11px] font-black text-lp-on-primary disabled:opacity-50"
              disabled={!girdi.trim()}
            >
              {aktif.dugme}
            </button>
          </form>
        ) : null}

        {hata ? <p id="asistan-konum-hata" className="mt-2 text-[11px] font-bold text-red-500" role="alert" aria-live="assertive">{hata}</p> : null}

        {/* Bitiş — Kayıt yoksa /kayit'a yönlendir (Flutter'daki hesapKorumasız karşılığı) */}
        {bitti && !yayinTamamlandi ? (
          <Link
            href="/kayit"
            className="flex w-full items-center justify-center rounded-xl bg-lp-primary px-3 py-2.5 text-[12px] font-black text-lp-on-primary"
          >
            {ASISTAN_BITIS.dugme}
          </Link>
        ) : null}

        {/* Yayın tamamlandı — Flutter Web'deki "Vitrinini aç" + "Detaylı formu aç" */}
        {yayinTamamlandi && olusturulanSlug ? (
          <div className="space-y-2">
            <Link
              href={`/v/${olusturulanSlug}?owner=true`}
              className="flex w-full items-center justify-center rounded-xl bg-lp-primary px-3 py-2.5 text-[12px] font-black text-lp-on-primary"
            >
              Vitrinini aç
            </Link>
            <Link
              href={`/v/${olusturulanSlug}?owner=true&tab=profile`}
              className="flex w-full items-center justify-center rounded-xl border border-lp-border px-3 py-2 text-[11px] font-bold text-lp-text-alt"
            >
              Detaylı formu aç
            </Link>
          </div>
        ) : null}
      </div>
    </div>
  );
}

function Balon({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex gap-2.5">
      <div className="flex h-7 w-7 shrink-0 items-center justify-center overflow-hidden rounded-full bg-lp-primary/20">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/images/vixrex_v_crystal_mascot.png"
          alt=""
          width={20}
          height={20}
          className="h-5 w-5 object-contain"
        />
      </div>
      <div className="max-w-[260px] rounded-xl rounded-tl-sm border border-lp-primary/20 bg-lp-primary/[0.08] px-3.5 py-3 text-[13px] leading-[1.5] text-lp-text">
        {children}
      </div>
    </div>
  );
}

/**
 * Kategori ızgarası — Flutter'daki KategoriSecici widget'ının birebir karşılığı.
 * 2 sütunlu grid, her hücrede ikon + label.
 *
 * Presentation label tercümanı: shared JSON kısa label kullanır
 * ("Danışmanlık"), Flutter Web uzun label kullanır ("Hizmet & Danışmanlık").
 * Kullanıcıya gösterilen metin Flutter Web ile aynı olmalı.
 * Veri olarak kısa label (shared JSON) gönderilir — canonical key korunur.
 */
const FLUTTER_WEB_LABEL: Record<string, string> = {
  "Danışmanlık": "Hizmet & Danışmanlık",
  "Eğitim": "Eğitim & Ders",
  "Ev Temizlik": "Ev & Temizlik",
  "Spor / Fitness": "Spor & Fitness",
  "Pet / Veteriner": "Pet Shop & Veteriner",
  "Sağlık / Yaşam": "Sağlık & Yaşam",
  "Oto / Araç": "Oto & Araç Hizmetleri",
};

/** Shared JSON label → Flutter Web presentation label */
function gosterimLabeli(sharedLabel: string): string {
  return FLUTTER_WEB_LABEL[sharedLabel] ?? sharedLabel;
}

/** Flutter Web presentation label → shared JSON label (seçim sonrası veri için) */
function veriLabeli(gosterim: string): string {
  for (const [kisa, uzun] of Object.entries(FLUTTER_WEB_LABEL)) {
    if (uzun === gosterim) return kisa;
  }
  return gosterim;
}

const KATEGORI_SIMGELERI: Record<string, string> = {
  "Giyim": "👕",
  "Butik": "🛍️",
  "Gıda": "🍎",
  "Fırın": "🍞",
  "Kozmetik": "💄",
  "Dekorasyon": "🪴",
  "Elektronik": "📱",
  "Kırtasiye": "📚",
  "Kafe / Lokanta": "☕",
  "Kuaför": "✂️",
  "Teknik Servis": "🔧",
  "Hizmet & Danışmanlık": "💼",
  "Eğitim & Ders": "🎓",
  "Ev & Temizlik": "🧹",
  "Spor & Fitness": "🏋️",
  "Pet Shop & Veteriner": "🐾",
  "Sağlık & Yaşam": "🏥",
  "Oto & Araç Hizmetleri": "🚗",
  "Diğer": "🏪",
};

function KategoriGrid({
  secenekler,
  secilen,
  onSelect,
}: {
  secenekler: readonly string[];
  secilen: string;
  onSelect: (deger: string) => void;
}) {
  return (
    <div className="relative max-h-[272px] overflow-y-auto">
      <p className="mb-2 text-center text-[11px] font-bold text-lp-muted">İşini seç</p>
      <div className="grid grid-cols-2 gap-2">
        {secenekler.map((secenek) => {
          const gorunen = gosterimLabeli(secenek);
          return (
            <button
              key={secenek}
              type="button"
              onClick={() => onSelect(veriLabeli(gorunen))}
              className={`flex aspect-[2.35] flex-col items-center justify-center gap-1 rounded-xl border px-2 text-[12px] font-bold transition-all ${
                secilen === veriLabeli(gorunen)
                  ? "border-lp-primary bg-lp-primary/10 text-lp-text"
                  : "border-lp-border bg-lp-surface text-lp-text hover:border-lp-primary/50"
              }`}
            >
              <span className="text-[18px]">{KATEGORI_SIMGELERI[gorunen] ?? "🏪"}</span>
              <span className="text-center text-[11px] leading-tight">{gorunen}</span>
            </button>
          );
        })}
      </div>
      {/* Solma efekti — Flutter'daki ShaderMask ile aynı */}
      <div className="pointer-events-none absolute bottom-0 left-0 right-0 h-12 bg-gradient-to-t from-lp-bg-editor to-transparent" />
    </div>
  );
}
