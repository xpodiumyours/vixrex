"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

type StatusBarProps = {
  sahipSlug?: string | null;
  premium?: { aktif: boolean; bitis: string | null } | null;
};

export function StatusBar({ sahipSlug, premium }: StatusBarProps) {
  const [session, setSession] = useState<boolean | null>(null);
  const [vitrinDurumu, setVitrinDurumu] = useState<'misafir' | 'yok' | 'yayinlanmamis' | 'yayinli'>('misafir');

  useEffect(() => {
    async function durumuGetir() {
      const { data } = await supabase.auth.getSession();
      setSession(data.session !== null);

      if (data.session && sahipSlug) {
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
      } else if (!data.session) {
        setVitrinDurumu('misafir');
      } else {
        setVitrinDurumu('yok');
      }
    }
    void durumuGetir();
  }, [sahipSlug]);

  if (vitrinDurumu === 'misafir') {
    return (
      <div className="sticky top-0 z-10 bg-lp-bg-editor px-6 py-4 md:px-8 border-b border-lp-border">
        <div className="mx-auto max-w-[1200px] flex items-center justify-between w-full">
          <span className="text-[14px] font-medium text-lp-text">
            Misafir girişi. <Link href="/giris" className="text-lp-primary hover:underline">Vitrin oluştur</Link> için hesap açın.
          </span>
        </div>
      </div>
    );
  }

  if (vitrinDurumu === 'yok') {
    return (
      <div className="sticky top-0 z-10 bg-lp-bg-editor px-6 py-4 md:px-8 border-b border-lp-border">
        <div className="mx-auto max-w-[1200px] flex items-center justify-between w-full">
          <span className="text-[14px] font-medium text-lp-text">
            Vitrininiz henüz oluşturulmadı. <Link href="/app" className="text-lp-primary hover:underline">Vitrin oluştur</Link> başlayın.
          </span>
        </div>
      </div>
    );
  }

  if (vitrinDurumu === 'yayinlanmamis') {
    return (
      <div className="sticky top-0 z-10 bg-lp-bg-editor px-6 py-4 md:px-8 border-b border-lp-border">
        <div className="mx-auto max-w-[1200px] flex items-center justify-between w-full">
          <span className="text-[14px] font-medium text-lp-text">
            <span className="font-semibold text-lp-muted">Yayında değil</span> — <Link href="/app" className="text-lp-primary hover:underline">Vitrini yayınla</Link>.
          </span>
        </div>
      </div>
    );
  }

  if (vitrinDurumu === 'yayinli') {
    return (
      <div className="sticky top-0 z-10 bg-lp-bg-editor px-6 py-4 md:px-8 border-b border-lp-border">
        <div className="mx-auto max-w-[1200px] flex items-center justify-between w-full">
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