"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { taslakClientId } from "@/lib/canliVitrinSenkron";
import { FIELD_BY_KEY, type VitrinField } from "@/lib/vitrinFieldSchema";
import type { Mesaj } from "./useOwnerChat";

interface Deps {
  slug: string;
  seciliAlan: VitrinField | null;
  mesajEkle: (kimden: Mesaj["kimden"], metin: string) => void;
  setAlan: (kolon: string, deger: unknown) => void;
  setGiris: (v: string) => void;
}

interface FieldRestoreHook {
  geriAliniyor: boolean;
  canliyaDondur: () => Promise<void>;
  /**
   * Adı ve string[] imzası büyük OwnerAssistantPanel yüzeyine dokunmamak için
   * korunuyor. Artık dizi ALANLARI değil tek commandId taşır.
   */
  coklaCanliyaDondur: (commandTokens: string[]) => Promise<void>;
}

export function useFieldRestore({
  slug,
  seciliAlan,
  mesajEkle,
  setAlan,
  setGiris,
}: Deps): FieldRestoreHook {
  const router = useRouter();
  const [geriAliniyor, setGeriAliniyor] = useState(false);
  const seciliAnahtarRef = useRef(seciliAlan?.anahtar ?? null);

  useEffect(() => {
    seciliAnahtarRef.current = seciliAlan?.anahtar ?? null;
  }, [seciliAlan?.anahtar]);

  // Manuel "canlı hâline döndür" işlevi AYNI kalır. Bu, Assistant'ın
  // command-bazlı undo'su değildir ve ayrı kullanıcı niyetidir.
  const canliyaDondur = useCallback(async () => {
    if (!seciliAlan) return;
    const alan = seciliAlan;
    setGeriAliniyor(true);

    try {
      const yanit = await fetch("/api/owner-draft-restore", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug,
          anahtar: alan.anahtar,
          clientId: taslakClientId(),
        }),
      });
      const govde = (await yanit.json()) as {
        hata?: string;
        degisti?: boolean;
        deger?: unknown;
      };

      if (!yanit.ok) {
        mesajEkle("asistan", govde.hata ?? "Canlı hâline döndürülemedi.");
        return;
      }

      // Sunucu "değişmedi" dese bile kanonik değeri uygula: başka sekmenin
      // broadcast'i kaçırıldıysa bu sekmenin yerel kopyası eski kalmış olabilir.
      setAlan(alan.kolon, govde.deger);
      // İstek sürerken kullanıcı vitrinden başka bir alan seçmiş olabilir.
      // Eski yanıt yeni alanın giriş kutusunu ezmemeli.
      if (seciliAnahtarRef.current === alan.anahtar) {
        setGiris(
          alan.tip === "acikKapali" ||
            govde.deger === null ||
            govde.deger === undefined
            ? ""
            : String(govde.deger)
        );
      }
      mesajEkle(
        "asistan",
        govde.degisti
          ? `${alan.etiket} canlı hâline döndürüldü. Diğer değişikliklerin korundu.`
          : `${alan.etiket} zaten canlıdakiyle aynı.`
      );
      router.refresh();
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setGeriAliniyor(false);
    }
  }, [slug, seciliAlan, mesajEkle, setAlan, setGiris, router]);

  const coklaCanliyaDondur = useCallback(
    async (commandTokens: string[]) => {
      // OwnerAssistantPanel mevcut geri_al: payload'ını virgülden ayırıyor.
      // Yeni payload tek UUID olduğundan burada tam bir token bekleriz; eski
      // alan-listesi payload'ı fail-closed olur ve yanlış undo yapmaz.
      if (commandTokens.length !== 1) {
        mesajEkle("asistan", "Bu eski geri alma işlemi güvenle uygulanamıyor.");
        return;
      }
      const commandId = commandTokens[0]?.trim() ?? "";
      if (!commandId) return;
      setGeriAliniyor(true);

      try {
        const yanit = await fetch("/api/owner-draft-undo", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            slug,
            commandId,
            clientId: taslakClientId(),
          }),
        });
        const govde = (await yanit.json()) as {
          hata?: string;
          degisiklikler?: Array<{
            anahtar?: unknown;
            kolon?: unknown;
            etiket?: unknown;
            deger?: unknown;
          }>;
        };

        if (!yanit.ok) {
          // Cerrahi 2026-09-11 (Risk 6): geri al kilidi sessiz kalmasın —
          // kullanıcıya sunucu metni gösterilir (görsel aynı), kayıp loglanır.
          console.warn("[vixrex-assistant] geri alma uygulanamadi", {
            commandId,
            hata: govde.hata ?? null,
          });
          mesajEkle("asistan", govde.hata ?? "Geri alınamadı, tekrar dener misin?");
          return;
        }

        const degisiklikler = Array.isArray(govde.degisiklikler)
          ? govde.degisiklikler
          : [];
        const geriAlinanEtiketler: string[] = [];

        for (const item of degisiklikler) {
          if (typeof item.anahtar !== "string" || typeof item.kolon !== "string") {
            continue;
          }
          const alan = FIELD_BY_KEY.get(item.anahtar);
          if (!alan || alan.kolon !== item.kolon) continue;

          setAlan(alan.kolon, item.deger);
          geriAlinanEtiketler.push(
            typeof item.etiket === "string" ? item.etiket : alan.etiket
          );
          if (seciliAnahtarRef.current === alan.anahtar) {
            setGiris(
              alan.tip === "acikKapali" ||
                item.deger === null ||
                item.deger === undefined
                ? ""
                : String(item.deger)
            );
          }
        }

        if (geriAlinanEtiketler.length === 0) {
          // Sunucu başarılı dediği halde ayrıntı yoksa yerel state'i tahmin
          // etmeyiz; server component yeniden okur.
          mesajEkle("asistan", "Geri alma tamamlandı. Vitrini yeniledim.");
        } else {
          mesajEkle(
            "asistan",
            `${geriAlinanEtiketler.join(", ")} önceki taslak değerlerine geri alındı.`
          );
        }
        router.refresh();
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
      } finally {
        setGeriAliniyor(false);
      }
    },
    [slug, mesajEkle, setAlan, setGiris, router]
  );

  return { geriAliniyor, canliyaDondur, coklaCanliyaDondur };
}
