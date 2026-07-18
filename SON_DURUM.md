TARİH: 18 Temmuz 2026
BUGÜN YAPILAN: Public vitrin 404/hata ayrımı ve vitrin silmede uzak işlem başarılı olmadan yerel veriyi koruma commitlendi; hesap silme tek JWT korumalı Edge Function yoluna taşındı ve test sözleşmesi hazırlandı.
YARIM KALAN: Kullanıcının çalıştıracağı yerel test kapıları; hesap silme değişikliklerinin commit/push işlemi; ayrı onayla Edge Function deploy, uygulama yayını ve RPC emeklilik migration'ı; canlı kabul.
SIRADAKİ ADIM: Yerel test sonuçlarını al, başarısızlık yoksa hesap silme paketini commit et; canlıda sırasıyla Edge Function → uygulama → RPC emeklilik migration'ı uygula.
DOKUNULAN DOSYALAR: public_web vitrin sayfası/error/test; store publish/controller/testleri; delete-user-account Edge Function; AuthService ve SupabaseAuthRepository; iki ileri migration; hesap silme sözleşme testi.
DİKKAT: Canlı işlem yapılmadı. RPC emeklilik migration'ı Edge Function ve yeni uygulama yayınlanmadan uygulanmaz; Android imza, public vitrin tek sahipliği ve mevcut mobil akış korunur.
