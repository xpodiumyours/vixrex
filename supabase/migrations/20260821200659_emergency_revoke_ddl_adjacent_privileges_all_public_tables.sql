-- ACİL (2026-08-21, canlıda bulundu): stores'daki sızıntıyı araştırırken
-- aynı deseninin şemadaki NEREDEYSE TÜM tablolarda (18 tablo) olduğu
-- görüldü — anon ve/veya authenticated rolüne TRUNCATE/MAINTAIN/
-- REFERENCES/TRIGGER tablo-seviyesinde açıktı. TRUNCATE RLS'ten muaftır;
-- bu hâliyle herkese açık anon anahtarla audit_logs, appointments,
-- products, profiles, legal_documents, platform_settings dahil neredeyse
-- her tablo boşaltılabilirdi. PostgREST bu 4 yetkiyi standart REST
-- arayüzünden (GET/POST/PATCH/DELETE → SELECT/INSERT/UPDATE/DELETE)
-- hiçbir zaman kullanmaz — kaldırmak hiçbir uygulama işlevini bozmaz.

do $$
declare
  r record;
begin
  for r in
    select c.relname
    from pg_class c
    where c.relnamespace = 'public'::regnamespace
      and c.relkind in ('r', 'p')
  loop
    execute format(
      'revoke truncate, maintain, references, trigger on table public.%I from anon, authenticated;',
      r.relname
    );
  end loop;
end $$;

notify pgrst, 'reload schema';
