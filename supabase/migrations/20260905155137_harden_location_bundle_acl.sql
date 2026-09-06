-- 5.9 GPS bundle bugün yalnız Next server route üzerinden çağrılır.
-- Flutter direct GPS bundle henüz bu aşamada bağlı değildir; gereksiz
-- SECURITY DEFINER yüzeyini kapat.
--
-- DİKKAT: yalnız `authenticated`'tan geri almak YETMEZ. PostgreSQL, yeni
-- fonksiyonlarda EXECUTE yetkisini varsayılan olarak PUBLIC'e verir; PUBLIC
-- geri alınmazsa `anon` (oturum açmamış herkes) bu SECURITY DEFINER
-- fonksiyonunu çağırabilmeye devam eder. Bu yüzden üç rolden de alınır.
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
) from public, anon, authenticated;

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
