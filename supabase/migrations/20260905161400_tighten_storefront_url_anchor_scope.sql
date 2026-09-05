-- Vixrex Akıllı Motor 5.9 — URL anchor kapsamını daralt.
-- Normal URL alanları yalnız http/https kabul eder. #anchor yalnız
-- galeriAksiyonLinki action-link alanında geçerlidir.

create or replace function public.vixrex_validate_storefront_value(
  p_contract jsonb,
  p_value jsonb
)
returns boolean
language plpgsql
immutable
set search_path = pg_catalog, public
as $$
declare
  v_type text := p_contract ->> 'type';
  v_required boolean := coalesce((p_contract ->> 'required')::boolean, false);
  v_validation text := p_contract ->> 'validation';
  v_field_key text := p_contract ->> 'fieldKey';
  v_text text;
  v_len int;
  v_min_len int;
  v_max_len int;
  v_num numeric;
  v_min numeric;
  v_max numeric;
begin
  if p_contract is null then return false; end if;

  if p_value is null or jsonb_typeof(p_value) = 'null' then
    return not v_required;
  end if;

  if v_type = 'acikKapali' then
    return jsonb_typeof(p_value) = 'boolean';
  end if;

  if v_type = 'sayi' then
    if jsonb_typeof(p_value) <> 'number' then return false; end if;
    v_num := (p_value #>> '{}')::numeric;
    v_min := nullif(p_contract ->> 'min', '')::numeric;
    v_max := nullif(p_contract ->> 'max', '')::numeric;
    if v_min is not null and v_num < v_min then return false; end if;
    if v_max is not null and v_num > v_max then return false; end if;
    return true;
  end if;

  if jsonb_typeof(p_value) <> 'string' then return false; end if;
  v_text := pg_catalog.btrim(p_value #>> '{}');
  v_len := char_length(v_text);
  v_min_len := nullif(p_contract ->> 'minLength', '')::int;
  v_max_len := nullif(p_contract ->> 'maxLength', '')::int;

  if v_len = 0 then return false; end if;
  if v_min_len is not null and v_len < v_min_len then return false; end if;
  if v_max_len is not null and v_len > v_max_len then return false; end if;

  if v_validation = 'adres' then
    if v_len < 10 then return false; end if;
    if v_text !~ '[0-9]'
       and lower(v_text) !~ '(cad|sok|mah|bulv|blv|apt|blok|sit|plaza|çarşı|carsi|pasaj|sanayi|osb|küme|kume)' then
      return false;
    end if;
  end if;

  if v_type = 'telefon' then
    if v_validation = 'tr_mobil' then
      return v_text ~ '^905[0-9]{9}$';
    end if;
    return v_text ~ '^[0-9]{10,13}$';
  elsif v_type = 'eposta' then
    return v_text ~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]{2,}$';
  elsif v_type = 'url' then
    return v_text ~ '^https?://.+'
       or (v_field_key = 'galeriAksiyonLinki' and v_text ~ '^#.+$');
  elsif v_type = 'gorsel' then
    return v_text ~ '^https?://.+';
  elsif v_type = 'secim' then
    return jsonb_typeof(p_contract -> 'options') = 'array'
       and (p_contract -> 'options') @> jsonb_build_array(v_text);
  elsif v_type in ('metin', 'uzunMetin') then
    return true;
  end if;

  return false;
end;
$$;
