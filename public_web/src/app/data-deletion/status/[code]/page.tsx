import { notFound } from "next/navigation";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

interface PageProps {
  params: Promise<{ code: string }>;
}

async function getDeletionRequest(code: string) {
  const admin = getSupabaseAdmin();
  const { data, error } = await admin
    .from("meta_data_deletion_requests")
    .select("*")
    .eq("confirmation_code", code)
    .maybeSingle();

  if (error || !data) return null;
  return data;
}

export async function generateMetadata() {
  return {
    title: "Veri Silme Talebi Durumu - VixRex",
    robots: "noindex, nofollow",
  };
}

export default async function DataDeletionStatusPage(props: PageProps) {
  const params = await props.params;
  const request = await getDeletionRequest(params.code);

  if (!request) {
    notFound();
  }

  const getStatusTextAndColor = (status: string) => {
    switch (status) {
      case "completed":
        return { text: "Tamamlandı", color: "text-emerald-500 bg-emerald-500/10 border-emerald-500/20" };
      case "processing":
        return { text: "İşleniyor", color: "text-amber-500 bg-amber-500/10 border-amber-500/20" };
      case "failed":
        return { text: "Başarısız", color: "text-rose-500 bg-rose-500/10 border-rose-500/20" };
      default:
        return { text: "Alındı", color: "text-blue-500 bg-blue-500/10 border-blue-500/20" };
    }
  };

  const statusInfo = getStatusTextAndColor(request.status);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-8 shadow-2xl relative overflow-hidden">
        {/* Glow decoration */}
        <div className="absolute -top-24 -left-24 w-48 h-48 bg-blue-500/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-24 -right-24 w-48 h-48 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />

        <div className="flex flex-col items-center text-center gap-6">
          <div className="w-16 h-16 rounded-2xl bg-slate-800 border border-slate-700 flex items-center justify-center">
            <svg
              className="w-8 h-8 text-blue-500"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
              />
            </svg>
          </div>

          <div className="flex flex-col gap-2">
            <h1 className="text-2xl font-black tracking-tight">Veri Silme Talebi</h1>
            <p className="text-sm text-slate-400 font-medium leading-relaxed">
              Meta/Instagram entegrasyonu üzerinden oluşturulan veri silme talebinizin anlık durumunu aşağıdan takip edebilirsiniz.
            </p>
          </div>

          <div className="w-full h-px bg-slate-800/80 my-2" />

          <div className="w-full flex flex-col gap-4 text-left">
            <div className="flex justify-between items-center bg-slate-850 p-4 rounded-2xl border border-slate-800">
              <span className="text-sm font-bold text-slate-400">Talep Durumu</span>
              <span className={`text-xs font-black uppercase px-3 py-1 rounded-full border ${statusInfo.color}`}>
                {statusInfo.text}
              </span>
            </div>

            <div className="flex flex-col gap-3 bg-slate-850 p-5 rounded-2xl border border-slate-800 text-sm">
              <div className="flex justify-between">
                <span className="font-semibold text-slate-400">Onay Kodu:</span>
                <span className="font-mono text-slate-200 font-bold">{request.confirmation_code}</span>
              </div>
              <div className="flex justify-between">
                <span className="font-semibold text-slate-400">Kaynak Platform:</span>
                <span className="text-slate-200 font-bold capitalize">{request.provider}</span>
              </div>
              <div className="flex justify-between">
                <span className="font-semibold text-slate-400">Talep Tarihi:</span>
                <span className="text-slate-200 font-bold">
                  {new Date(request.requested_at).toLocaleDateString("tr-TR")}
                </span>
              </div>
              {request.completed_at && (
                <div className="flex justify-between">
                  <span className="font-semibold text-slate-400">Tamamlanma Tarihi:</span>
                  <span className="text-slate-200 font-bold">
                    {new Date(request.completed_at).toLocaleDateString("tr-TR")}
                  </span>
                </div>
              )}
              {request.error_message && (
                <div className="flex flex-col gap-1 mt-2 p-3 bg-rose-500/5 border border-rose-500/10 rounded-xl">
                  <span className="text-xs font-bold text-rose-400">Hata Mesajı:</span>
                  <span className="text-xs text-rose-300 font-medium">{request.error_message}</span>
                </div>
              )}
            </div>
          </div>

          <p className="text-[10px] text-slate-500 font-bold tracking-wider mt-4 uppercase">
            VixRex Veri Güvenliği Yönetimi
          </p>
        </div>
      </div>
    </div>
  );
}
