-- FOUND is a PL/pgSQL status variable and must not be schema-qualified.
DO $$
DECLARE
  function_definition text;
BEGIN
  SELECT pg_get_functiondef(p.oid)
  INTO function_definition
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'update_store_with_token'
    AND pg_get_function_identity_arguments(p.oid) =
      'p_slug text, p_edit_token text, p_store jsonb';

  IF function_definition IS NULL THEN
    RAISE EXCEPTION 'UPDATE_STORE_RPC_NOT_FOUND';
  END IF;

  EXECUTE replace(function_definition, 'pg_catalog.found', 'FOUND');
END;
$$;

NOTIFY pgrst, 'reload schema';
