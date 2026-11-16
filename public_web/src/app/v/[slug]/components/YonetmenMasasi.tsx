"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  sektorelYonetmenSecenekleri,
  type YonetmenKampanyaSecenegi,
  type YonetmenHikayeSecenegi,
} from "@/lib/sektorelSablonlar";

interface Props {
  slug: string;
  kategoriEtiketi?: string | null;
  onDuzenleAc?: (mod: "kampanya" | "hikaye" | "sss") => void;
  onMesajGonder?: (metin: string) => void;
}

type AktifMasa = "genel" | "kampanya" | "hikaye" | "sss";

export function YonetmenMasasi({
  slug,
  kategoriEtiketi,
  onDuzenleAc,
  onMesajGonder,
}: Props) {
  const router = useRouter();
  const [aktifMasa, setAktifMasa] = useState<AktifMasa>("genel");
  const [islemdekiId, setIslemdekiId] = useState<string | null>(null);
  const [bildirim, setBildirim] = useState<{ tip: "basari" | "hata"; metin: string } | null>(null);

  const secenekler = sektorelYonetmenSecenekleri(kategoriEtiketi);

  const bildirimGoster = useCallback((metin: string, tip: "basari" | "hata") => {
    setBildirim({ tip, metin });
    setTimeout(() => {
      setBildirim(null);
    }, 3200);
  }, []);

  // 1. KAMPANYA AFİŞİNİ VİTRİNE AS (Katman A & B)
  const kampanyayiVitrineAs = useCallback(
    async (kampanya: YonetmenKampanyaSecenegi) => {
      if (islemdekiId) return; // Çift tıklama koruması
      setIslemdekiId(kampanya.id);

      const degisiklikler = [
        { anahtar: "bantEtiket", deger: kampanya.rozet },
        { anahtar: "bantBaslik", deger: kampanya.baslik },
        { anahtar: "bantAciklama", deger: kampanya.aciklama },
      ];

      try {
        const res = await fetch("/api/owner-draft-batch", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            slug,
            commandId: crypto.randomUUID(),
            degisiklikler,
            clientId: null,
          }),
        });

        if (!res.ok) {
          const err = await res.json().catch(() => null);
          bildirimGoster(err?.hata || "Kampanya kaydedilemedi. Lütfen tekrar deneyin.", "hata");
          return;
        }

        bildirimGoster(`✓ "${kampanya.baslik}" afişi vitrininize asıldı!`, "basari");
        onMesajGonder?.(`"${kampanya.baslik}" kampanyasını vitrine astım.`);
        router.refresh();
      } catch {
        bildirimGoster("Bağlantı hatası: Değişiklik kaydedilemedi.", "hata");
      } finally {
        setIslemdekiId(null);
      }
    },
    [slug, islemdekiId, router, bildirimGoster, onMesajGonder],
  );

  // 2. HİKAYE VE DEĞERLERİ VİTRİNE AS (Katman A & B)
  const hikayeyiVitrineAs = useCallback(
    async (hikaye: YonetmenHikayeSecenegi) => {
      if (islemdekiId) return; // Çift tıklama koruması
      setIslemdekiId(hikaye.id);

      const degisiklikler = [
        { anahtar: "hakkindaUstBaslik", deger: hikaye.kicker },
        { anahtar: "hakkindaBaslik", deger: hikaye.title },
        { anahtar: "hakkindaMetin", deger: hikaye.bio },
      ];

      try {
        // Metin alanları batch API'ye
        const batchRes = await fetch("/api/owner-draft-batch", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            slug,
            commandId: crypto.randomUUID(),
            degisiklikler,
            clientId: null,
          }),
        });

        if (!batchRes.ok) {
          const err = await batchRes.json().catch(() => null);
          bildirimGoster(err?.hata || "Hikaye kaydedilemedi. Lütfen tekrar deneyin.", "hata");
          return;
        }

        // Değer kartları JSONB API'ye
        const valuesRes = await fetch("/api/owner-structured-field", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            slug,
            kolon: "about_values",
            deger: hikaye.values,
          }),
        });

        if (!valuesRes.ok) {
          const err = await valuesRes.json().catch(() => null);
          bildirimGoster(err?.hata || "Değer kartları kaydedilemedi.", "hata");
          return;
        }

        bildirimGoster(`✓ "${hikaye.tonAdi}" hikayesi ve değerleri vitrininize asıldı!`, "basari");
        onMesajGonder?.(`"${hikaye.tonAdi}" duruşunu ve değer kartlarını vitrine astım.`);
        router.refresh();
      } catch {
        bildirimGoster("Bağlantı hatası: Değişiklik kaydedilemedi.", "hata");
      } finally {
        setIslemdekiId(null);
      }
    },
    [slug, islemdekiId, router, bildirimGoster, onMesajGonder],
  );

  return (
    <div className="border-b border-white/10 bg-[#0B1324] px-4 py-3 sm:px-5 sm:py-4">
      {/* CANLI GERİ BİLDİRİM TOASTI */}
      {bildirim && (
        <div
          role="status"
          className={`mb-3 flex items-center justify-between rounded-xl px-3.5 py-2.5 text-[12px] font-bold shadow-lg transition-all ${
            bildirim.tip === "basari"
              ? "border border-emerald-400/40 bg-emerald-500/15 text-emerald-300"
              : "border border-rose-400/40 bg-rose-500/15 text-rose-300"
          }`}
        >
          <span>{bildirim.metin}</span>
          <button
            type="button"
            onClick={() => setBildirim(null)}
            className="ml-2 text-white/50 hover:text-white"
          >
            ✕
          </button>
        </div>
      )}

      {/* MASALAR ARASI GEÇİŞ NAVİGASYONU */}
      {aktifMasa !== "genel" && (
        <div className="mb-3 flex items-center justify-between">
          <button
            type="button"
            onClick={() => setAktifMasa("genel")}
            className="flex items-center gap-1.5 text-[11px] font-bold text-sky-400 hover:text-sky-300"
          >
            <span>← Ana Yönetim Masası</span>
          </button>
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500">
            {aktifMasa === "kampanya" ? "Kampanya Masası" : aktifMasa === "hikaye" ? "Hikaye & Duruş" : "Soru-Cevap"}
          </span>
        </div>
      )}

      {/* 1. ANA YÖNETİM MASASI (4 EYLEM KARTI) */}
      {aktifMasa === "genel" && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-[13px] font-black tracking-[-0.01em] text-white">
                Vixrex Yaratıcı Yönetmen
              </p>
              <p className="text-[11px] font-medium text-slate-400">
                Sektörünüze özel hazır paketleri tek tıkla vitrine asın.
              </p>
            </div>
            <span className="rounded-full border border-sky-400/30 bg-sky-400/10 px-2 py-0.5 text-[10px] font-bold text-sky-300">
              Ajans Modu
            </span>
          </div>

          <div className="grid grid-cols-2 gap-2">
            {/* KART 1: KAMPANYA */}
            <button
              type="button"
              onClick={() => setAktifMasa("kampanya")}
              className="group flex flex-col items-start rounded-xl border border-white/10 bg-white/[0.03] p-3 text-left transition hover:border-sky-400/40 hover:bg-sky-500/[0.06] active:scale-[0.98]"
            >
              <span className="text-[18px]">🏷️</span>
              <span className="mt-1 text-[12px] font-bold text-white group-hover:text-sky-300">
                Kampanya Afişi
              </span>
              <span className="mt-0.5 text-[10px] text-slate-400">
                3 hazır seçenekten seç
              </span>
            </button>

            {/* KART 2: HİKAYE & DURUŞ */}
            <button
              type="button"
              onClick={() => setAktifMasa("hikaye")}
              className="group flex flex-col items-start rounded-xl border border-white/10 bg-white/[0.03] p-3 text-left transition hover:border-indigo-400/40 hover:bg-indigo-500/[0.06] active:scale-[0.98]"
            >
              <span className="text-[18px]">📖</span>
              <span className="mt-1 text-[12px] font-bold text-white group-hover:text-indigo-300">
                Hikaye & Duruş
              </span>
              <span className="mt-0.5 text-[10px] text-slate-400">
                3 esnaf tonundan seç
              </span>
            </button>

            {/* KART 3: SSS */}
            <button
              type="button"
              onClick={() => onDuzenleAc ? onDuzenleAc("sss") : setAktifMasa("sss")}
              className="group flex flex-col items-start rounded-xl border border-white/10 bg-white/[0.03] p-3 text-left transition hover:border-amber-400/40 hover:bg-amber-500/[0.06] active:scale-[0.98]"
            >
              <span className="text-[18px]">❓</span>
              <span className="mt-1 text-[12px] font-bold text-white group-hover:text-amber-300">
                Sık Sorulanlar
              </span>
              <span className="mt-0.5 text-[10px] text-slate-400">
                Soruları yönet
              </span>
            </button>

            {/* KART 4: FATURA İLE ÜRÜN */}
            <Link
              href="/app/urunler"
              className="group flex flex-col items-start rounded-xl border border-emerald-400/30 bg-emerald-500/[0.05] p-3 text-left transition hover:border-emerald-400/60 hover:bg-emerald-500/[0.1] active:scale-[0.98]"
            >
              <span className="text-[18px]">📸</span>
              <span className="mt-1 text-[12px] font-bold text-emerald-300">
                Faturadan Ürün
              </span>
              <span className="mt-0.5 text-[10px] text-slate-400">
                Reyona yeni ürün dök
              </span>
            </Link>
          </div>
        </div>
      )}

      {/* 2. KAMPANYA MASASI */}
      {aktifMasa === "kampanya" && (
        <div className="space-y-2.5">
          <p className="text-[11px] font-medium text-slate-300">
            Dükkânınız için hazırlanan 3 hazır afişten birini seçip tek tıkla vitrine asabilirsiniz:
          </p>

          <div className="space-y-2">
            {secenekler.kampanyalar.map((k, idx) => (
              <div
                key={k.id}
                className="rounded-xl border border-white/10 bg-white/[0.03] p-3 transition hover:border-sky-400/30"
              >
                <div className="flex items-center justify-between">
                  <span className="text-[9px] font-black uppercase tracking-wider text-sky-400">
                    {k.rozet}
                  </span>
                  <span className="text-[9px] font-bold text-slate-500">
                    Seçenek {idx + 1}
                  </span>
                </div>
                <p className="mt-1 text-[13px] font-bold text-white leading-tight">
                  {k.baslik}
                </p>
                <p className="mt-1 text-[11px] text-slate-400 leading-snug">
                  {k.aciklama}
                </p>

                <div className="mt-2.5 flex items-center gap-2">
                  <button
                    type="button"
                    disabled={islemdekiId !== null}
                    onClick={() => kampanyayiVitrineAs(k)}
                    className="flex-1 rounded-lg bg-sky-500 px-3 py-1.5 text-center text-[11px] font-black text-white shadow-md transition hover:bg-sky-400 active:scale-95 disabled:opacity-50"
                  >
                    {islemdekiId === k.id ? "Asılıyor..." : "⚡ Bu Kampanyayı Vitrine As"}
                  </button>
                  {onDuzenleAc && (
                    <button
                      type="button"
                      onClick={() => onDuzenleAc("kampanya")}
                      className="rounded-lg border border-white/10 px-2 py-1.5 text-[10px] font-semibold text-slate-400 hover:text-white"
                    >
                      Özelleştir
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 3. HİKAYE & DURUŞ MASASI */}
      {aktifMasa === "hikaye" && (
        <div className="space-y-2.5">
          <p className="text-[11px] font-medium text-slate-300">
            Dükkânınızın müşterilere vereceği güven duygusunu 3 farklı esnaf tonunda hazırladık:
          </p>

          <div className="space-y-2">
            {secenekler.hikayeler.map((h, idx) => (
              <div
                key={h.id}
                className="rounded-xl border border-white/10 bg-white/[0.03] p-3 transition hover:border-indigo-400/30"
              >
                <div className="flex items-center justify-between">
                  <span className="text-[9px] font-black uppercase tracking-wider text-indigo-400">
                    {h.tonAdi}
                  </span>
                  <span className="text-[9px] font-bold text-slate-500">
                    Ton {idx + 1}
                  </span>
                </div>
                <p className="mt-1 text-[13px] font-bold text-white leading-tight">
                  {h.title}
                </p>
                <p className="mt-1 line-clamp-2 text-[11px] text-slate-400 leading-snug">
                  {h.bio}
                </p>

                <div className="mt-2 flex flex-wrap gap-1">
                  {h.values.map((v) => (
                    <span
                      key={v.id}
                      className="rounded-md bg-white/[0.05] border border-white/10 px-1.5 py-0.5 text-[9px] font-medium text-slate-300"
                    >
                      ✓ {v.title}
                    </span>
                  ))}
                </div>

                <div className="mt-2.5 flex items-center gap-2">
                  <button
                    type="button"
                    disabled={islemdekiId !== null}
                    onClick={() => hikayeyiVitrineAs(h)}
                    className="flex-1 rounded-lg bg-indigo-500 px-3 py-1.5 text-center text-[11px] font-black text-white shadow-md transition hover:bg-indigo-400 active:scale-95 disabled:opacity-50"
                  >
                    {islemdekiId === h.id ? "Asılıyor..." : "⚡ Bu Hikayeyi Vitrine As"}
                  </button>
                  {onDuzenleAc && (
                    <button
                      type="button"
                      onClick={() => onDuzenleAc("hikaye")}
                      className="rounded-lg border border-white/10 px-2 py-1.5 text-[10px] font-semibold text-slate-400 hover:text-white"
                    >
                      Özelleştir
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
