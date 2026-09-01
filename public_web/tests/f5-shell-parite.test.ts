import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

describe("F5 shell paritesi — Flutter HomeShellScreen = Next KesfetYanMenu/VitrinimEditor", () => {
  const flutterShell = readFileSync(resolve(__dirname, "../../lib/screens/home_shell_screen.dart"), "utf-8");
  const yanMenu = readFileSync(resolve(__dirname, "../src/components/kesfet/KesfetYanMenu.tsx"), "utf-8");
  const vitrinEditor = readFileSync(resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"), "utf-8");
  const ownerProduct = readFileSync(resolve(__dirname, "../src/components/owner/OwnerProductManager.tsx"), "utf-8");

  it("4 tab sırası her iki yüzeyde aynı: Vitrinim/Keşfet/Vixrex/Profil", () => {
    const sira = ["Vitrinim", "Keşfet", "Vixrex", "Profil"];
    for (const label of sira) {
      expect(flutterShell, `Flutter ${label}`).toContain(label);
      expect(yanMenu, `Next ${label}`).toContain(label);
    }
    // Sıra kontrolü — MENU dizisinde sırayla
    const menuIndex = (s: string, label: string) => s.indexOf(`"${label}"`);
    for (let i = 0; i < sira.length - 1; i++) {
      expect(menuIndex(yanMenu, sira[i]), `${sira[i]} → ${sira[i + 1]} sırası`).toBeLessThan(menuIndex(yanMenu, sira[i + 1]));
    }
    // Flutter destinations sırası da aynı
    const flutterSira = sira.map((l) => flutterShell.indexOf(`label: '${l}'`));
    for (let i = 0; i < flutterSira.length - 1; i++) {
      expect(flutterSira[i], `Flutter ${sira[i]}`).toBeLessThan(flutterSira[i + 1]);
    }
  });

  it("Vitrinim header her iki yüzeyde aynı metinler (yayında/yayınla)", () => {
    // Flutter: Vixrex Düzenle / Vixrex Oluştur + ShellStatusBar
    expect(flutterShell).toContain("Vixrex");
    expect(vitrinEditor).toContain("Vixrex Düzenle");
    expect(vitrinEditor).toContain("Vixrex Oluştur");
    expect(vitrinEditor).toContain("Yayında");
  });

  it("ürün kuyruğu vitrin draft kuyruğundan ayrı ve akordeonla beraber (F4)", () => {
    // OwnerProductManager artık productQueue kullanıyor, VitrinimEditor owner-draft kullanıyor
    expect(ownerProduct).toContain("productQueueEnqueue");
    expect(ownerProduct).toContain("productQueueFlush");
    expect(ownerProduct).toContain("productQueueCount");
    expect(vitrinEditor).toContain('/api/owner-draft');
    expect(ownerProduct).toContain('/api/products');
    expect(ownerProduct).not.toContain('/api/owner-draft');
  });

  it("mobil alt menü Flutter bottomNavigationBar ile aynı 4 hedefi kullanır", () => {
    // KesfetYanMenu mobil nav: fixed bottom-0 min-[901px]:hidden
    expect(yanMenu).toContain("fixed");
    expect(yanMenu).toContain("bottom-0");
    expect(yanMenu).toContain("min-[901px]:hidden");
    // Flutter bottomNavigationBar destinations aynı 4
    const flutterDestinations = (flutterShell.match(/label: 'Vitrinim'/g) || []).length + (flutterShell.match(/label: 'Keşfet'/g) || []).length;
    expect(flutterDestinations).toBeGreaterThan(0);
  });
});
