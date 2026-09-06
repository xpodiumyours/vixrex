import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

describe("F5 shell paritesi — Flutter HomeShellScreen = Next ortak AppShell", () => {
  const flutterShell = readFileSync(resolve(__dirname, "../../lib/screens/home_shell_screen.dart"), "utf-8");
  const flutterProfile = readFileSync(resolve(__dirname, "../../lib/screens/profile_screen.dart"), "utf-8");
  const appNav = readFileSync(resolve(__dirname, "../src/components/app/AppSidebar.tsx"), "utf-8");
  const appBoundary = readFileSync(resolve(__dirname, "../src/components/app/AppShellBoundary.tsx"), "utf-8");
  const kesfet = readFileSync(resolve(__dirname, "../src/components/kesfet/KesfetIcerik.tsx"), "utf-8");
  const vixrexPage = readFileSync(resolve(__dirname, "../src/app/app/vixrex/page.tsx"), "utf-8");
  const profilePage = readFileSync(resolve(__dirname, "../src/app/app/profil/page.tsx"), "utf-8");
  const vitrinEditor = readFileSync(resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"), "utf-8");
  const ownerProduct = readFileSync(resolve(__dirname, "../src/components/owner/OwnerProductManager.tsx"), "utf-8");

  it("4 tab sırası her iki yüzeyde aynı: Vitrinim/Keşfet/Vixrex/Profil", () => {
    const sira = ["Vitrinim", "Keşfet", "Vixrex", "Profil"];
    for (const label of sira) {
      expect(flutterShell, `Flutter ${label}`).toContain(label);
      expect(appNav, `Next ${label}`).toContain(label);
    }

    const menuIndex = (s: string, label: string) => s.indexOf(`label: "${label}"`);
    for (let i = 0; i < sira.length - 1; i++) {
      expect(menuIndex(appNav, sira[i]), `${sira[i]} → ${sira[i + 1]} sırası`).toBeLessThan(
        menuIndex(appNav, sira[i + 1]),
      );
    }

    const flutterSira = sira.map((l) => flutterShell.indexOf(`label: '${l}'`));
    for (let i = 0; i < flutterSira.length - 1; i++) {
      expect(flutterSira[i], `Flutter ${sira[i]}`).toBeLessThan(flutterSira[i + 1]);
    }
  });

  it("Vixrex üçüncü gerçek sekmedir; modal veya Keşfet iç görünümü değildir", () => {
    expect(appNav).toContain('href: "/app/vixrex"');
    expect(appNav).not.toContain("AsistanPaneli");
    expect(appNav).not.toContain("SharedVixrexAssistant");
    expect(vixrexPage).toContain("SharedVixrexAssistant");
    expect(kesfet).not.toContain("SharedVixrexAssistant");
    expect(kesfet).not.toContain("KesfetYanMenu");
    expect(kesfet).toContain('router.push("/app/vixrex")');
  });

  it("yalnız dört ana yüz shell içinde; Profil alt ekranları push ekranıdır", () => {
    expect(appBoundary).toContain('pathname === "/app"');
    expect(appBoundary).toContain('pathname === "/app/vixrex"');
    expect(appBoundary).toContain('pathname === "/app/profil"');
    expect(appBoundary).toContain('pathname === "/kesfet"');
    expect(appBoundary).toContain("<AppSidebar />");
    expect(appBoundary).toContain("<AppBottomNav />");
    expect(appBoundary).not.toContain('pathname.startsWith("/app/")');
    expect(appBoundary).not.toContain('"/app/ayarlar"');
    expect(appBoundary).not.toContain('"/app/hesap"');
  });

  it("Flutter masaüstü eşiği ve sidebar genişliği korunur", () => {
    expect(appNav).toContain("w-[220px]");
    expect(appNav).toContain("min-[901px]:flex");
    expect(appNav).toContain("min-[901px]:hidden");
    expect(flutterShell).toContain("size.width > 900");
  });

  it("Profil yalnız Flutter referansındaki ana yüzeyi taşır", () => {
    const ortakMetinler = [
      "Profil",
      "Hesap",
      "Vitrin Bağlantısı",
      "Hızlı QR Kod Paylaşımı",
      "Uygulama Ayarları",
      "Kullanım Bilgisi & Destek",
      "Gizlilik ve Güvenlik politikası",
    ];
    for (const metin of ortakMetinler) {
      expect(flutterProfile).toContain(metin);
      expect(profilePage).toContain(metin);
    }
    expect(profilePage).not.toContain("Şifre Değiştir");
    expect(profilePage).not.toContain("Tehlikeli Bölge");
    expect(profilePage).not.toContain("Çıkış Yap");
    expect(profilePage).not.toContain("← Geri");
  });

  it("Vitrinim header her iki yüzeyde aynı metinler (yayında/yayınla)", () => {
    expect(flutterShell).toContain("Vixrex");
    expect(vitrinEditor).toContain("Vixrex Düzenle");
    expect(vitrinEditor).toContain("Vixrex Oluştur");
    expect(vitrinEditor).toContain("Yayında");
  });

  it("ürün kuyruğu vitrin draft kuyruğundan ayrı ve akordeonla beraber (F4)", () => {
    expect(ownerProduct).toContain("productQueueEnqueue");
    expect(ownerProduct).toContain("productQueueFlush");
    expect(ownerProduct).toContain("productQueueCount");
    expect(vitrinEditor).toContain('/api/owner-draft');
    expect(ownerProduct).toContain('/api/products');
    expect(ownerProduct).not.toContain('/api/owner-draft');
  });
});
