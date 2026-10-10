-- C6: per-document invoice cost trace. No historical guesswork.
alter table public.invoice_read_usage
  add column if not exists document_fingerprint text;
alter table public.invoice_read_usage
  add constraint invoice_usage_document_fingerprint_format
  check (document_fingerprint is null or document_fingerprint ~ '^[a-f0-9]{64}$');
create index if not exists invoice_usage_store_document_idx
  on public.invoice_read_usage (store_id, document_fingerprint)
  where document_fingerprint is not null;
comment on column public.invoice_read_usage.document_fingerprint is
  'SHA-256 of uploaded document bytes, not the supplier invoice number. Nullable for historical records.';
