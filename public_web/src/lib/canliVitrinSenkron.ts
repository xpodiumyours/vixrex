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
// `draft:${slug}` kanalından gelen "alan_guncellendi" Broadcast olayı
// dinlenir. GÜVENLİK: bu kanala public anon key ile, sahip oturumu
// olmadan da bağlanılabiliyor (Supabase Broadcast kanalları varsayılan
// açık) — bu yüzden olayın payload'ında ASLA alan değeri taşınmaz,
// yalnız "bir şey değişti" sinyali gelir. Gerçek değer yalnız
// router.refresh() ile, sahip çerezi sunucuda yeniden doğrulanarak okunur
// (code-review, 2026-08-10 — ilk sürüm değeri payload'da taşıyordu).
//
// taslakDinle=true iken bu sinyal geldiğinde de (kanal 1 gibi)
// router.refresh() çağrılır — güvenlik notundaki sebepten payload alan
// verisi taşımadığı için tazeleme dışında bir yol yok.
//
// KENDİ YANKISINI ATLAMA: kaydı yapan sekme de kendi broadcast'ini geri
// alır — o zaten setAlan() ile yerel state'i güncellemişti, tekrar tazelemek
// gereksiz bir ağ isteği ve titreme demek. Payload'a alan verisi koymadan
// bunu ayırt etmenin tek yolu, gönderenin kimliğini (değerini değil)
// taşıyan opak bir `clientId` — her sekme kendi ürettiği id'yi görürse
// yenilemeyi atlar (code-review, 2026-08-10 ikinci tur).
const senkronClientId =
  typeof globalThis.crypto?.randomUUID === "function"
    ? globalThis.crypto.randomUUID()
    : `${Date.now()}-${Math.random()}`;

/** Bu sekmenin taslak broadcast'lerini imzalamak için kullandığı opak kimlik. */
export function taslakClientId(): string {
  return senkronClientId;
}

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const SUPABASE_ANON = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

/**
 * Verilen slug'ın yayınlanmış kaydını dinler; değişince sayfayı tazeler.
 * `etkin` false ise hiç bağlanmaz.
 *
 * `taslakDinle` true ise sahip taslak değişikliklerini de dinler; başka bir
 * sekmeden/oturumdan gelen alan değişikliğinde sayfa tazelenir. Aynı
 * sekmenin kendi kaydettiği değişikliğin yankısı `clientId` eşleşmesiyle
 * atlanır (bkz. yukarıki not).
 */
export function useCanliVitrinSenkron(
  slug: string,
  etkin: boolean,
  taslakDinle = false
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

    // Kanal 2 — taslak değişiklik sinyali (Broadcast). Yalnız taslakDinle
    // isteniyorsa bağlanır. Payload alan verisi taşımaz — yalnız gönderenin
    // opak clientId'si (bkz. dosya başı not).
    const taslakKanal = taslakDinle
      ? client
          .channel(`draft:${slug}`)
          .on<{ clientId?: string }>(
            "broadcast",
            { event: "alan_guncellendi" },
            (payload) => {
              if (payload.payload?.clientId === senkronClientId) return;
              router.refresh();
            }
          )
          .subscribe()
      : null;

    return () => {
      void client.removeChannel(canliKanal);
      if (taslakKanal) void client.removeChannel(taslakKanal);
    };
  }, [slug, etkin, router, taslakDinle]);
}
