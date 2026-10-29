-- Barkodsuz fatura satırı, vitrindeki bir kartla "aynı ürün olabilir" görünüyorsa
-- kart sessizce ikinci kez açılmaz; satır bu iki kolonla esnafın kararına bırakılır.
--
-- merge_candidate_product_id : şüpheli eşleşmenin gösterildiği mevcut kart
-- merge_decision             : esnafın cevabı ('birlestir' | 'ayri')
--
-- Karar yoksa hiçbir kart yazılmaz; karar 'ayri' ise kart normal yoldan açılır.
-- 'birlestir' ise satır var olan karta bağlanır, stok toplanır.
-- İki dolu ve farklı barkod hiçbir koşulda birleşmez (kural faturaUrunBaglantisi.ts).

alter table public.invoice_job_lines
  add column if not exists merge_candidate_product_id uuid
    references public.products(id) on delete set null,
  add column if not exists merge_decision text;

alter table public.invoice_job_lines
  drop constraint if exists invoice_job_lines_merge_decision_check;

alter table public.invoice_job_lines
  add constraint invoice_job_lines_merge_decision_check
  check (merge_decision is null or merge_decision in ('birlestir', 'ayri'));

comment on column public.invoice_job_lines.merge_candidate_product_id is
  'Barkodsuz fatura satırının "aynı ürün olabilir" diye gösterdiği mevcut kart. Onay yoksa kart açılmaz.';
comment on column public.invoice_job_lines.merge_decision is
  'Esnafın kararı: birlestir = var olan karta bağla, ayri = yeni kart aç. Boşsa karar bekleniyor.';

create index if not exists invoice_job_lines_merge_candidate_idx
  on public.invoice_job_lines (merge_candidate_product_id);
