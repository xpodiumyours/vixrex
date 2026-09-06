"use client";

import { useRouter } from "next/navigation";
import { SharedVixrexAssistant } from "@/components/vixrex/SharedVixrexAssistant";

/**
 * Flutter HomeShellScreen'deki üçüncü sekmenin Next.js karşılığı.
 * Vixrex artık başka sayfaların üstüne açılan modal veya Keşfet'in yerel
 * görünümü değildir; ortak shell içinde gerçek bir bölümdür.
 *
 * Bu faz yalnız mimari yerleşimi eşitler. Asistanın akıllı motor davranışı
 * ayrı kapsamdır ve burada değiştirilmez.
 */
export default function VixrexPage() {
  const router = useRouter();

  return (
    <main className="min-h-full bg-lp-bg-editor">
      <SharedVixrexAssistant onBrowse={() => router.push("/kesfet")} />
    </main>
  );
}
