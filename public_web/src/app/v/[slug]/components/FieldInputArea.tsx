import { useRef } from "react";
import type { VitrinField } from "@/lib/vitrinFieldSchema";
import { ImagePickerPanel } from "./ImagePickerPanel";
import type { HazirGorsel } from "../hooks/useOwnerActions";

interface Props {
  seciliAlan: VitrinField | null;
  giris: string;
  girisRef: React.RefObject<HTMLTextAreaElement | null>;
  kaydediliyor: boolean;
  hazirGorseller: HazirGorsel[];
  hazirYukleniyor: boolean;
  setGiris: (v: string) => void;
  gorselYukle: (dosya: File) => Promise<void>;
  hazirGorselleriAc: () => Promise<void>;
  hazirGorselSec: (url: string) => Promise<void>;
  gonder: () => Promise<void>;
}

export function FieldInputArea({
  seciliAlan,
  giris,
  girisRef,
  kaydediliyor,
  hazirGorseller,
  hazirYukleniyor,
  setGiris,
  gorselYukle,
  hazirGorselleriAc,
  hazirGorselSec,
  gonder,
}: Props) {
  return (
    <div className="border-t border-white/10 px-4 py-3">
      {seciliAlan && (
        <p className="mb-2 text-[11px] text-blue-300">
          Düzenleniyor: <strong>{seciliAlan.etiket}</strong>
          {seciliAlan.maxUzunluk
            ? ` · ${giris.length}/${seciliAlan.maxUzunluk}`
            : ""}
        </p>
      )}
      {seciliAlan?.tip === "gorsel" ? (
        <div>
          <label
            className={`flex w-full cursor-pointer items-center justify-center gap-2 rounded-lg border border-dashed border-blue-500/40 bg-blue-500/[0.06] px-4 py-4 text-xs font-semibold text-blue-300 transition hover:bg-blue-500/10 ${
              kaydediliyor ? "pointer-events-none opacity-50" : ""
            }`}
          >
            <span className="text-base">📷</span>
            {kaydediliyor ? "Yükleniyor…" : "Fotoğraf Seç"}
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              disabled={kaydediliyor}
              className="hidden"
              onChange={(e) => {
                const dosya = e.target.files?.[0];
                e.target.value = ""; // aynı dosya tekrar seçilebilsin
                if (dosya) void gorselYukle(dosya);
              }}
            />
          </label>
          <ImagePickerPanel
            hazirGorseller={hazirGorseller}
            hazirYukleniyor={hazirYukleniyor}
            kaydediliyor={kaydediliyor}
            hazirGorselleriAc={hazirGorselleriAc}
            hazirGorselSec={hazirGorselSec}
          />
          <p className="mt-2 text-center text-[11px] text-slate-500">
            JPG, PNG veya WebP · en fazla 5 MB
          </p>
        </div>
      ) : seciliAlan?.tip === "secim" && seciliAlan.secenekler ? (
        <div className="flex items-end gap-2">
          <select
            value={giris}
            onChange={(e) => setGiris(e.target.value)}
            disabled={kaydediliyor}
            className="flex-1 rounded-lg border border-white/10 bg-slate-900/70 px-3 py-2 text-xs text-white outline-none focus:border-blue-500/60"
          >
            <option value="" disabled>Kategori seçin…</option>
            {seciliAlan.secenekler.map((secenek) => (
              <option key={secenek} value={secenek}>
                {secenek}
              </option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => void gonder()}
            disabled={kaydediliyor || !giris}
            className="rounded-lg bg-blue-600 px-3 py-2 text-xs font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {kaydediliyor ? "…" : "Gönder"}
          </button>
        </div>
      ) : (
        <div className="flex items-end gap-2">
          <textarea
            ref={girisRef}
            value={giris}
            onChange={(e) => setGiris(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                if (!kaydediliyor) void gonder();
              }
            }}
            rows={seciliAlan?.tip === "uzunMetin" ? 3 : 1}
            maxLength={seciliAlan?.maxUzunluk}
            disabled={kaydediliyor}
            placeholder={
              seciliAlan
                ? "Yeni değeri yazın…"
                : "Vitrinde bir yazıya tıkla…"
            }
            className="flex-1 resize-none rounded-lg border border-white/10 bg-slate-900/70 px-3 py-2 text-xs text-white outline-none focus:border-blue-500/60"
          />
          <button
            type="button"
            onClick={() => void gonder()}
            disabled={kaydediliyor}
            className="rounded-lg bg-blue-600 px-3 py-2 text-xs font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {kaydediliyor ? "…" : "Gönder"}
          </button>
        </div>
      )}
    </div>
  );
}
