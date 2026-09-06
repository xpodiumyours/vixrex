import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

describe("Flutter Web ↔ Next.js tek-shell paritesi", () => {
  const flutterShell = readFileSync(resolve(__dirname, "../../lib/screens/home_shell_screen.dart"), "utf-8");
  const flutterTheme = readFileSync(resolve(__dirname, "../../lib/theme/app_theme.dart"), "utf-8");
  const flutterProfile = readFileSync(resolve(__dirname, "../../lib/screens/profile_screen.dart"), "utf-8");
  const appContext = readFileSync(resolve(__dirname, "../src/components/app/AppShellContext.tsx"), "utf-8");
  const appNav = readFileSync(resolve(__dirname, "../src/components/app/AppSidebar.tsx"), "utf-8");
  const appBoundary = readFileSync(resolve(__dirname, "../src/components/app/AppShellBoundary.tsx"), "utf-8");
  const statusBar = readFileSync(resolve(__dirname, "../src/components/kesfet/StatusBar.tsx"), "utf-8");
  const kesfet = readFileSync(resolve(__dirname, "../src/components/kesfet/KesfetIcerik.tsx"), "utf-8");
  const vixrexPage = readFileSync(resolve(__dirname, "../src/app/app/vixrex/page.tsx"), "utf-8");
  const profilePage = readFileSync(resolve(__dirname, "../src/app/app/profil/page.tsx"), "utf-8");
  const vitrinEditor = readFileSync(resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"), "utf-8");
  const ownerProduct = readFileSync(resolve(__dirname, "../src/components/owner/OwnerProductManager.tsx"), "utf-8");

  it("dört ana sekme aynı sırada ve Vixrex gerçek üçüncü rotadır", () => {
    const sira = ["Vitrinim", "Keşfet", "Vixrex", "Profil"];
    for (const label of sira) {
      expect(flutterShell).toContain(label);
      expect(appNav).toContain(label);
    }
    const nextIndexes = sira.map((label) => appNav.indexOf(`label: "${label}"`));
    const flutterIndexes = sira.map((label) => flutterShell.indexOf(`label: '${label}'`));
    for (let i = 0; i < sira.length - 1; i++) {
      expect(nextIndexes[i]).toBeLessThan(nextIndexes[i + 1]);
      expect(flutterIndexes[i]).toBeLessThan(flutterIndexes[i + 1]);
    }
    expect(appNav).toContain('href: "/app/vixrex"');
    expect(vixrexPage).toContain("SharedVixrexAssistant");
    expect(appNav).not.toContain("AsistanPaneli");
    expect(kesfet).not.toContain("SharedVixrexAssistant");
  });

  it("tek shell tek status bar taşır; sayfalar ikinci kopya üretmez", () => {
    expect(appBoundary).toContain("<AppShellProvider>");
    expect(appBoundary).toContain("<AppSidebar />");
    expect(appBoundary).toContain("<StatusBar />");
    expect(appBoundary).toContain("<AppBottomNav />");
    expect(kesfet).not.toContain("<StatusBar");
    expect(vitrinEditor).not.toContain("sticky top-0 z-20");
    expect(statusBar).toContain("Vitrininiz henüz yayınlanmadı");
    expect(statusBar).toContain("Vitrini yayınla");
    expect(statusBar).toContain("Kopyala");
    expect(statusBar).toContain("QR");
    expect(statusBar).toContain("Vitrini aç");
  });

  it("sidebar ve Keşfet aynı arama state'ini kullanır", () => {
    expect(appContext).toContain("globalSearch");
    expect(appContext).toContain("setGlobalSearch");
    expect(appNav).toContain("useAppShell");
    expect(kesfet).toContain("useAppShellSearch");
    expect(kesfet).not.toContain('useState("")');
  });

  it("masaüstü 220px/>900 ve mobil NavigationBar 68px sözleşmesini korur", () => {
    expect(appNav).toContain("w-[220px]");
    expect(appNav).toContain("min-[901px]:flex");
    expect(appNav).toContain("min-[901px]:hidden");
    expect(appNav).toContain("h-[68px]");
    expect(flutterShell).toContain("size.width > 900");
    expect(flutterTheme).toContain("height: 68");
  });

  it("yalnız ana yüzler shell'dedir; Profil alt ekranları push ekranıdır", () => {
    expect(appBoundary).toContain('pathname === "/app"');
    expect(appBoundary).toContain('pathname === "/app/vixrex"');
    expect(appBoundary).toContain('pathname === "/app/profil"');
    expect(appBoundary).toContain('pathname === "/kesfet"');
    expect(appBoundary).not.toContain('pathname.startsWith("/app/")');
    expect(appBoundary).not.toContain('"/app/ayarlar"');
    expect(appBoundary).not.toContain('"/app/hesap"');
  });

  it("Profil Flutter ana yüzüyle aynı ana öğeleri taşır, Next'e özgü hesap blokları taşımaz", () => {
    const ortak = [
      "Profil",
      "Vitrin Bağlantısı",
      "Hızlı QR Kod Paylaşımı",
      "Uygulama Ayarları",
      "Kullanım Bilgisi & Destek",
      "Gizlilik ve Güvenlik politikası",
    ];
    for (const metin of ortak) {
      expect(flutterProfile).toContain(metin);
      expect(profilePage).toContain(metin);
    }
    expect(profilePage).not.toContain("Şifre Değiştir");
    expect(profilePage).not.toContain("Tehlikeli Bölge");
    expect(profilePage).not.toContain("Çıkış Yap");
    expect(profilePage).not.toContain("← Geri");
  });

  it("Keşfet kategori başlangıcını filtre olarak tutar; Vixrex yalnız açık istekle açılır", () => {
    expect(kesfet).toContain("ilkKategoriKimligi");
    expect(kesfet).toContain('params.get("vixrex") === "1"');
    expect(kesfet).not.toContain("ilkKategoriKimligi\n      ) {\n        router");
  });

  it("Vitrinim ortak shell'e aittir; Vixrex ile rozeti navigasyon değildir ve paylaşım kartı ortaktır", () => {
    expect(vitrinEditor).toContain("Vixrex Düzenle");
    expect(vitrinEditor).toContain("Vixrex Oluştur");
    expect(vitrinEditor).toContain("Vixrex ile");
    expect(vitrinEditor).toContain("VitrinPaylasimKarti");
    expect(vitrinEditor).toContain("refreshShellStatus");
    expect(vitrinEditor).not.toContain('router.push("/kesfet?vixrex=1")');
  });

  it("ürün kuyruğu vitrin taslak kuyruğundan ayrı kalır", () => {
    expect(ownerProduct).toContain("productQueueEnqueue");
    expect(ownerProduct).toContain("productQueueFlush");
    expect(ownerProduct).toContain("productQueueCount");
    expect(vitrinEditor).toContain('/api/owner-draft');
    expect(ownerProduct).toContain('/api/products');
    expect(ownerProduct).not.toContain('/api/owner-draft');
  });
});
