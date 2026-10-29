export const vitrinGorunum = {
  yuzey: {
    panel: "border border-white/10 bg-[#0E1B2E]",
  },
  fiyat: {
    ana: "text-white",
    eski: "text-slate-500 line-through",
    birim: "text-slate-400",
    birimDeger: "text-slate-300",
  },
  rozet: {
    gorsel: "rounded-lg bg-red-600 text-white",
    indirim: "rounded-md bg-red-500/15 text-red-400",
  },
  buton: {
    ana: "bg-blue-600 text-white transition hover:bg-blue-500 active:scale-[0.98]",
    ikincil:
      "border border-white/10 bg-white/[0.03] text-white/70 transition hover:border-white/20 hover:text-white",
    whatsapp:
      "border border-emerald-500/40 bg-emerald-500/10 text-emerald-300 transition hover:bg-emerald-500/15",
    whatsappDolu: "bg-[#25D366] text-[#04140a]",
    devreDisi: "cursor-not-allowed border border-white/10 bg-white/[0.03] text-white/35",
  },
  metin: {
    marka: "text-[10px] font-extrabold uppercase tracking-[0.14em] text-slate-400",
    soluk: "text-slate-400",
    ikincil: "text-slate-300",
  },
  baglanti: {
    sessiz: "text-white/45 transition hover:text-white",
  },
  durum: {
    teyit: "text-emerald-300",
    uyari: "text-amber-200/80",
  },
} as const;
