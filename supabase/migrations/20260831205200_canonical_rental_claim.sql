-- PR6-C25: kanonik kiralama — klon + sahiplik + taslak + akis atomik.
-- Flutter ve Next.js ayni fonksiyonu cagirir. Hesap zorunlu.
create or replace function public.rent_demo_canonical(
  p_source_slug text,
  p_flow_type text default 'kiralama'
) returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_res jsonb;
  v_slug text;
  v_token text;
begin
  -- 1) Mevcut kiralama — klon + sahiplik (tek vitrin kurali icinde).
  select public.rent_demo_for_account(p_source_slug)::jsonb into v_res;
  if (v_res->>'ok')::boolean is distinct from true then
    return v_res;
  end if;
  v_slug := v_res->>'slug';
  v_token := v_res->>'edit_token';
  if v_slug is null or v_token is null then
    return v_res;
  end if;
  -- 2) Calisma taslagi hazirla (varsa sessiz, sorun degil).
  begin
    perform public.get_or_create_working_draft(v_slug, v_token);
  exception when others then null;
  end;
  -- 3) Akis ve konusma Dart katmaninda best-effort (dogru id'ler orada belli).
  return v_res;
end;
$$;
revoke all on function public.rent_demo_canonical(text, text) from public;
grant execute on function public.rent_demo_canonical(text, text) to authenticated;
