"use client";

import { useEffect } from "react";
import { createClient } from "@supabase/supabase-js";
import { useRouter } from "next/navigation";

// Canlı senkron — tarayıcı tarafı.
//
// SORUN (kullanıcı, 2026-08-06): "anlık veri 2 tarafa eşit bir şekilde
// gidiyor mu baktım, gitmedi." Esnaf vitrinini uygulamadan da tarayıcıdan
// da düzenleyebiliyor. Uygulamadan yayınladığı değişikliği açık duran
// tarayıcı sekmesi görmüyordu; sayfa yalnız yenilenince tazeleniyordu.
//
// ÇÖZÜM: bu vitrinin stores satırı dinlenir, değişince router.refresh()
// çağrılır. Sunucu bileşeni yeniden çalışır, güncel veri gelir.
//
// TASLAK EZİLMEZ: sayfa taslak varsa taslağı gösteriyor. refresh yalnız
// sunucudan yeniden okur; sahibin yarım kalan düzenlemesi hep önceliklidir.
//
// YALNIZ SAHİP: ziyaretçilerde açılmaz. Her ziyaretçi için kalıcı bir
// websocket açmak, kimsenin istemediği bir yük demek.

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const SUPABASE_ANON = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

/**
 * Verilen slug'ın yayınlanmış kaydını dinler; değişince sayfayı tazeler.
 * `etkin` false ise hiç bağlanmaz.
 */
export function useCanliVitrinSenkron(slug: string, etkin: boolean): void {
  const router = useRouter();

  useEffect(() => {
    if (!etkin) return;
    if (!slug || !SUPABASE_URL || !SUPABASE_ANON) return;

    const client = createClient(SUPABASE_URL, SUPABASE_ANON, {
      auth: { persistSession: false },
    });

    const kanal = client
      .channel(`vitrin_${slug}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "stores",
          filter: `slug=eq.${slug}`,
        },
        () => {
          router.refresh();
        }
      )
      .subscribe();

    return () => {
      void client.removeChannel(kanal);
    };
  }, [slug, etkin, router]);
}
