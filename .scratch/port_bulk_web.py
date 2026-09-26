from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
path = 'public_web/src/components/owner/BulkProductUpload.tsx'
p = root / path
t = p.read_text(encoding='utf-8')
s = subprocess.check_output(['git', 'show', 'work/product-live-ready-20260914:' + path], cwd=root).decode('utf-8')

def replace(old, new):
    global t
    assert old in t, old[:100]
    t = t.replace(old, new)

replace('interface ParsedProduct {', 'export interface ParsedProduct {')
replace('interface ColumnMapping {', 'export interface ColumnMapping {')
replace('  stockStatus: string;', '  stockStatus: string;\n  stockQuantity: number | null;\n  brand: string;\n  barcode: string;\n  sku: string;')
replace('  stockStatus: number | null;', '  stockStatus: number | null;\n  stockQuantity: number | null;\n  brand: number | null;\n  barcode: number | null;\n  sku: number | null;')
replace('stockStatus: null, imageUrls: null,', 'stockStatus: null, imageUrls: null, stockQuantity: null, brand: null, barcode: null, sku: null,')
replace('stockStatus: null, imageUrls: null });', 'stockStatus: null, imageUrls: null, stockQuantity: null, brand: null, barcode: null, sku: null });')
replace('  const [headers, setHeaders]', '  const [sourceRows, setSourceRows] = useState<string[][]>([]);\n  const [headers, setHeaders]')
replace('    .replace(/[iiî]/g, "i")', '    .replace(/[ıiî]/g, "i")')
replace('const IMAGE_ALIASES', 'const QUANTITY_ALIASES = new Set(["stokadedi", "stokmiktari", "stockquantity", "quantity", "adet"]);\nconst BRAND_ALIASES = new Set(["marka", "brand", "uretici", "manufacturer"]);\nconst BARCODE_ALIASES = new Set(["barkod", "barcode", "gtin", "ean", "upc", "kod"]);\nconst SKU_ALIASES = new Set(["sku", "stokkodu", "urunkodu", "productcode", "code"]);\nconst IMAGE_ALIASES')
start = s.index('function isImageHeader')
end = s.index('function normalizePrice', start)
replace('function normalizePrice', s[start:end].replace('(gorsel|image|foto|resim)', '(gorsel|image|foto|fotograf|resim|kapak|cover)') + 'function normalizePrice')
start = s.index('function collectImageUrls')
end = s.index('export default function', start)
helpers = s[start:end].replace('  return urls.slice(0, MAX_PRODUCT_IMAGES);', '  return urls;')
helpers = helpers.replace('function parseRows(', 'export function parseRows(')
a = helpers.index('    if (imageUrls.length < MIN_PRODUCT_IMAGES)')
b = helpers.index('    const priceRaw', a)
helpers = helpers[:a] + helpers[b:]
helpers = helpers.replace('    products.push({', '''    const quantityRaw = mapping.stockQuantity !== null ? values[mapping.stockQuantity] ?? "" : mapping.stockStatus !== null ? values[mapping.stockStatus] ?? "" : "";
    const stockQuantity = /^\d+$/.test(quantityRaw) ? Number(quantityRaw) : null;
    products.push({''')
helpers = helpers.replace('      imageUrls,', '''      stockQuantity,
      brand: mapping.brand !== null ? values[mapping.brand] ?? "" : "",
      barcode: mapping.barcode !== null ? values[mapping.barcode] ?? "" : "",
      sku: mapping.sku !== null ? values[mapping.sku] ?? "" : "",
      imageUrls,''')
helpers = helpers.replace('stockStatus: mapping.stockStatus', 'stockStatus: stockQuantity === 0 ? "Tükendi" : mapping.stockStatus')
replace('export default function BulkProductUpload', helpers + 'export default function BulkProductUpload')
replace('      setHeaders(headerRow);', '      setHeaders(headerRow);\n      setSourceRows(rows);')
replace('else if (IMAGE_ALIASES.has(n)', 'else if (isImageHeader(h)')
replace('        const n = normalizeHeader(h);', '''        const n = normalizeHeader(h);
        if (QUANTITY_ALIASES.has(n) && autoMap.stockQuantity === null) autoMap.stockQuantity = i;
        if (BRAND_ALIASES.has(n) && autoMap.brand === null) autoMap.brand = i;
        if (BARCODE_ALIASES.has(n) && autoMap.barcode === null) autoMap.barcode = i;
        if (SKU_ALIASES.has(n) && autoMap.sku === null) autoMap.sku = i;''')
a = t.index('      const products: ParsedProduct[] = [];', t.index('  const handleFile'))
b = t.index('      setStep("map");', a)
old = t[a:b]
comments = '\n'.join(line[line.index('//'):] for line in old.splitlines() if '//' in line)
t = t[:a] + '      ' + comments + '\n      const parsed = parseRows(rows, headerRow, autoMap);\n      setParsedProducts(parsed.products);\n      setErrors(parsed.errors.slice(0, 10));\n' + t[b:]
replace('    setStep("review");\n  }', '''    const parsed = parseRows(sourceRows, headers, mapping);
    setParsedProducts(parsed.products);
    setErrors(parsed.errors.slice(0, 10));
    if (parsed.products.length === 0) return;
    setStep("review");
  }''')
replace('            image_urls: p.imageUrls,', '''            category_name: p.category || null,
            stock_status: p.stockStatus,
            stock_quantity: p.stockQuantity,
            brand: p.brand || null,
            barcode: p.barcode || null,
            sku: p.sku || null,
            image_urls: p.imageUrls,''')
replace('    setHeaders([]);', '    setHeaders([]);\n    setSourceRows([]);')
replace('["stockStatus", "Stok Durumu", false],', '''["stockStatus", "Stok Durumu", false],
              ["stockQuantity", "Stok Adedi", false],
              ["brand", "Marka", false],
              ["barcode", "Barkod", false],
              ["sku", "SKU", false],''')
replace('Ürün Adı,Fiyat,Açıklama,Kategori,Stok Durumu,Görsel URL\\nÖrnek Ürün 1,125.50,Günlük kullanım için uygun,Genel,Mevcut,\\nÖrnek Ürün 2,\\"1,250.00\\",Özel tasarım elbise,Elbise,Mevcut,https://ornek.com/gorsel.jpg\\nÖrnek Ürün 3,,Kampanyalı fiyat,Genel,Tükendi,', 'Ürün Adı,Fiyat,Açıklama,Kategori,Stok Durumu,Stok Adedi,Marka,Barkod,SKU,Görsel URL 1,Görsel URL 2,Görsel URL 3\\nÖrnek Ürün,125.50,Günlük kullanım için uygun,Genel,Mevcut,12,Örnek Marka,8690000000005,ORNEK-1,https://ornek.com/urun-a.jpg,https://ornek.com/urun-b.jpg,https://ornek.com/urun-c.jpg')
p.write_text(t, encoding='utf-8')
p = root / 'supabase/migrations/20260915020000_product_batch_rich_fields.sql'
t = p.read_text(encoding='utf-8').replace('public.slugify_tr(v_category_name)', 'public._normalize_product_slug(v_category_name)')
p.write_text(t, encoding='utf-8')
