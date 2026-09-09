import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("Randevu yönetimi sekme ve eylem paritesi", () => {
  const flutterYonetim = oku(
    "../../lib/screens/booking_management_screen.dart",
  );
  const webYonetim = oku("../src/app/v/[slug]/randevu-yonetim/page.tsx");

  it("üç sekme iki tarafta aynıdır", () => {
    expect(flutterYonetim).toContain("TabController(length: 3");
    expect(webYonetim).toContain('"bekleyen" | "bugun" | "yaklasan"');
    expect(flutterYonetim).toContain("Bekleyen (");
    expect(webYonetim).toContain("Bekleyen");
    expect(flutterYonetim).toContain("Yaklaşan (");
    expect(webYonetim).toContain("Yaklaşan");
  });

  it("onay/ret ve ertele eylemleri aynı sonucu çağırır", () => {
    expect(flutterYonetim).toContain("action: 'confirm'");
    expect(webYonetim).toContain('action: "confirm"');
    expect(flutterYonetim).toContain("action: 'reject'");
    expect(webYonetim).toContain('action: "reject"');
    expect(flutterYonetim).toContain("rescheduleAction: 'approve'");
    expect(webYonetim).toContain('rescheduleAction: "approve"');
    expect(flutterYonetim).toContain("rescheduleAction: 'reject'");
    expect(webYonetim).toContain('rescheduleAction: "reject"');
    expect(webYonetim).toContain("respond_to_appointment");
  });

  it("durum etiketleri iki tarafta aynıdır", () => {
    const etiketler = [
      "Onaylandı",
      "Reddedildi",
      "Müşteri İptal Etti",
      "İşletme İptal Etti",
      "Süresi Doldu",
      "Onay Bekliyor",
    ];
    for (const etiket of etiketler) {
      expect(flutterYonetim).toContain(etiket);
      expect(webYonetim).toContain(etiket);
    }
  });

  it("boş liste mesajı iki tarafta aynıdır", () => {
    expect(flutterYonetim).toContain("Bekleyen randevu talebi bulunmuyor.");
    expect(webYonetim).toContain("Bekleyen randevu talebi bulunmuyor.");
  });

  it("tarih gösterimi iki tarafta aynı biçimdedir", () => {
    expect(flutterYonetim).toContain("padLeft(2, '0')");
    expect(webYonetim).toContain('padStart(2, "0")');
    expect(flutterYonetim).toContain("·");
    expect(webYonetim).toContain("·");
  });

  it("hata yüzeyi iki tarafta bildirim verir", () => {
    expect(flutterYonetim).toContain("Randevu güncellendi.");
    expect(webYonetim).toContain('role="alert"');
    expect(webYonetim).toContain("Randevular yüklenemedi.");
  });
});
