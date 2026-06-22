import { NextRequest, NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { articleId, reason, turnstileToken } = body;

    if (!articleId || !reason) {
      return NextResponse.json({ message: "Missing required fields (articleId, reason)" }, { status: 400 });
    }

    // Cloudflare Turnstile Verification (Enforced if secret key is configured)
    const turnstileSecret = process.env.TURNSTILE_SECRET_KEY;
    if (turnstileSecret) {
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
    }

    // Fetch reporter's IP address
    const xForwardedFor = req.headers.get("x-forwarded-for");
    const ip = xForwardedFor ? xForwardedFor.split(",")[0].trim() : "127.0.0.1";

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
