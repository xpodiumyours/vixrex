create table if not exists public.supplier_permission_requests (
  id uuid primary key default gen_random_uuid(),
  token text unique not null,
  store_id uuid not null references public.stores(id) on delete cascade,
  supplier_name text not null,
  brand text not null,
  line_ids jsonb not null default '[]'::jsonb,
  product_ids jsonb not null default '[]'::jsonb,
  status text not null default 'bekliyor'
    check (status in ('bekliyor', 'onaylandi', 'reddedildi')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days'
);

alter table public.supplier_permission_requests
  add column if not exists token text,
  add column if not exists brand text not null default '',
  add column if not exists line_ids jsonb not null default '[]'::jsonb,
  add column if not exists product_ids jsonb not null default '[]'::jsonb,
  add column if not exists expires_at timestamptz not null default now() + interval '30 days';

create unique index if not exists supplier_permission_requests_token_uq
  on public.supplier_permission_requests (token)
  where token is not null;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'supplier_permission_requests'
      and column_name = 'supplier_key'
  ) then
    execute 'alter table public.supplier_permission_requests alter column supplier_key set default ''''';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'supplier_permission_requests'
      and column_name = 'requested_by'
  ) then
    execute 'alter table public.supplier_permission_requests alter column requested_by set default ''owner''';
  end if;
end $$;

alter table public.supplier_permission_requests
  drop constraint if exists supplier_permission_requests_status_check;

alter table public.supplier_permission_requests
  add constraint supplier_permission_requests_status_check
  check (
    status in (
      'bekliyor',
      'onaylandi',
      'reddedildi',
      'hazirlandi',
      'gonderim_bekliyor',
      'gonderildi',
      'cevaplandi',
      'geri_cekildi'
    )
  );

alter table public.supplier_permission_requests enable row level security;

revoke all on public.supplier_permission_requests from anon, authenticated, public;

create or replace function public.create_supplier_permission_request(
  p_store_id uuid,
  p_edit_token text,
  p_supplier_name text,
  p_brand text,
  p_line_ids jsonb,
  p_product_ids jsonb
)
returns text
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_edit_token text := pg_catalog.btrim(coalesce(p_edit_token, ''));
  v_is_demo boolean;
  v_brand text := pg_catalog.btrim(coalesce(p_brand, ''));
  v_supplier_name text := pg_catalog.btrim(coalesce(p_supplier_name, ''));
  v_line_ids jsonb := '[]'::jsonb;
  v_product_ids jsonb := '[]'::jsonb;
  v_token text;
begin
  if p_store_id is null or pg_catalog.length(v_edit_token) < 24 then
    raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode = 'P0001';
  end if;

  select s.is_demo
    into v_is_demo
  from public.stores s
  where s.id = p_store_id
    and s.edit_token = v_edit_token
    and (s.edit_token_expires_at is null or s.edit_token_expires_at > pg_catalog.now());

  if not found then
    raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode = 'P0001';
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode = 'P0001';
  end if;

  if v_brand = '' then
    raise exception 'INVALID_BRAND' using errcode = 'P0001';
  end if;

  if v_supplier_name = '' then
    v_supplier_name := v_brand;
  end if;

  if jsonb_typeof(p_line_ids) = 'array' then
    select coalesce(jsonb_agg(distinct l.id::text), '[]'::jsonb)
      into v_line_ids
    from public.invoice_job_lines l
    join public.invoice_jobs j on j.id = l.job_id
    where j.store_id = p_store_id
      and p_line_ids ? l.id::text;
  end if;

  if jsonb_typeof(p_product_ids) = 'array' then
    select coalesce(jsonb_agg(distinct p.id::text), '[]'::jsonb)
      into v_product_ids
    from public.products p
    where p.store_id = p_store_id
      and p.is_active = true
      and p_product_ids ? p.id::text;
  end if;

  if jsonb_array_length(v_line_ids) = 0 and jsonb_array_length(v_product_ids) = 0 then
    raise exception 'EMPTY_PERMISSION_SCOPE' using errcode = 'P0001';
  end if;

  v_token := encode(extensions.gen_random_bytes(32), 'hex');

  insert into public.supplier_permission_requests (
    token,
    store_id,
    supplier_name,
    brand,
    line_ids,
    product_ids,
    status,
    expires_at
  ) values (
    v_token,
    p_store_id,
    v_supplier_name,
    v_brand,
    v_line_ids,
    v_product_ids,
    'bekliyor',
    pg_catalog.now() + interval '30 days'
  );

  return v_token;
end;
$$;

alter function public.create_supplier_permission_request(uuid, text, text, text, jsonb, jsonb) owner to postgres;
revoke all on function public.create_supplier_permission_request(uuid, text, text, text, jsonb, jsonb) from public, anon, authenticated;
grant execute on function public.create_supplier_permission_request(uuid, text, text, text, jsonb, jsonb) to service_role;

create or replace function public.get_supplier_permission_request(
  p_token text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token text := lower(pg_catalog.btrim(coalesce(p_token, '')));
  v_req record;
  v_products jsonb := '[]'::jsonb;
  v_line_count integer := 0;
begin
  if pg_catalog.length(v_token) <> 64 or v_token !~ '^[0-9a-f]{64}$' then
    return null;
  end if;

  select
    r.id,
    r.store_id,
    r.brand,
    r.line_ids,
    r.product_ids,
    r.status,
    r.created_at,
    r.expires_at,
    s.name as store_name,
    s.slug as store_slug
  into v_req
  from public.supplier_permission_requests r
  join public.stores s on s.id = r.store_id
  where r.token = v_token
    and r.expires_at > pg_catalog.now();

  if not found then
    return null;
  end if;

  if jsonb_typeof(v_req.line_ids) = 'array' then
    v_line_count := jsonb_array_length(v_req.line_ids);
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'name', p.name,
        'slug', p.slug,
        'brand', coalesce(nullif(pg_catalog.btrim(p.brand), ''), v_req.brand),
        'model', coalesce(p.metadata->>'model', ''),
        'image_urls', coalesce(p.image_urls, '[]'::jsonb),
        'permission_status', case
          when exists (
            select 1
            from public.invoice_job_lines l
            join public.invoice_image_rights ir on ir.line_id = l.id
            where l.product_id = p.id
              and ir.usage_status = 'verified_supplier_permission'
          ) then 'onaylandi'
          else 'bekliyor'
        end
      )
      order by p.sort_order, p.id
    ),
    '[]'::jsonb
  )
  into v_products
  from public.products p
  where p.store_id = v_req.store_id
    and p.is_active = true
    and (
      (jsonb_typeof(v_req.product_ids) = 'array' and v_req.product_ids ? p.id::text)
      or exists (
        select 1
        from public.invoice_job_lines l
        where l.product_id = p.id
          and jsonb_typeof(v_req.line_ids) = 'array'
          and v_req.line_ids ? l.id::text
      )
    );

  return jsonb_build_object(
    'store_name', v_req.store_name,
    'store_slug', v_req.store_slug,
    'brand', v_req.brand,
    'status', v_req.status,
    'created_at', v_req.created_at,
    'expires_at', v_req.expires_at,
    'product_count', jsonb_array_length(v_products),
    'line_count', v_line_count,
    'products', v_products
  );
end;
$$;

alter function public.get_supplier_permission_request(text) owner to postgres;
revoke all on function public.get_supplier_permission_request(text) from public;
grant execute on function public.get_supplier_permission_request(text) to anon, authenticated, service_role;

create or replace function public.approve_supplier_permission_request(
  p_token text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token text := lower(pg_catalog.btrim(coalesce(p_token, '')));
  v_req record;
  v_target_line_ids uuid[];
  v_updated_rights integer := 0;
begin
  if pg_catalog.length(v_token) <> 64 or v_token !~ '^[0-9a-f]{64}$' then
    return jsonb_build_object('success', false, 'error', 'INVALID_TOKEN');
  end if;

  select *
    into v_req
  from public.supplier_permission_requests
  where token = v_token
  for update;

  if not found then
    return jsonb_build_object('success', false, 'error', 'NOT_FOUND');
  end if;

  if v_req.expires_at <= pg_catalog.now() then
    return jsonb_build_object('success', false, 'error', 'TOKEN_EXPIRED');
  end if;

  if v_req.status = 'reddedildi' then
    return jsonb_build_object('success', false, 'error', 'REQUEST_REJECTED');
  end if;

  if v_req.status = 'onaylandi' then
    return jsonb_build_object('success', true, 'already_approved', true, 'status', 'onaylandi');
  end if;

  select coalesce(array_agg(distinct l.id), '{}'::uuid[])
    into v_target_line_ids
  from public.invoice_job_lines l
  join public.invoice_jobs j on j.id = l.job_id
  where j.store_id = v_req.store_id
    and (
      (jsonb_typeof(v_req.line_ids) = 'array' and v_req.line_ids ? l.id::text)
      or (jsonb_typeof(v_req.product_ids) = 'array' and v_req.product_ids ? l.product_id::text)
    );

  if coalesce(array_length(v_target_line_ids, 1), 0) > 0 then
    update public.invoice_image_rights
    set
      usage_status = 'verified_supplier_permission',
      source = 'supplier_permission_request:' || v_req.id::text,
      checked_at = pg_catalog.now()
    where line_id = any(v_target_line_ids)
      and usage_status = 'unknown';

    get diagnostics v_updated_rights = row_count;

    update public.products p
    set
      fatura_kanit = jsonb_set(
        p.fatura_kanit,
        '{gorselKaynaklari}',
        coalesce((
          select jsonb_agg(
            case
              when coalesce(elem->>'hakKayitDurumu', '') = 'unknown'
                and exists (
                  select 1
                  from public.invoice_image_rights ir
                  where ir.line_id = any(v_target_line_ids)
                    and ir.image_url = elem->>'kaynakGorsel'
                    and ir.usage_status = 'verified_supplier_permission'
                )
              then elem || jsonb_build_object(
                'hakKayitDurumu', 'verified_supplier_permission',
                'hakIncelemeGerekiyor', false
              )
              else elem
            end
          )
          from jsonb_array_elements(p.fatura_kanit->'gorselKaynaklari') elem
        ), '[]'::jsonb),
        false
      ),
      updated_at = pg_catalog.now()
    where p.store_id = v_req.store_id
      and p.source_type = 'invoice'
      and jsonb_typeof(p.fatura_kanit) = 'object'
      and jsonb_typeof(p.fatura_kanit->'gorselKaynaklari') = 'array'
      and (
        (jsonb_typeof(v_req.product_ids) = 'array' and v_req.product_ids ? p.id::text)
        or exists (
          select 1
          from public.invoice_job_lines l
          where l.id = any(v_target_line_ids)
            and l.product_id = p.id
        )
      );
  end if;

  update public.supplier_permission_requests
  set
    status = 'onaylandi',
    updated_at = pg_catalog.now()
  where id = v_req.id;

  return jsonb_build_object(
    'success', true,
    'status', 'onaylandi',
    'updated_rights_count', v_updated_rights
  );
end;
$$;

alter function public.approve_supplier_permission_request(text) owner to postgres;
revoke all on function public.approve_supplier_permission_request(text) from public;
grant execute on function public.approve_supplier_permission_request(text) to anon, authenticated, service_role;

notify pgrst, 'reload schema';
