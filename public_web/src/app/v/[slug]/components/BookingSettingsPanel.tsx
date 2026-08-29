"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";

/**
 * Randevu ayarları paneli — Flutter Web'deki WorkingHoursEditor +
 * BookingSettings yönetimine karşılık gelir.
 *
 * Yönetilebilir alanlar:
 *   - Randevu aktif/pasif
 *   - Kapasite (1-5)
 *   - Çalışma saatleri (Pazartesi-Pazar, start/end/active)
 *   - Öğle arası (start/end/active)
 */

const GUN_ISIMLERI = [
  { key: "1", label: "Pazartesi" },
  { key: "2", label: "Salı" },
  { key: "3", label: "Çarşamba" },
  { key: "4", label: "Perşembe" },
  { key: "5", label: "Cuma" },
  { key: "6", label: "Cumartesi" },
  { key: "7", label: "Pazar" },
] as const;

interface WorkingHoursDay {
  start: string;
  end: string;
  active: boolean;
}

interface BookingSettings {
  is_enabled: boolean;
  capacity: number;
  working_hours: Record<string, WorkingHoursDay>;
  lunch_break: { start: string; end: string; active: boolean };
}

interface Props {
  slug: string;
  mevcutAyarlar: BookingSettings | null;
}

const VARSAYILAN_CALISMA: WorkingHoursDay = {
  start: "09:00",
  end: "19:00",
  active: true,
};

const VARSAYILAN_OGLE = { start: "12:00", end: "13:00", active: true };

function varsayilanAyarlar(): BookingSettings {
  const wh: Record<string, WorkingHoursDay> = {};
  for (const g of GUN_ISIMLERI) {
    if (g.key === "7") {
      wh[g.key] = { start: "00:00", end: "00:00", active: false };
    } else if (g.key === "6") {
      wh[g.key] = { start: "09:00", end: "16:00", active: true };
    } else {
      wh[g.key] = { ...VARSAYILAN_CALISMA };
    }
  }
  return {
    is_enabled: false,
    capacity: 1,
    working_hours: wh,
    lunch_break: { ...VARSAYILAN_OGLE },
  };
}

export function BookingSettingsPanel({ slug, mevcutAyarlar }: Props) {
  const router = useRouter();
  const [acik, setAcik] = useState(false);
  const [kaydediliyor, setKaydediliyor] = useState(false);
  const [mesaj, setMesaj] = useState<string | null>(null);

  const ayarlar = mevcutAyarlar ?? varsayilanAyarlar();

  const kaydet = useCallback(
    async (guncel: Partial<BookingSettings>) => {
      setKaydediliyor(true);
      setMesaj(null);
      try {
        const res = await fetch("/api/owner-booking-settings", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ slug, ...guncel }),
        });
        const govde = await res.json();
        if (!res.ok) {
          setMesaj(govde?.hata ?? "Kaydedilemedi.");
          return;
        }
        setMesaj("Kaydedildi.");
        router.refresh();
        setTimeout(() => setMesaj(null), 2000);
      } catch {
        setMesaj("Bağlantı kurulamadı.");
      } finally {
        setKaydediliyor(false);
      }
    },
    [slug, router]
  );

  const toggleEnabled = useCallback(() => {
    kaydet({ is_enabled: !ayarlar.is_enabled });
  }, [ayarlar.is_enabled, kaydet]);

  const capacityDegistir = useCallback(
    (val: number) => {
      kaydet({ capacity: Math.max(1, Math.min(5, val)) });
    },
    [kaydet]
  );

  const gunDegistir = useCallback(
    (gunKey: string, alan: "start" | "end" | "active", deger: string | boolean) => {
      const yeni = {
        ...ayarlar.working_hours,
        [gunKey]: { ...ayarlar.working_hours[gunKey], [alan]: deger },
      };
      kaydet({ working_hours: yeni });
    },
    [ayarlar.working_hours, kaydet]
  );

  const ogleDegistir = useCallback(
    (alan: "start" | "end" | "active", deger: string | boolean) => {
      kaydet({
        lunch_break: { ...ayarlar.lunch_break, [alan]: deger },
      });
    },
    [ayarlar.lunch_break, kaydet]
  );

  return (
    <div className="border-t border-white/10 px-4 py-3">
      <button
        type="button"
        onClick={() => setAcik(!acik)}
        className="flex w-full items-center justify-between text-left text-sm font-semibold text-white/80 hover:text-white transition"
      >
        <span className="flex items-center gap-2">
          📅 Randevu Ayarları
          {ayarlar.is_enabled && (
            <span className="rounded-full bg-green-500/20 px-2 py-0.5 text-[10px] font-bold text-green-400">
              Aktif
            </span>
          )}
        </span>
        <span
          className={`text-xs transition-transform ${acik ? "rotate-180" : ""}`}
        >
          ▾
        </span>
      </button>

      {acik && (
        <div className="mt-3 space-y-4">
          {/* Aktif/Pasif */}
          <div className="flex items-center justify-between">
            <span className="text-[13px] text-white/70">Randevu Sistemi</span>
            <button
              type="button"
              role="switch"
              aria-checked={ayarlar.is_enabled}
              disabled={kaydediliyor}
              onClick={toggleEnabled}
              className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full transition-colors ${
                ayarlar.is_enabled ? "bg-green-500" : "bg-white/20"
              }`}
            >
              <span
                className={`inline-block h-3.5 w-3.5 rounded-full bg-white shadow transition-transform ${
                  ayarlar.is_enabled ? "translate-x-4" : "translate-x-0.5"
                }`}
              />
            </button>
          </div>

          {/* Kapasite */}
          <div className="flex items-center justify-between">
            <span className="text-[13px] text-white/70">Kapasite (saatlik)</span>
            <div className="flex items-center gap-2">
              <button
                type="button"
                disabled={kaydediliyor || ayarlar.capacity <= 1}
                onClick={() => capacityDegistir(ayarlar.capacity - 1)}
                className="flex h-6 w-6 items-center justify-center rounded-lg bg-white/10 text-xs font-bold text-white/70 hover:bg-white/20 disabled:opacity-30"
              >
                −
              </button>
              <span className="w-6 text-center text-sm font-bold text-white">
                {ayarlar.capacity}
              </span>
              <button
                type="button"
                disabled={kaydediliyor || ayarlar.capacity >= 5}
                onClick={() => capacityDegistir(ayarlar.capacity + 1)}
                className="flex h-6 w-6 items-center justify-center rounded-lg bg-white/10 text-xs font-bold text-white/70 hover:bg-white/20 disabled:opacity-30"
              >
                +
              </button>
            </div>
          </div>

          {/* Çalışma Saatleri */}
          <div>
            <p className="mb-2 text-[11px] font-semibold text-white/50 uppercase tracking-wider">
              Çalışma Saatleri
            </p>
            <div className="space-y-1.5">
              {GUN_ISIMLERI.map((gun) => {
                const gunVerisi = ayarlar.working_hours[gun.key] ?? VARSAYILAN_CALISMA;
                return (
                  <div
                    key={gun.key}
                    className="flex items-center gap-2 rounded-lg bg-white/5 px-2 py-1.5"
                  >
                    <button
                      type="button"
                      role="switch"
                      aria-checked={gunVerisi.active}
                      disabled={kaydediliyor}
                      onClick={() => gunDegistir(gun.key, "active", !gunVerisi.active)}
                      className={`relative inline-flex h-4 w-7 shrink-0 cursor-pointer items-center rounded-full transition-colors ${
                        gunVerisi.active ? "bg-blue-500" : "bg-white/15"
                      }`}
                    >
                      <span
                        className={`inline-block h-3 w-3 rounded-full bg-white shadow transition-transform ${
                          gunVerisi.active ? "translate-x-3.5" : "translate-x-0.5"
                        }`}
                      />
                    </button>
                    <span
                      className={`w-20 text-[11px] font-semibold ${
                        gunVerisi.active ? "text-white/80" : "text-white/30"
                      }`}
                    >
                      {gun.label}
                    </span>
                    {gunVerisi.active ? (
                      <>
                        <input
                          type="time"
                          value={gunVerisi.start}
                          disabled={kaydediliyor}
                          onChange={(e) => gunDegistir(gun.key, "start", e.target.value)}
                          className="rounded border border-white/10 bg-white/5 px-1.5 py-0.5 text-[11px] text-white/80 [color-scheme:dark]"
                        />
                        <span className="text-[10px] text-white/30">—</span>
                        <input
                          type="time"
                          value={gunVerisi.end}
                          disabled={kaydediliyor}
                          onChange={(e) => gunDegistir(gun.key, "end", e.target.value)}
                          className="rounded border border-white/10 bg-white/5 px-1.5 py-0.5 text-[11px] text-white/80 [color-scheme:dark]"
                        />
                      </>
                    ) : (
                      <span className="text-[11px] text-white/20">Kapalı</span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Öğle Arası */}
          <div>
            <p className="mb-2 text-[11px] font-semibold text-white/50 uppercase tracking-wider">
              Öğle Arası
            </p>
            <div className="flex items-center gap-2 rounded-lg bg-white/5 px-2 py-1.5">
              <button
                type="button"
                role="switch"
                aria-checked={ayarlar.lunch_break.active}
                disabled={kaydediliyor}
                onClick={() => ogleDegistir("active", !ayarlar.lunch_break.active)}
                className={`relative inline-flex h-4 w-7 shrink-0 cursor-pointer items-center rounded-full transition-colors ${
                  ayarlar.lunch_break.active ? "bg-blue-500" : "bg-white/15"
                }`}
              >
                <span
                  className={`inline-block h-3 w-3 rounded-full bg-white shadow transition-transform ${
                    ayarlar.lunch_break.active ? "translate-x-3.5" : "translate-x-0.5"
                  }`}
                />
              </button>
              {ayarlar.lunch_break.active ? (
                <>
                  <input
                    type="time"
                    value={ayarlar.lunch_break.start}
                    disabled={kaydediliyor}
                    onChange={(e) => ogleDegistir("start", e.target.value)}
                    className="rounded border border-white/10 bg-white/5 px-1.5 py-0.5 text-[11px] text-white/80 [color-scheme:dark]"
                  />
                  <span className="text-[10px] text-white/30">—</span>
                  <input
                    type="time"
                    value={ayarlar.lunch_break.end}
                    disabled={kaydediliyor}
                    onChange={(e) => ogleDegistir("end", e.target.value)}
                    className="rounded border border-white/10 bg-white/5 px-1.5 py-0.5 text-[11px] text-white/80 [color-scheme:dark]"
                  />
                </>
              ) : (
                <span className="text-[11px] text-white/20">Pasif</span>
              )}
            </div>
          </div>

          {/* Mesaj */}
          {mesaj && (
            <p
              className={`text-[11px] font-semibold ${
                mesaj.includes("hata") || mesaj.includes("kayedilemedi")
                  ? "text-red-400"
                  : "text-green-400"
              }`}
            >
              {mesaj}
            </p>
          )}
        </div>
      )}
    </div>
  );
}
