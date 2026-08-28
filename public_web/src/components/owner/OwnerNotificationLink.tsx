"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

export function OwnerNotificationLink() {
  const [okunmamis, setOkunmamis] = useState(0);

  useEffect(() => {
    async function sayaciGetir() {
      const { count, error } = await supabase
        .from("notification_inbox")
        .select("id", { count: "exact", head: true })
        .is("read_at", null);
      if (!error) setOkunmamis(count ?? 0);
    }
    void sayaciGetir();
  }, []);

  return (
    <Link href="/app/bildirimler" className="owner-card owner-link group flex items-center gap-3 p-4 no-underline transition hover:border-[var(--owner-primary)]">
      <span className="text-2xl" aria-hidden="true">🔔</span>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <p className="text-sm font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">Bildirimler</p>
          {okunmamis > 0 ? (
            <span className="rounded-full bg-[var(--owner-primary)] px-2 py-0.5 text-xs font-black text-[var(--owner-on-primary)]" aria-label={`${okunmamis} okunmamış bildirim`}>
              {okunmamis > 99 ? "99+" : okunmamis}
            </span>
          ) : null}
        </div>
        <p className="text-xs text-[var(--owner-muted)]">Randevu ve durum güncellemeleri</p>
      </div>
    </Link>
  );
}
