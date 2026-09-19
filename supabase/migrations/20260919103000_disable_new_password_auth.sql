-- Vixrex kalıcı hesap politikası: şifreli hesap açma/yazma kapalı.
-- 14 günlük kiralık vitrin denemesi anonim/misafir olarak çalışmaya devam eder.
-- Google OAuth kullanıcılarında encrypted_password boş olduğu için etkilenmez.
-- Mevcut iki legacy password kullanıcısına dokunmaz; yeni password hash
-- oluşturulmasını ve mevcut hesaba yeni password eklenmesini engeller.

begin;

create or replace function public.reject_vixrex_password_auth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(new.encrypted_password, '') <> '' then
    raise exception 'VIXREX_PASSWORD_AUTH_DISABLED'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.reject_vixrex_password_auth() from public;
revoke all on function public.reject_vixrex_password_auth() from anon;
revoke all on function public.reject_vixrex_password_auth() from authenticated;

drop trigger if exists vixrex_no_password_auth on auth.users;
create trigger vixrex_no_password_auth
before insert or update of encrypted_password on auth.users
for each row
execute function public.reject_vixrex_password_auth();

comment on function public.reject_vixrex_password_auth() is
  'Vixrex kalıcı hesapları Google-only tutar; anonim deneme hesapları password hash taşımadığı için etkilenmez.';

commit;
