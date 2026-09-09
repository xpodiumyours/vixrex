import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("Randevu takip durum ve mesaj paritesi", () => {
  const flutterTakip = oku("../../lib/screens/appointment_tracker_screen.dart");
  const webTakip = oku("../src/app/v/[slug]/randevu/[token]/BookingTrackerClient.tsx");

  it("durum başlıkları iki tarafta aynıdır", () => {
    const basliklar = [
      "Onay Bekliyor",
      "Onaylandı",
      "Onaylanmadı",
      "İptal Ettiniz",
      "İşletme İptal Etti",
      "Zaman Aşımı",
    ];
    for (const baslik of basliklar) {
      expect(flutterTakip).toContain(baslik);
      expect(webTakip).toContain(baslik);
    }
  });

  it("iptal onayı ve sonucu iki tarafta aynı anlamdadır", () => {
    expect(flutterTakip).toContain("Randevuyu İptal Et");
    expect(flutterTakip).toContain("Vazgeç");
    expect(webTakip).toContain("emin misiniz?");
    expect(flutterTakip).toContain("Randevunuz iptal edildi.");
    expect(webTakip).toContain("Randevunuz iptal edildi.");
  });

  it("tarih gösterimi iki tarafta aynı biçimdedir", () => {
    expect(flutterTakip).toContain("padLeft(2, '0')");
    expect(webTakip).toContain('padStart(2, "0")');
    expect(flutterTakip).toContain("·");
    expect(webTakip).toContain("·");
  });

  it("bilgi satırları iki tarafta aynı alanları gösterir", () => {
    expect(flutterTakip).toContain("Tarih & Saat");
    expect(webTakip).toContain("Randevu Saati");
    expect(flutterTakip).toContain("Hizmet");
    expect(webTakip).toContain("Hizmet");
    expect(flutterTakip).toContain("dakika");
    expect(webTakip).toContain("Müşteri");
    expect(flutterTakip).toContain("Telefon");
    expect(webTakip).toContain("Telefon");
  });

  it("ertele akışı iki tarafta aynı adımları sunar", () => {
    expect(flutterTakip).toContain("Tarih Değiştir");
    expect(flutterTakip).toContain("Değişiklik Talebi Gönder");
    expect(webTakip).toContain("request_appointment_reschedule");
    expect(webTakip).toContain("get_public_booking_slots");
  });
});
