-- Vixrex Akıllı Motor 5.9 — GPS/location special-flow coupled transaction.
-- Dev Supabase proof version: 20260905154433.
-- Production rollout remains blocked until 5.10/general check-up.

create table if not exists public.vixrex_turkey_location_contract (
  province_code text primary key check (province_code ~ '^[0-9]{2}$'),
  province_name text not null unique,
  districts jsonb not null check (jsonb_typeof(districts) = 'array')
);

alter table public.vixrex_turkey_location_contract enable row level security;
revoke all on table public.vixrex_turkey_location_contract from public, anon, authenticated;

insert into public.vixrex_turkey_location_contract(province_code, province_name, districts) values
('01','Adana','["Aladağ","Ceyhan","Çukurova","Feke","İmamoğlu","Karaisalı","Karataş","Kozan","Pozantı","Saimbeyli","Sarıçam","Tufanbeyli","Yumurtalık","Yüreğir"]'::jsonb),
('02','Adıyaman','["Besni","Çelikhan","Gerger","Gölbaşı","Kahta","Merkez","Samsat","Sincik","Tut"]'::jsonb),
('03','Afyonkarahisar','["Başmakçı","Bayat","Bolvadin","Çay","Çobanlar","Dazkırı","Dinar","Emirdağ","Evciler","Hocalar","İhsaniye","İscehisar","Merkez","Sandıklı","Sinanpaşa","Sultandağı","Şuhut","Kızılören"]'::jsonb),
('04','Ağrı','["Diyadin","Doğubayazıt","Eleşkirt","Hamur","Merkez","Patnos","Taşlıçay","Tutak"]'::jsonb),
('05','Amasya','["Göynücek","Gümüşhacıköy","Hamamözü","Merkez","Merzifon","Suluova","Taşova"]'::jsonb),
('06','Ankara','["Akyurt","Altındağ","Ayaş","Bala","Beypazarı","Çamlıdere","Çankaya","Çubuk","Elmadağ","Etimesgut","Evren","Gölbaşı","Güdül","Haymana","Kahramankazan","Kalecik","Keçiören","Kızılcahamam","Mamak","Nallıhan","Polatlı","Pursaklar","Sincan","Şereflikoçhisar","Yenimahalle"]'::jsonb),
('07','Antalya','["Akseki","Aksu","Alanya","Demre","Döşemealtı","Elmalı","Finike","Gazipaşa","Gündoğmuş","İbradı","Kaş","Kemer","Kepez","Konyaaltı","Korkuteli","Kumluca","Manavgat","Muratpaşa","Serik"]'::jsonb),
('08','Artvin','["Ardanuç","Arhavi","Borçka","Hopa","Merkez","Murgul","Şavşat","Yusufeli","Kemalpaşa"]'::jsonb),
('09','Aydın','["Bozdoğan","Buharkent","Çine","Didim","Efeler","Germencik","İncirliova","Karacasu","Karpuzlu","Koçarlı","Köşk","Kuşadası","Kuyucak","Nazilli","Söke","Sultanhisar","Yenipazar"]'::jsonb),
('10','Balıkesir','["Altıeylül","Ayvalık","Balya","Bandırma","Bigadiç","Burhaniye","Dursunbey","Edremit","Erdek","Gömeç","Gönen","Havran","İvrindi","Karesi","Kepsut","Manyas","Marmara","Savaştepe","Sındırgı","Susurluk"]'::jsonb),
('11','Bilecik','["Bozüyük","Gölpazarı","İnhisar","Merkez","Osmaneli","Pazaryeri","Söğüt","Yenipazar"]'::jsonb),
('12','Bingöl','["Adaklı","Genç","Karlıova","Kiğı","Merkez","Solhan","Yayladere","Yedisu"]'::jsonb),
('13','Bitlis','["Adilcevaz","Ahlat","Güroymak","Hizan","Merkez","Mutki","Tatvan"]'::jsonb),
('14','Bolu','["Dörtdivan","Gerede","Göynük","Kıbrıscık","Mengen","Merkez","Mudurnu","Seben","Yeniçağa"]'::jsonb),
('15','Burdur','["Ağlasun","Altınyayla","Bucak","Çavdır","Çeltikçi","Gölhisar","Karamanlı","Kemer","Merkez","Tefenni","Yeşilova"]'::jsonb),
('16','Bursa','["Büyükorhan","Gemlik","Gürsu","Harmancık","İnegöl","İznik","Karacabey","Keles","Kestel","Mudanya","Mustafakemalpaşa","Nilüfer","Orhaneli","Orhangazi","Osmangazi","Yenişehir","Yıldırım"]'::jsonb),
('17','Çanakkale','["Ayvacık","Bayramiç","Biga","Bozcaada","Çan","Eceabat","Ezine","Gelibolu","Gökçeada","Lapseki","Merkez","Yenice"]'::jsonb),
('18','Çankırı','["Atkaracalar","Bayramören","Çerkeş","Eldivan","Ilgaz","Kızılırmak","Korgun","Kurşunlu","Merkez","Orta","Şabanözü","Yapraklı"]'::jsonb),
('19','Çorum','["Alaca","Bayat","Boğazkale","Dodurga","İskilip","Kargı","Laçin","Mecitözü","Merkez","Oğuzlar","Ortaköy","Osmancık","Sungurlu","Uğurludağ"]'::jsonb),
('20','Denizli','["Acıpayam","Babadağ","Baklan","Bekilli","Beyağaç","Bozkurt","Buldan","Çal","Çameli","Çardak","Çivril","Güney","Honaz","Kale","Merkezefendi","Pamukkale","Sarayköy","Serinhisar","Tavas"]'::jsonb),
('21','Diyarbakır','["Bağlar","Bismil","Çermik","Çınar","Çüngüş","Dicle","Eğil","Ergani","Hani","Hazro","Kayapınar","Kocaköy","Kulp","Lice","Silvan","Sur","Yenişehir"]'::jsonb),
('22','Edirne','["Enez","Havsa","İpsala","Keşan","Lalapaşa","Meriç","Merkez","Süloğlu","Uzunköprü"]'::jsonb),
('23','Elazığ','["Ağın","Alacakaya","Arıcak","Baskil","Karakoçan","Keban","Kovancılar","Maden","Merkez","Palu","Sivrice"]'::jsonb),
('24','Erzincan','["Çayırlı","İliç","Kemah","Kemaliye","Merkez","Otlukbeli","Refahiye","Tercan","Üzümlü"]'::jsonb),
('25','Erzurum','["Aşkale","Aziziye","Çat","Hınıs","Horasan","İspir","Karaçoban","Karayazı","Köprüköy","Mamak","Merkez","Oltu","Olur","Palandöken","Pasinler","Pazaryolu","Şenkaya","Tekman","Tortum","Uzundere","Yakutiye"]'::jsonb),
('26','Eskişehir','["Alpu","Beylikova","Çifteler","Günyüzü","Han","İnönü","Mahmudiye","Mihalgazi","Mihalıççık","Odunpazarı","Sarıcakaya","Seyitgazi","Sivrihisar","Tepebaşı"]'::jsonb),
('27','Gaziantep','["Araban","İslahiye","Karkamış","Nizip","Nurdağı","Oğuzeli","Şahinbey","Şehitkamil","Yavuzeli"]'::jsonb),
('28','Giresun','["Alucra","Bulancak","Çamoluk","Çanakçı","Dereli","Doğankent","Espiye","Eynesil","Görele","Güce","Keşap","Merkez","Piraziz","Şebinkarahisar","Tirebolu","Yağlıdere"]'::jsonb),
('29','Gümüşhane','["Kelkit","Köse","Merkez","Kürtün","Şiran","Torul"]'::jsonb),
('30','Hakkari','["Çukurca","Derecik","Merkez","Şemdinli","Yüksekova"]'::jsonb),
('31','Hatay','["Altınözü","Antakya","Arsuz","Belen","Defne","Dörtyol","Erzin","Hassa","İskenderun","Kırıkhan","Kumlu","Payas","Reyhanlı","Samandağ","Yayladağı"]'::jsonb),
('32','Isparta','["Aksu","Atabey","Eğirdir","Gelendost","Gönen","Keçiborlu","Merkez","Senirkent","Sütçüler","Şarkikaraağaç","Uluborlu","Yalvaç","Yenişarbademli"]'::jsonb),
('33','Mersin','["Anamur","Aydıncık","Bozyazı","Çamlıyayla","Erdemli","Gülnar","Akdeniz","Mezitli","Toroslar","Yenişehir","Mut","Silifke","Tarsus"]'::jsonb),
('34','İstanbul','["Adalar","Arnavutköy","Ataşehir","Avcılar","Bağcılar","Bahçelievler","Bakırköy","Başakşehir","Bayrampaşa","Beşiktaş","Beykoz","Beylikdüzü","Beyoğlu","Büyükçekmece","Çatalca","Çekmeköy","Esenler","Esenyurt","Eyüpsultan","Fatih","Gaziosmanpaşa","Güngören","Kadıköy","Kağıthane","Kartal","Küçükçekmece","Maltepe","Pendik","Sancaktepe","Sarıyer","Silivri","Sultanbeyli","Sultangazi","Şile","Şişli","Tuzla","Ümraniye","Üsküdar","Zeytinburnu"]'::jsonb),
('35','İzmir','["Aliağa","Balçova","Bayındır","Bayraklı","Bergama","Beydağ","Bornova","Buca","Çeşme","Çiğli","Dikili","Foça","Gaziemir","Güzelbahçe","Karabağlar","Karaburun","Karşıyaka","Kemalpaşa","Kınık","Kiraz","Konak","Menderes","Menemen","Narlıdere","Ödemiş","Seferihisar","Selçuk","Tire","Torbalı","Urla"]'::jsonb),
('36','Kars','["Akyaka","Arpaçay","Digor","Kağızman","Merkez","Sarıkamış","Selim","Susuz"]'::jsonb),
('37','Kastamonu','["Abana","Ağlı","Araç","Azdavay","Bozkurt","Cide","Çatalzeytin","Daday","Devrekani","Doğanyurt","Hanönü","İhsangazi","İnebolu","Merkez","Pınarbaşı","Seydiler","Şenpazar","Taşköprü","Tosya","Küre"]'::jsonb),
('38','Kayseri','["Akkışla","Bünyan","Develi","Felahiye","Hacılar","İncesu","Kocasinan","Melikgazi","Özvatan","Pınarbaşı","Sarıoğlan","Sarız","Talas","Tomarza","Yahyalı","Yeşilhisar"]'::jsonb),
('39','Kırklareli','["Babaeski","Demirköy","Kofçaz","Lüleburgaz","Merkez","Pehlivanköy","Pınarhisar","Vize"]'::jsonb),
('40','Kırşehir','["Akçakent","Akpınar","Boztepe","Çiçekdağı","Kaman","Merkez","Mucur"]'::jsonb),
('41','Kocaeli','["Başiskele","Çayırova","Darıca","Derince","Dilovası","Gebze","Gölcük","İzmit","Kandıra","Karamürsel","Kartepe","Körfez"]'::jsonb),
('42','Konya','["Ahırlı","Akören","Akşehir","Altınekin","Beyşehir","Bozkır","Cihanbeyli","Çeltik","Çumra","Derbent","Derebucak","Doğanhisar","Emirgazi","Ereğli","Güneysınır","Hadim","Halkapınar","Hüyük","Ilgın","Kadınhanı","Karapınar","Karatay","Kulu","Meram","Sarayönü","Selçuklu","Seydişehir","Taşkent","Tuzlukçu","Yalıhüyük","Yunak"]'::jsonb),
('43','Kütahya','["Altıntaş","Aslanapa","Çavdarhisar","Domaniç","Dumlupınar","Emet","Gediz","Hisarcık","Merkez","Pazarlar","Şaphane","Simav","Tavşanlı"]'::jsonb),
('44','Malatya','["Akçadağ","Arapgir","Arguvan","Battalgazi","Darende","Doğanşehir","Doğanyol","Hekimhan","Kale","Kuluncak","Pütürge","Yazıhan","Yeşilyurt"]'::jsonb),
('45','Manisa','["Ahmetli","Akhisar","Alaşehir","Demirci","Gölmarmara","Gördes","Kırkağaç","Köprübaşı","Kula","Salihli","Sarıgöl","Saruhanlı","Selendi","Soma","Şehzadeler","Turgutlu","Yunusemre"]'::jsonb),
('46','Kahramanmaraş','["Afşin","Andırın","Çağlayancerit","Dulkadiroğlu","Ekinözü","Elbistan","Göksun","Onikişubat","Nurhak","Pazarcık","Türkoğlu"]'::jsonb),
('47','Mardin','["Artuklu","Dargeçit","Derik","Kızıltepe","Mazıdağı","Midyat","Nusaybin","Ömerli","Savur","Yeşilli"]'::jsonb),
('48','Muğla','["Bodrum","Dalaman","Datça","Fethiye","Kavaklıdere","Köyceğiz","Marmaris","Menteşe","Milas","Ortaca","Seydikemer","Ula","Yatağan"]'::jsonb),
('49','Muş','["Bulanık","Hasköy","Korkut","Merkez","Malazgirt","Varto"]'::jsonb),
('50','Nevşehir','["Acıgöl","Avanos","Derinkuyu","Gülşehir","Hacıbektaş","Kozaklı","Merkez","Ürgüp"]'::jsonb),
('51','Niğde','["Altunhisar","Bor","Çamardı","Çiftlik","Merkez","Ulukışla"]'::jsonb),
('52','Ordu','["Akkuş","Altınordu","Aybastı","Çamaş","Çatalpınar","Çaybaşı","Fatsa","Gölköy","Gülyalı","Gürgentepe","İkizce","Kabadüz","Kabataş","Korgan","Kumru","Mesudiye","Perşembe","Ulubey","Ünye"]'::jsonb),
('53','Rize','["Ardeşen","Çamlıhemşin","Çayeli","Derepazarı","Fındıklı","Güneysu","Hemşin","İkizdere","İyidere","Kalkandere","Merkez","Pazar"]'::jsonb),
('54','Sakarya','["Adapazarı","Akyazı","Arifiye","Erenler","Ferizli","Geyve","Hendek","Karapürçek","Karasu","Kaynarca","Kocaali","Pamukova","Sapanca","Serdivan","Söğütlü","Taraklı"]'::jsonb),
('55','Samsun','["19 Mayıs","Alaçam","Asarcık","Atakum","Ayvacık","Bafra","Canik","Çarşamba","Havza","Kavak","Ladik","Salıpazarı","İlkadım","Tekkeköy","Terme","Vezirköprü","Yakakent"]'::jsonb),
('56','Siirt','["Baykan","Eruh","Kurtalan","Merkez","Pervari","Şirvan","Tillo"]'::jsonb),
('57','Sinop','["Ayancık","Boyabat","Dikmen","Durağan","Erfelek","Gerze","Merkez","Saraydüzü","Türkeli"]'::jsonb),
('58','Sivas','["Akıncılar","Altınyayla","Divriği","Doğanşar","Gemerek","Gölova","Hafik","İmranlı","Kangal","Koyulhisar","Merkez","Suşehri","Şarkışla","Ulaş","Yıldızeli","Zara","Gürün"]'::jsonb),
('59','Tekirdağ','["Çerkezköy","Çorlu","Ergene","Hayrabolu","Kapaklı","Malkara","Marmaraereğlisi","Muratlı","Süleymanpaşa","Saray","Şarköy"]'::jsonb),
('60','Tokat','["Almus","Artova","Başçiftlik","Erbaa","Merkez","Niksar","Pazar","Reşadiye","Sulusaray","Turhal","Yeşilyurt","Zile"]'::jsonb),
('61','Trabzon','["Akçaabat","Araklı","Arsin","Beşikdüzü","Çarşıbaşı","Çaykara","Dernekpazarı","Düzköy","Hayrat","Köprübaşı","Maçka","Of","Ortahisar","Sürmene","Şalpazarı","Tonya","Vakfıkebir","Yomra"]'::jsonb),
('62','Tunceli','["Çemişgezek","Hozat","Mazgirt","Merkez","Nazımiye","Ovacık","Pertek","Pülümür"]'::jsonb),
('63','Şanlıurfa','["Akçakale","Birecik","Bozova","Ceylanpınar","Eyyübiye","Halfeti","Haliliye","Harran","Hilvan","Karaköprü","Siverek","Suruç","Viranşehir"]'::jsonb),
('64','Uşak','["Banaz","Eşme","Karahallı","Merkez","Sivaslı","Ulubey"]'::jsonb),
('65','Van','["Bahçesaray","Başkale","Çaldıran","Çatak","Edremit","Erciş","Gevaş","Gürpınar","İpekyolu","Muradiye","Özalp","Saray","Tuşba"]'::jsonb),
('66','Yozgat','["Akdağmadeni","Aydıncık","Boğazlıyan","Çandır","Çayıralan","Çekerek","Kadışehri","Merkez","Saraykent","Sarıkaya","Sorgun","Şefaatli","Yenifakılı","Yerköy"]'::jsonb),
('67','Zonguldak','["Alaplı","Çaycuma","Devrek","Gökçebey","Karadeniz Ereğli","Kilimli","Kozlu","Merkez"]'::jsonb),
('68','Aksaray','["Ağaçören","Eskil","Gülağaç","Güzelyurt","Merkez","Ortaköy","Sarıyahşi","Sultanhanı"]'::jsonb),
('69','Bayburt','["Aydıntepe","Demirözü","Merkez"]'::jsonb),
('70','Karaman','["Ayrancı","Başyayla","Ermenek","Merkez","Kazımkarabekir","Sarıveliler"]'::jsonb),
('71','Kırıkkale','["Bahşılı","Balışeyh","Çelebi","Delice","Karakeçili","Keskin","Merkez","Yahşihan","Sulakyurt"]'::jsonb),
('72','Batman','["Beşiri","Gercüş","Hasankeyf","Kozluk","Merkez","Sason"]'::jsonb),
('73','Şırnak','["Beytüşşebap","Cizre","Güçlükonak","İdil","Merkez","Silopi","Uludere"]'::jsonb),
('74','Bartın','["Amasra","Kurucaşile","Merkez","Ulus"]'::jsonb),
('75','Ardahan','["Çıldır","Damal","Göle","Hanak","Merkez","Posof"]'::jsonb),
('76','Iğdır','["Aralık","Karakoyunlu","Merkez","Tuzluca"]'::jsonb),
('77','Yalova','["Altınova","Armutlu","Çiftlikköy","Çınarcık","Merkez","Termal"]'::jsonb),
('78','Karabük','["Eflani","Eskipazar","Merkez","Ovacık","Safranbolu","Yenice"]'::jsonb),
('79','Kilis','["Elbeyli","Merkez","Musabeyli","Polateli"]'::jsonb),
('80','Osmaniye','["Bahçe","Düziçi","Hasanbeyli","Kadirli","Merkez","Sumbas","Toprakkale"]'::jsonb),
('81','Düzce','["Akçakoca","Cumayeri","Çilimli","Gölyaka","Gümüşova","Kaynaşlı","Merkez","Yığılca"]'::jsonb)
on conflict (province_code) do update set province_name=excluded.province_name, districts=excluded.districts;

create unique index if not exists ux_audit_logs_smart_engine_location_command
on public.audit_logs (target_id, ((metadata ->> 'command_id')))
where action = 'smart_engine_location_bundle' and metadata ? 'command_id';

create or replace function public.vixrex_apply_location_bundle(
  p_session_token text,
  p_latitude double precision,
  p_longitude double precision,
  p_address text,
  p_province_code text,
  p_province_name text,
  p_district_name text,
  p_expected_draft_version bigint,
  p_command_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_store_id uuid;
  v_store_user_id uuid;
  v_session_id uuid;
  v_is_demo boolean;
  v_token_hash text;
  v_draft_data jsonb;
  v_current_version bigint;
  v_new_version bigint;
  v_old_bundle jsonb;
  v_new_bundle jsonb;
  v_receipt public.audit_logs%rowtype;
  v_lat_contract jsonb;
  v_lon_contract jsonb;
  v_address_contract jsonb;
  v_province_contract jsonb;
  v_district_contract jsonb;
  v_lat_col text;
  v_lon_col text;
  v_address_col text;
  v_province_col text;
  v_district_col text;
  v_command_text text := p_command_id::text;
begin
  if p_command_id is null or p_expected_draft_version is null then
    raise exception 'INVALID_LOCATION_PRECONDITION' using errcode='P0001';
  end if;

  if not coalesce((select is_enabled from public.feature_flags where flag_key='vixrex_smart_engine_enabled'), false)
     or not coalesce((select is_enabled from public.feature_flags where flag_key='vixrex_smart_engine_storefront_enabled'), false) then
    raise exception 'SMART_ENGINE_DISABLED' using errcode='P0001';
  end if;

  if p_latitude is null or p_latitude < -90 or p_latitude > 90
     or p_longitude is null or p_longitude < -180 or p_longitude > 180 then
    raise exception 'INVALID_LOCATION_COORDINATES' using errcode='P0001';
  end if;

  if nullif(pg_catalog.btrim(coalesce(p_address, '')), '') is null then
    raise exception 'INVALID_LOCATION_ADDRESS' using errcode='P0001';
  end if;

  if not exists (
    select 1
    from public.vixrex_turkey_location_contract c
    where c.province_code = pg_catalog.btrim(p_province_code)
      and c.province_name = pg_catalog.btrim(p_province_name)
      and c.districts ? pg_catalog.btrim(p_district_name)
  ) then
    raise exception 'INVALID_LOCATION_RELATION' using errcode='P0001';
  end if;

  v_lat_contract := public.vixrex_storefront_field_contract('enlem');
  v_lon_contract := public.vixrex_storefront_field_contract('boylam');
  v_address_contract := public.vixrex_storefront_field_contract('adres');
  v_province_contract := public.vixrex_storefront_field_contract('il');
  v_district_contract := public.vixrex_storefront_field_contract('ilce');

  if v_lat_contract is null or v_lon_contract is null or v_address_contract is null
     or v_province_contract is null or v_district_contract is null then
    raise exception 'LOCATION_CONTRACT_MISSING' using errcode='P0001';
  end if;

  if not public.vixrex_validate_storefront_value(v_lat_contract, to_jsonb(p_latitude))
     or not public.vixrex_validate_storefront_value(v_lon_contract, to_jsonb(p_longitude))
     or not public.vixrex_validate_storefront_value(v_address_contract, to_jsonb(pg_catalog.btrim(p_address)))
     or not public.vixrex_validate_storefront_value(v_province_contract, to_jsonb(pg_catalog.btrim(p_province_name)))
     or not public.vixrex_validate_storefront_value(v_district_contract, to_jsonb(pg_catalog.btrim(p_district_name))) then
    raise exception 'INVALID_LOCATION_VALUE' using errcode='P0001';
  end if;

  if nullif(pg_catalog.btrim(coalesce(p_session_token, '')), '') is not null then
    if length(pg_catalog.btrim(p_session_token)) <> 64 then
      raise exception 'INVALID_SESSION_TOKEN' using errcode='P0001';
    end if;
    v_token_hash := encode(extensions.digest(pg_catalog.btrim(p_session_token)::bytea, 'sha256'), 'hex');
    select os.store_id, os.id, s.user_id, s.is_demo
      into v_store_id, v_session_id, v_store_user_id, v_is_demo
    from public.owner_sessions os
    join public.stores s on s.id = os.store_id
    where os.session_token_hash = v_token_hash
      and os.consumed_at is not null
      and os.expires_at > now();
    if v_store_id is null then
      raise exception 'INVALID_SESSION_TOKEN' using errcode='P0001';
    end if;
  else
    if v_user_id is null or not public.is_permanent_user() then
      raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode='P0001';
    end if;
    select id, user_id, is_demo
      into v_store_id, v_store_user_id, v_is_demo
    from public.stores
    where user_id = v_user_id
    order by created_at asc
    limit 1;
    if v_store_id is null then
      raise exception 'OWNER_AUTHORIZATION_REQUIRED' using errcode='P0001';
    end if;
  end if;

  if v_is_demo then
    raise exception 'DEMO_STORE_IMMUTABLE' using errcode='P0001';
  end if;

  v_lat_col := v_lat_contract ->> 'column';
  v_lon_col := v_lon_contract ->> 'column';
  v_address_col := v_address_contract ->> 'column';
  v_province_col := v_province_contract ->> 'column';
  v_district_col := v_district_contract ->> 'column';

  select draft_data, draft_version
    into v_draft_data, v_current_version
  from public.store_working_drafts
  where store_id = v_store_id
  for update;

  if not found then
    raise exception 'WORKING_DRAFT_NOT_FOUND' using errcode='P0001';
  end if;

  v_new_bundle := jsonb_build_object(
    'enlem', p_latitude,
    'boylam', p_longitude,
    'adres', pg_catalog.btrim(p_address),
    'il', pg_catalog.btrim(p_province_name),
    'ilce', pg_catalog.btrim(p_district_name),
    'province_code', pg_catalog.btrim(p_province_code)
  );

  select * into v_receipt
  from public.audit_logs
  where action='smart_engine_location_bundle'
    and target_id=v_store_id::text
    and metadata ->> 'command_id'=v_command_text
  limit 1;

  if found then
    if coalesce(v_receipt.new_value, 'null'::jsonb) is distinct from v_new_bundle then
      raise exception 'IDEMPOTENCY_KEY_REUSE' using errcode='P0001';
    end if;
    return jsonb_build_object(
      'ok', true,
      'replayed', true,
      'store_id', v_store_id,
      'command_id', p_command_id,
      'draft_version', (v_receipt.metadata ->> 'result_draft_version')::bigint,
      'location', v_new_bundle
    );
  end if;

  if v_current_version <> p_expected_draft_version then
    raise exception 'DRAFT_VERSION_CONFLICT' using errcode='P0001';
  end if;

  v_old_bundle := jsonb_build_object(
    'enlem', coalesce(v_draft_data -> v_lat_col, 'null'::jsonb),
    'boylam', coalesce(v_draft_data -> v_lon_col, 'null'::jsonb),
    'adres', coalesce(v_draft_data -> v_address_col, 'null'::jsonb),
    'il', coalesce(v_draft_data -> v_province_col, 'null'::jsonb),
    'ilce', coalesce(v_draft_data -> v_district_col, 'null'::jsonb)
  );

  update public.store_working_drafts
  set draft_data = draft_data
        || jsonb_build_object(v_lat_col, to_jsonb(p_latitude))
        || jsonb_build_object(v_lon_col, to_jsonb(p_longitude))
        || jsonb_build_object(v_address_col, to_jsonb(pg_catalog.btrim(p_address)))
        || jsonb_build_object(v_province_col, to_jsonb(pg_catalog.btrim(p_province_name)))
        || jsonb_build_object(v_district_col, to_jsonb(pg_catalog.btrim(p_district_name))),
      draft_version = draft_version + 1,
      updated_at = now()
  where store_id = v_store_id
  returning draft_version into v_new_version;

  insert into public.audit_logs(
    user_id, session_id, action, target_type, target_id, old_value, new_value, metadata
  ) values (
    coalesce(v_user_id, v_store_user_id),
    v_session_id::text,
    'smart_engine_location_bundle',
    'store_working_draft',
    v_store_id::text,
    v_old_bundle,
    v_new_bundle,
    jsonb_build_object(
      'command_id', v_command_text,
      'domain', 'storefront',
      'source', 'smart_engine',
      'special_flow', 'location_bundle',
      'result_draft_version', v_new_version
    )
  );

  return jsonb_build_object(
    'ok', true,
    'replayed', false,
    'store_id', v_store_id,
    'command_id', p_command_id,
    'draft_version', v_new_version,
    'location', v_new_bundle
  );
end;
$$;

revoke all on function public.vixrex_apply_location_bundle(text,double precision,double precision,text,text,text,text,bigint,uuid) from public, anon;
grant execute on function public.vixrex_apply_location_bundle(text,double precision,double precision,text,text,text,text,bigint,uuid) to authenticated, service_role;
