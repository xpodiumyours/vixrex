"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { FIELD_BY_KEY, type VitrinField } from "@/lib/vitrinFieldSchema";
import { hazirlikRaporu } from "@/lib/vitrinReadiness";

// Vixrex Asistan — sahip paneli (implementation_plan.md Commit 9).
//
// TEK PANEL, İKİ YOL:
//   1. Vitrindeki alana tıkla → asistan o alanı seçer, kutuya yazarsın
//   2. Eksik alan listesinden seç → aynı yere gelir
//
// Alan başına bileşen veya dallanma YOKTUR: hangi kutunun çizileceğine
// şemadaki `tip` karar verir. Yeni alan eklemek bu dosyayı değiştirmez.
//
// DÜRÜSTLÜK KURALI: asistan anlamadığı bir şeyi "işledim" diye geçiştirmez.
// Referans HTML'de bu yapılıyordu ("içeriği işlendi!") ve hiçbir şey
// olmuyordu; kullanıcı güvenini en hızlı yakan şey budur.

interface Props {
  slug: string;
  draftData: Record<string, unknown>;
}

interface Mesaj {
  id: number;
  kimden: "asistan" | "kullanici";
  metin: string;
}

const VURGU_SINIFI = "vixrex-secili-alan";

export default function OwnerAssistantPanel({ slug, draftData }: Props) {
  const router = useRouter();
  const rapor = useMemo(() => hazirlikRaporu(draftData), [draftData]);

  const [acik, setAcik] = useState(false);
  const [mesajlar, setMesajlar] = useState<Mesaj[]>([]);
  const [seciliAlan, setSeciliAlan] = useState<VitrinField | null>(null);
  const [giris, setGiris] = useState("");
  const [kaydediliyor, setKaydediliyor] = useState(false);

  const girisRef = useRef<HTMLTextAreaElement>(null);
  const akisRef = useRef<HTMLDivElement>(null);
  const vurguluRef = useRef<Element | null>(null);
  const sayacRef = useRef(0);

  const mesajEkle = useCallback((kimden: Mesaj["kimden"], metin: string) => {
    // Numara BURADA sabitlenir. Güncelleyicinin içinde okunursa, aynı anda
    // eklenen mesajlar React toplu güncelleme yaptığı için hepsi son değeri
    // alır ve aynı anahtarı paylaşır ("two children with the same key").
    sayacRef.current += 1;
    const id = sayacRef.current;
    setMesajlar((m) => [...m, { id, kimden, metin }]);
  }, []);

  // Açılış selamı — bir kez.
  useEffect(() => {
    if (mesajlar.length > 0) return;
    const selam = rapor.temelTamam
      ? `Vitrininiz yayına hazır görünüyor. Doluluk: %${rapor.yuzde}.`
      : `Vitrininizin doluluk oranı %${rapor.yuzde}. Birkaç alan eksik.`;
    mesajEkle("asistan", selam);
    if (rapor.sonrakiAdim) mesajEkle("asistan", rapor.sonrakiAdim);
    mesajEkle(
      "asistan",
      "Değiştirmek istediğiniz yazıya vitrinde tıklayın — buradan düzenleriz."
    );
  }, [mesajlar.length, rapor, mesajEkle]);

  useEffect(() => {
    akisRef.current?.scrollTo({ top: akisRef.current.scrollHeight });
  }, [mesajlar]);

  const vurguyuTemizle = useCallback(() => {
    vurguluRef.current?.classList.remove(VURGU_SINIFI);
    vurguluRef.current = null;
  }, []);

  const alanSec = useCallback(
    (anahtar: string, oge?: Element | null) => {
      const alan = FIELD_BY_KEY.get(anahtar);
      if (!alan) return;

      vurguyuTemizle();
      const hedef =
        oge ?? document.querySelector(`[data-vixrex-editable="${anahtar}"]`);
      if (hedef) {
        hedef.classList.add(VURGU_SINIFI);
        vurguluRef.current = hedef;
        hedef.scrollIntoView({ behavior: "smooth", block: "center" });
      }

      setSeciliAlan(alan);
      const mevcut = draftData[alan.kolon];
      setGiris(
        alan.tip === "acikKapali"
          ? ""
          : mevcut === null || mevcut === undefined
          ? ""
          : String(mevcut)
      );
      setAcik(true);
      mesajEkle(
        "asistan",
        `"${alan.etiket}" alanını seçtiniz. Yeni değeri yazıp gönderin.${
          alan.ipucu ? ` (${alan.ipucu})` : ""
        }`
      );
      window.setTimeout(() => girisRef.current?.focus(), 60);
    },
    [draftData, mesajEkle, vurguyuTemizle]
  );

  // Vitrindeki işaretli öğeler için tek dinleyici.
  useEffect(() => {
    const tiklama = (e: MouseEvent) => {
      const hedef = (e.target as HTMLElement | null)?.closest(
        "[data-vixrex-editable]"
      );
      if (!hedef) return;
      const anahtar = hedef.getAttribute("data-vixrex-editable");
      if (!anahtar) return;
      e.preventDefault();
      alanSec(anahtar, hedef);
    };
    document.addEventListener("click", tiklama);
    return () => document.removeEventListener("click", tiklama);
  }, [alanSec]);

  useEffect(() => vurguyuTemizle, [vurguyuTemizle]);

  // Görsel alanları: URL yazdırmak yerine dosya yükletiyoruz. Esnafın
  // elinde adres yok, telefonunda fotoğraf var.
  const gorselYukle = async (dosya: File) => {
    if (!seciliAlan || seciliAlan.tip !== "gorsel") return;
    const alan = seciliAlan;

    mesajEkle("kullanici", `📷 ${dosya.name}`);
    setKaydediliyor(true);

    try {
      const form = new FormData();
      form.append("slug", slug);
      form.append("anahtar", alan.anahtar);
      form.append("dosya", dosya);

      const yukleme = await fetch("/api/owner-upload", {
        method: "POST",
        body: form,
      });
      const yuklemeGovde = await yukleme.json();

      if (!yukleme.ok) {
        mesajEkle("asistan", yuklemeGovde?.hata ?? "Görsel yüklenemedi.");
        return;
      }

      // Yükleme başarılı — adres NORMAL alan kayıt yolundan geçer. Böylece
      // doğrulama ve yetki kontrolü tek yerde kalır, ikinci kayıt yolu açılmaz.
      const kayit = await fetch("/api/owner-draft", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug,
          anahtar: alan.anahtar,
          deger: yuklemeGovde.url,
        }),
      });
      const kayitGovde = await kayit.json();

      if (!kayit.ok) {
        mesajEkle("asistan", kayitGovde?.hata ?? "Görsel kaydedilemedi.");
        return;
      }

      mesajEkle("asistan", `${alan.etiket} güncellendi.`);
      setSeciliAlan(null);
      vurguyuTemizle();
      router.refresh();
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar deneyin.");
    } finally {
      setKaydediliyor(false);
    }
  };

  const gonder = async () => {
    const metin = giris.trim();

    if (!seciliAlan) {
      // Anlamadığımızı dürüstçe söyleriz.
      if (metin) mesajEkle("kullanici", metin);
      mesajEkle(
        "asistan",
        "Hangi alanı değiştireceğinizi bilmiyorum. Vitrinde düzenlemek istediğiniz yazıya tıklayın, sonra yeni değeri yazın."
      );
      setGiris("");
      return;
    }

    const alan = seciliAlan;
    const gonderilecek: string | boolean =
      alan.tip === "acikKapali"
        ? ["evet", "aç", "açık", "göster", "true"].includes(metin.toLowerCase())
        : metin;

    mesajEkle("kullanici", metin || "(boş bırak)");
    setKaydediliyor(true);

    try {
      const yanit = await fetch("/api/owner-draft", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, anahtar: alan.anahtar, deger: gonderilecek }),
      });
      const govde = await yanit.json();

      if (!yanit.ok) {
        mesajEkle("asistan", govde?.hata ?? "Kaydedilemedi.");
        return;
      }

      mesajEkle(
        "asistan",
        `${alan.etiket} güncellendi. Müşteriler yayınlayana kadar göremez.`
      );
      setGiris("");
      setSeciliAlan(null);
      vurguyuTemizle();
      router.refresh();
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar deneyin.");
    } finally {
      setKaydediliyor(false);
    }
  };

  return (
    <>
      {/* Maskot düğmesi */}
      <button
        type="button"
        onClick={() => setAcik((v) => !v)}
        className="fixed bottom-5 right-5 z-[75] flex items-center gap-2 rounded-full bg-gradient-to-r from-blue-600 to-blue-700 px-4 py-3 text-white shadow-lg shadow-blue-500/30 hover:shadow-blue-500/50 transition"
        aria-label="Vixrex Asistan"
      >
        <span className="text-xl leading-none">🦊</span>
        <span className="text-sm font-semibold hidden sm:inline">
          Vixrex Asistan
        </span>
        {!rapor.temelTamam && (
          <span className="ml-1 rounded-full bg-amber-400 px-2 py-0.5 text-[10px] font-bold text-slate-900">
            %{rapor.yuzde}
          </span>
        )}
      </button>

      {acik && (
        <div className="fixed bottom-24 right-5 z-[75] flex w-[min(24rem,calc(100vw-2.5rem))] flex-col rounded-2xl border border-white/10 bg-[#0B1120] shadow-2xl">
          <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
            <div>
              <p className="text-sm font-bold text-white">🦊 Vixrex Asistan</p>
              <p className="text-[11px] text-slate-400">
                Doluluk %{rapor.yuzde} · {rapor.doluSayisi}/{rapor.toplamSayisi} alan
              </p>
            </div>
            <button
              type="button"
              onClick={() => setAcik(false)}
              className="text-lg leading-none text-slate-400 hover:text-white"
              aria-label="Kapat"
            >
              ×
            </button>
          </div>

          <div
            ref={akisRef}
            className="max-h-72 space-y-2 overflow-y-auto px-4 py-3"
          >
            {mesajlar.map((m) => (
              <div
                key={m.id}
                className={`max-w-[85%] rounded-xl px-3 py-2 text-xs leading-relaxed ${
                  m.kimden === "asistan"
                    ? "bg-white/[0.06] text-slate-200"
                    : "ml-auto bg-blue-600 text-white"
                }`}
              >
                {m.metin}
              </div>
            ))}
          </div>

          {/* Eksik alanlar — şemadan üretilir, elle sayılmaz */}
          {rapor.eksikler.length > 0 && !seciliAlan && (
            <div className="border-t border-white/10 px-4 py-3">
              <p className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                Eksik alanlar
              </p>
              <div className="flex flex-wrap gap-1.5">
                {rapor.eksikler.slice(0, 6).map((e) => (
                  <button
                    key={e.anahtar}
                    type="button"
                    onClick={() => alanSec(e.anahtar)}
                    className={`rounded-full px-2.5 py-1 text-[11px] font-medium transition ${
                      e.onem === "temel"
                        ? "bg-amber-500/15 text-amber-300 hover:bg-amber-500/25"
                        : "bg-white/[0.06] text-slate-300 hover:bg-white/10"
                    }`}
                  >
                    {e.etiket}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div className="border-t border-white/10 px-4 py-3">
            {seciliAlan && (
              <p className="mb-2 text-[11px] text-blue-300">
                Düzenleniyor: <strong>{seciliAlan.etiket}</strong>
                {seciliAlan.maxUzunluk
                  ? ` · ${giris.length}/${seciliAlan.maxUzunluk}`
                  : ""}
              </p>
            )}
            {seciliAlan?.tip === "gorsel" ? (
              <div>
                <label
                  className={`flex w-full cursor-pointer items-center justify-center gap-2 rounded-lg border border-dashed border-blue-500/40 bg-blue-500/[0.06] px-4 py-4 text-xs font-semibold text-blue-300 transition hover:bg-blue-500/10 ${
                    kaydediliyor ? "pointer-events-none opacity-50" : ""
                  }`}
                >
                  <span className="text-base">📷</span>
                  {kaydediliyor ? "Yükleniyor…" : "Fotoğraf Seç"}
                  <input
                    type="file"
                    accept="image/jpeg,image/png,image/webp"
                    disabled={kaydediliyor}
                    className="hidden"
                    onChange={(e) => {
                      const dosya = e.target.files?.[0];
                      e.target.value = ""; // aynı dosya tekrar seçilebilsin
                      if (dosya) void gorselYukle(dosya);
                    }}
                  />
                </label>
                <p className="mt-2 text-center text-[11px] text-slate-500">
                  JPG, PNG veya WebP · en fazla 5 MB
                </p>
              </div>
            ) : (
            <div className="flex items-end gap-2">
              <textarea
                ref={girisRef}
                value={giris}
                onChange={(e) => setGiris(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) {
                    e.preventDefault();
                    if (!kaydediliyor) void gonder();
                  }
                }}
                rows={seciliAlan?.tip === "uzunMetin" ? 3 : 1}
                maxLength={seciliAlan?.maxUzunluk}
                disabled={kaydediliyor}
                placeholder={
                  seciliAlan
                    ? "Yeni değeri yazın…"
                    : "Vitrinde bir yazıya tıklayın…"
                }
                className="flex-1 resize-none rounded-lg border border-white/10 bg-slate-900/70 px-3 py-2 text-xs text-white outline-none focus:border-blue-500/60"
              />
              <button
                type="button"
                onClick={() => void gonder()}
                disabled={kaydediliyor}
                className="rounded-lg bg-blue-600 px-3 py-2 text-xs font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
              >
                {kaydediliyor ? "…" : "Gönder"}
              </button>
            </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
