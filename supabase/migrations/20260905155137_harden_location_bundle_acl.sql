-- 5.9 GPS bundle bugün yalnız Next server route üzerinden çağrılır.
-- Flutter direct GPS bundle henüz bu aşamada bağlı değildir; gereksiz
-- authenticated SECURITY DEFINER yüzeyini kapat.
revoke execute on function public.vixrex_apply_location_bundle(
  text,
  double precision,
  double precision,
  text,
  text,
  text,
  text,
  bigint,
  uuid
) from authenticated;

grant execute on function public.vixrex_apply_location_bundle(
  text,
  double precision,
  double precision,
  text,
  text,
  text,
  text,
  bigint,
  uuid
) to service_role;
