import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, "..", yol), "utf8");

/**
 * Keşfet listesi 5 dakika saklanıyor (src/lib/explore.ts).
 *
 * Yayın anında düşürülmezse esnaf "yayınladım" der ama kendi vitrinini
 * Keşfet'te dakikalarca göremez — akış orada çalışmıyor gibi durur
 * (2026-10-03 şikâyeti). Bu dosya üç şeyi kilitler:
 *   1) yayınlama uçları listeyi tazeliyor,
 *   2) niyet köprüsü artık yalnız kiralık vitrinlere bağlanmıyor,
 *   3) kapaksız/ürünsüz kart açıklayıcı bir metin gösteriyor.
 */
describe("Keşfet — yayın sonrası anında tazelenme", () => {
  it("explore, düşürme yardımcısını dışa açıyor", () => {
    const kaynak = oku("src/lib/explore.ts");
    expect(kaynak).toContain("export function kesfetOnbelleginiYenile");
    expect(kaynak).toContain('revalidateTag("kesfet"');
  });

  it("create-store başarılı yayından sonra listeyi tazeliyor", () => {
    const kaynak = oku("src/app/api/create-store/route.ts");
    expect(kaynak).toContain("kesfetOnbelleginiYenile()");
  });

  it("owner-publish başarılı yayından sonra listeyi tazeliyor", () => {
    const kaynak = oku("src/app/api/owner-publish/route.ts");
    expect(kaynak).toContain("kesfetOnbelleginiYenile()");
  });

  it("ürün yayını da listeyi tazeliyor — karttaki bilgi değişir", () => {
    const kaynak = oku("src/lib/vitrinYayinDogrula.ts");
    expect(kaynak).toContain('"kesfet"');
  });

  it("pasifleştirme listeyi tazeliyor — mevcut davranış korunuyor", () => {
    const kaynak = oku("src/app/api/account/route.ts");
    expect(kaynak).toContain('"kesfet"');
  });
});

describe("Keşfet — niyet köprüsü hem kiralık hem gerçek vitrini gösterir", () => {
  it("landing asistanı yalnız kiralık listesine bağlanmıyor", () => {
    const kaynak = oku(
      "src/components/landing/LandingAsistanSohbeti.tsx"
    );
    expect(kaynak).not.toContain("yalniz_kiralik=1");
    expect(kaynak).toContain("`/kesfet?kategori=");
    expect(kaynak).toContain('"/kesfet"');
  });
});

describe("Keşfet kartı — boşsa açıklayıcı", () => {
  const kart = () =>
    oku("src/components/kesfet/VitrinKarti.tsx");

  it("kapak yoksa kategori öne çıkar, eksiklik açıkça yazılır", () => {
    const kaynak = kart();
    expect(kaynak).toContain("{vitrin.kategoriEtiketi}");
    expect(kaynak).toContain("Kapak görseli eklenmedi");
    // Kiralık şablonun davranışı değişmedi
    expect(kaynak).toContain("Kapak görseli bekleniyor");
  });

  it("ürünsüz gerçek vitrin 'Henüz ürün eklenmedi' der", () => {
    expect(kart()).toContain("Henüz ürün eklenmedi");
  });

  it("Flutter kartı web ile aynı metinleri kullanıyor (parite)", () => {
    const flutter = readFileSync(
      resolve(__dirname, "../../lib/widgets/vitrin_store_card.dart"),
      "utf8"
    );
    expect(flutter).toContain("Henüz ürün eklenmedi");
    expect(flutter).toContain("Kapak görseli eklenmedi");
    expect(flutter).toContain("Kapak görseli bekleniyor");
  });
});
