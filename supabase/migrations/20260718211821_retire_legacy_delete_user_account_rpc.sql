-- Account deletion is owned by the JWT-protected delete-user-account Edge
-- Function. It removes Storage objects through the Storage API and deletes the
-- Auth user with the server-only admin client, which PostgreSQL RPC cannot do
-- safely.
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM anon;
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM authenticated;
DROP FUNCTION IF EXISTS public.delete_user_account();

NOTIFY pgrst, 'reload schema';
