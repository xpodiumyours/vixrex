import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { expect, it } from "vitest";

it("vitrin kartı izin etiketini yalnız sahip önizlemesinde gösterir", () => {
  const source = readFileSync(
    fileURLToPath(new URL("../src/app/v/[slug]/ProductCatalog.tsx", import.meta.url)),
    "utf8",
  );
  expect(source).toContain("{ownerPreview && product.gorselIzinBekliyor ?");
  expect(source).toContain("ownerPreview?: boolean");
});

it("sahip modu vitrin sayfasından kataloğa iletilir", () => {
  const source = readFileSync(
    fileURLToPath(new URL("../src/app/v/[slug]/page.tsx", import.meta.url)),
    "utf8",
  );
  expect(source).toContain("ownerPreview={isOwnerMode}");
});

it("tüketici ürün sayfası izin etiketi hesaplamaz", () => {
  const source = readFileSync(
    fileURLToPath(new URL("../src/app/v/[slug]/urun/[productSlug]/page.tsx", import.meta.url)),
    "utf8",
  );
  expect(source).not.toContain("gorselIzinBekliyorMu");
  expect(source).not.toContain("gorselIzinBekliyor");
});

it("tüketici detay bileşeni izin etiketi çizmez", () => {
  const source = readFileSync(
    fileURLToPath(new URL("../src/components/ProductDetailExperienceBase.tsx", import.meta.url)),
    "utf8",
  );
  expect(source).not.toContain("İzin belgesi bekleniyor");
});
