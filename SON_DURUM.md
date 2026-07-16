TARİH: 17 Temmuz 2026
BUGÜN YAPILAN: Landing’de sağ alttaki sabit maskot artık route/çekmece açmadan mevcut telefon maketinin içinde Vixrex kurulum sohbetini açıyor; Kapat ile telefon tekrar dönen vitrinlere dönüyor.
YARIM KALAN: Chrome görsel kabul testi; telefon içi sohbetin dar ekrandaki taşma/okunabilirlik kontrolü ve kullanıcı onayı, commit/push yok.
SIRADAKİ ADIM: Chrome hot restart → landing’de maskota bas → telefon içi sohbet aç/kapat → dört vitrin döngüsünün geri geldiğini ekran görüntüsüyle doğrula.
DOKUNULAN DOSYALAR: landing_screen.dart, landing_hero_section.dart, landing_hero_mockup.dart, vixrex_onboarding_chat_screen.dart, widget_test.dart.
DİKKAT: Yeni landing davranışı widget testi geçti; linter hatası yok. Tam widget testindeki eski Keşfet beklentisi kodun Auth yönlendirmesiyle çelişiyor; OpenAI askıda.
