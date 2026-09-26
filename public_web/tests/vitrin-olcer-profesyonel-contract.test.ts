import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const migration = readFileSync(
  resolve(__dirname, "../../supabase/migrations/20260926180000_vitrin_olcer_profesyonel.sql"),
  "utf8",
);

describe("Vitrin Ölçer profesyonel sözleşmesi", () => {
  it("ham olay, beğeni ve yorum verisini ayrı tutar", () => {
    expect(migration).toContain("public.vitrin_engagement_events");
    expect(migration).toContain("public.vitrin_product_likes");
    expect(migration).toContain("public.vitrin_product_comments");
  });

  it("ham ziyaretçi anahtarını yeni olaylarda SHA-256 aktör anahtarına çevirir", () => {
    expect(migration).toContain("sha256(v_session::bytea)");
    expect(migration).toContain("v_actor_key text := public.vitrin_actor_key");
  });

  it("ürün görüntülemeyi tekrar yenilemeyle kolayca şişirmez", () => {
    expect(migration).toContain("interval '30 minutes'");
    expect(migration).toContain("v_event_type = 'product_view'");
  });

  it("yorum için kalıcı hesap ister ve e-postayı public yorum alanına koymaz", () => {
    expect(migration).toContain("not public.is_permanent_user()");
    expect(migration).not.toMatch(/author_name[^\n]*email/i);
  });

  it("kötüye kullanım için event ve yorum hız sınırları vardır", () => {
    expect(migration).toContain("interval '1 minute'");
    expect(migration).toContain(">= 120");
    expect(migration).toContain("COMMENT_RATE_LIMIT");
    expect(migration).toContain("DUPLICATE_COMMENT");
  });

  it("sahip özeti auth uid ile kendi vitrinini bulur", () => {
    expect(migration).toContain("create or replace function public.get_vitrin_olcer_summary");
    expect(migration).toContain("s.user_id = v_user_id");
    expect(migration).toContain("'conversion_percent'");
    expect(migration).toContain("'traffic_sources'");
    expect(migration).toContain("'top_products'");
    expect(migration).toContain("'period_start'");
    expect(migration).toContain("'period_end'");
    expect(migration).toContain("count(distinct coalesce(");
  });
});
