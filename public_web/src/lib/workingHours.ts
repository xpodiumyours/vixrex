/**
 * Public vitrin çalışma saatleri — booking_settings map + stores string.
 * Gün anahtarları: "1"=Pazartesi … "7"=Pazar (Flutter booking ile aynı).
 */

export type DayHours = {
  start: string;
  end: string;
  active: boolean;
};

export type WeekMap = Record<string, DayHours>;

export type OpenState = {
  isOpen: boolean;
  label: string;
  detail?: string;
  source: "hours" | "manual" | "fallback";
};

const DAY_LABELS_TR = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"] as const;
const SCHEMA_DAYS = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
] as const;

const TIMEZONE = "Europe/Istanbul";

function padTime(value: string): string | null {
  const m = String(value || "")
    .trim()
    .match(/^(\d{1,2}):(\d{2})$/);
  if (!m) return null;
  const h = Number(m[1]);
  const min = Number(m[2]);
  if (h < 0 || h > 23 || min < 0 || min > 59) return null;
  return `${String(h).padStart(2, "0")}:${String(min).padStart(2, "0")}`;
}

function parseDay(raw: unknown): DayHours | null {
  if (!raw || typeof raw !== "object") return null;
  const row = raw as Record<string, unknown>;
  const start = padTime(String(row.start ?? ""));
  const end = padTime(String(row.end ?? ""));
  const active = Boolean(row.active);
  if (!start || !end) return null;
  return { start, end, active };
}

/** booking_settings.working_hours benzeri map */
export function normalizeWeekMap(raw: unknown): WeekMap | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const src = raw as Record<string, unknown>;
  const out: WeekMap = {};
  let count = 0;
  for (let d = 1; d <= 7; d++) {
    const key = String(d);
    const parsed = parseDay(src[key] ?? src[d as unknown as string]);
    if (parsed) {
      out[key] = parsed;
      count++;
    }
  }
  return count > 0 ? out : null;
}

/** "09:00 - 20:00" biçimindeki saat aralığı deseni — çalışma saatleri
 * serbest metinden çıkarımının da kullandığı TEK DOĞRU KAYNAK (bkz.
 * serbestMetinCikarim.ts). Anchor YOK: bir cümlenin/paragrafın ortasında
 * geçen bir aralığı da bulur, yalnız tam eşleşen bir string'i değil. */
export const TIME_RANGE_REGEX = /(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})/;

/** Bir metindeki ilk "HH:MM - HH:MM" aralığını bulur. */
export function findTimeRange(
  text: string | null | undefined,
): { start: string; end: string; raw: string } | null {
  const raw = String(text || "");
  const m = raw.match(TIME_RANGE_REGEX);
  if (!m) return null;
  const start = padTime(m[1]);
  const end = padTime(m[2]);
  if (!start || !end) return null;
  return { start, end, raw: `${start} - ${end}` };
}

/** Eski string alan: "09:00 - 20:00" → hafta içi varsayılan (bilgi amaçlı, zayıf).
 * Bu fallback public görüntüleme içindir; Akıllı Motor mutation kaynağı değildir. */
export function weekMapFromPlainString(value: string | null | undefined): WeekMap | null {
  const raw = String(value || "").trim();
  if (!raw) return null;
  const bulunan = findTimeRange(raw);
  if (!bulunan) return null;
  const { start, end } = bulunan;
  const out: WeekMap = {};
  for (let d = 1; d <= 6; d++) {
    out[String(d)] = { start, end, active: true };
  }
  out["7"] = { start: "00:00", end: "00:00", active: false };
  return out;
}

export function resolveWeekMap(
  bookingHours: unknown,
  storeHours: unknown,
): WeekMap | null {
  return (
    normalizeWeekMap(bookingHours) ||
    (typeof storeHours === "string" ? weekMapFromPlainString(storeHours) : normalizeWeekMap(storeHours))
  );
}

function istanbulParts(now: Date) {
  const fmt = new Intl.DateTimeFormat("en-GB", {
    timeZone: TIMEZONE,
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });
  const parts = fmt.formatToParts(now);
  const weekday = parts.find((p) => p.type === "weekday")?.value ?? "Mon";
  const hour = Number(parts.find((p) => p.type === "hour")?.value ?? "0");
  const minute = Number(parts.find((p) => p.type === "minute")?.value ?? "0");
  const map: Record<string, number> = {
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
    Sun: 7,
  };
  return { dayKey: String(map[weekday] ?? 1), minutes: hour * 60 + minute };
}

function toMinutes(hhmm: string): number {
  const [h, m] = hhmm.split(":").map(Number);
  return h * 60 + m;
}

function previousDayKey(dayKey: string): string {
  const day = Number(dayKey);
  return String(day <= 1 ? 7 : day - 1);
}

function isOvernight(hours: DayHours): boolean {
  return toMinutes(hours.start) > toMinutes(hours.end);
}

export function formatTodayLine(map: WeekMap, now = new Date()): string | null {
  const { dayKey } = istanbulParts(now);
  const day = map[dayKey];
  if (!day) return null;
  if (!day.active) return "Bugün kapalı";
  return `Bugün ${day.start}–${day.end}`;
}

export function formatWeekLines(map: WeekMap): Array<{ day: string; hours: string; isToday: boolean }> {
  const { dayKey } = istanbulParts(new Date());
  return DAY_LABELS_TR.map((label, i) => {
    const key = String(i + 1);
    const day = map[key];
    const hours = !day || !day.active ? "Kapalı" : `${day.start}–${day.end}`;
    return { day: label, hours, isToday: key === dayKey };
  });
}

/**
 * Kural A: status === "Kapalı" her zaman kazanır;
 * değilse saatten hesapla; saat yoksa status / Açık.
 *
 * Geceye sarkan aralık (örn. Pzt 22:00–02:00) iki takvim gününü kapsar:
 * - Pazartesi 22:00 sonrası bugünkü satırdan,
 * - Salı 02:00 öncesi bir önceki günün satırından
 * hesaplanır. Böylece gece yarısından sonra yanlışlıkla "Kapalı" denmez.
 */
export function resolveOpenState(
  map: WeekMap | null,
  manualStatus: string | null | undefined,
  now = new Date(),
): OpenState {
  const status = String(manualStatus || "").trim();
  if (status === "Kapalı") {
    return { isOpen: false, label: "Kapalı", source: "manual" };
  }

  if (map) {
    const { dayKey, minutes } = istanbulParts(now);

    // Önce dün başlayan ve gece yarısından sonra bugüne taşan aralığı kontrol et.
    const previous = map[previousDayKey(dayKey)];
    if (previous?.active && isOvernight(previous)) {
      const previousEnd = toMinutes(previous.end);
      if (minutes < previousEnd) {
        return {
          isOpen: true,
          label: "Açık",
          detail: `${previous.end} kadar`,
          source: "hours",
        };
      }
    }

    const day = map[dayKey];
    if (!day || !day.active) {
      return { isOpen: false, label: "Kapalı", detail: "Bugün kapalı", source: "hours" };
    }

    const start = toMinutes(day.start);
    const end = toMinutes(day.end);

    // start === end mevcut sözleşmede 24 saat anlamına gelmez; kapalı kabul edilir.
    if (start === end) {
      return { isOpen: false, label: "Kapalı", detail: "Bugün kapalı", source: "hours" };
    }

    if (start > end) {
      // Bugün başlayan overnight aralığın yalnız gece yarısına kadarki kısmı.
      if (minutes >= start) {
        return {
          isOpen: true,
          label: "Açık",
          detail: `${day.end} kadar`,
          source: "hours",
        };
      }
      return {
        isOpen: false,
        label: "Kapalı",
        detail: `${day.start} açılır`,
        source: "hours",
      };
    }

    const open = minutes >= start && minutes < end;
    if (open) {
      return {
        isOpen: true,
        label: "Açık",
        detail: `${day.end} kadar`,
        source: "hours",
      };
    }
    return {
      isOpen: false,
      label: "Kapalı",
      detail: minutes < start ? `${day.start} açılır` : "Bugün kapandı",
      source: "hours",
    };
  }

  if (status === "Açık" || status === "") {
    return { isOpen: true, label: "Açık", source: status ? "manual" : "fallback" };
  }

  return { isOpen: false, label: status || "Kapalı", source: "manual" };
}

export function toOpeningHoursSpecification(map: WeekMap) {
  return Object.entries(map)
    .filter(([, hours]) => hours.active)
    .map(([day, hours]) => ({
      "@type": "OpeningHoursSpecification",
      dayOfWeek: SCHEMA_DAYS[Number(day) - 1],
      opens: hours.start,
      closes: hours.end,
    }));
}
