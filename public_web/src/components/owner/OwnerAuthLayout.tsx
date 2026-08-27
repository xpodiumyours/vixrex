import Link from "next/link";
import type { ReactNode } from "react";

interface OwnerAuthLayoutProps {
  title: string;
  description: string;
  children: ReactNode;
}

export function OwnerAuthLayout({
  title,
  description,
  children,
}: OwnerAuthLayoutProps) {
  return (
    <main className="owner-shell flex items-center justify-center px-4 py-10 sm:px-6">
      <section className="owner-card w-full max-w-md p-6 sm:p-8" aria-labelledby="auth-title">
        <Link href="/" className="owner-link mb-6 inline-flex items-center gap-2 font-bold no-underline">
          <span aria-hidden="true" className="h-2.5 w-2.5 rounded-full bg-[var(--owner-primary)]" />
          Vixrex
        </Link>
        <p className="mb-2 text-xs font-bold uppercase tracking-[0.16em] text-[var(--owner-secondary)]">
          Vitrin Yönetimi
        </p>
        <h1 id="auth-title" className="text-2xl font-bold text-[var(--owner-text)]">
          {title}
        </h1>
        <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)]">{description}</p>
        <div className="mt-6">{children}</div>
      </section>
    </main>
  );
}
