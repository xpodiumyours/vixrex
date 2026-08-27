import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import katalog from "../../shared/vixrex_mesajlar.json";

const editorPath = resolve(
  __dirname,
  "../src/app/v/[slug]/blog-yonetim/[articleSlug]/page.tsx"
);
const blogManagement = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/blog-yonetim/page.tsx"),
  "utf8"
);
const flutterEditor = readFileSync(
  resolve(__dirname, "../../lib/screens/blog_editor_screen.dart"),
  "utf8"
);
const mesajlar = Object.fromEntries(
  katalog.mesajlar.map((mesaj) => [mesaj.anahtar, mesaj.metin])
);

describe("web blog editörü kullanıcı sözleşmesi", () => {
  it("sahip kabuğunda uygulamadaki blog alanlarını sunar", () => {
    expect(existsSync(editorPath), "blog editör sayfası yok").toBe(true);
    const source = readFileSync(editorPath, "utf8");

    expect(source).toContain("owner-shell");
    for (const label of [
      "Yazı Başlığı *",
      "Yazı Özeti (Meta Açıklaması) *",
      "Makale Metni (İçerik) *",
      "Kapak Görseli",
      "Yazı Türü",
      "Hedef Anahtar Kelime / Konu",
      "Hedef Şehir (Yerel SEO)",
      "SEO Puanı",
      "Taslak Kaydet",
      "Yayınla",
    ]) {
      expect(source, `${label} editörde yok`).toContain(label);
    }
    expect(source.match(/#[0-9A-Fa-f]{6}/g) ?? []).toEqual([]);
  });

  it("mevcut sahip API'lerini ve ortak yayın mesajını kullanır", () => {
    expect(existsSync(editorPath), "blog editör sayfası yok").toBe(true);
    const source = readFileSync(editorPath, "utf8");

    expect(source).toContain('method: "PATCH"');
    expect(source).toContain('fetch("/api/articles"');
    expect(source).toContain('fetch("/api/owner-upload"');
    expect(source).toContain('form.append("anahtar", "kapakGorseli")');
    expect(source).toContain("sahipOturumuAc");
    expect(source).toContain("disabled={kaydediyor || yukluyor}");
    expect(source).toContain('vixRexMesajlari["blog_yayinlandi"]');
  });

  it("mevcut yazı kartı sahibini düzenleme adresine götürür", () => {
    expect(blogManagement).toContain(
      "href={`/v/${slug}/blog-yonetim/${yazi.slug}`}"
    );
    expect(blogManagement).toContain("Düzenle");
  });

  it("yeni yazı oluşturulunca boş taslağın editörünü açar", () => {
    expect(blogManagement).toContain(
      "router.push(`/v/${slug}/blog-yonetim/${sonuc.slug}`)"
    );
  });

  it("iki yüzey aynı dürüst yayın mesajını kullanır", () => {
    expect(mesajlar.blog_yayinlandi).toBe("Yazı yayınlandı.");
    expect(flutterEditor).toContain("vixRexMesajlari['blog_yayinlandi']");
    expect(flutterEditor).not.toContain("Güvenilir yazar değilseniz");
    expect(flutterEditor).not.toContain("moderatör incelemesine");
  });
});
