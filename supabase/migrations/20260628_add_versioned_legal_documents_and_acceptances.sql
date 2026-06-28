-- Versioned legal documents and auditable publication consent.
-- Documents are seeded as inactive until the real data-controller identity and
-- lawyer-approved text are supplied.

create schema if not exists private;
revoke all on schema private from public;

create table if not exists public.legal_documents (
  id uuid primary key default gen_random_uuid(),
  document_type text not null check (
    document_type in ('privacy', 'terms', 'consent', 'dataDeletion')
  ),
  version text not null,
  title text not null,
  subtitle text not null default '',
  sections jsonb not null check (jsonb_typeof(sections) = 'array'),
  content_hash text not null default '',
  is_active boolean not null default false,
  effective_at timestamptz,
  created_at timestamptz not null default now(),
  unique (document_type, version)
);

create unique index if not exists legal_documents_one_active_per_type
on public.legal_documents (document_type)
where is_active;

alter table public.legal_documents enable row level security;

revoke all on table public.legal_documents from anon, authenticated;
grant select on table public.legal_documents to anon, authenticated;
grant select, insert, update, delete on table public.legal_documents
to service_role;

drop policy if exists "Active legal documents are publicly readable"
on public.legal_documents;
create policy "Active legal documents are publicly readable"
on public.legal_documents
for select
to anon, authenticated
using (is_active = true);

create or replace function private.set_legal_document_hash()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and old.is_active and (
    new.document_type is distinct from old.document_type
    or new.version is distinct from old.version
    or new.title is distinct from old.title
    or new.subtitle is distinct from old.subtitle
    or new.sections is distinct from old.sections
  ) then
    raise exception 'ACTIVE_LEGAL_DOCUMENT_IS_IMMUTABLE';
  end if;

  new.content_hash := pg_catalog.md5(
    new.document_type || '|' ||
    new.version || '|' ||
    new.title || '|' ||
    new.subtitle || '|' ||
    new.sections::text
  );
  return new;
end;
$$;

revoke execute on function private.set_legal_document_hash() from public;

drop trigger if exists trg_set_legal_document_hash
on public.legal_documents;
create trigger trg_set_legal_document_hash
before insert or update on public.legal_documents
for each row execute function private.set_legal_document_hash();

alter table public.stores
add column if not exists privacy_notice_acknowledged boolean not null default false,
add column if not exists privacy_notice_acknowledged_at timestamptz,
add column if not exists privacy_notice_version text,
add column if not exists privacy_notice_hash text,
add column if not exists terms_accepted boolean not null default false,
add column if not exists terms_accepted_at timestamptz,
add column if not exists terms_version text,
add column if not exists terms_hash text,
add column if not exists publication_consent_accepted boolean not null default false,
add column if not exists publication_consent_accepted_at timestamptz,
add column if not exists publication_consent_withdrawn_at timestamptz,
add column if not exists publication_consent_version text,
add column if not exists publication_consent_hash text;

create table if not exists public.legal_acceptance_events (
  id uuid primary key default gen_random_uuid(),
  store_slug text not null,
  user_id uuid,
  event_type text not null check (
    event_type in (
      'privacy_notice_acknowledged',
      'terms_accepted',
      'publication_consent_granted',
      'publication_consent_withdrawn'
    )
  ),
  document_type text not null,
  document_version text not null,
  document_hash text not null,
  occurred_at timestamptz not null default now()
);

create index if not exists legal_acceptance_events_store_slug_idx
on public.legal_acceptance_events (store_slug, occurred_at desc);

alter table public.legal_acceptance_events enable row level security;
revoke all on table public.legal_acceptance_events from anon, authenticated;
grant select on table public.legal_acceptance_events to service_role;

create or replace function private.validate_store_legal_acceptance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := pg_catalog.now();
begin
  if tg_op = 'UPDATE'
    and old.publication_consent_accepted
    and new.publication_consent_accepted is not true
    and new.publication_consent_withdrawn_at is null then
    new.publication_consent_withdrawn_at := v_now;
  end if;

  if new.is_published is not true then
    return new;
  end if;

  if new.privacy_notice_acknowledged is not true then
    raise exception 'PRIVACY_NOTICE_REQUIRED';
  end if;
  if new.terms_accepted is not true then
    raise exception 'TERMS_ACCEPTANCE_REQUIRED';
  end if;
  if new.publication_consent_accepted is not true then
    raise exception 'PUBLICATION_CONSENT_REQUIRED';
  end if;

  if not exists (
    select 1 from public.legal_documents d
    where d.document_type = 'privacy'
      and d.is_active
      and d.version = new.privacy_notice_version
      and d.content_hash = new.privacy_notice_hash
  ) then
    raise exception 'PRIVACY_NOTICE_VERSION_INVALID';
  end if;

  if not exists (
    select 1 from public.legal_documents d
    where d.document_type = 'terms'
      and d.is_active
      and d.version = new.terms_version
      and d.content_hash = new.terms_hash
  ) then
    raise exception 'TERMS_VERSION_INVALID';
  end if;

  if not exists (
    select 1 from public.legal_documents d
    where d.document_type = 'consent'
      and d.is_active
      and d.version = new.publication_consent_version
      and d.content_hash = new.publication_consent_hash
  ) then
    raise exception 'PUBLICATION_CONSENT_VERSION_INVALID';
  end if;

  if tg_op = 'INSERT'
    or old.privacy_notice_acknowledged is not true
    or old.privacy_notice_version is distinct from new.privacy_notice_version
    or old.privacy_notice_hash is distinct from new.privacy_notice_hash then
    new.privacy_notice_acknowledged_at := v_now;
  end if;

  if tg_op = 'INSERT'
    or old.terms_accepted is not true
    or old.terms_version is distinct from new.terms_version
    or old.terms_hash is distinct from new.terms_hash then
    new.terms_accepted_at := v_now;
  end if;

  if tg_op = 'INSERT'
    or old.publication_consent_accepted is not true
    or old.publication_consent_version is distinct from new.publication_consent_version
    or old.publication_consent_hash is distinct from new.publication_consent_hash then
    new.publication_consent_accepted_at := v_now;
    new.publication_consent_withdrawn_at := null;
  end if;

  return new;
end;
$$;

revoke execute on function private.validate_store_legal_acceptance()
from public;

drop trigger if exists trg_validate_store_legal_acceptance
on public.stores;
create trigger trg_validate_store_legal_acceptance
before insert or update on public.stores
for each row execute function private.validate_store_legal_acceptance();

create or replace function private.record_store_legal_events()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.privacy_notice_acknowledged and (
    tg_op = 'INSERT'
    or old.privacy_notice_acknowledged is not true
    or old.privacy_notice_version is distinct from new.privacy_notice_version
    or old.privacy_notice_hash is distinct from new.privacy_notice_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug, user_id, event_type, document_type,
      document_version, document_hash, occurred_at
    ) values (
      new.slug, new.user_id, 'privacy_notice_acknowledged', 'privacy',
      new.privacy_notice_version, new.privacy_notice_hash,
      new.privacy_notice_acknowledged_at
    );
  end if;

  if new.terms_accepted and (
    tg_op = 'INSERT'
    or old.terms_accepted is not true
    or old.terms_version is distinct from new.terms_version
    or old.terms_hash is distinct from new.terms_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug, user_id, event_type, document_type,
      document_version, document_hash, occurred_at
    ) values (
      new.slug, new.user_id, 'terms_accepted', 'terms',
      new.terms_version, new.terms_hash, new.terms_accepted_at
    );
  end if;

  if new.publication_consent_accepted and (
    tg_op = 'INSERT'
    or old.publication_consent_accepted is not true
    or old.publication_consent_version is distinct from new.publication_consent_version
    or old.publication_consent_hash is distinct from new.publication_consent_hash
  ) then
    insert into public.legal_acceptance_events (
      store_slug, user_id, event_type, document_type,
      document_version, document_hash, occurred_at
    ) values (
      new.slug, new.user_id, 'publication_consent_granted', 'consent',
      new.publication_consent_version, new.publication_consent_hash,
      new.publication_consent_accepted_at
    );
  end if;

  if tg_op = 'UPDATE'
    and old.publication_consent_accepted
    and new.publication_consent_accepted is not true then
    insert into public.legal_acceptance_events (
      store_slug, user_id, event_type, document_type,
      document_version, document_hash, occurred_at
    ) values (
      new.slug, new.user_id, 'publication_consent_withdrawn', 'consent',
      old.publication_consent_version, old.publication_consent_hash,
      new.publication_consent_withdrawn_at
    );
  end if;

  return new;
end;
$$;

revoke execute on function private.record_store_legal_events() from public;

drop trigger if exists trg_record_store_legal_events
on public.stores;
create trigger trg_record_store_legal_events
after insert or update on public.stores
for each row execute function private.record_store_legal_events();

create or replace function public.update_store_with_token(
  p_slug text,
  p_edit_token text,
  p_store jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_slug is null or pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  update public.stores
  set
    name = coalesce(p_store->>'name', name),
    business_type = coalesce(p_store->>'business_type', business_type),
    description = coalesce(p_store->>'description', description),
    corporate_bio = coalesce(p_store->>'corporate_bio', corporate_bio),
    whatsapp = coalesce(p_store->>'whatsapp', whatsapp),
    instagram = coalesce(p_store->>'instagram', instagram),
    website = coalesce(p_store->>'website', website),
    address = coalesce(p_store->>'address', address),
    theme = coalesce(p_store->>'theme', theme),
    status = coalesce(p_store->>'status', status),
    marketplace_links = coalesce(p_store->'marketplace_links', marketplace_links),
    gallery_items = coalesce(p_store->'gallery_items', gallery_items),
    products = coalesce(p_store->'products', products),
    offerings = coalesce(p_store->'offerings', offerings),
    catalog_link = coalesce(p_store->>'catalog_link', catalog_link),
    references_link = coalesce(p_store->>'references_link', references_link),
    vcard_link = coalesce(p_store->>'vcard_link', vcard_link),
    shelf_image_url = coalesce(nullif(p_store->>'shelf_image_url', ''), shelf_image_url),
    logo_url = coalesce(nullif(p_store->>'logo_url', ''), logo_url),
    working_hours = coalesce(p_store->>'working_hours', working_hours),
    is_published = true,
    is_store = coalesce((p_store->>'is_store')::boolean, is_store),
    kategori = coalesce(p_store->>'kategori', kategori),
    latitude = case when p_store ? 'latitude' then (p_store->>'latitude')::float8 else latitude end,
    longitude = case when p_store ? 'longitude' then (p_store->>'longitude')::float8 else longitude end,
    location_accuracy_meters = case when p_store ? 'location_accuracy_meters' then (p_store->>'location_accuracy_meters')::float8 else location_accuracy_meters end,
    location_consent_at = case when p_store ? 'location_consent_at' then (p_store->>'location_consent_at')::timestamptz else location_consent_at end,
    location_source = case when p_store ? 'location_source' then p_store->>'location_source' else location_source end,
    province_code = coalesce(p_store->>'province_code', province_code),
    province_name = coalesce(p_store->>'province_name', province_name),
    district_code = coalesce(p_store->>'district_code', district_code),
    district_name = coalesce(p_store->>'district_name', district_name),
    google_business_link = coalesce(p_store->>'google_business_link', google_business_link),
    privacy_notice_acknowledged = coalesce((p_store->>'privacy_notice_acknowledged')::boolean, privacy_notice_acknowledged),
    privacy_notice_version = coalesce(p_store->>'privacy_notice_version', privacy_notice_version),
    privacy_notice_hash = coalesce(p_store->>'privacy_notice_hash', privacy_notice_hash),
    terms_accepted = coalesce((p_store->>'terms_accepted')::boolean, terms_accepted),
    terms_version = coalesce(p_store->>'terms_version', terms_version),
    terms_hash = coalesce(p_store->>'terms_hash', terms_hash),
    publication_consent_accepted = coalesce((p_store->>'publication_consent_accepted')::boolean, publication_consent_accepted),
    publication_consent_version = coalesce(p_store->>'publication_consent_version', publication_consent_version),
    publication_consent_hash = coalesce(p_store->>'publication_consent_hash', publication_consent_hash),
    updated_at = pg_catalog.now()
  where slug = p_slug
    and edit_token = p_edit_token
    and edit_token <> '';

  if not found then
    raise exception 'EDIT_TOKEN_MISMATCH' using errcode = 'P0001';
  end if;
end;
$$;

revoke execute on function public.update_store_with_token(text, text, jsonb)
from public;
grant execute on function public.update_store_with_token(text, text, jsonb)
to anon, authenticated;

create or replace function public.withdraw_store_publication_consent(
  p_slug text,
  p_edit_token text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_slug is null or pg_catalog.length(pg_catalog.btrim(p_slug)) = 0 then
    raise exception 'INVALID_SLUG';
  end if;
  if p_edit_token is null or pg_catalog.length(pg_catalog.btrim(p_edit_token)) < 24 then
    raise exception 'INVALID_EDIT_TOKEN';
  end if;

  update public.stores
  set
    is_published = false,
    publication_consent_accepted = false,
    publication_consent_withdrawn_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  where slug = p_slug
    and edit_token = p_edit_token
    and edit_token <> '';

  if not found then
    raise exception 'EDIT_TOKEN_MISMATCH' using errcode = 'P0001';
  end if;
end;
$$;

revoke execute on function public.withdraw_store_publication_consent(text, text)
from public;
grant execute on function public.withdraw_store_publication_consent(text, text)
to anon, authenticated;

-- Draft documents. Activate only after real company identity and legal review.
insert into public.legal_documents (
  document_type, version, title, subtitle, sections, is_active, effective_at
)
values
(
  'privacy',
  'privacy-2026-06-28-draft',
  'Gizlilik ve KVKK Politikası',
  'Kişisel verilerin işlenmesine ilişkin aydınlatma metni.',
  '[{"title":"Veri Sorumlusu","body":"VitrinX kapsamında kişisel verileriniz [RESMİ Xpodiumyours UNVANI VE ADRESİ] tarafından veri sorumlusu sıfatıyla işlenir."},{"title":"İşlenen Veriler","body":"Vitrin adı, açıklama, kategori, adres, il/ilçe, konum, iletişim bilgileri, sosyal bağlantılar, logo, galeri, ürün, hizmet, çalışma saatleri, hesap ve teknik kayıtlar işlenebilir."},{"title":"Instagram Entegrasyonu Kapsamında İşlenen Veriler","body":"Instagram hesabınızı VitrinX’e bağlamanız halinde, yalnızca açıkça izin verdiğiniz ve resmi Meta/Instagram API’leri üzerinden sağlanan veriler işlenir. Bu kapsamda Instagram kullanıcı adınız, Instagram kullanıcı kimliğiniz, hesap türünüz, izin kapsamları, bağlantı durumu, token bitiş tarihi, seçtiğiniz medya içeriklerine ait medya kimliği, görsel bağlantısı, açıklama/caption, permalink, zaman bilgisi ve ürün olarak aktarmayı seçtiğiniz medya görselleri işlenebilir.\\n\\nInstagram erişim token’ları istemci tarafında saklanmaz; sunucu tarafında şifreli olarak saklanır ve yalnızca Instagram bağlantısını sürdürmek, medya listesini görüntülemek ve kullanıcının seçtiği içerikleri ürüne dönüştürmek amacıyla kullanılır.\\n\\nInstagram’dan aktarılan görseller VitrinX’in kullandığı Supabase Storage altyapısında saklanabilir. Instagram bağlantınızı kestiğinizde token bilgileriniz silinir. Ayrıca talep etmeniz halinde Instagram’dan aktarılan ürün, görsel ve import kayıtlarının silinmesini isteyebilirsiniz.\\n\\nVitrinX, üçüncü taraf Instagram profillerinden, kullanıcının izin vermediği hesaplardan veya public feed’lerden scraping yoluyla veri toplamaz.\\n\\nİşleme Amacı: Vitrin içeriğini zenginleştirmek, Instagram gönderilerini pratik şekilde ürüne dönüştürmek ve vitrin ziyaretçilerine sunmak.\\nHukuki Sebep: Kullanıcının entegrasyonu başlatmasıyla verilen açık rıza ve platform hizmet sözleşmesinin ifası.\\nAktarım: Veriler, entegrasyonun sağlanması için Meta API''leri, görsel ve veri barındırma hizmetleri için Supabase altyapısı ve sunucu sağlayıcılarıyla paylaşılabilir.\\nSaklama Süresi: Instagram entegrasyonu aktif olduğu sürece veya kullanıcı ürünleri/bağlantıyı silene kadar saklanır.\\nSilme/Bağlantı Kesme: Ayarlar menüsünden Instagram bağlantısını kesebilir, dilerseniz \\\"Bağlantıyı kes ve Instagram\'\'dan aktarılanları temizle\\\" (Mod B) seçeneğiyle tüm verileri silebilir veya privacy@vitrinx.app adresine yazılı talep gönderebilirsiniz.\\nKullanıcı Hakları: KVKK Madde 11 kapsamındaki tüm haklarınız (bilgi alma, düzeltme, silme talebi vb.) saklıdır."},{"title":"Amaç ve Hukuki Sebep","body":"Veriler dijital vitrinin oluşturulması, yayınlanması, güvenlik ve destek süreçleri için; sözleşmenin kurulması veya ifası, hukuki yükümlülük, meşru menfaat ve uygun olduğu faaliyetlerde açık rıza hukuki sebeplerine dayanılarak işlenebilir."},{"title":"Aktarım ve Saklama","body":"Veriler yalnızca hizmetin çalışması için kullanılan altyapı sağlayıcılarıyla gerekli ölçüde paylaşılır; saklama süreleri gerçek operasyon ve hukuki yükümlülüklere göre nihai metinde belirtilecektir."},{"title":"Haklar ve Başvuru","body":"KVKK kapsamındaki haklarınız için privacy@vitrinx.app adresinden başvurabilirsiniz."}]'::jsonb,
  false,
  null
),
(
  'terms',
  'terms-2026-06-28-draft',
  'Kullanım Şartları',
  'VitrinX platform kullanım kuralları.',
  '[{"title":"Platform Niteliği","body":"VitrinX, kullanıcıların kendi mağaza, ürün, hizmet, iletişim ve görsel içeriklerini dijital vitrin olarak yayınlayabildiği bir platformdur."},{"title":"Kullanıcı Sorumluluğu","body":"Kullanıcı tarafından eklenen ürün, hizmet, fiyat, açıklama, stok, görsel, marka, bağlantı, kampanya ve iletişim bilgilerinin doğruluğu, güncelliği ve hukuka uygunluğu ilgili kullanıcıya aittir."},{"title":"Sorumluluk Sınırı","body":"VitrinX, kullanıcı içeriklerine dayalı iletişimlerden, satışlardan, randevulardan, üçüncü taraf bağlantılardan veya mağaza sahibinin beyanlarından sorumlu tutulamaz."},{"title":"İçerik Denetimi","body":"VitrinX, hukuka veya platform kurallarına aykırı içerikleri inceleme, kaldırma, yayından alma veya erişimi sınırlandırma hakkını saklı tutar."}]'::jsonb,
  false,
  null
),
(
  'consent',
  'consent-2026-06-28-draft',
  'Açık Rıza Beyanı',
  'Vitrin bilgilerinin kamuya açık yayınlanmasına ilişkin beyan.',
  '[{"title":"Yayınlama Açık Rızası","body":"Vitrin oluştururken paylaştığım mağaza adı, açıklama, kategori, adres, konum, iletişim, sosyal bağlantılar, logo, galeri, ürün, hizmet ve çalışma saatlerinin VitrinX üzerindeki dijital vitrinimde müşterilere açık şekilde yayınlanmasına açık rıza veriyorum."},{"title":"Tercih ve Geri Çekme","body":"Bu rızayı vermediğimde yerel taslağımı düzenleyebileceğimi ancak herkese açık vitrin yayınlayamayacağımı; verdiğim rızayı daha sonra geri çekerek vitrini yayından kaldırabileceğimi biliyorum."}]'::jsonb,
  false,
  null
),
(
  'dataDeletion',
  'data-deletion-2026-06-28-draft',
  'Hesap ve Veri Silme',
  'Hesap, vitrin ve mağaza verilerinin silinmesi.',
  '[{"title":"Silme Talebi","body":"Hesap veya vitrin verilerinizin silinmesi için privacy@vitrinx.app adresine talep gönderebilirsiniz."},{"title":"Rızayı Geri Çekme","body":"Yayınlama rızasını geri çektiğinizde vitrin yayından kaldırılır. Verilerin tamamen silinmesi için ayrıca veri silme talebi oluşturabilirsiniz."}]'::jsonb,
  false,
  null
)
on conflict (document_type, version) do nothing;
