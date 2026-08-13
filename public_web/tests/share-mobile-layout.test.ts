import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const viewSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

describe("mobil vitrin paylaşım alanı", () => {
  it("uzun vitrin bağlantısının sosyal paylaşım düğmelerini kart dışına itmesini önler", () => {
    expect(viewSource).toContain(
      'className="grid min-w-0 lg:grid-cols-[auto_1fr] gap-8 items-center"'
    );
    expect(viewSource).toContain('className="space-y-5 min-w-0"');
    expect(viewSource).toContain(
      'className="font-mono text-sm text-slate-300 truncate min-w-0 flex-1"'
    );
    expect(viewSource).toContain(
      'className="grid min-w-0 grid-cols-2 sm:grid-cols-4 gap-3"'
    );
  });
});

describe("vitrin paylaşım alanı — sahip modunda gizlenir", () => {
  // Casper, 2026-08-14 canlı ekran görüntüsü: taslak önizlemedeyken
  // WhatsApp/Instagram/SMS paylaşım düğmeleri düzenleme kancası DEĞİL,
  // gerçek dış linkler — tıklayınca sahip kendi WhatsApp'ına/Instagram'ına
  // atılıyor, düzenleme durmuyor. Taslak zaten yayında değil, paylaşılacak
  // bir şey yok — bölüm sahip modunda hiç gösterilmemeli.
  const shareSectionBlock = viewSource.slice(
    viewSource.indexOf("SHARE & QR SECTION"),
    viewSource.indexOf("KİRALA — yalnız hazır demo vitrinlerde")
  );

  it("paylaşım bölümü {!ownerMode && (...)} ile sarılı", () => {
    expect(shareSectionBlock).toMatch(/\{!ownerMode\s*&&\s*\(/);
  });

  it("paylaşım bölümünün WhatsApp/Instagram/SMS linkleri hâlâ gerçek dış linkler (editableProps değil)", () => {
    expect(shareSectionBlock).toContain("api.whatsapp.com/send");
    expect(shareSectionBlock).not.toContain("editableProps");
  });
});
