-- ACİL DÜZELTME (2026-08-20, canlıda bulundu): Sahip ekranları 403 veriyordu.
--
-- KÖK NEDEN: 20260818050000_fix_stores_public_user_id_exposure.sql (V-09)
-- `stores.user_id` sütununun SELECT'ini anon VE authenticated'ten haklı
-- olarak revoke etti — public vitrin cevabında sahibin iç kullanıcı
-- kimliğinin sızmasını önlemek içindi, doğru bir düzeltmeydi.
--
-- AMA: 11 tabloda 24 RLS politikası "bu satırın sahibi ben miyim" diye
-- `EXISTS (SELECT 1 FROM stores s WHERE ... AND s.user_id = auth.uid())`
-- deseniyle stores.user_id'yi DOLAYLI okuyor. PostgreSQL bir politikanın
-- USING/WITH CHECK ifadesini değerlendirirken, başka bir tablonun alt
-- sorgusunda geçen kolon için de çağıran rolün SELECT yetkisini arıyor —
-- authenticated artık user_id'yi okuyamadığı için bu politikaların HEPSİ
-- "permission denied for table stores" (42501) ile patlıyordu. Etki: giriş
-- yapmış esnaf kendi ürün/kategori/randevu/blog/Instagram/XML feed
-- verisini yönetemiyor — Keşfet ekranındaki "vitrinler yüklenemedi" hatası
-- bunun yalnız görünen bir belirtisiydi, kapsamı çok daha genişti.
-- Canlıda `set local role authenticated` + gerçek JWT claim'iyle birebir
-- reprodüklendi.
--
-- ÇÖZÜM: V-09'un REVOKE'unu GERİ ALMIYORUZ (o düzeltme doğruydu, user_id
-- hâlâ public'e kapalı kalmalı). Bunun yerine iki SECURITY DEFINER
-- fonksiyon eklenir — yalnız true/false döner, user_id'nin kendisini asla
-- client'a sızdırmaz. Fonksiyon sahibinin (postgres) yetkisiyle çalıştığı
-- için çağıran rolün stores.user_id'ye kolon bazlı erişimine ihtiyaç
-- kalmaz. 24 politika bu fonksiyonları kullanacak şekilde yeniden yazılır;
-- her politikanın ORİJİNAL semantiği (ek koşullar dahil) korunur, yalnız
-- sahiplik kontrolünün kaynağı değişir.

-- ── Yardımcı fonksiyonlar ───────────────────────────────────────────────
create or replace function public.is_store_owner_by_id(p_store_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.stores where id = p_store_id and user_id = auth.uid()
  );
$$;

comment on function public.is_store_owner_by_id(uuid) is
  'Çağıranın (auth.uid()) verilen store_id''nin sahibi olup olmadığını
   döner. SECURITY DEFINER — stores.user_id''nin kolon bazlı SELECT''i
   authenticated''ten kapalı (V-09) olsa da RLS politikaları içeride bu
   kontrolü yapabilsin diye var. user_id''nin kendisini DÖNMEZ, yalnız
   boolean.';

revoke all on function public.is_store_owner_by_id(uuid) from public;
grant execute on function public.is_store_owner_by_id(uuid) to authenticated;

create or replace function public.is_store_owner_by_slug(p_store_slug text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.stores where slug = p_store_slug and user_id = auth.uid()
  );
$$;

comment on function public.is_store_owner_by_slug(text) is
  'is_store_owner_by_id ile aynı, slug üzerinden eşleşen tablolar için
   (appointments, booking_settings, store_articles vb.).';

revoke all on function public.is_store_owner_by_slug(text) from public;
grant execute on function public.is_store_owner_by_slug(text) to authenticated;

-- ── appointment_reschedule_requests ─────────────────────────────────────
drop policy if exists "Owners can update reschedule requests" on public.appointment_reschedule_requests;
create policy "Owners can update reschedule requests" on public.appointment_reschedule_requests
  for update to authenticated
  using (exists (
    select 1 from public.appointments a
    where a.id = appointment_reschedule_requests.appointment_id
      and public.is_store_owner_by_slug(a.store_slug)
  ));

drop policy if exists "Owners can view reschedule requests" on public.appointment_reschedule_requests;
create policy "Owners can view reschedule requests" on public.appointment_reschedule_requests
  for select to authenticated
  using (exists (
    select 1 from public.appointments a
    where a.id = appointment_reschedule_requests.appointment_id
      and public.is_store_owner_by_slug(a.store_slug)
  ));

-- ── appointments ─────────────────────────────────────────────────────────
drop policy if exists "Owners can update their store appointments" on public.appointments;
create policy "Owners can update their store appointments" on public.appointments
  for update to authenticated
  using (auth.uid() is not null and public.is_store_owner_by_slug(appointments.store_slug))
  with check (auth.uid() is not null and public.is_store_owner_by_slug(appointments.store_slug));

drop policy if exists "Owners can view their store appointments" on public.appointments;
create policy "Owners can view their store appointments" on public.appointments
  for select to authenticated
  using (auth.uid() is not null and public.is_store_owner_by_slug(appointments.store_slug));

-- ── booking_blocks ───────────────────────────────────────────────────────
drop policy if exists "Owners can manage booking blocks" on public.booking_blocks;
create policy "Owners can manage booking blocks" on public.booking_blocks
  for all to authenticated
  using (public.is_store_owner_by_slug(booking_blocks.store_slug))
  with check (public.is_store_owner_by_slug(booking_blocks.store_slug));

-- ── booking_settings ─────────────────────────────────────────────────────
drop policy if exists "Owners can insert booking settings" on public.booking_settings;
create policy "Owners can insert booking settings" on public.booking_settings
  for insert to authenticated
  with check (public.is_store_owner_by_slug(booking_settings.store_slug));

drop policy if exists "Owners can update booking settings" on public.booking_settings;
create policy "Owners can update booking settings" on public.booking_settings
  for update to authenticated
  using (public.is_store_owner_by_slug(booking_settings.store_slug))
  with check (public.is_store_owner_by_slug(booking_settings.store_slug));

-- ── product_categories ───────────────────────────────────────────────────
drop policy if exists "owner_delete_categories" on public.product_categories;
create policy "owner_delete_categories" on public.product_categories
  for delete to authenticated
  using (public.is_store_owner_by_id(product_categories.store_id));

drop policy if exists "owner_insert_categories" on public.product_categories;
create policy "owner_insert_categories" on public.product_categories
  for insert to authenticated
  with check (public.is_store_owner_by_id(product_categories.store_id));

drop policy if exists "owner_select_categories" on public.product_categories;
create policy "owner_select_categories" on public.product_categories
  for select to authenticated
  using (public.is_store_owner_by_id(product_categories.store_id));

drop policy if exists "owner_update_categories" on public.product_categories;
create policy "owner_update_categories" on public.product_categories
  for update to authenticated
  using (public.is_store_owner_by_id(product_categories.store_id))
  with check (public.is_store_owner_by_id(product_categories.store_id));

-- ── products ─────────────────────────────────────────────────────────────
drop policy if exists "owner_delete_products" on public.products;
create policy "owner_delete_products" on public.products
  for delete to authenticated
  using (public.is_store_owner_by_id(products.store_id));

drop policy if exists "owner_insert_products" on public.products;
create policy "owner_insert_products" on public.products
  for insert to authenticated
  with check (public.is_store_owner_by_id(products.store_id));

drop policy if exists "owner_select_products" on public.products;
create policy "owner_select_products" on public.products
  for select to authenticated
  using (public.is_store_owner_by_id(products.store_id));

drop policy if exists "owner_update_products" on public.products;
create policy "owner_update_products" on public.products
  for update to authenticated
  using (public.is_store_owner_by_id(products.store_id))
  with check (public.is_store_owner_by_id(products.store_id));

-- ── store_articles ───────────────────────────────────────────────────────
drop policy if exists "Owners can delete their own articles" on public.store_articles;
create policy "Owners can delete their own articles" on public.store_articles
  for delete to authenticated
  using (public.is_store_owner_by_slug(store_articles.store_slug));

drop policy if exists "Owners can insert their own articles" on public.store_articles;
create policy "Owners can insert their own articles" on public.store_articles
  for insert to authenticated
  with check (public.is_store_owner_by_slug(store_articles.store_slug));

drop policy if exists "Owners can read all their own articles" on public.store_articles;
create policy "Owners can read all their own articles" on public.store_articles
  for select to authenticated
  using (public.is_store_owner_by_slug(store_articles.store_slug));

drop policy if exists "Owners can update their own articles" on public.store_articles;
create policy "Owners can update their own articles" on public.store_articles
  for update to authenticated
  using (public.is_store_owner_by_slug(store_articles.store_slug))
  with check (public.is_store_owner_by_slug(store_articles.store_slug));

-- ── store_category_image_usage ──────────────────────────────────────────
drop policy if exists "store_cat_usage_owner_insert" on public.store_category_image_usage;
create policy "store_cat_usage_owner_insert" on public.store_category_image_usage
  for insert to authenticated
  with check (public.is_store_owner_by_id(store_category_image_usage.store_id));

drop policy if exists "store_cat_usage_owner_select" on public.store_category_image_usage;
create policy "store_cat_usage_owner_select" on public.store_category_image_usage
  for select to authenticated
  using (public.is_store_owner_by_id(store_category_image_usage.store_id));

-- ── store_instagram_connections ─────────────────────────────────────────
drop policy if exists "Owners can read own Instagram connection" on public.store_instagram_connections;
create policy "Owners can read own Instagram connection" on public.store_instagram_connections
  for select to authenticated
  using (public.is_store_owner_by_slug(store_instagram_connections.store_slug));

-- ── store_instagram_imports ─────────────────────────────────────────────
drop policy if exists "Owners can read own Instagram imports" on public.store_instagram_imports;
create policy "Owners can read own Instagram imports" on public.store_instagram_imports
  for select to authenticated
  using (public.is_store_owner_by_slug(store_instagram_imports.store_slug));

-- ── xml_feeds ────────────────────────────────────────────────────────────
drop policy if exists "owner_xml_feeds" on public.xml_feeds;
create policy "owner_xml_feeds" on public.xml_feeds
  for all to authenticated
  using (public.is_store_owner_by_id(xml_feeds.store_id))
  with check (public.is_store_owner_by_id(xml_feeds.store_id));

notify pgrst, 'reload schema';
