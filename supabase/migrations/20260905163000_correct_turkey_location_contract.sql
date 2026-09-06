-- Vixrex Akıllı Motor 5.9 — canonical Erzurum ilçe sözleşmesi düzeltmesi.
-- İçişleri Bakanlığı'nın güncel ilçe listesine göre Erzurum 20 ilçedir;
-- Narman dahildir, Mamak ve "Merkez" Erzurum ilçesi değildir.

update public.vixrex_turkey_location_contract
set districts = '["Aşkale","Aziziye","Çat","Hınıs","Horasan","İspir","Karaçoban","Karayazı","Köprüköy","Narman","Oltu","Olur","Palandöken","Pasinler","Pazaryolu","Şenkaya","Tekman","Tortum","Uzundere","Yakutiye"]'::jsonb
where province_code = '25'
  and province_name = 'Erzurum';

do $$
begin
  if not exists (
    select 1
    from public.vixrex_turkey_location_contract
    where province_code = '25'
      and province_name = 'Erzurum'
      and jsonb_array_length(districts) = 20
      and districts ? 'Narman'
      and districts ? 'Pasinler'
      and not districts ? 'Mamak'
      and not districts ? 'Merkez'
  ) then
    raise exception 'ERZURUM_LOCATION_CONTRACT_CORRECTION_FAILED';
  end if;
end;
$$;
