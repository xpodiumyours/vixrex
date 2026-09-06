"use client";

import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { validateField } from "@/lib/vitrinFieldValidation";
import { vixRexMesajlari } from "@/lib/vixrexMesajlari";
import { LandingAsistanSohbeti } from "./LandingAsistanSohbeti";

function apkWelcomeText(raw: string): string {
  return raw
    .replace("- Tek Link & QR Kod:", "• 📱 Tek Link & QR Kod:")
    .replace("- WhatsApp Sipariş:", "• 💬 WhatsApp Sipariş:")
    .replace("- Ürün & Galeri:", "• 🛍️ Ürün & Galeri:")
    .replace("- Konum & Adres:", "• 📍 Konum & Adres:");
}

function ApkTopBar({ onClose }: { onClose?: () => void }) {
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

function ApkAssistantBubble({ title, body }: { title: string; body: string }) {
  return (
    <div className="flex items-start gap-2.5">
      <span className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center overflow-hidden rounded-full border border-lp-primary/70 bg-lp-surface shadow-[0_0_10px_rgba(20,125,255,0.3)]" aria-hidden="true">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/images/vixrex_v_crystal_mascot.png" alt="" className="h-6 w-6 object-contain" />
      </span>
      <div className="max-w-[265px] rounded-[18px] rounded-tl-[8px] border border-lp-primary/55 bg-[#10244A] px-4 py-3.5 text-[14px] leading-[1.55] text-lp-text shadow-[0_8px_24px_rgba(0,0,0,0.18)]">
        <p className="font-medium">{title}</p>
        <p className="mt-2 whitespace-pre-line text-lp-text-alt">{body}</p>
      </div>
    </div>
  );
}

export function LandingApkAssistant({
  initialName = "",
  onClose,
}: {
  initialName?: string;
  onClose?: () => void;
}) {
  const router = useRouter();
  const tasinanAd = initialName.trim();
  const [sahne, setSahne] = useState<"welcome" | "name" | "chat">(tasinanAd ? "chat" : "welcome");
  const [isletmeAdi, setIsletmeAdi] = useState(tasinanAd);
  const [devamAdi, setDevamAdi] = useState(tasinanAd);
  const [hata, setHata] = useState("");

  const welcomeBody = useMemo(
    () => apkWelcomeText(vixRexMesajlari.welcome_aciklama ?? ""),
    [],
  );

  if (sahne === "chat" && devamAdi) {
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
    setSahne("chat");
  }

  return (
    <div className="flex h-full flex-col bg-lp-bg-editor">
      <ApkTopBar onClose={onClose} />

      <main className="flex-1 overflow-y-auto px-3.5 py-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {sahne === "welcome" ? (
          <ApkAssistantBubble
            title={vixRexMesajlari.welcome_baslik ?? "Merhaba, ben Vixrex Asistan."}
            body={welcomeBody}
          />
        ) : (
          <ApkAssistantBubble
            title={vixRexMesajlari.setup_name_baslik ?? "İşletme adınızı girin"}
            body={vixRexMesajlari.setup_name_aciklama ?? "Vitrininizde görünecek işletme adını yazın."}
          />
        )}
      </main>

      <footer className="border-t border-lp-border bg-lp-surface px-3.5 pb-4 pt-3">
        {sahne === "welcome" ? (
          <>
            <p className="mb-3 text-center text-[11px] font-extrabold tracking-[0.4px] text-lp-muted">Hızlı Seçenekler</p>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => setSahne("name")}
                className="flex min-h-[52px] items-center justify-center gap-1.5 rounded-[18px] bg-gradient-to-r from-lp-primary to-lp-secondary px-3 text-[12px] font-black text-lp-on-primary shadow-[0_8px_18px_rgba(20,125,255,0.28)]"
              >
                <span aria-hidden="true">✨</span>
                Evet, Oluşturalım
              </button>
              <button
                type="button"
                onClick={() => router.push("/kesfet")}
                className="flex min-h-[52px] items-center justify-center gap-1.5 rounded-[18px] border border-lp-primary/70 bg-lp-surface px-3 text-[12px] font-black text-lp-text"
              >
                <span aria-hidden="true">◉</span>
                Bakınıyorum
              </button>
            </div>
          </>
        ) : (
          <form onSubmit={adiOnayla} className="space-y-2.5">
            <label htmlFor="apk-asistan-isletme-adi" className="sr-only">İşletme adı</label>
            <input
              id="apk-asistan-isletme-adi"
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
