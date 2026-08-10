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
//
// İKİNCİ KANAL — taslak değişiklik sinyali (2026-08-10):
// `draft:${slug}` kanalından gelen "alan_guncellendi" Broadcast olayları
// dinlenir. Değişiklik owner-draft API'sinden broadcast edilir.
// onTaslakGuncellendi callback ile OwnerAssistantPanel local state'ini
// günceller — tam sayfa yenilemesi olmadan anlık yansır.

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const SUPABASE_ANON = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

/** Broadcast'ten gelen taslak alan güncelleme verisi. */
export interface TaslakGuncellemesi {
  /** stores tablosundaki kolon adı (draftData key'i). */
  kolon: string;
  /** vitrinFieldSchema'daki alan anahtarı. */
  anahtar: string;
  deger: unknown;
}

/**
 * Verilen slug'ın yayınlanmış kaydını dinler; değişince sayfayı tazeler.
 * `etkin` false ise hiç bağlanmaz.
 *
 * `onTaslakGuncellendi` verilirse sahip taslak değişikliklerini de dinler;
 * değişince callback çağrılır (sayfa yenilenmez, yalnız local state güncellenir).
 */
export function useCanliVitrinSenkron(
  slug: string,
  etkin: boolean,
  onTaslakGuncellendi?: (guncelleme: TaslakGuncellemesi) => void
): void {
  const router = useRouter();

  useEffect(() => {
    if (!etkin) return;
    if (!slug || !SUPABASE_URL || !SUPABASE_ANON) return;

    const client = createClient(SUPABASE_URL, SUPABASE_ANON, {
      auth: { persistSession: false },
    });

    // Kanal 1 — yayınlanmış vitrin (stores tablosu)
    const canliKanal = client
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

    // Kanal 2 — taslak değişiklik sinyali (Broadcast)
    // Yalnız onTaslakGuncellendi callback verilmişse bağlanır.
    const taslakKanal = onTaslakGuncellendi
      ? client
          .channel(`draft:${slug}`)
          .on<TaslakGuncellemesi>(
            "broadcast",
            { event: "alan_guncellendi" },
            (payload) => {
              if (payload.payload.kolon) {
                onTaslakGuncellendi(payload.payload);
              }
            }
          )
          .subscribe()
      : null;

    return () => {
      void client.removeChannel(canliKanal);
      if (taslakKanal) void client.removeChannel(taslakKanal);
    };
  }, [slug, etkin, router, onTaslakGuncellendi]);
}
