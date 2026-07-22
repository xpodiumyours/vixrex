insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'shelf-images',
  'shelf-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

drop policy if exists "Allow public shelf image uploads" on storage.objects;

create policy "Allow public shelf image uploads"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'shelf-images'
  and name ~ '^[a-z0-9_-]+(/[a-z0-9_-]+){0,3}/[0-9]{10,}\.(jpg|png|webp)$'
);

drop policy if exists "Allow public shelf image reads" on storage.objects;
