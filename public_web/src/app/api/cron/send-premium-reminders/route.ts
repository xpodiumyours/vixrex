import { NextRequest, NextResponse } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

// #257: Premium süresi dolmadan önce esnafa OneSignal push hatırlatması.
//
// NEDEN AYRI BİR ROTA
// Vercel Cron bu rotayı günde bir çağırır (bkz. vercel.json "crons").
// Supabase tarafı yalnız "kime gönderilecek" listesini döner
// (list_premium_expiry_reminder_candidates) — gerçek HTTP çağrısı
// (OneSignal) burada, Next.js sunucusunda yapılır. Bu proje Postgres'ten
// dış HTTP çağrısı yapmıyor (pg_net kullanılmıyor) — mevcut sınır korunur.
//
// GÜVENLİK
//   1. Yalnız Vercel Cron çağırabilir — CRON_SECRET eksikse fail-closed
//      reddedilir (secret yoksa istek sessizce geçmez).
//   2. OneSignal secret'ları eksikse de fail-closed reddedilir.
//   3. Önce gönder, SONRA işaretle — push başarısız olursa satır
//      işaretsiz kalır, ertesi gün tekrar denenir (bkz. migration notu).

export const dynamic = "force-dynamic";

const REMINDER_WINDOW_DAYS = 3;
const ONESIGNAL_URL = "https://api.onesignal.com/notifications";
const MS_PER_DAY = 86_400_000;

interface ReminderCandidate {
  store_id: string;
  user_id: string;
  store_slug: string;
  store_name: string | null;
  premium_expires_at: string;
}

function reminderCopy(candidate: ReminderCandidate): { title: string; body: string } {
  const daysLeft = Math.max(
    1,
    Math.round((new Date(candidate.premium_expires_at).getTime() - Date.now()) / MS_PER_DAY)
  );
  const storeLabel = candidate.store_name?.trim() || candidate.store_slug;
  const title = "Aboneliğin yakında sona eriyor";
  const body =
    daysLeft === 1
      ? `${storeLabel} vitrininizin premium aboneliği yarın sona eriyor. Yenilemezseniz vitrin yayından kalkar.`
      : `${storeLabel} vitrininizin premium aboneliği ${daysLeft} gün içinde sona eriyor. Yenilemezseniz vitrin yayından kalkar.`;
  return { title, body };
}

async function sendOneSignalPush(
  candidate: ReminderCandidate,
  appId: string,
  restKey: string
): Promise<boolean> {
  const { title, body } = reminderCopy(candidate);
  try {
    const res = await fetch(ONESIGNAL_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        Authorization: `Key ${restKey}`,
      },
      body: JSON.stringify({
        app_id: appId,
        include_aliases: { external_id: [candidate.user_id] },
        target_channel: "push",
        headings: { en: title, tr: title },
        contents: { en: body, tr: body },
        data: {
          type: "premium_reminder",
          storeSlug: candidate.store_slug,
          slug: candidate.store_slug,
        },
      }),
    });
    if (!res.ok) {
      console.error(
        "[cron/send-premium-reminders] OneSignal başarısız:",
        candidate.store_slug,
        await res.text().catch(() => "")
      );
      return false;
    }
    return true;
  } catch (err) {
    console.error("[cron/send-premium-reminders] fetch hatası:", candidate.store_slug, err);
    return false;
  }
}

export async function GET(req: NextRequest) {
  const cronSecret = process.env.CRON_SECRET;
  if (!cronSecret) {
    console.error(
      "[cron/send-premium-reminders] CRON_SECRET tanımlı değil — reddediliyor (fail-closed)"
    );
    return NextResponse.json({ message: "Not configured" }, { status: 503 });
  }
  if (req.headers.get("authorization") !== `Bearer ${cronSecret}`) {
    return NextResponse.json({ message: "Unauthorized" }, { status: 401 });
  }

  const appId = process.env.ONESIGNAL_APP_ID;
  const restKey = process.env.ONESIGNAL_REST_API_KEY;
  if (!appId || !restKey) {
    console.error(
      "[cron/send-premium-reminders] OneSignal yapılandırması eksik — reddediliyor (fail-closed)"
    );
    return NextResponse.json({ message: "OneSignal not configured" }, { status: 503 });
  }

  const { data, error } = await getSupabaseAdmin().rpc(
    "list_premium_expiry_reminder_candidates",
    { p_within_days: REMINDER_WINDOW_DAYS }
  );

  if (error) {
    console.error("[cron/send-premium-reminders] RPC başarısız:", error.message);
    return NextResponse.json({ message: "RPC failed" }, { status: 500 });
  }

  const candidates = (Array.isArray(data) ? data : []) as ReminderCandidate[];
  let sent = 0;
  let failed = 0;

  for (const candidate of candidates) {
    const ok = await sendOneSignalPush(candidate, appId, restKey);
    if (!ok) {
      failed += 1;
      continue;
    }
    const { error: markError } = await getSupabaseAdmin().rpc(
      "mark_premium_expiry_reminder_sent",
      {
        p_store_id: candidate.store_id,
        p_premium_expires_at: candidate.premium_expires_at,
      }
    );
    if (markError) {
      // Push zaten gönderildi — işaretleme başarısız olsa bile bunu
      // "başarısız" saymıyoruz, yalnız logluyoruz. En kötü ihtimalle
      // ertesi gün bir kez daha hatırlatma gider (çift bildirim,
      // kaçırılan bildirimden daha iyi bir hata — bkz. migration notu).
      console.error(
        "[cron/send-premium-reminders] işaretleme başarısız (push yine de gitti):",
        candidate.store_slug,
        markError.message
      );
    }
    sent += 1;
  }

  return NextResponse.json({ ok: true, targeted: candidates.length, sent, failed });
}
