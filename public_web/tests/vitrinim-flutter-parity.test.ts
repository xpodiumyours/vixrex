import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

describe("Vitrinim Flutter Web paritesi", () => {
  const next = readFileSync(resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"), "utf-8");
  const flutterForm = readFileSync(resolve(__dirname, "../../lib/screens/my_vitrin/sections/vitrin_form_section.dart"), "utf-8");
  const flutterLocation = readFileSync(resolve(__dirname, "../../lib/widgets/editor/location_editor_section.dart"), "utf-8");
  const flutterLocationSection = readFileSync(resolve(__dirname, "../../lib/widgets/editor/sections/konum_saatler_bolumu.dart"), "utf-8");
  const flutterContent = readFileSync(resolve(__dirname, "../../lib/widgets/editor/sections/icerik_seo_bolumu.dart"), "utf-8");
  const structuredRoute = readFileSync(resolve(__dirname, "../src/app/api/owner-structured-field/route.ts"), "utf-8");

  it("beş akordeon ve Flutter ilerleme toplamlarını korur", () => {
    for (const title of ["Kimlik", "İletişim", "Konum ve saatler", "Görseller", "İçerik ve SEO"]) {
      expect(flutterForm).toContain(`'${title}'`);
      expect(next).toContain(`title: "${title}"`);
    }
    expect(next).toContain('total: 5');
    expect(next).toContain('total: 4');
    expect(next).toContain('total: 6');
    expect(next).toContain('total: 12');
    expect(next).toContain('const adresTamam = ["adres", "il", "ilce"].every');
    expect(next).not.toContain('total: 9');
  });

  it("GPS kullanıcı onayı gelmeden hiçbir vitrin alanını yazmaz", () => {
    expect(flutterLocation).toContain('ONAYA KADAR HİÇBİR ŞEY YAZILMAZ');
    expect(flutterLocation).toContain('Evet, burası');
    expect(flutterLocation).toContain('Hayır, elle yazayım');

    const findStart = next.indexOf("async function konumuAl()");
    const confirmStart = next.indexOf("async function gpsOnerisiniKabulEt()");
    expect(findStart).toBeGreaterThan(-1);
    expect(confirmStart).toBeGreaterThan(findStart);
    const findPhase = next.slice(findStart, confirmStart);
    expect(findPhase).toContain("setGpsOnerisi");
    expect(findPhase).not.toContain("saveValue(");
    expect(findPhase).not.toContain("updateLocal(");

    const confirmPhase = next.slice(confirmStart, next.indexOf("function gpsOnerisiniReddet()"));
    expect(confirmPhase).toContain("saveValue(");
    expect(next).toContain("Konumunu buldum. Burası mı?");
    expect(next).toContain("Evet, burası");
    expect(next).toContain("Hayır, elle yazayım");
  });

  it("il ve ilçe Flutter gibi listeden seçilir ve ilçe ile birlikte kaydedilir", () => {
    expect(next).toContain("turkeyProvinces");
    expect(next).toContain("getDistrictsForProvince");
    expect(next).toContain("İl seçiniz");
    expect(next).toContain("Önce il seçiniz");
    expect(next).toContain("ilceDegistir");
  });

  it("yol tarifi ve puan görünürlüğü Flutter metinleriyle aynı yüzeydedir", () => {
    expect(flutterLocationSection).toContain("Yol tarifi butonu göster");
    expect(next).toContain("Yol tarifi butonu göster");
    expect(next).toContain('boolDegistir("yolTarifiGoster"');

    expect(flutterContent).toContain("Vitrinde puan bandı göster");
    expect(next).toContain("Vitrinde puan bandı göster");
    expect(next).toContain('boolDegistir("puanGoster"');
  });

  it("bölüm görünürlüğü Vitrinim içinde ve yapılandırılmış doğru kayıt yolundadır", () => {
    for (const key of ["categories", "products", "about", "gallery", "blog", "faq", "contact"]) {
      expect(next).toContain(`key: "${key}"`);
    }
    expect(next).toContain('saveStructured("section_visibility"');
    expect(next).toContain('/api/owner-structured-field');
    expect(structuredRoute).toContain('"section_visibility"');
  });

  it("kapak için Flutter'daki üç giriş yolu bulunur: dosya, kamera, hazır görsel", () => {
    expect(next).toContain("Dosya yükle");
    expect(next).toContain('capture="environment"');
    expect(next).toContain("Hazır görseller");
    expect(next).toContain("/api/category-images?category=");
  });

  it("ilerleme hesabı Flutter'ın güncel alan toplamını kullanır; eski Next ekstra alanlarını saymaz", () => {
    const progressStart = next.indexOf("const progress = useMemo");
    const progressEnd = next.indexOf("const addressCompleted");
    const progressSource = next.slice(progressStart, progressEnd);
    for (const key of ["logo", "mahalle", "enlem", "boylam"]) {
      expect(progressSource).not.toContain(`"${key}"`);
    }
  });
});