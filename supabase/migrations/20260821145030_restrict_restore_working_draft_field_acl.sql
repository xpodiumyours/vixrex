-- #261: proje default privileges'i yeni fonksiyonlara service_role dahil
-- açık EXECUTE verebilir. Önce tüm Data API rollerini temizle, sonra bu
-- sahip-tokenlı RPC için yalnız gereken rolleri geri aç.

revoke all on function public.restore_working_draft_field(text, text)
  from public, anon, authenticated, service_role;

grant execute on function public.restore_working_draft_field(text, text)
  to anon, authenticated;

notify pgrst, 'reload schema';
