import { NextRequest, NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";

// GÜVENLİK (2026-08-15 taraması):
//   1) Önceden TURNSTILE_SECRET_KEY tanımlı değilse bot doğrulaması
//      SESSİZCE atlanıyordu (fail-open) — .env.example'da bu değişken
//      boş, yani prod'da hiç ayarlanmamışsa koruma HİÇ çalışmıyordu.
//      Artık secret yoksa istek REDDEDİLİYOR (fail-closed).
//   2) Hiç oran sınırı yoktu — artık aynı desen (assistant_rate_limits/
//      consume_assistant_request) burada da kullanılıyor.
const REPORT_LIMIT_PER_IP = 10;
const REPORT_LIMIT_WINDOW_SECONDS = 3600;

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { articleId, reason, turnstileToken } = body;

    if (!articleId || !reason) {
      return NextResponse.json({ message: "Missing required fields (articleId, reason)" }, { status: 400 });
    }

    const turnstileSecret = process.env.TURNSTILE_SECRET_KEY;
    if (!turnstileSecret) {
      console.error("[report-abuse] TURNSTILE_SECRET_KEY not configured — reddediliyor (fail-closed)");
      return NextResponse.json(
        { message: "Bot verification is not configured. Please try again later." },
        { status: 503 }
      );
    }
    if (!turnstileToken) {
      return NextResponse.json({ message: "Bot verification token is required" }, { status: 400 });
    }
    const verifyResponse = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `secret=${encodeURIComponent(turnstileSecret)}&response=${encodeURIComponent(turnstileToken)}`,
    });
    const verifyData = (await verifyResponse.json()) as { success: boolean };
    if (!verifyData.success) {
      return NextResponse.json({ message: "Bot verification failed" }, { status: 403 });
    }

    const ip = getClientIp(req);
    const clientKey = fingerprintClient(ip);

    const { data: limitRows, error: limitError } = await getSupabaseAdmin().rpc(
      "consume_assistant_request",
      {
        p_client_key: `report_abuse:${clientKey}`,
        p_max_requests: REPORT_LIMIT_PER_IP,
        p_window_seconds: REPORT_LIMIT_WINDOW_SECONDS,
      }
    );
    const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
    if (limitError) {
      console.error("[report-abuse] rate limit check failed:", limitError.message);
      return NextResponse.json({ message: "Failed to submit report" }, { status: 500 });
    }
    if (limit && !limit.allowed) {
      return NextResponse.json(
        { message: `Too many reports. Try again in ${limit.retry_after_seconds}s.` },
        { status: 429 }
      );
    }

    // Insert report into Supabase
    const { error } = await supabase
      .from("article_reports")
      .insert({
        article_id: articleId,
        reason: reason.trim(),
        reporter_ip: ip,
      });

    if (error) {
      throw error;
    }

    return NextResponse.json({ success: true, message: "Report successfully submitted" });
  } catch (err: unknown) {
    console.error("Error submitting report:", err);
    const errMsg = err instanceof Error ? err.message : "Failed to submit report";
    return NextResponse.json({ message: errMsg }, { status: 500 });
  }
}
