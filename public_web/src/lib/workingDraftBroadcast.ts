import { createClient } from "@supabase/supabase-js";

function supabaseAnon() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL || "",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      process.env.SUPABASE_PUBLISHABLE_KEY ||
      ""
  );
}

/**
 * Başka sahip sekmelerine yalnız "taslak değişti" sinyali gönderir.
 * Payload alan adı veya değeri taşımaz; gerçek veri sahip çerezi yeniden
 * doğrulanarak okunur. Broadcast hatası asıl yazma işlemini geçersiz kılmaz.
 */
export function broadcastTaslakGuncellendi(
  slug: string,
  clientId: string | null
): void {
  void (async () => {
    try {
      await supabaseAnon()
        .channel(`draft:${slug}`)
        .send({
          type: "broadcast",
          event: "alan_guncellendi",
          payload: { clientId },
        });
    } catch {
      // Fire-and-forget: taslak yazımı tamamlandıysa broadcast ikincildir.
    }
  })();
}
