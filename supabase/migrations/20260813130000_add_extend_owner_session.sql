-- Sahip oturumunu (owner_sessions) aktif kullanımda kaydırmalı biçimde
-- uzatır — "bankacılık usulü" oturum: kullanıcı aktifken hiç düşmez,
-- gerçekten terk edilirse (aktivite kesilirse) süresi dolar.
--
-- Casper 2026-08-13: sabit, yenilenemeyen 15 dakikalık oturum ürün kararıyla
-- değiştirildi ("dakikalık, demo ürün parçası gibi olmamalı"). Süre
-- UZATILIR, SINIRSIZ yapılmaz — sızan bir bağlantının sonsuza kadar geçerli
-- kalmaması için (oturumu iptal eden bir "çıkış" düğmesi henüz yok).
--
-- Süre penceresi Next.js tarafındaki OWNER_SESSION_TTL_MS ile aynı
-- (30 dakika, public_web/src/lib/ownerSession.ts) — ikisi de değişirse
-- birlikte değişmeli.
--
-- Yalnız hâlâ geçerli (tüketilmiş, süresi henüz dolmamış) bir oturumu
-- uzatır; süresi zaten dolmuş bir tokenla çağrılırsa hiçbir satırı
-- etkilemez — ölü bir oturum "canlandırılamaz", yalnız aktif oturum kayar.
create or replace function public.extend_owner_session(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_token text := pg_catalog.btrim(coalesce(p_session_token, ''));
  v_token_hash text;
  v_expires_at timestamptz;
begin
  if v_token = '' or pg_catalog.length(v_token) <> 64 then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  v_token_hash := encode(sha256(v_token::bytea), 'hex');

  update public.owner_sessions
  set expires_at = now() + interval '30 minutes'
  where session_token_hash = v_token_hash
    and consumed_at is not null
    and expires_at > now()
  returning expires_at into v_expires_at;

  if v_expires_at is null then
    raise exception 'INVALID_SESSION_TOKEN';
  end if;

  return jsonb_build_object('expires_at', v_expires_at);
end;
$$;

revoke execute on function public.extend_owner_session(text) from public;
grant execute on function public.extend_owner_session(text) to anon, authenticated;

notify pgrst, 'reload schema';
