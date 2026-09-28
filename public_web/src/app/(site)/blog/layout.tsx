import type { Metadata } from "next";
import { blogOnizlemeMi } from "@/data/blogYazilari";

export function generateMetadata(): Metadata {
  return blogOnizlemeMi() ? { robots: { index: false, follow: false } } : {};
}

export default function BlogLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <a
        href="#blog-icerik"
        className="sr-only focus:not-sr-only focus:block focus:bg-lp-primary focus:p-4 focus:text-lp-on-primary"
      >
        İçeriğe geç
      </a>
      {blogOnizlemeMi() ? (
        <div className="border-y border-amber-300/30 bg-amber-950 px-5 py-3 text-center text-sm text-amber-100">
          Yayın öncesi önizleme · Bu yazılar henüz yayında değil.
        </div>
      ) : null}
      <div id="blog-icerik" tabIndex={-1}>
        {children}
      </div>
    </>
  );
}
