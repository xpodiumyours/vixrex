-- Akıllı Motor runtime kill-switch.
--
-- Güvenlik/rollout kuralı:
--   - production deploy ilk olarak OFF,
--   - iki capability de açık olmadan storefront motoru çalışmaz,
--   - mevcut feature_flags RLS/GRANT/get_feature_flags() altyapısı korunur.
--
-- Bu migration yeni tablo/fonksiyon/GRANT oluşturmaz.

insert into public.feature_flags (
  flag_key,
  is_enabled,
  target_users,
  description
)
values
  (
    'vixrex_smart_engine_enabled',
    false,
    'all',
    'Vixrex Akıllı Motor global runtime kill-switch'
  ),
  (
    'vixrex_smart_engine_storefront_enabled',
    false,
    'all',
    'Vixrex Akıllı Motor storefront domain runtime kill-switch'
  )
on conflict (flag_key) do update
set
  is_enabled = false,
  target_users = 'all',
  description = excluded.description,
  updated_at = now();
