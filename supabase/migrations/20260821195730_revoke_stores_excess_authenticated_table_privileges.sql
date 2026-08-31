-- anon fix'iyle aynı taramada bulundu: authenticated rolünün de
-- public.stores üzerinde TRUNCATE/MAINTAIN/REFERENCES/TRIGGER gibi hiçbir
-- uygulama kodunun kullanmadığı, RLS'in kapsamadığı (TRUNCATE) veya DDL
-- gerektiren (REFERENCES/TRIGGER/MAINTAIN) tablo-seviyesi yetkileri var.
-- SELECT/INSERT/UPDATE/DELETE'e dokunulmuyor: SELECT zaten sütun bazlı
-- kısıtlı, UPDATE gerçekten kullanılıyor (auto_fill_service.dart) ve RLS
-- ile "auth.uid() = user_id" olarak doğru kısıtlanmış, DELETE aynı şekilde
-- RLS korumalı, INSERT için hiç RLS politikası yok (varsayılan red).

revoke truncate, maintain, references, trigger
  on table public.stores from authenticated;

notify pgrst, 'reload schema';
