import {beforeEach,describe,it,expect,vi} from "vitest";
import {NextRequest} from "next/server";
const m=vi.hoisted(()=>({from:vi.fn(),process:vi.fn()}));
vi.mock("@/lib/supabaseAdmin",()=>({getSupabaseAdmin:()=>({from:m.from})}));
vi.mock("@/lib/faturaArkaPlanIslemi",()=>({arkaPlanFaturaSonucunuAl:m.process}));
import {POST} from "@/app/api/cron/fatura-provider/route";
const ID="11111111-1111-4111-8111-111111111111", STORE="22222222-2222-4222-8222-222222222222",TOKEN="33333333-3333-4333-8333-333333333333";
const req=(token=TOKEN)=>new NextRequest("https://vixrex.com/api/cron/fatura-provider",{method:"POST",headers:{"content-type":"application/json","x-vixrex-callback":token},body:JSON.stringify({jobId:ID})});
beforeEach(()=>{vi.clearAllMocks();m.from.mockImplementation((table:string)=>({
  select:()=>({eq:()=>({maybeSingle:async()=>({data:table==="stores"?{slug:"demo"}:{job_id:ID,store_id:STORE,state:"received",callback_token:TOKEN},error:null})})})
}));m.process.mockResolvedValue({hazirlaniyor:true});});
describe("fatura provider callback",()=>{
 it("yetkisiz isteği reddeder",async()=>{expect((await POST(req(STORE))).status).toBe(401);expect(m.process).not.toHaveBeenCalled();});
 it("geçerli özel iş yetkisiyle aşamayı ilerletir",async()=>{expect((await POST(req())).status).toBe(200);expect(m.process).toHaveBeenCalledWith(expect.anything(),STORE,"demo",ID);});
});
