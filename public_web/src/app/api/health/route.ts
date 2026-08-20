import { NextResponse } from "next/server";
import { paytrEnv } from "@/lib/paytr";
import { isSupabaseConfigured, supabase } from "@/lib/supabase";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const DATABASE_TIMEOUT_MS = 3_000;

type DatabaseCheck = { status: "ok" | "error" };

async function checkDatabase(): Promise<DatabaseCheck> {
  if (!isSupabaseConfigured()) {
    return { status: "error" };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), DATABASE_TIMEOUT_MS);

  try {
    const { error } = await supabase
      .from("stores")
      .select("id")
      .limit(1)
      .abortSignal(controller.signal);

    if (error) {
      console.error("[health] database check failed");
      return { status: "error" };
    }

    return { status: "ok" };
  } catch {
    console.error("[health] database check failed");
    return { status: "error" };
  } finally {
    clearTimeout(timeout);
  }
}

export async function GET() {
  const database = await checkDatabase();
  // PayTR'nin genel bir health ucu yok; durum sorgusu gerçek merchant_oid
  // ister. Sağlık kontrolü bu nedenle sahte işlem açmadan, ödeme rotalarının
  // kullandığı aynı sunucu ayarının eksiksiz olup olmadığını doğrular.
  const paytr = paytrEnv()
    ? ({ status: "configured" } as const)
    : ({ status: "unconfigured" } as const);
  const healthy = database.status === "ok" && paytr.status === "configured";

  return NextResponse.json(
    {
      status: healthy ? "ok" : "unhealthy",
      checkedAt: new Date().toISOString(),
      checks: {
        application: { status: "ok" },
        database,
        paytr,
      },
    },
    {
      status: healthy ? 200 : 503,
      headers: {
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff",
      },
    },
  );
}
