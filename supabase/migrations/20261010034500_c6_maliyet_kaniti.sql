-- C6 isolated 17-product Luna test: provider reported USD vs budget reserve.
-- Historical entries remain legacy-unverified, never presented as verified charges.
alter table public.invoice_read_usage
  add column if not exists provider_cost_usd numeric,
  add column if not exists budget_reserve_usd numeric not null default 0,
  add column if not exists cost_basis text not null default 'legacy-unverified';
alter table public.invoice_read_usage
  add constraint invoice_usage_provider_cost_positive
  check (provider_cost_usd is null or provider_cost_usd >= 0);
alter table public.invoice_read_usage
  add constraint invoice_usage_budget_reserve_positive check (budget_reserve_usd >= 0);
alter table public.invoice_read_usage
  add constraint invoice_usage_cost_basis_valid
  check (cost_basis in ('legacy-unverified','reported','estimated'));
comment on column public.invoice_read_usage.cost_usd is
  'Budget ledger only. Includes estimates/reservations and is not actual provider charges.';
comment on column public.invoice_read_usage.provider_cost_usd is
  'Only provider-reported OpenRouter usage.cost; null if unavailable.';
comment on column public.invoice_read_usage.budget_reserve_usd is
  'Search budget cushion, not a claim about charges.';
