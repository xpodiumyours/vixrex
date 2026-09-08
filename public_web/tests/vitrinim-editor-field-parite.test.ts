import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("Vitrinim standart EditorTextField paritesi", () => {
  const flutterField = oku("../../lib/widgets/editor/common_form_fields.dart");
  const flutterKimlik = oku("../../lib/widgets/editor/sections/kimlik_bolumu.dart");
  const flutterIletisim = oku("../../lib/widgets/editor/sections/iletisim_bolumu.dart");
  const flutterKonum = oku("../../lib/widgets/editor/sections/konum_saatler_bolumu.dart");
  const flutterAdvancedLocation = oku("../../lib/widgets/editor/advanced_location_fields.dart");
  const flutterMedia = oku("../../lib/widgets/editor/form_media_picker.dart");
  const flutterGallery = oku("../../lib/widgets/editor/gallery_editor_section.dart");
  const flutterSeo = oku("../../lib/widgets/editor/sections/icerik_seo_bolumu.dart");
  const appCss = oku("../src/app/vixrex-app-ui.css");
  const webEditor = oku("../src/components/owner/VitrinimEditor.tsx");

  it("Flutter EditorTextField temel görsel değerlerini kaybetmez", () => {
    expect(flutterField).toContain("fillColor: AppColors.inputBg");
    expect(flutterField).toContain("BorderRadius.circular(AppColors.radius14)");
    expect(flutterField).toContain("fontSize: 14");
    expect(flutterField).toContain("fontWeight: FontWeight.w700");
    expect(flutterField).toContain("horizontal: 14");
    expect(flutterField).toContain("vertical: 14");
    expect(flutterField).toContain("width: 1.4");
    expect(flutterField).toContain("size: 18");
    expect(appCss).toContain("--vx-app-input-bg: #0D1C38");
    expect(appCss).toContain("--vx-app-radius-editor-field: 14px");
    expect(appCss).toContain("--vx-app-prefix-icon-width: 48px");
    expect(appCss).toContain("--vx-app-prefix-icon-size: 18px");
    expect(appCss).toContain("padding-left: var(--vx-app-prefix-icon-width)");
  });

  it("Google Material Symbols yalnız kullanılan alan ikonlarıyla alt kümelenir", () => {
    expect(appCss).toContain("Material+Symbols+Outlined:FILL,ROND@0..1,100");
    expect(appCss).toContain("icon_names=article,camera_alt,category,chat_bubble,email,inventory_2,label,link,map,notes,phone,place,rate_review,schedule,sell,smart_button,storefront,title");
    expect(appCss).toContain("display=block");
    expect(appCss).toContain('font-family: "Material Symbols Outlined"');
    expect(appCss).toContain('font-variation-settings: "FILL" 0, "ROND" 100');
    expect(appCss).toContain('font-variation-settings: "FILL" 1, "ROND" 100');
  });

  it("yalnız Flutter'da EditorTextField olduğu doğrulanan ana alanlar hedeflenir", () => {
    const mappings = [
      ["isletmeAdi", flutterKimlik, "İşletme / Vixrex Adı", "Örn: Aymira Butik", "Icons.storefront_rounded", "storefront"],
      ["isletmeTuru", flutterKimlik, "İşletme Türü", "Örn: Kadın giyim / butik", "Icons.storefront_outlined", "storefront"],
      ["kisaTanitim", flutterKimlik, "Kısa Açıklama", "Bugün vitrinde ne var? Kısa bir tanıtım yaz.", "Icons.notes_rounded", "notes"],
      ["heroRozet", flutterKimlik, "Kapak Rozeti", "Örn: Atölye / Mağaza", "Icons.sell_outlined", "sell"],
      ["whatsapp", flutterIletisim, "WhatsApp Numarası", "05xx xxx xx xx", "Icons.chat_bubble_rounded", "chat_bubble"],
      ["telefon", flutterIletisim, "Telefon", "05xx xxx xx xx (isteğe bağlı)", "Icons.phone_rounded", "phone"],
      ["eposta", flutterIletisim, "E-posta", "ornek@isletme.com", "Icons.email_outlined", "email"],
      ["instagram", flutterIletisim, "Instagram", "@kullanici_adi veya profil linki", "Icons.camera_alt_rounded", "camera_alt"],
      ["konumMetni", flutterAdvancedLocation, "Hero Konum Metni", "Örn: Kadıköy, İstanbul", "Icons.place_outlined", "place"],
      ["haritaEtiketi", flutterAdvancedLocation, "Harita Kartı Etiketi", "Örn: Atatürk Cad. No:24", "Icons.map_outlined", "map"],
      ["calismaSaatleri", flutterKonum, "Çalışma Saatleri", "Örn: Pzt — Cmt 09:00 - 20:00", "Icons.schedule_rounded", "schedule"],
      ["galeriUstBaslik", flutterMedia, "Galeri üst etiketi", "Örn: Mağazadan kareler", "Icons.label_outline_rounded", "label"],
      ["galeriBaslik", flutterMedia, "Galeri başlığı", "Örn: Atmosferi yakından tanı", "Icons.title_rounded", "title"],
      ["galeriAksiyonMetni", flutterGallery, "Galeri Buton Metni", "Örn: Kataloğu Gör", "Icons.smart_button_outlined", "smart_button"],
      ["galeriAksiyonLinki", flutterGallery, "Galeri Buton Bağlantısı", "https://... veya #sayfa-icı", "Icons.link_rounded", "link"],
      ["referansLinki", flutterSeo, "Referanslar Bağlantısı", "https://...", "Icons.link_rounded", "link"],
      ["kategoriBolumBaslik", flutterSeo, "Kategori Bölümü Başlığı", "Örn: Servis Alanlarımız", "Icons.category_outlined", "category"],
      ["urunBolumBaslik", flutterSeo, "Ürün Bölümü Başlığı", "Örn: Servis Fiyat Listesi", "Icons.inventory_2_outlined", "inventory_2"],
      ["blogUstBaslik", flutterSeo, "Blog Üst Başlık", "Örn: Teknik rehber", "Icons.label_outline_rounded", "label"],
      ["blogBaslik", flutterSeo, "Blog Bölüm Başlığı", "Örn: Mağazadan Haberler", "Icons.article_outlined", "article"],
      ["haritaLinki", flutterSeo, "Google Yorum Bağlantısı", "https://search.google.com/local/writereview?placeid=...", "Icons.rate_review_rounded", "rate_review"],
    ] as const;

    for (const [key, flutterSource, flutterLabel, flutterHint, flutterIcon, webIcon] of mappings) {
      expect(flutterSource).toContain(`label: '${flutterLabel}'`);
      expect(flutterSource).toContain(`hint: '${flutterHint}'`);
      expect(flutterSource).toContain(`icon: ${flutterIcon}`);
      expect(webEditor).toContain(`key: "${key}"`);
      expect(webEditor).toContain(`label: "${flutterLabel}"`);
      expect(webEditor).toContain(`placeholder: "${flutterHint}"`);
      expect(webEditor).toContain(`icon: "${webIcon}"`);
      expect(appCss).toContain(`#vitrin-${key}`);
    }
  });

  it("zorunlu alan yıldızı Flutter primary/w900 sözleşmesini izler", () => {
    expect(flutterField).toContain("if (requiredField)");
    expect(flutterField).toContain("color: AppColors.primary");
    expect(flutterField).toContain("fontWeight: FontWeight.w900");
    expect(webEditor).toContain("vixrex-required-mark");
    expect(appCss).toContain(".vixrex-required-mark");
    expect(appCss).toContain("font-weight: 900");
  });

  it("il/ilçe/adres ve özel medya alanları standart EditorTextField grubuna yanlışlıkla alınmaz", () => {
    expect(appCss).not.toContain("#vitrin-il,");
    expect(appCss).not.toContain("#vitrin-ilce,");
    expect(appCss).not.toContain("#vitrin-adres,");
    expect(appCss).not.toContain("#vitrin-kategori,");
    expect(appCss).not.toContain("#vitrin-kapakGorseli,");
    expect(appCss).not.toContain("#vitrin-logo,");
  });
});
