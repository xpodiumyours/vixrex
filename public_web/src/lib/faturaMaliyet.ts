import type { SupabaseClient } from "@supabase/supabase-js";
import type { GoruSonucu } from "@/lib/faturaGoru";

export async function kullanimKaydet(
  admin: SupabaseClient,
  magazaId: string,
  okuma: Pick<GoruSonucu, "maliyet" | "gercekMaliyet" | "girdiToken" | "ciktiToken" | "akilToken">,
  webButceRezervUsd = 0,
  belgeParmakIzi: string | null = null,
): Promise<void> {
  if (belgeParmakIzi !== null && !/^[a-f0-9]{64}$/.test(belgeParmakIzi)) throw new Error("BELGE_KIMLIGI_GECERSIZ");
  const bildirim = okuma.gercekMaliyet;
  const gercek = typeof bildirim === "number" && Number.isFinite(bildirim) && bildirim >= 0 ? bildirim : null;
  const rezerv = Number.isFinite(webButceRezervUsd) && webButceRezervUsd >= 0 ? webButceRezervUsd : 0;
  const { error } = await admin.from("invoice_read_usage").insert({
    store_id: magazaId,
    document_fingerprint: belgeParmakIzi,
    input_tokens: okuma.girdiToken,
    output_tokens: okuma.ciktiToken,
    reasoning_tokens: okuma.akilToken,
    cost_usd: okuma.maliyet ?? 0,
    provider_cost_usd: gercek,
    budget_reserve_usd: rezerv,
    cost_basis: gercek === null ? "estimated" : "reported",
  });
  if (error) throw new Error("MALIYET_YAZILAMADI");
}


/** Belgeye ait yalnız veritabanına GERÇEKTEN kaydedilmiş OpenRouter kullanımı. */
export async function belgeMaliyetOzeti(admin: SupabaseClient, storeId: string, belgeParmakIzi: string) {
  if (!/^[a-f0-9]{64}$/.test(belgeParmakIzi)) throw new Error("BELGE_KIMLIGI_GECERSIZ");
  const { data, error } = await admin
    .from("invoice_read_usage")
    .select("cost_usd,provider_cost_usd,budget_reserve_usd,cost_basis")
    .eq("store_id", storeId)
    .eq("document_fingerprint", belgeParmakIzi);
  if (error) throw new Error("BELGE_MALIYETI_OKUNAMADI");
  const records = data ?? [];
  return {
    kayitSayisi: records.length,
    gercekUsd: records.reduce((sum, row) =>
      sum + (row.cost_basis === "reported" ? Number(row.provider_cost_usd ?? 0) : 0), 0),
    tahminiUsd: records.reduce((sum, row) =>
      sum + (row.cost_basis !== "reported"
        ? Math.max(0, Number(row.cost_usd ?? 0) - Number(row.budget_reserve_usd ?? 0)) : 0), 0),
    tahminiKayitSayisi: records.filter((row) => row.cost_basis !== "reported").length,
    ayrilanButceUsd: records.reduce((sum, row) => sum + Number(row.budget_reserve_usd ?? 0), 0),
  };
}
