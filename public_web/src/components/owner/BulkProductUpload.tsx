"use client";

import { useState, useRef, useCallback } from "react";
import {
  MAX_PRODUCT_IMAGES,
  MIN_PRODUCT_IMAGES,
} from "@/lib/productImagePolicy";

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

function isImageHeader(header: string): boolean {
  const normalized = normalizeHeader(header);
  return (
    IMAGE_ALIASES.has(normalized) ||
    /^(gorsel|image|foto|resim)(url)?\d+$/.test(normalized)
  );
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

function collectImageUrls(
  values: string[],
  headers: string[],
  mappedIndex: number | null,
): string[] {
  if (mappedIndex === null) return [];
  const indexes = new Set<number>([mappedIndex]);
  headers.forEach((header, index) => {
    if (isImageHeader(header)) indexes.add(index);
  });

  const urls: string[] = [];
  for (const index of indexes) {
    const cell = String(values[index] ?? "").trim();
    if (!cell) continue;
    for (const raw of cell.split(/\s*\|\s*|\r?\n/)) {
      const trimmed = raw.trim();
      if (!trimmed) continue;
      const url = trimmed.startsWith("//") ? `https:${trimmed}` : trimmed;
      if (/^https?:\/\//i.test(url) && !urls.includes(url)) urls.push(url);
    }
  }
  return urls.slice(0, MAX_PRODUCT_IMAGES);
}

function parseRows(
  rows: string[][],
  headers: string[],
  mapping: ColumnMapping,
): { products: ParsedProduct[]; errors: string[] } {
  const products: ParsedProduct[] = [];
  const errors: string[] = [];

  for (let i = 1; i < rows.length; i++) {
    const values = rows[i].map((value) => String(value ?? "").trim());
    const name = mapping.name !== null ? (values[mapping.name] ?? "") : "";
    if (!name.trim()) {
      errors.push(`Satır ${i + 1}: Ürün adı boş, atlandı.`);
      continue;
    }

    const imageUrls = collectImageUrls(values, headers, mapping.imageUrls);
    if (imageUrls.length < MIN_PRODUCT_IMAGES) {
      errors.push(
        `Satır ${i + 1}: En az ${MIN_PRODUCT_IMAGES} ürün fotoğrafı gerekli, satır atlandı.`,
      );
      continue;
    }

    const priceRaw = mapping.price_text !== null ? (values[mapping.price_text] ?? "") : "";
    products.push({
      name: name.trim(),
      description: mapping.description !== null ? (values[mapping.description] ?? "").trim() : "",
      price_text: normalizePrice(priceRaw),
      category: mapping.category !== null ? (values[mapping.category] ?? "").trim() : "",
      stockStatus: mapping.stockStatus !== null ? normalizeStock(values[mapping.stockStatus] ?? "") : "Mevcut",
      imageUrls,
      _raw: Object.fromEntries(headers.map((header, index) => [header, values[index] ?? ""])),
      _rowIndex: i + 1,
    });
  }

  return { products, errors };
}

export default function BulkProductUpload({
  storeSlug,
  onUploaded,
}: BulkProductUploadProps) {
  const [step, setStep] = useState<"pick" | "map" | "review" | "saving" | "done">("pick");
  const [headers, setHeaders] = useState<string[]>([]);
  const [sourceRows, setSourceRows] = useState<string[][]>([]);
  const [mapping, setMapping] = useState<ColumnMapping>({
    name: null, description: null, price_text: null,
    category: null, stockStatus: null, imageUrls: null,
  });
  const [parsedProducts, setParsedProducts] = useState<ParsedProduct[]>([]);
  const [errors, setErrors] = useState<string[]>([]);
  const [batchResult, setBatchResult] = useState<BatchResult | null>(null);
  const [busy, setBusy] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

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
          .filter((line) => line.trim())
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

      const headerRow = rows[0].map((header) => String(header ?? ""));
      setHeaders(headerRow);
      setSourceRows(rows);

      const autoMap: ColumnMapping = {
        name: null, description: null, price_text: null,
        category: null, stockStatus: null, imageUrls: null,
      };
      headerRow.forEach((header, index) => {
        const normalized = normalizeHeader(header);
        if (NAME_ALIASES.has(normalized) && autoMap.name === null) autoMap.name = index;
        else if (PRICE_ALIASES.has(normalized) && autoMap.price_text === null) autoMap.price_text = index;
        else if (DESC_ALIASES.has(normalized) && autoMap.description === null) autoMap.description = index;
        else if (CATEGORY_ALIASES.has(normalized) && autoMap.category === null) autoMap.category = index;
        else if (STOCK_ALIASES.has(normalized) && autoMap.stockStatus === null) autoMap.stockStatus = index;
        else if (isImageHeader(header) && autoMap.imageUrls === null) autoMap.imageUrls = index;
      });

      if (autoMap.name === null) {
        setErrors(["Dosyada \"Ürün Adı\" veya \"Name\" başlığı bulunamadı."]);
        return;
      }

      setMapping(autoMap);
      const parsed = parseRows(rows, headerRow, autoMap);
      if (parsed.products.length === 0) {
        setErrors(["Dosyada kalite kuralını geçen ürün bulunamadı.", ...parsed.errors.slice(0, 10)]);
        return;
      }

      setParsedProducts(parsed.products);
      setErrors(parsed.errors.slice(0, 10));
      setStep("map");
    } catch {
      setErrors(["Dosya işlenirken hata oluştu."]);
    }
  }, []);

  function updateMapping(field: keyof ColumnMapping, colIndex: number | null) {
    setMapping((prev) => ({ ...prev, [field]: colIndex }));
  }

  function reParseWithMapping() {
    if (headers.length === 0 || sourceRows.length === 0) return;
    const parsed = parseRows(sourceRows, headers, mapping);
    setParsedProducts(parsed.products);
    setErrors(parsed.errors.slice(0, 10));
    if (parsed.products.length === 0) return;
    setStep("review");
  }

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
          products: parsedProducts.map((product, index) => ({
            name: product.name,
            description: product.description,
            price_text: product.price_text,
            category_name: product.category || null,
            stock_status: product.stockStatus,
            image_urls: product.imageUrls,
            source_type: "bulk_import",
            sort_order: index,
          })),
        }),
      });

      const payload = await res.json().catch(() => null);
      if (!res.ok) {
        throw new Error(
          payload && typeof payload === "object" && "hata" in payload
            ? String((payload as { hata?: unknown }).hata)
            : "Toplu ekleme başarısız oldu.",
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

  function reset() {
    setStep("pick");
    setHeaders([]);
    setSourceRows([]);
    setMapping({ name: null, description: null, price_text: null, category: null, stockStatus: null, imageUrls: null });
    setParsedProducts([]);
    setErrors([]);
    setBatchResult(null);
    setBusy(false);
    if (fileRef.current) fileRef.current.value = "";
  }

  function removeProduct(index: number) {
    setParsedProducts((prev) => prev.filter((_, i) => i !== index));
  }

  return (
    <section className="mt-6" aria-labelledby="bulk-upload-title">
      <h2 id="bulk-upload-title" className="text-lg font-bold text-[var(--owner-text)]">
        Toplu Ürün Yükleme
      </h2>
      <p className="mt-1 text-sm text-[var(--owner-muted)]">
        Excel (.xlsx) veya CSV dosyasından ürünleri toplu olarak ekle.
      </p>

      <div className="mt-4 flex items-center gap-2 text-xs text-[var(--owner-muted)]">
        <span className={`rounded-full px-2 py-0.5 font-bold ${step === "pick" ? "bg-[var(--owner-primary)] text-white" : "bg-[var(--owner-border)]"}`}>1. Dosya</span>
        <span aria-hidden="true">→</span>
        <span className={`rounded-full px-2 py-0.5 font-bold ${step === "map" ? "bg-[var(--owner-primary)] text-white" : "bg-[var(--owner-border)]"}`}>2. Eşleme</span>
        <span aria-hidden="true">→</span>
        <span className={`rounded-full px-2 py-0.5 font-bold ${step === "review" ? "bg-[var(--owner-primary)] text-white" : "bg-[var(--owner-border)]"}`}>3. Önizleme</span>
        <span aria-hidden="true">→</span>
        <span className={`rounded-full px-2 py-0.5 font-bold ${step === "done" ? "bg-[var(--owner-success)] text-white" : "bg-[var(--owner-border)]"}`}>4. Sonuç</span>
      </div>

      {errors.length > 0 && (
        <div className="mt-4 rounded-xl border border-red-400/40 bg-red-400/10 p-3">
          <p className="text-sm font-bold text-red-600">Uyarılar</p>
          <ul className="mt-1 list-disc pl-5 text-xs text-red-600">
            {errors.map((error, index) => (
              <li key={index}>{error}</li>
            ))}
          </ul>
        </div>
      )}

      {step === "pick" && (
        <div className="mt-4">
          <div
            className="owner-card cursor-pointer border-2 border-dashed p-8 text-center transition hover:border-[var(--owner-primary)]"
            onClick={() => fileRef.current?.click()}
            role="button"
            tabIndex={0}
            onKeyDown={(event) => {
              if (event.key === "Enter" || event.key === " ") fileRef.current?.click();
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
            onChange={(event) => {
              const file = event.target.files?.[0];
              if (file) handleFile(file);
            }}
          />
          <button
            type="button"
            className="owner-button-secondary mt-3 text-xs"
            onClick={() => {
              const csv = "Ürün Adı,Fiyat,Açıklama,Kategori,Stok Durumu,Görsel URL 1,Görsel URL 2,Görsel URL 3\nÖrnek Ürün 1,125.50,Günlük kullanım için uygun,Genel,Mevcut,https://ornek.com/urun1-a.jpg,https://ornek.com/urun1-b.jpg,https://ornek.com/urun1-c.jpg\nÖrnek Ürün 2,\"1,250.00\",Özel tasarım elbise,Elbise,Mevcut,https://ornek.com/urun2-a.jpg,https://ornek.com/urun2-b.jpg,https://ornek.com/urun2-c.jpg";
              const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
              const url = URL.createObjectURL(blob);
              const anchor = document.createElement("a");
              anchor.href = url;
              anchor.download = "urun-sablonu.csv";
              anchor.click();
              URL.revokeObjectURL(url);
            }}
          >
            📥 CSV Şablonu İndir
          </button>
        </div>
      )}

      {step === "map" && (
        <div className="mt-4">
          <p className="text-sm font-bold text-[var(--owner-text)]">Sütun Eşlemesi</p>
          <p className="mt-1 text-xs text-[var(--owner-muted)]">
            Her alan için hangi sütunu kullanacağını seç. Görsel 1/2/3 gibi ek görsel sütunları otomatik olarak aynı ürün galerisine eklenir.
          </p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {([
              ["name", "Ürün Adı *", true],
              ["price_text", "Fiyat", false],
              ["description", "Açıklama", false],
              ["category", "Kategori", false],
              ["stockStatus", "Stok Durumu", false],
              ["imageUrls", "İlk Görsel Sütunu *", true],
            ] as const).map(([field, label, required]) => (
              <div key={field}>
                <label className="owner-label text-xs">
                  {label} {required && <span className="text-red-500">*</span>}
                </label>
                <select
                  className="owner-input w-full text-xs"
                  value={mapping[field] !== null ? String(mapping[field]) : ""}
                  onChange={(event) => {
                    const value = event.target.value;
                    updateMapping(field, value === "" ? null : Number(value));
                  }}
                >
                  <option value="">— Seçilmedi —</option>
                  {headers.map((header, index) => (
                    <option key={index} value={index}>
                      {header} (sütun {index + 1})
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
              disabled={mapping.name === null || mapping.imageUrls === null}
            >
              Önizle ({parsedProducts.length} ürün)
            </button>
          </div>
        </div>
      )}

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
                {parsedProducts.map((product, index) => (
                  <tr key={index} className="border-b border-[var(--owner-border)]/50">
                    <td className="px-2 py-1.5 text-[var(--owner-muted)]">{product._rowIndex}</td>
                    <td className="max-w-[200px] truncate px-2 py-1.5 font-medium text-[var(--owner-text)]">{product.name}</td>
                    <td className="px-2 py-1.5 text-[var(--owner-text)]">{product.price_text || "—"}</td>
                    <td className="px-2 py-1.5 text-[var(--owner-text)]">{product.category || "—"}</td>
                    <td className="px-2 py-1.5 text-[var(--owner-text)]">{product.stockStatus}</td>
                    <td className="px-2 py-1.5">
                      <button
                        type="button"
                        className="text-red-500 hover:text-red-700"
                        onClick={() => removeProduct(index)}
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
              {batchResult.hatali > 0 ? "kısmen başarılı" : "tümü kaydedildi"}
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
                {batchResult.hataDetaylari.slice(0, 5).map((error, index) => (
                  <li key={index}>Satır {error.index}: {error.error}</li>
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