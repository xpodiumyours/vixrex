"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

type StatusBarProps = {
  sahipSlug?: string | null;
  premium?: { aktif: boolean; bitis: string | null } | null;
};

export function StatusBar({ sahipSlug, premium }: StatusBarProps) {
  const [vitrinDurumu, setVitrinDurumu] = useState<'misafir' | 'yok' | 'yayinlanmamis' | 'yayinli'>('misafir');

  useEffect(() => {
    async function durumuGetir() {
      const { data } = await supabase.auth.getSession();
      const kaliciHesapVar =
        data.session?.user != null && !data.session.user.is_anonymous;

      if (kaliciHesapVar && sahipSlug) {
        const { data: vitrinData, error } = await supabase
          .from('vitriner')
          .select('published, store_name, public_link')
          .eq('slug', sahipSlug)
          .single();

        if (!error && vitrinData) {
          setVitrinDurumu(vitrinData.published ? 'yayinli' : 'yayinlanmamis');
        } else {
          setVitrinDurumu('yok');
        }
      } else if (!kaliciHesapVar) {
        setVitrinDurumu('misafir');
      } else {
        setVitrinDurumu('yok');
      }
    }
    void durumuGetir();
  }, [sahipSlug]);

  if (vitrinDurumu === 'misafir') {
    return (
      <div className="sticky top-0 z-10 min-h-[61px] border-b border-lp-border bg-lp-bg-editor px-5 py-3">
        <div className="flex min-h-9 w-full items-center justify-between gap-4">
          <span className="text-[14px] font-medium text-lp-text">
            Misafir girişi. <Link href="/giris" className="text-lp-primary hover:underline">Vitrin oluştur</Link> için hesap açın.
          </span>
          <Link href="/giris" className="hidden min-h-9 shrink-0 items-center rounded-xl bg-lp-primary px-4 text-[14px] font-black text-lp-on-primary hover:brightness-110 sm:flex">
            Vitrin oluştur
          </Link>
        </div>
      </div>
    );
  }

  if (vitrinDurumu === 'yok') {
    return (
      <div className="sticky top-0 z-10 min-h-[61px] border-b border-lp-border bg-lp-bg-editor px-5 py-3">
        <div className="flex min-h-9 w-full items-center justify-between gap-4">
          <span className="text-[14px] font-medium text-lp-text">
            Vitrininiz henüz oluşturulmadı. <Link href="/app" className="text-lp-primary hover:underline">Vitrin oluştur</Link> başlayın.
          </span>
          <Link href="/app" className="hidden min-h-9 shrink-0 items-center rounded-xl bg-lp-primary px-4 text-[14px] font-black text-lp-on-primary hover:brightness-110 sm:flex">
            Vitrin oluştur
          </Link>
        </div>
      </div>
    );
  }

  if (vitrinDurumu === 'yayinlanmamis') {
    return (
      <div className="sticky top-0 z-10 min-h-[61px] border-b border-lp-border bg-lp-bg-editor px-5 py-3">
        <div className="flex min-h-9 w-full items-center justify-between gap-4">
          <span className="text-[14px] font-medium text-lp-text">
            <span className="rounded-full border border-lp-border bg-lp-surface-soft px-3 py-1 text-[12px] font-black text-lp-muted">Yayında değil</span>
            <span className="ml-3 text-[12px] font-semibold text-lp-muted">Vitrininizi henüz yayınlamadınız</span>
          </span>
          <Link href="/app" className="flex min-h-9 shrink-0 items-center rounded-xl bg-lp-primary px-4 text-[14px] font-black text-lp-on-primary hover:brightness-110">
            Vitrini yayınla
          </Link>
        </div>
      </div>
    );
  }

  if (vitrinDurumu === 'yayinli') {
    return (
      <div className="sticky top-0 z-10 min-h-[61px] border-b border-lp-border bg-lp-bg-editor px-5 py-3">
        <div className="flex min-h-9 w-full items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <span className="text-[14px] font-medium text-lp-text">
              {premium?.aktif ? 'Premium' : ''}
            </span>
            <span className="text-[14px] font-medium text-lp-primary" style={{ whiteSpace: 'nowrap' }}>
              {sahipSlug ? 'Vitrininize gir' : ''}
            </span>
          </div>
          <div className="hidden sm:flex items-center gap-2">
            <Link
              href={`/v/${sahipSlug}`}
              className="text-[12px] font-black text-lp-primary hover:underline"
              title="Vitrin'i aç"
            >
              Aç
            </Link>
            <button
              onClick={() => navigator.clipboard.writeText(`/v/${sahipSlug}`)}
              className="text-[12px] font-black text-lp-primary hover:underline"
              title="Kopyala"
            >
              Kopyala
            </button>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
