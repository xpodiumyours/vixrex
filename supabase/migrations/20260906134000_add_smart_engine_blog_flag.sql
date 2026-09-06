-- Katman 4 — Vixrex Asistan Blog domain runtime capability.
--
-- Güvenlik:
--   - ayrı Blog capability storefront flag'inden bağımsızdır,
--   - production rollout OFF başlar,
--   - mevcut global vixrex_smart_engine_enabled ayrıca açık değilse Blog
--     komutları hiçbir istemcide etkin sayılmaz.

insert into public.feature_flags (
  flag_key,
  is_enabled,
  target_users,
  description
)
values (
  'vixrex_smart_engine_blog_enabled',
  false,
  'all',
  'Vixrex Akıllı Motor Blog domain runtime kill-switch'
)
on conflict (flag_key) do update
set
  is_enabled = false,
  target_users = 'all',
  description = excluded.description,
  updated_at = now();
