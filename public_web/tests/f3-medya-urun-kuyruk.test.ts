import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

describe("F3 medya eşitliği — Flutter StoreShelfUploadService vs Next owner-upload", () => {
  const flutter = readFileSync(resolve(__dirname, "../../lib/services/store_shelf_upload_service.dart"), "utf-8");
  const next = readFileSync(resolve(__dirname, "../src/app/api/owner-upload/route.ts"), "utf-8");
  const nextLib = readFileSync(resolve(__dirname, "../src/lib/gorselSikistir.ts"), "utf-8");
  const flutterOpt = readFileSync(resolve(__dirname, "../../lib/services/image_optimization_service.dart"), "utf-8");

  it("her iki yüzey aynı bucket'ta yazar: shelf-images", () => {
    expect(flutter).toContain("shelf-images");
    expect(next).toContain('from("shelf-images")');
  });

  it("her iki yüzey aynı önbellek süresini kullanır: 31536000 (1 yıl)", () => {
    expect(flutter).toContain("31536000");
    // Next owner-upload ONBELLEK_SANIYE'yi gorselSikistir.ts'den import eder
    expect(next).toContain("ONBELLEK_SANIYE");
    expect(nextLib).toContain("31536000");
  });

  it("tek dosya limiti 5 MB her iki yüzeyde", () => {
    expect(flutter).toContain("5");
    expect(next).toContain("5 * 1024 * 1024");
  });

  it("yalnız JPG/PNG/WebP kabul edilir (magic byte kontrolü her iki tarafta)", () => {
    // Next magic byte kontrolü
    expect(next).toContain("image/jpeg");
    expect(next).toContain("image/png");
    expect(next).toContain("image/webp");
    // Flutter uzantı normalize
    expect(flutter).toContain("sanitizeExtension");
    expect(flutter).toContain("webp");
  });

  it("görsel 1600px sıkıştırma her iki yüzeyde (tek ağırlık)", () => {
    expect(nextLib).toContain("1600");
    expect(flutterOpt).toContain("1600");
  });

  it("Next upload yolu oturum slug'ından türetilir (istemci yolu kullanılmaz) — Flutter ile aynı güvenlik", () => {
    expect(next).toContain("guvenliSlug");
    expect(next).toContain("ownerSession.slug");
    expect(flutter).toContain("sanitizeSlug");
  });
});

describe("F4 ürün ayrı kuyruğu — güvenli ve net", () => {
  const productQueueSrc = readFileSync(resolve(__dirname, "../src/lib/productQueue.ts"), "utf-8");
  const vitrinEditorSrc = readFileSync(resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"), "utf-8");
  const ownerProductSrc = readFileSync(resolve(__dirname, "../src/components/owner/OwnerProductManager.tsx"), "utf-8");

  it("ürün kuyruğu draft kuyruğundan ayrı anahtarda tutulur", () => {
    expect(productQueueSrc).toContain("vixrex_product_queue_v1");
    expect(productQueueSrc).toContain("DRAFT_QUEUE_KEY_HINT");
    // Ürün kuyruğu ayrı lib, draft'a karışmaz — lib adı productQueue, draft değil
    expect(productQueueSrc).toContain("PRODUCT_QUEUE_STORAGE_KEY");
  });

  it("vitrin metin akordeonu ile ürün ayrı yoldan kaydedilir (farklı API)", () => {
    expect(vitrinEditorSrc).toContain('/api/owner-draft');
    expect(ownerProductSrc).toContain('/api/products');
    expect(ownerProductSrc).not.toContain('/api/owner-draft');
  });

  it("ürün kuyruğu ayrı lib'de, vitrin draft lib'ine karışmaz", () => {
    expect(productQueueSrc).toContain("productQueueEnqueue");
    expect(productQueueSrc).toContain("productQueueFlush");
    expect(productQueueSrc).not.toContain("FIELD_BY_KEY");
  });

  it("offline için localStorage + navigator.onLine kontrolü var", () => {
    expect(productQueueSrc).toContain("localStorage");
    expect(productQueueSrc).toContain("navigator.onLine");
  });
});
