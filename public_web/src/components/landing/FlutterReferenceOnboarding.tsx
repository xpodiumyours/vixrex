"use client";

import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { PROFILES } from "@/lib/vitrinProfile";
import { resolveBusinessCategory, kategoriUrlParcasi } from "@/lib/businessCategories";
import { validateField } from "@/lib/vitrinFieldValidation";
import { vixRexHizliSecenekler, vixRexMesajlari } from "@/lib/vixrexMesajlari";
import { LandingAsistanSohbeti } from "./LandingAsistanSohbeti";

type Sahne = "welcome" | "template_intent" | "name" | "continue";

function hizliSecenek(id: "hazir_vitrin_sec" | "sifirdan_olustur" | "bakiniyorum") {
  const secenek = vixRexHizliSecenekler.find((item) => item.id === id);
  if (!secenek) throw new Error(`Vixrex hızlı seçenek katalogda yok: ${id}`);
  return secenek;
}

function WelcomeText({ raw }: { raw: string }) {
  const text = useMemo(
    () => raw
      .replace("- Tek Link & QR Kod:", "• 📱 Tek Link & QR Kod:")
      .replace("- WhatsApp Sipariş:", "• 💬 WhatsApp Sipariş:")
      .replace("- Ürün & Galeri:", "• 🛍️ Ürün & Galeri:")
      .replace("- Konum & Adres:", "• 📍 Konum & Adres:"),
    [raw],
  );
  return <>{text}</>;
}

function TopBar({ onClose }: { onClose?: () => void }) {
  return (
    <header className="flex min-h-[72px] items-center justify-between border-b border-lp-border bg-lp-surface px-3.5 py-3">
      <div className="flex min-w-0 items-center gap-3">
        <span className="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-full border border-lp-primary/80 bg-lp-surface shadow-[0_0_16px_rgba(20,125,255,0.45)]" aria-hidden="true">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/images/vixrex_v_crystal_mascot.png" alt="" className="h-9 w-9 object-contain" />
        </span>
        <span className="min-w-0">
          <span className="block truncate text-[16px] font-black leading-tight text-lp-text">Vixrex</span>
          <span className="mt-1 block truncate text-[11px] font-extrabold leading-none text-lp-primary">Dijital vitrin asistanı</span>
        </span>
      </div>
      <button type="button" onClick={onClose} className="min-h-10 shrink-0 px-2 text-[13px] font-black text-lp-muted hover:text-lp-text">
        Kapat
      </button>
    </header>
  );
}

function BotBubble({ title, body }: { title: string; body?: React.ReactNode }) {
  return (
    <div className="flex items-start gap-2.5">
      <span className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center overflow-hidden rounded-full border border-lp-primary/70 bg-lp-surface shadow-[0_0_10px_rgba(20,125,255,0.3)]" aria-hidden="true">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/images/vixrex_v_crystal_mascot.png" alt="" className="h-6 w-6 object-contain" />
      </span>
      <div className="max-w-[265px] rounded-[18px] rounded-tl-[8px] border border-lp-primary/55 bg-[#10244A] px-4 py-3.5 text-[14px] leading-[1.55] text-lp-text shadow-[0_8px_24px_rgba(0,0,0,0.18)]">
        <p className="font-medium">{title}</p>
        {body ? <p className="mt-2 whitespace-pre-line text-lp-text-alt">{body}</p> : null}
      </div>
    </div>
  );
}

function UserBubble({ children }: { children: React.ReactNode }) {
  return (
    <p className="ml-auto max-w-[80%] rounded-xl rounded-tr-sm bg-lp-surface px-3 py-2.5 text-right text-[13px] font-semibold text-lp-text">
      {children}
    </p>
  );
}

export function FlutterReferenceOnboarding({
  initialName = "",
  onClose,
}: {
  initialName?: string;
  onClose?: () => void;
}) {
  const router = useRouter();
  const tasinanAd = initialName.trim();
  const [sahne, setSahne] = useState<Sahne>(tasinanAd ? "continue" : "welcome");
  const [isletmeAdi, setIsletmeAdi] = useState(tasinanAd);
  const [devamAdi, setDevamAdi] = useState(tasinanAd);
  const [hata, setHata] = useState("");
  const [bakiniyorumAck, setBakiniyorumAck] = useState(false);
  const [niyetSerbestMetin, setNiyetSerbestMetin] = useState("");

  if (sahne === "continue" && devamAdi) {
    return <LandingAsistanSohbeti initialName={devamAdi} onClose={onClose} />;
  }

  function adiOnayla(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const sonuc = validateField("isletmeAdi", isletmeAdi);
    if (!sonuc.ok || sonuc.deger == null) {
      setHata(sonuc.ok ? "İşletme adı gerekli." : sonuc.hata);
      return;
    }
    const temiz = String(sonuc.deger).trim();
    setDevamAdi(temiz);
    setHata("");
    setSahne("continue");
  }

  function kategoriyeGit(label: string) {
    const kategori = resolveBusinessCategory(label);
    const hedef = kategori
      ? `/kesfet?yalniz_kiralik=1&kategori=${encodeURIComponent(kategoriUrlParcasi(kategori.id))}`
      : "/kesfet?yalniz_kiralik=1";
    router.push(hedef);
  }

  return (
    <div className="flex h-full flex-col bg-lp-bg-editor" data-testid="flutter-reference-onboarding">
      <TopBar onClose={onClose} />

      <main className="flex-1 space-y-3 overflow-y-auto px-3.5 py-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        <BotBubble
          title={vixRexMesajlari.welcome_baslik ?? "Merhaba, ben Vixrex Asistan."}
          body={<WelcomeText raw={vixRexMesajlari.welcome_aciklama ?? ""} />}
        />

        {bakiniyorumAck ? (
          <>
            <UserBubble>Şimdilik bakınıyorum</UserBubble>
            <BotBubble title="Tamam. Hazır olunca buradayım." />
          </>
        ) : null}

        {sahne === "template_intent" ? (
          <BotBubble
            title={vixRexMesajlari.niyet_kategori_baslik}
            body={vixRexMesajlari.niyet_kategori_aciklama}
          />
        ) : null}

        {sahne === "name" ? (
          <BotBubble
            title={vixRexMesajlari.setup_name_baslik ?? "İşletme adınızı girin"}
            body={vixRexMesajlari.setup_name_aciklama ?? "Vitrininizde görünecek işletme adını yazın."}
          />
        ) : null}
      </main>

      <footer className="border-t border-lp-border bg-lp-surface px-3.5 pb-4 pt-3">
        {sahne === "welcome" ? (
          <div className="space-y-2" data-testid="landing-onboarding-quick-options">
            <p className="mb-3 text-center text-[11px] font-extrabold tracking-[0.4px] text-lp-muted">Hızlı Seçenekler</p>
            <button
              type="button"
              onClick={() => {
                setBakiniyorumAck(false);
                setSahne("template_intent");
              }}
              className="flex min-h-[52px] w-full items-center justify-center gap-1.5 rounded-[18px] bg-gradient-to-r from-lp-primary to-lp-secondary px-3 text-[12px] font-black text-lp-on-primary shadow-[0_8px_18px_rgba(20,125,255,0.28)]"
            >
              {hizliSecenek("hazir_vitrin_sec").etiket}
            </button>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => {
                  setBakiniyorumAck(false);
                  setSahne("name");
                }}
                className="flex min-h-[52px] items-center justify-center gap-1.5 rounded-[18px] border border-lp-primary/70 bg-lp-surface px-3 text-[12px] font-black text-lp-text"
              >
                {hizliSecenek("sifirdan_olustur").etiket}
              </button>
              <button
                type="button"
                onClick={() => {
                  setBakiniyorumAck(true);
                  setSahne("welcome");
                }}
                className="flex min-h-[52px] items-center justify-center gap-1.5 rounded-[18px] border border-lp-primary/70 bg-lp-surface px-3 text-[12px] font-black text-lp-text"
              >
                {hizliSecenek("bakiniyorum").etiket}
              </button>
            </div>
          </div>
        ) : sahne === "template_intent" ? (
          <div className="space-y-2" data-testid="landing-template-intent">
            <div className="grid grid-cols-3 gap-1.5">
              {PROFILES.map((profile) => (
                <button
                  key={profile.id}
                  type="button"
                  onClick={() => kategoriyeGit(profile.label)}
                  className="min-h-10 rounded-xl border border-lp-border bg-lp-bg-light px-1.5 text-[10px] font-bold text-lp-text"
                >
                  {profile.label}
                </button>
              ))}
            </div>
            <p className="text-center text-[10px] font-bold text-lp-muted">veya</p>
            <textarea
              value={niyetSerbestMetin}
              onChange={(event) => setNiyetSerbestMetin(event.target.value)}
              placeholder={vixRexMesajlari.niyet_serbest_yertutucu}
              rows={2}
              className="w-full rounded-xl border border-lp-border bg-lp-bg-light px-3 py-2.5 text-[12px] font-medium text-lp-text outline-none placeholder:text-lp-muted"
            />
            {niyetSerbestMetin.trim() ? (
              <button
                type="button"
                onClick={() => kategoriyeGit(niyetSerbestMetin.trim())}
                className="w-full rounded-xl bg-lp-primary px-3 py-2.5 text-[12px] font-black text-lp-on-primary"
              >
                {vixRexMesajlari.niyet_anlat_buton}
              </button>
            ) : null}
            <button
              type="button"
              onClick={() => {
                setNiyetSerbestMetin("");
                setSahne("welcome");
              }}
              className="min-h-10 w-full text-center text-[11px] font-bold text-lp-muted hover:text-lp-text"
            >
              {vixRexMesajlari.niyet_geri_buton}
            </button>
          </div>
        ) : (
          <form onSubmit={adiOnayla} className="space-y-2.5" data-testid="landing-name-step">
            <label htmlFor="flutter-ref-isletme-adi" className="sr-only">İşletme adı</label>
            <input
              id="flutter-ref-isletme-adi"
              autoFocus
              value={isletmeAdi}
              onChange={(event) => {
                setIsletmeAdi(event.target.value);
                if (hata) setHata("");
              }}
              placeholder="İşletme adınız"
              className="h-12 w-full rounded-xl border border-lp-border bg-lp-bg-light px-3.5 text-[13px] font-semibold text-lp-text outline-none placeholder:text-lp-muted focus:border-lp-primary"
            />
            {hata ? <p className="text-[11px] font-bold text-red-400" role="alert">{hata}</p> : null}
            <div className="grid grid-cols-[1fr_auto] gap-2">
              <button type="button" onClick={() => setSahne("welcome")} className="min-h-11 rounded-xl border border-lp-border px-3 text-[12px] font-bold text-lp-muted">
                Geri
              </button>
              <button type="submit" className="min-h-11 rounded-xl bg-lp-primary px-4 text-[12px] font-black text-lp-on-primary">
                Devam
              </button>
            </div>
          </form>
        )}
      </footer>
    </div>
  );
}
