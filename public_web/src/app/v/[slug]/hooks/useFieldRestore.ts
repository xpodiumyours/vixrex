"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { taslakClientId } from "@/lib/canliVitrinSenkron";
import type { VitrinField } from "@/lib/vitrinFieldSchema";
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

      if (!govde.degisti) {
        mesajEkle("asistan", `${alan.etiket} zaten canlıdakiyle aynı.`);
        return;
      }

      setAlan(alan.kolon, govde.deger);
      setGiris(
        alan.tip === "acikKapali" || govde.deger === null || govde.deger === undefined
          ? ""
          : String(govde.deger)
      );
      mesajEkle(
        "asistan",
        `${alan.etiket} canlı hâline döndürüldü. Diğer değişikliklerin korundu.`
      );
      router.refresh();
    } catch {
      mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setGeriAliniyor(false);
    }
  }, [slug, seciliAlan, mesajEkle, setAlan, setGiris, router]);

  return { geriAliniyor, canliyaDondur };
}
