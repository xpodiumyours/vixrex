-- FAZ 1 Manuel Migration — Supabase Dashboard SQL Editor'e yapıştır
-- Zamanlama: Vercel deploy ÖNCESİ, canlı DB'ye tek sefer uygula
-- Idempotent: CREATE OR REPLACE, tekrar çalıştırılabilir
-- Kaynak: supabase/migrations/20260901003000, 20260901050000, 20260901060000

-- 1) Tek konuşma seam'i: Flutter + Next.js ortak `assistant_conversations`
-- (20260901003000)
create or replace function public.ensure_assistant_conversation()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_conversation public.assistant_conversations%rowtype;
  v_store_id uuid;
begin
  if v_user_id is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_conversation from public.assistant_conversations where user_id = v_user_id limit 1;
  if found then return to_jsonb(v_conversation); end if;
  select id into v_store_id from public.stores where user_id = v_user_id limit 1;
  insert into public.assistant_conversations (user_id, store_id) values (v_user_id, v_store_id) returning * into v_conversation;
  return to_jsonb(v_conversation);
end;
$$;
revoke all on function public.ensure_assistant_conversation() from public;
grant execute on function public.ensure_assistant_conversation() to authenticated;

create or replace function public.get_assistant_conversation()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_conversation_id uuid;
  v_conversation jsonb;
begin
  if v_user_id is null then raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001'; end if;
  v_conversation_id := (public.ensure_assistant_conversation()->>'id')::uuid;
  select jsonb_build_object('id', c.id, 'store_id', c.store_id, 'created_at', c.created_at, 'updated_at', c.updated_at, 'messages', coalesce((select jsonb_agg(to_jsonb(recent_message) order by recent_message.seq asc) from (select m.id, m.seq, m.role, m.message_key, m.message_text, m.catalog_snapshot, m.client_message_id, m.created_at from public.assistant_messages m where m.conversation_id = c.id order by m.seq desc limit 500) recent_message), '[]'::jsonb)) into v_conversation from public.assistant_conversations c where c.id = v_conversation_id and c.user_id = v_user_id;
  return v_conversation;
end;
$$;
revoke all on function public.get_assistant_conversation() from public;
grant execute on function public.get_assistant_conversation() to authenticated;

-- 2) Bootstrap sıralama düzeltmesi (20260901050000) — 42803 fix
create or replace function public.get_owner_workspace_bootstrap()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_store jsonb;
  v_draft jsonb;
  v_flow jsonb;
  v_conversation jsonb;
  v_store_id uuid;
begin
  if v_user_id is null then return jsonb_build_object('user_id', null, 'store', null, 'working_draft', null, 'flow_state', null, 'conversation', null); end if;
  select to_jsonb(s) into v_store from public.stores s where s.user_id = v_user_id limit 1;
  if v_store is not null then v_store_id := (v_store->>'id')::uuid;
    select jsonb_build_object('store_id', d.store_id, 'draft_data', public.strip_draft_secrets(d.draft_data), 'draft_version', d.draft_version, 'base_live_version', d.base_live_version, 'updated_at', d.updated_at) into v_draft from public.store_working_drafts d where d.store_id = v_store_id;
  end if;
  select to_jsonb(f) into v_flow from public.owner_flow_states f where f.user_id = v_user_id order by f.updated_at desc limit 1;
  select jsonb_build_object('id', c.id, 'store_id', c.store_id, 'created_at', c.created_at, 'updated_at', c.updated_at, 'messages', coalesce((select jsonb_agg(last_message.payload order by last_message.seq asc) from (select m.seq, jsonb_build_object('id', m.id, 'seq', m.seq, 'role', m.role, 'message_key', m.message_key, 'message_text', m.message_text, 'catalog_snapshot', m.catalog_snapshot, 'client_message_id', m.client_message_id, 'created_at', m.created_at) as payload from public.assistant_messages m where m.conversation_id = c.id order by m.seq desc limit 20) last_message), '[]'::jsonb)) into v_conversation from public.assistant_conversations c where c.user_id = v_user_id order by c.updated_at desc limit 1;
  return jsonb_build_object('user_id', v_user_id, 'store', coalesce(v_store, 'null'::jsonb), 'working_draft', v_draft, 'flow_state', v_flow, 'conversation', v_conversation);
end;
$$;
revoke execute on function public.get_owner_workspace_bootstrap() from public;
grant execute on function public.get_owner_workspace_bootstrap() to authenticated;

-- 3) Demo trial 14 gün (20260901060000)
BEGIN;
CREATE OR REPLACE FUNCTION public.clone_demo_store_as_draft(p_source_slug text, p_new_slug text, p_edit_token text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, extensions AS $$
BEGIN
  IF p_new_slug IS NULL OR pg_catalog.length(pg_catalog.btrim(p_new_slug)) = 0 THEN RAISE EXCEPTION 'INVALID_SLUG'; END IF;
  IF p_edit_token IS NULL OR pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 THEN RAISE EXCEPTION 'INVALID_EDIT_TOKEN'; END IF;
  INSERT INTO public.stores (slug, edit_token, user_id, name, business_type, description, corporate_bio, whatsapp, phone, email, hero_badge, instagram, website, address, theme, theme_preset, status, marketplace_links, gallery_items, products, product_categories, offerings, catalog_link, references_link, vcard_link, shelf_image_url, logo_url, working_hours, is_published, is_store, kategori, latitude, longitude, location_accuracy_meters, location_source, province_code, province_name, district_code, district_name, google_business_link, featured_banner_label, featured_banner_title, featured_banner_description, featured_banner_image_url, featured_banner_price_text, faq_items, about_kicker, about_title, about_image_url, about_image_caption, about_values, gallery_section_kicker, gallery_section_title, show_storefront_rating, show_directions_link, edit_token_expires_at)
  SELECT pg_catalog.btrim(p_new_slug), pg_catalog.btrim(p_edit_token), null, name, business_type, description, corporate_bio, whatsapp, phone, email, hero_badge, instagram, website, address, theme, theme_preset, 'draft', marketplace_links, gallery_items, products, product_categories, offerings, catalog_link, references_link, vcard_link, shelf_image_url, logo_url, working_hours, false, is_store, kategori, latitude, longitude, location_accuracy_meters, location_source, province_code, province_name, district_code, district_name, google_business_link, featured_banner_label, featured_banner_title, featured_banner_description, featured_banner_image_url, featured_banner_price_text, faq_items, about_kicker, about_title, about_image_url, about_image_caption, about_values, gallery_section_kicker, gallery_section_title, show_storefront_rating, show_directions_link, now() + interval '14 days' FROM public.stores WHERE slug = pg_catalog.btrim(p_source_slug) AND is_demo = true;
  IF NOT FOUND THEN RAISE EXCEPTION 'SOURCE_NOT_FOUND'; END IF;
END;
$$;
COMMIT;

-- Doğrulama (Dashboard'da çalıştır, 3 satır dönmeli)
-- select proname from pg_proc where proname in ('ensure_assistant_conversation','get_assistant_conversation','get_owner_workspace_bootstrap');
