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
      <span className="text-[var(--owner-secondary)]" aria-hidden="true"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M18 8a6 6 0 1 0-12 0c0 7-3 8-3 8h18s-3-1-3-8" /><path d="M13.7 21a2 2 0 0 1-3.4 0" /></svg></span>
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
