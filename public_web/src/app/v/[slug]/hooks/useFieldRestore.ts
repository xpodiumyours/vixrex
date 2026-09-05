"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { taslakClientId } from "@/lib/canliVitrinSenkron";
import { FIELD_BY_KEY, type VitrinField } from "@/lib/vitrinFieldSchema";
import { undoSmartEngineCommand } from "@/lib/smartEngineCommandClient";
import { useOwnerDraftVersion } from "../OwnerDraftVersionContext";
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
   * Legacy alan-listesi geri dönüşünü korur. 5.6 authoritative onay kartı
   * ise tek öğe olarak `command:<uuid>` yollar; o durumda server receipt'leri
   * çözer ve atomik command Undo çalışır.
   */
  coklaCanliyaDondur: (anahtarlar: string[]) => Promise<void>;
}

export function useFieldRestore({
  slug,
  seciliAlan,
  mesajEkle,
  setAlan,
  setGiris,
}: Deps): FieldRestoreHook {
  const router = useRouter();
  const { setDraftVersion } = useOwnerDraftVersion();
  const [geriAliniyor, setGeriAliniyor] = useState(false);
  const seciliAnahtarRef = useRef(seciliAlan?.anahtar ?? null);

  useEffect(() => {
    seciliAnahtarRef.current = seciliAlan?.anahtar ?? null;
  }, [seciliAlan?.anahtar]);

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
    async (anahtarlar: string[]) => {
      const commandToken =
        anahtarlar.length === 1 && anahtarlar[0]?.startsWith("command:")
          ? anahtarlar[0].slice("command:".length)
          : null;

      if (commandToken) {
        setGeriAliniyor(true);
        try {
          const sonuc = await undoSmartEngineCommand({
            slug,
            commandId: commandToken,
            clientId: taslakClientId(),
          });

          if (!sonuc.ok) {
            mesajEkle("asistan", sonuc.message);
            return;
          }

          setDraftVersion(sonuc.draftVersion);
          mesajEkle(
            "asistan",
            sonuc.replayed
              ? "Bu akıllı motor işlemi zaten geri alınmıştı."
              : `${sonuc.rolledBackActionCount} değişiklik güvenle geri alındı.`
          );
          router.refresh();
        } finally {
          setGeriAliniyor(false);
        }
        return;
      }

      const alanlar = anahtarlar
        .map((a) => FIELD_BY_KEY.get(a))
        .filter((a): a is VitrinField => Boolean(a));
      if (alanlar.length === 0) return;
      setGeriAliniyor(true);

      try {
        const sonuclar = await Promise.all(
          alanlar.map(async (alan) => {
            const yanit = await fetch("/api/owner-draft-restore", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                slug,
                anahtar: alan.anahtar,
                clientId: taslakClientId(),
              }),
            });
            const govde = (await yanit.json()) as { hata?: string; deger?: unknown };
            return { alan, ok: yanit.ok, govde };
          })
        );

        for (const { alan, ok, govde } of sonuclar) {
          if (!ok) continue;
          setAlan(alan.kolon, govde.deger);
          if (seciliAnahtarRef.current === alan.anahtar) {
            setGiris(
              alan.tip === "acikKapali" ||
                govde.deger === null ||
                govde.deger === undefined
                ? ""
                : String(govde.deger)
            );
          }
        }

        const basarili = sonuclar.filter((s) => s.ok).map((s) => s.alan.etiket);
        if (basarili.length === 0) {
          mesajEkle("asistan", "Geri alınamadı, tekrar dener misin?");
          return;
        }
        mesajEkle("asistan", `${basarili.join(", ")} canlı hâline döndürüldü.`);
        router.refresh();
      } catch {
        mesajEkle("asistan", "Bağlantı kurulamadı. Tekrar dene.");
      } finally {
        setGeriAliniyor(false);
      }
    },
    [slug, mesajEkle, setAlan, setGiris, router, setDraftVersion]
  );

  return { geriAliniyor, canliyaDondur, coklaCanliyaDondur };
}
