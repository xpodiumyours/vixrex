-- Landing sayfasındaki demo linkleri herkese açıktır. Bu nedenle bu dört
-- pazarlama kaydı bir capability token ile dahi değiştirilemez olmalıdır.
-- Normal kullanıcı taslakları bu kurala dahil değildir; Next.js panelindeki
-- kendi taslağını kaydetme akışı aynen devam eder.

UPDATE public.stores
SET is_demo = true
WHERE slug IN (
  'demo-aymira-giyim',
  'demo-lezzet-duragi',
  'demo-nova-kuafor',
  'demo-teknofix'
)
  AND is_demo IS NOT TRUE;

CREATE OR REPLACE FUNCTION public.prevent_demo_store_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF OLD.is_demo THEN
    RAISE EXCEPTION 'DEMO_STORE_IMMUTABLE' USING ERRCODE = 'P0001';
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_landing_demo_stores ON public.stores;

CREATE TRIGGER protect_landing_demo_stores
BEFORE UPDATE OR DELETE ON public.stores
FOR EACH ROW
EXECUTE FUNCTION public.prevent_demo_store_mutation();

NOTIFY pgrst, 'reload schema';
