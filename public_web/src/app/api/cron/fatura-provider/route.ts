import { timingSafeEqual } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { arkaPlanFaturaSonucunuAl } from "@/lib/faturaArkaPlanIslemi";
export const dynamic = "force-dynamic";
export const maxDuration = 60;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function same(actual: unknown, provided: string): boolean {
  if (typeof actual !== "string" || !UUID.test(actual) || !UUID.test(provided)) return false;
  const a=Buffer.from(actual.toLowerCase(),"utf8"), b=Buffer.from(provided.toLowerCase(),"utf8");
  return a.length===b.length && timingSafeEqual(a,b);
}
export async function POST(request: NextRequest) {
  const token=(request.headers.get("x-vixrex-callback") ?? "").trim();
  let body: {jobId?:unknown};
  try { body=await request.json(); }
  catch { return NextResponse.json({error:"Invalid request"},{status:400}); }
  const id=body?.jobId;
  if (typeof id!=="string" || !UUID.test(id) || !UUID.test(token)) {
    return NextResponse.json({error:"Unauthorized"},{status:401});
  }
  const admin=getSupabaseAdmin();
  const {data: job,error: jobError}=await admin.from("invoice_provider_runs")
    .select("job_id,store_id,state,callback_token").eq("job_id",id).maybeSingle();
  if (jobError) return NextResponse.json({error:"Worker unavailable"},{status:503});
  if (!job || !same(job.callback_token,token)) return NextResponse.json({error:"Unauthorized"},{status:401});
  if (job.state!=="received") return NextResponse.json({ok:true,pending:job.state==="queued"});
  const {data: store,error: storeError}=await admin.from("stores").select("slug").eq("id",job.store_id).maybeSingle();
  if (storeError || !store?.slug) return NextResponse.json({error:"Store unavailable"},{status:503});
  try {
    const result=await arkaPlanFaturaSonucunuAl(admin,job.store_id,store.slug,id);
    return NextResponse.json({ok:true,pending:result.hazirlaniyor===true},{headers:{"Cache-Control":"no-store"}});
  } catch (err) {
    const code=err instanceof Error && /^[A-Z_]{1,96}$/.test(err.message) ? err.message : "FATURA_WORKER_FAILED";
    console.error("[fatura-provider] failed:",code);
    return NextResponse.json({error:"Processing failed"},{status:503});
  }
}
