-- The three-argument rate limiter mutates shared counters and must only be
-- callable from trusted server code. Direct anon access lets a caller exhaust
-- another store's known counter key and deny service to its owner.
begin;

revoke all on function public.consume_assistant_request(text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.consume_assistant_request(text, integer, integer)
  to service_role;

comment on function public.consume_assistant_request(text, integer, integer) is
  'Server-only shared rate limiter. Direct Data API execution is restricted to service_role.';

commit;
