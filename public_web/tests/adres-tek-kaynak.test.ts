import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// Ölü alan adı nöbetçisi.
//
// 2026-08-07: vitrin sayfasında üç yerde `https://vixrex.com` elle yazılıydı.
// O alan adı KAYITLI DEĞİL — DNS'te yok. "Vitrin Oluştur" ve "Bu vitrini
// kirala" düğmeleri hiçbir yere gitmiyordu; paylaşım kutusunda da ölü bir
// adres yazıyordu. En sinsisi buydu: "Kopyala" doğru adresi kopyalıyordu,
// ekrandaki yazı yalan söylüyordu. Adresi okuyup elle yazan ya da
// müşterisine sözlü söyleyen esnaf kaybediyordu.
//
// Casper'ın turunda çıktı. Ürünün tek cümlelik vaadi "tek linkte hazır
// vitrin" — link ölüyse geri kalan her şey anlamsız.

// Aranan kalıp düz metin `includes("vixrex.com")` ile yazılmıyor: CodeQL
// bunu "eksik URL doğrulaması" sanıp yüksek öncelikli uyarı üretiyor
// (js/incomplete-url-substring-sanitization) ve PR'ları tıkıyor. Burada
// URL denetlenmiyor, kaynak metinde arama yapılıyor.
const OLU_ADRES = /vixrex\.com/i;

/** Yorumları çıkarır — açıklamada adı geçmesi hata değil, kodda geçmesi hata. */
function kodSatirlari(kaynak: string): string {
  const blokYorumsuz = kaynak.replace(/\/\*[\s\S]*?\*\//g, "");
  return blokYorumsuz
    .split("\n")
    .filter((satir) => !satir.trim().startsWith("//"))
    .join("\n");
}

// 2026-08-28: alan adı GERÇEKTEN ALINDI (vixrex.com, Vercel'den satın
// alındı ve vixrex-public projesine bağlandı; https://vixrex.com 200
// dönüyor). Artık ölü adres değil.
//
// Bu yüzden `siteUrl.ts` listeden ÇIKARILDI: adresin tanımlandığı tek
// yer orası ve orada yazılı olması gerekiyor. Testin asıl niyeti
// değişmedi — adres SAYFALARA dağılmasın, tek kaynaktan gelsin. Diğer üç
// dosyada elle yazılması hâlâ hata.
const KAYNAKLAR = [
  "../src/app/v/[slug]/VitrinProfileView.tsx",
  "../src/app/v/[slug]/OwnerAssistantPanel.tsx",
  "../src/app/(site)/page.tsx",
];

describe("Adresler tek kaynaktan gelir", () => {
  for (const yol of KAYNAKLAR) {
    it(`${yol.split("/").pop()} içinde elle yazılmış vixrex.com yok`, () => {
      const kod = kodSatirlari(readFileSync(resolve(__dirname, yol), "utf-8"));
      expect(
        OLU_ADRES.test(kod),
        "Elle yazılmış vixrex.com bulundu. O alan adı kayıtlı değil; " +
          "adres getSiteUrl() / getAppUrl() üzerinden gelmeli."
      ).toBe(false);
    });
  }

  it("uygulama adresi tek bir yerde tanımlı", () => {
    const siteUrl = readFileSync(
      resolve(__dirname, "../src/lib/siteUrl.ts"),
      "utf-8"
    );
    expect(siteUrl).toContain("export function getAppUrl");

    // Hiçbir sayfa kendi kopyasını tutmamalı — iki kaynak iki gerçek demek.
    // 2026-08-26: kök sayfa (site) route grubuna taşındı ve artık uygulama
    // adresine hiç ihtiyaç duymuyor (yönlendirme kaldırıldı, #344); bu
    // yüzden siteUrl'i içe aktarması ARTIK BEKLENMİYOR. Kilitlenen tek şey,
    // kendi getAppUrl kopyasını tanımlamaması.
    const page = readFileSync(
      resolve(__dirname, "../src/app/(site)/page.tsx"),
      "utf-8"
    );
    expect(page).not.toContain("function getAppUrl");

    // next.config.ts de kendi kopyasını tutuyordu; redirect kaldırılınca
    // o kopya da silindi.
    const nextConfig = readFileSync(
      resolve(__dirname, "../next.config.ts"),
      "utf-8"
    );
    expect(nextConfig).not.toContain("function getAppUrl");
  });

  it("alan adı yalnız siteUrl.ts içinde tanımlı", () => {
    // Adres artık gerçek, ama hâlâ TEK yerde durmalı. İkinci bir kopya
    // doğarsa iki gerçek doğar.
    const siteUrl = readFileSync(
      resolve(__dirname, "../src/lib/siteUrl.ts"),
      "utf-8"
    );
    const kod = kodSatirlari(siteUrl);
    const tanimSayisi = kod.split("const DEFAULT_SITE_URL").length - 1;
    expect(tanimSayisi).toBe(1);
    expect(OLU_ADRES.test(kod)).toBe(true);
  });

  it("paylaşım kutusu kopyalananla aynı adresi gösterir", () => {
    const view = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
      "utf-8"
    );
    expect(view).toContain("{formattedUrlDisplay}");
  });
});
