import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * ESNAF AKIŞI — "Yayınla"YA BASILINCA HEM GERÇEKTEN YAYINLANIR HEM DE
 * EKSİK BİLGİ SÖYLENİR (2026-10-02).
 *
 * NEDEN VAR
 * Aynı sorun iki kez yaşandı:
 *   1) asistan "yayınlandı" derdi, vitrin taslakta kalırdı → #619 çözdü
 *      (`update_store_with_token` ile zincire yayın adımı eklendi).
 *   2) yayın kapısı reddedince kullanıcıya "Vitrin oluşturulamadı.
 *      Lütfen tekrar dene" deniyordu — neyin eksik olduğu söylenmiyordu.
 *
 * Bu dosya ikinci sorunu kilitliyor. Üç iddia:
 *   - eksik bilgide vitrin HİÇ OLUŞMAZ, 422 ile NEYİN eksik olduğu söylenir;
 *   - eksik yasal onayda aynısı olur, taslak üretilmez;
 *   - veritabanından dönen ham kod (`STORE_WHATSAPP_INVALID` gibi) hiçbir
 *     zaman kullanıcıya çırplak gösterilmez.
 *
 * Ayrıca oluşturma ekranındaki tek onay kutusunun kilidi de burada:
 * vitrin daha oluşmadan sunucuya onay yazılamadığı için eski davranış
 * kutuyu hep hata döndürüyordu ve "Vitrinimi Yayına Al" hiç açılmıyordu.
 */

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

const rota = oku("src/app/api/create-store/route.ts");
const editor = oku("src/components/owner/VitrinimEditor.tsx");

describe("yayinla dediyse eksik bilgi soyenilir, taslak sessiz kalmaz", () => {
  it("rota, eksik alanlari tek tek toplayip 422 donuyor", () => {
    expect(rota).toContain("const eksik: string[] = [];");
    expect(rota).toContain('eksik.push("kategori")');
    expect(rota).toContain('eksik.push("açık adres")');
    expect(rota).toContain('eksik.push("il")');
    expect(rota).toContain('eksik.push("ilçe")');
    expect(rota).toContain("anında yayına alınır");
    expect(rota).toContain("üç yasal onayın tamamı gerekli");
    // İsim, alanlar ve yasal onay — üç ayrı erken ret.
    expect(rota.match(/\{ status: 422 \}/g)?.length).toBeGreaterThanOrEqual(3);
  });

  it("eksik bilgi kontrolu vitrin kaydindan ÖNCE geliyor", () => {
    const eksikIndex = rota.indexOf("const eksik: string[] = [];");
    const kayitIndex = rota.indexOf('"create_store_with_token"');
    expect(eksikIndex).toBeGreaterThan(-1);
    expect(kayitIndex).toBeGreaterThan(eksikIndex);
  });

  it("yayin zinciri korunuyor: olusturma ve ardindan yayina alma var", () => {
    // #619'un getirdiği adım — bu bir daha silinmemeli.
    expect(rota).toContain('"create_store_with_token"');
    expect(rota).toContain('"update_store_with_token"');
    expect(rota).toContain("is_published: true");
    expect(rota).toContain('status: "Açık"');
    // Belge sürümü/hash'i tarayıcıdan güvenilmez; sunucuda aktif kayıttan.
    expect(rota).toContain('"legal_documents"');
    expect(rota).toContain("aktifYasalBelgeleriHaritala");
  });

  it("veritabani kodu muğlak hataya donusturulmuyor", () => {
    expect(rota).toContain("RPC_HATA_METNI");
    expect(rota).toContain("function hataMetni(");
    for (const kod of [
      "STORE_CATEGORY_REQUIRED",
      "STORE_WHATSAPP_INVALID",
      "STORE_ADDRESS_REQUIRED",
      "STORE_PROVINCE_REQUIRED",
      "STORE_DISTRICT_REQUIRED",
      "PRIVACY_NOTICE_REQUIRED",
      "PUBLICATION_CONSENT_REQUIRED",
      "PRODUCT_IMAGE_REQUIRED",
    ]) {
      expect(rota, `${kod} için Türkçe metin yok`).toContain(`${kod}:`);
    }
    // Ham kod kullanıcıya yalnız çevrilmiş hâliyle ulaşır.
    expect(rota).toContain("hataMetni(");
  });

  it("olusturma modundaki tek onay kutusu calisiyor", () => {
    // Eski davranış: kutu her tıklamada /api/owner-accept-legal'i çağırıyor,
    // vitrin henüz olmadığı için hep hata dönüyordu → Yayınla hiç açılmıyordu.
    expect(editor).toContain(
      "if (isCreationMode) { setLegalAccepted(true); return; }",
    );
    expect(editor).toContain("initialDraft.legal_consent");
    expect(editor).toContain("legal_consent: true");
  });
});
