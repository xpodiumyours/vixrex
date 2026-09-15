import { describe, expect, it } from "vitest";
import { parseRows, type ColumnMapping } from "@/components/owner/BulkProductUpload";

const mapping: ColumnMapping = { name: 0, price_text: 1, category: 2, stockStatus: 3, stockQuantity: 4, brand: 5, barcode: 6, sku: 7, imageUrls: 8, description: null };
const headers = ["Ürün Adı", "Fiyat", "Kategori", "Stok", "Stok Adedi", "Marka", "Barkod", "SKU", "Görsel URL 1", "Görsel URL 2"];

describe("toplu yükleme önizlemesi", () => {
  it.each(["ftp://cdn.example/photo.jpg", "https://", "https://cdn.example/a b.jpg"])("geçersiz görseli sessizce silmez: %s", (url) => {
    const result = parseRows([headers, ["Ürün", "", "", "", "", "", "", "", url]], headers, mapping);
    expect(result.products).toHaveLength(0);
    expect(result.errors[0]).toContain("Satır 2:");
  });
  it.each([["out of stock", "Tükendi"], ["sold out", "Tükendi"], ["low", "Son birkaç adet"]])("stok karşılığını korur: %s", (input, expected) => {
    const result = parseRows([headers, ["Ürün", "", "", input]], headers, mapping);
    expect(result.products[0].stockStatus).toBe(expected);
  });
  it("boş adet hücresinde stok sütununu kullanır ve binlik fiyatı korur", () => {
    const result = parseRows([headers, ["Ürün", "1.299 TL", "", "10", ""]], headers, mapping);
    expect(result.products[0]).toMatchObject({ price_text: "1299", stockQuantity: 10 });
  });
  it("yeni alanları ve birden fazla fotoğrafı taşır", () => {
    const { products } = parseRows([headers, ["Ürün", "12,50", "Servis", "10", "10", "Marka", "00123", "S-1", "https://cdn.example/1.jpg", "https://cdn.example/2.jpg"]], headers, mapping);
    expect(products[0]).toMatchObject({ brand: "Marka", barcode: "00123", sku: "S-1", stockQuantity: 10, stockStatus: "Mevcut", price_text: "12.50", category: "Servis" });
    expect(products[0].imageUrls).toHaveLength(2);
  });

  it("görselsiz taslağı korur, adı boş satırı atlar ve eşlemeyi yeniden uygular", () => {
    const rows = [headers, ["", "Ürün", "", "", "0"]];
    expect(parseRows(rows, headers, mapping).errors).toHaveLength(1);
    const result = parseRows(rows, headers, { ...mapping, name: 1, price_text: null, imageUrls: null });
    expect(result.products[0]).toMatchObject({ name: "Ürün", imageUrls: [], stockQuantity: 0, stockStatus: "Tükendi", _rowIndex: 2 });
  });
});
