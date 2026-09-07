"use client";

import type { AnchorHTMLAttributes, MouseEvent, ReactNode } from "react";
import { useState } from "react";
import { getAppUrl } from "@/lib/siteUrl";
import { supabase } from "@/lib/supabase";

type AppEntryLinkProps = Omit<
  AnchorHTMLAttributes<HTMLAnchorElement>,
  "href" | "onClick" | "children"
> & {
  children: ReactNode;
};

const APP_TARGET = `${getAppUrl()}/app`;

/**
 * Public Next.js yüzeyinden tek Flutter Web uygulama kabuğuna geçiş.
 *
 * Kalıcı Supabase oturumu varsa sunucudan tek kullanımlık geçiş bağlantısı alır;
 * anonim/misafir kullanıcıyı doğrudan Flutter'a gönderir. Köprü hata verirse
 * kullanıcıyı ölü uçta bırakmaz, normal uygulama girişine düşer.
 */
export function AppEntryLink({ children, ...anchorProps }: AppEntryLinkProps) {
  const [geciliyor, setGeciliyor] = useState(false);

  async function handleClick(event: MouseEvent<HTMLAnchorElement>) {
    if (
      event.button !== 0 ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      anchorProps.target === "_blank"
    ) {
      return;
    }

    event.preventDefault();
    if (geciliyor) return;
    setGeciliyor(true);

    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (!session?.access_token || session.user.is_anonymous) {
        window.location.assign(APP_TARGET);
        return;
      }

      const response = await fetch("/api/app-handoff", {
        method: "POST",
        headers: { authorization: `Bearer ${session.access_token}` },
        cache: "no-store",
      });
      const result = (await response.json().catch(() => ({}))) as {
        yonlendir?: string;
      };

      if (response.ok && result.yonlendir) {
        window.location.assign(result.yonlendir);
        return;
      }
    } catch {
      // Güvenli yedek yol aşağıda: kullanıcı uygulamaya yine ulaşır ve gerekirse
      // Flutter kendi giriş ekranından kalıcı hesabını açar.
    }

    window.location.assign(APP_TARGET);
  }

  return (
    <a
      {...anchorProps}
      href={APP_TARGET}
      onClick={handleClick}
      aria-busy={geciliyor || undefined}
    >
      {children}
    </a>
  );
}
