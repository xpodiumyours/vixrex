"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@supabase/supabase-js";

// Yalnızca NEXT_PUBLIC_ değişkenleri — bu dosya tarayıcıda çalışır.
const supabaseBrowser = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || "",
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ""
);

interface PreviewEditorPanelProps {
  slug: string;
  editToken: string;
  initialName: string;
  initialWhatsapp: string;
  initialAddress: string;
  initialDescription: string;
  initialKategori: string;
}

export default function PreviewEditorPanel({
  slug,
  editToken,
  initialName,
  initialWhatsapp,
  initialAddress,
  initialDescription,
  initialKategori,
}: PreviewEditorPanelProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState(initialName);
  const [whatsapp, setWhatsapp] = useState(initialWhatsapp);
  const [address, setAddress] = useState(initialAddress);
  const [description, setDescription] = useState(initialDescription);
  const [kategori, setKategori] = useState(initialKategori);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState<number | null>(null);

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    const { error: rpcError } = await supabaseBrowser.rpc(
      "save_store_draft_with_token",
      {
        p_slug: slug,
        p_edit_token: editToken,
        p_store: { name, whatsapp, address, description, kategori },
      }
    );
    setSaving(false);
    if (rpcError) {
      setError("Kaydedilemedi: " + rpcError.message);
      return;
    }
    setSavedAt(Date.now());
    router.refresh();
  };

  const fieldClass =
    "w-full rounded-lg bg-white/5 border border-white/15 px-3 py-2 text-sm text-white placeholder:text-white/40 focus:outline-none focus:border-blue-400";
  const labelClass = "block text-xs font-semibold text-white/60 mb-1";

  return (
    <>
      {/* Mobilde aç/kapa düğmesi */}
      <button
        onClick={() => setOpen((v) => !v)}
        className="fixed bottom-5 right-5 z-[70] lg:hidden bg-blue-600 text-white rounded-full w-14 h-14 shadow-lg flex items-center justify-center text-xl"
        aria-label="Düzenleme panelini aç"
      >
        ✎
      </button>

      <aside
        className={`fixed top-0 right-0 z-[65] h-full w-full sm:w-96 bg-[#0B1120] border-l border-white/10 shadow-2xl overflow-y-auto transition-transform duration-200 ${
          open ? "translate-x-0" : "translate-x-full"
        } lg:translate-x-0`}
      >
        <div className="p-5 pt-14">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-white font-bold text-base">
              Vitrini Düzenle (Taslak)
            </h2>
            <button
              onClick={() => setOpen(false)}
              className="lg:hidden text-white/60 text-lg"
              aria-label="Kapat"
            >
              ✕
            </button>
          </div>

          <div className="space-y-4">
            <div>
              <label className={labelClass}>İşletme adı</label>
              <input
                className={fieldClass}
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </div>
            <div>
              <label className={labelClass}>WhatsApp numarası</label>
              <input
                className={fieldClass}
                value={whatsapp}
                onChange={(e) => setWhatsapp(e.target.value)}
                placeholder="05XXXXXXXXX"
              />
            </div>
            <div>
              <label className={labelClass}>Adres</label>
              <input
                className={fieldClass}
                value={address}
                onChange={(e) => setAddress(e.target.value)}
              />
            </div>
            <div>
              <label className={labelClass}>Açıklama</label>
              <textarea
                className={fieldClass + " min-h-[90px] resize-none"}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>
            <div>
              <label className={labelClass}>Kategori</label>
              <input
                className={fieldClass}
                value={kategori}
                onChange={(e) => setKategori(e.target.value)}
              />
            </div>
          </div>

          {error && (
            <p className="mt-3 text-sm text-red-400">{error}</p>
          )}
          {savedAt && !error && (
            <p className="mt-3 text-sm text-emerald-400">
              Kaydedildi — vitrin güncellendi.
            </p>
          )}

          <button
            onClick={handleSave}
            disabled={saving}
            className="mt-5 w-full bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-semibold rounded-lg py-2.5 text-sm transition"
          >
            {saving ? "Kaydediliyor..." : "Kaydet ve Önizlemeyi Güncelle"}
          </button>
        </div>
      </aside>
    </>
  );
}
