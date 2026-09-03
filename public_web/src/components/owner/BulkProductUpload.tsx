"use client";

import { useState, useRef, useCallback } from "react";

// ─── Türler ─────────────────────────────────────────────────────────────────

interface ParsedProduct {
  name: string;
  description: string;
  price_text: string;
  category: string;
  stockStatus: string;
  imageUrls: string[];
  _raw: Record<string, string>;
  _rowIndex: number;
}

interface ColumnMapping {
  name: number | null;
  description: number | null;
  price_text: number | null;
  category: number | null;
  stockStatus: number | null;
  imageUrls: number | null;
}

interface BatchResult {
  toplam: number;
  eklenen: number;
  hatali: number;
  hataDetaylari: Array<{ index?: number; error?: string }>;
}

interface BulkProductUploadProps {
  storeSlug: string;
  categories?: Array<{ id: string; name: string }>;
  onUploaded: () => Promise<void>;
}

// ─── Sütun Eşleme Sözlükleri ────────────────────────────────────────────────

const NAME_ALIASES = new Set([
  "urunadi", "urunad", "urun", "adi", "ad", "name", "productname",
  "baslik", "title", "product",
]);
const PRICE_ALIASES = new Set([
  "fiyat", "price", "satisfiyati", "satis", "tutar", "amount", "saleprice",
]);
const DESC_ALIASES = new Set([
  "aciklama", "description", "detay", "detail", "not", "note", "ozet", "summary",
]);
const CATEGORY_ALIASES = new Set([
  "kategori", "category", "kat", "grup", "group", "turu", "type",
]);
const STOCK_ALIASES = new Set([
  "stok", "stock", "stokdurumu", "stockstatus", "stokdurum",
]);
const IMAGE_ALIASES = new Set([
  "gorselurl", "gorsel", "imageurl", "image", "foto", "resim", "kapak", "cover",
]);

function normalizeHeader(h: string): string {
  return h
    .toLowerCase()
    .replace(/[üû]/g, "u")
    .replace(/[öo]/g, "o")
    .replace(/[çc]/g, "c")
    .replace(/[şs]/g, "s")
    .replace(/[ğg]/g, "g")
    .replace(/[iiî]/g, "i")
    .replace(/[^a-z0-9]/g, "")
    .trim();
}

function normalizePrice(raw: string): string {
  if (!raw.trim()) return "";
  let normalized = raw
    .replace(/\b(TL|TRY|₺|tl|try)\b/g, "")
    .replace(/\s+/g, " ")
    .trim();
  if (!normalized) return "";

  const lastComma = normalized.lastIndexOf(",");
  const lastDot = normalized.lastIndexOf(".");

  if (lastComma !== -1 && lastDot !== -1) {
    const decimalSep = lastComma > lastDot ? "," : ".";
    const thousandsSep = decimalSep === "," ? "." : ",";
    normalized = normalized.replaceAll(thousandsSep, "");
    if (decimalSep === ",") normalized = normalized.replaceAll(",", ".");
  } else if (lastComma !== -1) {
    const parts = normalized.split(",");
    if (parts.length === 2 && parts[1].length <= 2) {
      normalized = normalized.replaceAll(",", ".");
    } else {
      normalized = normalized.replaceAll(",", "");
    }
  }

  const num = Number(normalized);
  if (isNaN(num)) return raw.trim();
  return num % 1 === 0 ? String(num) : num.toFixed(2);
}

function normalizeStock(raw: string): string {
  const lower = raw.toLowerCase();
  if (lower.includes("tükendi") || lower.includes("yok") || lower === "0") return "Tükendi";
  if (lower.includes("son") || lower.includes("az") || lower.includes("limit")) return "Son birkaç adet";
  return "Mevcut";
}

// ─── Ana Bileşen ────────────────────────────────────────────────────────────

export default function BulkProductUpload({
  storeSlug,
  onUploaded,
}: BulkProductUploadProps) {
  const [step, setStep] = useState<"pick" | "map" | "review" | "saving" | "done">("pick");
  const [headers, setHeaders] = useState<string[]>([]);
  const [mapping, setMapping] = useState<ColumnMapping>({
    name: null, description: null, price_text: null,
    category: null, stockStatus: null, imageUrls: null,
  });
  const [parsedProducts, setParsedProducts] = useState<ParsedProduct[]>([]);
  const [errors, setErrors] = useState<string[]>([]);
  const [batchResult, setBatchResult] = useState<BatchResult | null>(null);
  const [busy, setBusy] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  // ─── Dosya Seçimi ────────────────────────────────────────────────

  const handleFile = useCallback(async (file: File) => {
    setErrors([]);
    const lowerName = file.name.toLowerCase();

    try {
      const buffer = await file.arrayBuffer();
      let rows: string[][] = [];

      if (lowerName.endsWith(".csv")) {
        const text = new TextDecoder("utf-8").decode(buffer);
        rows = text
          .split(/\r?\n/)
          .filter((l) => l.trim())
          .map((line) => {
            const cells: string[] = [];
            let current = "";
            let inQuotes = false;
            for (let i = 0; i < line.length; i++) {
              const ch = line[i];
              if (ch === '"') {
                if (inQuotes && i + 1 < line.length && line[i + 1] === '"') {
                  current += '"';
                  i++;
                } else {
                  inQuotes = !inQuotes;
                }
              } else if (ch === "," && !inQuotes) {
                cells.push(current.trim());
                current = "";
              } else {
                current += ch;
              }
            }
            cells.push(current.trim());
            return cells;
          });
      } else if (lowerName.endsWith(".xlsx") || lowerName.endsWith(".xls")) {
        // Excel okuyucu yalnız Excel dosyası seçilince yükleniyor. Statik
        // içe aktarımdayken ~400 KB'lık paket, ürün yönetimini AÇAN HERKESE
        // iniyordu — dosya yüklemeyenler dahil. Ayrıca paketin bilinen ve
        // yaması olmayan bir açığı var (prototype pollution / ReDoS); tarayıcıda
        // ve yalnız kullanıcının kendi dosyasıyla çalıştığı için etkisi sınırlı,
        // yine de yüzeyi küçük tutuyoruz.
        const XLSX = await import("xlsx");
        const workbook = XLSX.read(buffer, { type: "array" });
        const sheetName = workbook.SheetNames[0];
        if (!sheetName) {
          setErrors(["Dosyada sayfa bulunamadı."]);
          return;
        }
        const sheet = workbook.Sheets[sheetName];
        rows = XLSX.utils.sheet_to_json<string[]>(sheet, { header: 1 });
      } else {
        setErrors(["Desteklenmeyen format. .xlsx veya .csv kullanın."]);
        return;
      }

      if (rows.length < 2) {
        setErrors(["Dosyada en az 2 satır olmalı (başlık + veri)."]);
        return;
      }

      const headerRow = rows[0].map((h) => String(h ?? ""));
      setHeaders(headerRow);

      // Otomatik sütun eşleme
      const autoMap: ColumnMapping = {
        name: null, description: null, price_text: null,
        category: null, stockStatus: null, imageUrls: null,
      };
      headerRow.forEach((h, i) => {
        const n = normalizeHeader(h);
        if (NAME_ALIASES.has(n) && autoMap.name === null) autoMap.name = i;
        else if (PRICE_ALIASES.has(n) && autoMap.price_text === null) autoMap.price_text = i;
        else if (DESC_ALIASES.has(n) && autoMap.description === null) autoMap.description = i;
        else if (CATEGORY_ALIASES.has(n) && autoMap.category === null) autoMap.category = i;
        else if (STOCK_ALIASES.has(n) && autoMap.stockStatus === null) autoMap.stockStatus = i;
        else if (IMAGE_ALIASES.has(n) && autoMap.imageUrls === null) autoMap.imageUrls = i;
      });

      if (autoMap.name === null) {
        setErrors(["Dosyada \"Ürün Adı\" veya \"Name\" başlığı bulunamadı."]);
        return;
      }

      setMapping(autoMap);

      // Veri satırlarını ayrıştır
      const products: ParsedProduct[] = [];
      const parseErrors: string[] = [];
      for (let i = 1; i < rows.length; i++) {
        const vals = rows[i].map((v) => String(v ?? "").trim());
        const name = autoMap.name !== null ? (vals[autoMap.name] ?? "") : "";
        if (!name.trim()) {
          parseErrors.push(`Satır ${i + 1}: Ürün adı boş, atlandı.`);
          continue;
        }
        const priceRaw = autoMap.price_text !== null ? (vals[autoMap.price_text] ?? "") : "";
        const imageUrlRaw = autoMap.imageUrls !== null ? (vals[autoMap.imageUrls] ?? "") : "";

        products.push({
          name: name.trim(),
          description: autoMap.description !== null ? (vals[autoMap.description] ?? "").trim() : "",
          price_text: normalizePrice(priceRaw),
          category: autoMap.category !== null ? (vals[autoMap.category] ?? "").trim() : "",
          stockStatus: autoMap.stockStatus !== null ? normalizeStock(vals[autoMap.stockStatus] ?? "") : "Mevcut",
          imageUrls: imageUrlRaw.trim() ? [imageUrlRaw.trim()] : [],
          _raw: Object.fromEntries(headerRow.map((h, j) => [h, vals[j] ?? ""])),
          _rowIndex: i + 1,
        });
      }

      if (products.length === 0) {
        setErrors(["Dosyada geçerli ürün bulunamadı.", ...parseErrors]);
        return;
      }

      setParsedProducts(products);
      if (parseErrors.length > 0) {
        setErrors(parseErrors.slice(0, 10)); // İlk 10 hatayı göster
      }
      setStep("map");
    } catch {
      setErrors(["Dosya işlenirken hata oluştu."]);
    }
  }, []);

  // ─── Sütun Eşleme Değişikliği ───────────────────────────────────

  function updateMapping(field: keyof ColumnMapping, colIndex: number | null) {
    setMapping((prev) => ({ ...prev, [field]: colIndex }));
  }

  // ─── Eşleme ile yeniden ayrıştır ─────────────────────────────────

  function reParseWithMapping() {
    if (headers.length === 0) return;
    // Header zaten parse edildi, mapping değişikliği review adımında ürünleri filtreler
    setStep("review");
  }

  // ─── Toplu Kaydetme ─────────────────────────────────────────────

  async function saveAll() {
    if (parsedProducts.length === 0 || busy) return;
    setBusy(true);
    setStep("saving");
    setErrors([]);

    try {
      const res = await fetch("/api/products/batch", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          products: parsedProducts.map((p, i) => ({
            name: p.name,
            description: p.description,
            price_text: p.price_text,
            image_urls: p.imageUrls,
            source_type: "bulk_import",
            sort_order: i,
          })),
        }),
      });

      const payload = await res.json().catch(() => null);
      if (!res.ok) {
        throw new Error(
          payload && typeof payload === "object" && "hata" in payload
            ? String((payload as { hata?: unknown }).hata)
            : "Toplu ekleme başarısız oldu."
        );
      }

      const result = payload as BatchResult;
      setBatchResult(result);
      setStep("done");
      if (result.eklenen > 0) {
        await onUploaded();
      }
    } catch (err) {
      setErrors([err instanceof Error ? err.message : "Kaydetme başarısız oldu."]);
      setStep("review");
    } finally {
      setBusy(false);
    }
  }

  // ─── Sıfırlama ──────────────────────────────────────────────────

  function reset() {
    setStep("pick");
    setHeaders([]);
    setMapping({ name: null, description: null, price_text: null, category: null, stockStatus: null, imageUrls: null });
    setParsedProducts([]);
    setErrors([]);
    setBatchResult(null);
    setBusy(false);
    if (fileRef.current) fileRef.current.value = "";
  }

  // ─── Ürün Kaldırma ──────────────────────────────────────────────

  function removeProduct(index: number) {
    setParsedProducts((prev) => prev.filter((_, i) => i !== index));
  }

  // ─── Render ─────────────────────────────────────────────────────

  return (
    <section className="mt-6" aria-labelledby="bulk-upload-title">
      <h2 id="bulk-upload-title" className="text-lg font-bold text-[var(--owner-text)]">
        Toplu Ürün Yükleme
      </h2>
      <p className="mt-1 text-sm text-[var(--owner-muted)]">
        Excel (.xlsx) veya CSV dosyasından ürünleri toplu olarak ekle.
      </p>

      {/* Adım göstergesi */}
      <div className="mt-4 flex items-center gap-2 text-xs text-[var(--owner-muted)]">
        <span className={`rounded-full px-2 py-0.5 font-bold ${step === "pick" ? "bg-[var(--owner-primary)] text-white" : "bg-[var(--owner-border)]"}`}>1. Dosya</span>
        <span aria-hidden="true">→</span>
        <span className={`rounded-full px-2 py-0.5 font-bold ${step === "map" ? "bg-[var(--owner-primary)] text-white" : "bg-[var(--owner-border)]"}`}>2. Eşleme</span>
        <span aria-hidden="true">→</span>
        <span className={`rounded-full px-2 py-0.5 font-bold ${step === "review" ? "bg-[var(--owner-primary)] text-white" : "bg-[var(--owner-border)]"}`}>3. Önizleme</span>
        <span aria-hidden="true">→</span>
        <span className={`rounded-full px-2 py-0.5 font-bold ${step === "done" ? "bg-[var(--owner-success)] text-white" : "bg-[var(--owner-border)]"}`}>4. Sonuç</span>
      </div>

      {/* Hatalar */}
      {errors.length > 0 && (
        <div className="mt-4 rounded-xl border border-red-400/40 bg-red-400/10 p-3">
          <p className="text-sm font-bold text-red-600">Uyarılar</p>
          <ul className="mt-1 list-disc pl-5 text-xs text-red-600">
            {errors.map((e, i) => (
              <li key={i}>{e}</li>
            ))}
          </ul>
        </div>
      )}

      {/* Adım 1: Dosya Seçimi */}
      {step === "pick" && (
        <div className="mt-4">
          <div
            className="owner-card cursor-pointer border-2 border-dashed p-8 text-center transition hover:border-[var(--owner-primary)]"
            onClick={() => fileRef.current?.click()}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") fileRef.current?.click();
            }}
          >
            <p className="text-4xl">📄</p>
            <p className="mt-3 font-bold text-[var(--owner-text)]">Dosya seç veya sürükle bırak</p>
            <p className="mt-1 text-xs text-[var(--owner-muted)]">.xlsx veya .csv (maksimum 5 MB)</p>
          </div>
          <input
            ref={fileRef}
            type="file"
            accept=".xlsx,.xls,.csv"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) handleFile(file);
            }}
          />
          {/* CSV Şablonu İndirme */}
          <button
            type="button"
            className="owner-button-secondary mt-3 text-xs"
            onClick={() => {
              const csv = "Ürün Adı,Fiyat,Açıklama,Kategori,Stok Durumu,Görsel URL\nÖrnek Ürün 1,125.50,Günlük kullanım için uygun,Genel,Mevcut,\nÖrnek Ürün 2,\"1,250.00\",Özel tasarım elbise,Elbise,Mevcut,https://ornek.com/gorsel.jpg\nÖrnek Ürün 3,,Kampanyalı fiyat,Genel,Tükendi,";
              const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
              const url = URL.createObjectURL(blob);
              const a = document.createElement("a");
              a.href = url;
              a.download = "urun-sablonu.csv";
              a.click();
              URL.revokeObjectURL(url);
            }}
          >
            📥 CSV Şablonu İndir
          </button>
        </div>
      )}

      {/* Adım 2: Sütun Eşleme */}
      {step === "map" && (
        <div className="mt-4">
          <p className="text-sm font-bold text-[var(--owner-text)]">Sütun Eşlemesi</p>
          <p className="mt-1 text-xs text-[var(--owner-muted)]">
            Her alan için hangi sütunu kullanacağını seç. Otomatik algılama yapıldı — gerekirse değiştir.
          </p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {([
              ["name", "Ürün Adı *", true],
              ["price_text", "Fiyat", false],
              ["description", "Açıklama", false],
              ["category", "Kategori", false],
              ["stockStatus", "Stok Durumu", false],
              ["imageUrls", "Görsel URL", false],
            ] as const).map(([field, label, required]) => (
              <div key={field}>
                <label className="owner-label text-xs">
                  {label} {required && <span className="text-red-500">*</span>}
                </label>
                <select
                  className="owner-input w-full text-xs"
                  value={mapping[field] !== null ? String(mapping[field]) : ""}
                  onChange={(e) => {
                    const val = e.target.value;
                    updateMapping(field, val === "" ? null : Number(val));
                  }}
                >
                  <option value="">— Seçilmedi —</option>
                  {headers.map((h, i) => (
                    <option key={i} value={i}>
                      {h} (sütun {i + 1})
                    </option>
                  ))}
                </select>
              </div>
            ))}
          </div>
          <div className="mt-6 flex gap-3">
            <button type="button" className="owner-button-secondary" onClick={reset}>
              Geri
            </button>
            <button
              type="button"
              className="owner-button-primary"
              onClick={reParseWithMapping}
              disabled={mapping.name === null}
            >
              Önizle ({parsedProducts.length} ürün)
            </button>
          </div>
        </div>
      )}

      {/* Adım 3: Önizleme */}
      {step === "review" && (
        <div className="mt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm font-bold text-[var(--owner-text)]">
              {parsedProducts.length} ürün yüklenecek
            </p>
            <button type="button" className="owner-button-secondary text-xs" onClick={() => setStep("map")}>
              Eşlemeyi Değiştir
            </button>
          </div>

          <div className="mt-3 max-h-80 overflow-y-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="border-b border-[var(--owner-border)]">
                  <th className="px-2 py-1.5 text-left font-bold text-[var(--owner-text)]">#</th>
                  <th className="px-2 py-1.5 text-left font-bold text-[var(--owner-text)]">Ürün Adı</th>
                  <th className="px-2 py-1.5 text-left font-bold text-[var(--owner-text)]">Fiyat</th>
                  <th className="px-2 py-1.5 text-left font-bold text-[var(--owner-text)]">Kategori</th>
                  <th className="px-2 py-1.5 text-left font-bold text-[var(--owner-text)]">Stok</th>
                  <th className="px-2 py-1.5" />
                </tr>
              </thead>
              <tbody>
                {parsedProducts.map((p, i) => (
                  <tr key={i} className="border-b border-[var(--owner-border)]/50">
                    <td className="px-2 py-1.5 text-[var(--owner-muted)]">{p._rowIndex}</td>
                    <td className="max-w-[200px] truncate px-2 py-1.5 font-medium text-[var(--owner-text)]">{p.name}</td>
                    <td className="px-2 py-1.5 text-[var(--owner-text)]">{p.price_text || "—"}</td>
                    <td className="px-2 py-1.5 text-[var(--owner-text)]">{p.category || "—"}</td>
                    <td className="px-2 py-1.5 text-[var(--owner-text)]">{p.stockStatus}</td>
                    <td className="px-2 py-1.5">
                      <button
                        type="button"
                        className="text-red-500 hover:text-red-700"
                        onClick={() => removeProduct(i)}
                        title="Kaldır"
                      >
                        ✕
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="mt-4 flex gap-3">
            <button type="button" className="owner-button-secondary" onClick={reset} disabled={busy}>
              İptal
            </button>
            <button
              type="button"
              className="owner-button-primary"
              onClick={saveAll}
              disabled={busy || parsedProducts.length === 0}
            >
              {busy ? "Kaydediliyor…" : `${parsedProducts.length} Ürünü Kaydet`}
            </button>
          </div>
        </div>
      )}

      {/* Adım 4: Sonuç */}
      {step === "done" && batchResult && (
        <div className="mt-4">
          <div className={`rounded-xl border p-4 ${
            batchResult.hatali > 0
              ? "border-yellow-400/40 bg-yellow-400/10"
              : "border-[var(--owner-success)]/40 bg-[var(--owner-success)]/10"
          }`}>
            <p className={`text-sm font-bold ${
              batchResult.hatali > 0 ? "text-yellow-700" : "text-[var(--owner-success)]"
            }`}>
              {batchResult.hatali > 0
                ? `kısmen başarılı`
                : `tümü kaydedildi`}
            </p>
            <div className="mt-2 flex gap-4 text-xs text-[var(--owner-text)]">
              <span>📊 Toplam: {batchResult.toplam}</span>
              <span className="text-[var(--owner-success)]">Eklenen: {batchResult.eklenen}</span>
              {batchResult.hatali > 0 && (
                <span className="text-yellow-700">⚠️ Hatalı: {batchResult.hatali}</span>
              )}
            </div>
            {batchResult.hataDetaylari.length > 0 && (
              <ul className="mt-2 list-disc pl-5 text-xs text-yellow-700">
                {batchResult.hataDetaylari.slice(0, 5).map((e, i) => (
                  <li key={i}>Satır {e.index}: {e.error}</li>
                ))}
              </ul>
            )}
          </div>
          <button type="button" className="owner-button-primary mt-4" onClick={reset}>
            Yeni Dosya Yükle
          </button>
        </div>
      )}
    </section>
  );
}
