import { readdirSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { describe, expect, it } from "vitest";

const repo = resolve(__dirname, "../..");
const oku = (yol: string) => readFileSync(resolve(repo, yol), "utf8");

/**
 * Migration DOSYA ADINA sabitlenmez.
 *
 * Migration canlıya uygulanınca Supabase kendi zaman damgasını üretiyor ve
 * dosya adı ona çekiliyor (yerel/uzak `migration list` farkı olmasın diye).
 * Bu test ilk hâlinde adı sabit yazıyordu; damga değişince main kırıldı
 * (28 Ağustos). Artık dizinden desenle bulunuyor.
 */
function migrationOku(sonEk: string): string {
  const dizin = resolve(repo, "supabase/migrations");
  const dosya = readdirSync(dizin)
    .filter((ad) => ad.endsWith(sonEk))
    .sort()
    .at(-1);
  if (!dosya) {
    throw new Error(`Migration bulunamadı: *${sonEk}`);
  }
  return readFileSync(join(dizin, dosya), "utf8");
}

const migration = migrationOku("_notification_inbox.sql");
const flutterService = oku("lib/services/notification_inbox_service.dart");
const webPage = oku("public_web/src/app/app/bildirimler/page.tsx");
const badge = oku("public_web/src/components/owner/OwnerNotificationLink.tsx");

describe("Flutter ve web ortak bildirim kutusu", () => {
  it("tablo RLS ile kullanıcı satırına kilitli", () => {
    expect(migration).toContain("enable row level security");
    expect(migration).toContain("(select auth.uid()) = user_id");
    expect(migration).toContain("grant update (read_at)");
    expect(migration).not.toContain("to anon");
  });

  it("iki yüzey de notification_inbox kaynağını kullanıyor", () => {
    expect(flutterService).toContain(".from('notification_inbox')");
    expect(webPage).toContain('.from("notification_inbox")');
    expect(badge).toContain('.from("notification_inbox")');
  });

  it("okundu işlemi iki yüzeyde de read_at alanını güncelliyor", () => {
    expect(flutterService).toContain(".update({'read_at':");
    expect(webPage).toContain(".update({ read_at:");
    expect(webPage).toContain("Tümünü okundu yap");
  });
});
