import type { ProductManufacturerSource } from "@/lib/productRichData";

interface ManufacturerProductSourceProps {
  source?: ProductManufacturerSource;
}

function safeManufacturerUrl(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  try {
    const parsed = new URL(trimmed);
    if ((parsed.protocol !== "http:" && parsed.protocol !== "https:") || parsed.username || parsed.password) {
      return null;
    }
    return parsed.toString();
  } catch {
    return null;
  }
}

export default function ManufacturerProductSource({ source }: ManufacturerProductSourceProps) {
  const url = safeManufacturerUrl(source?.url);
  if (!url) return null;

  return (
    <div className="mt-5 rounded-2xl border border-white/10 bg-white/[0.03] px-4 py-3">
      <a
        href={url}
        target="_blank"
        rel="noopener noreferrer"
        className="text-xs font-extrabold text-blue-400 hover:text-blue-300"
      >
        Üretici ürün kaynağı →
      </a>
    </div>
  );
}
