TARİH: 17 Temmuz 2026
BUGÜN YAPILAN: Canlı Supabase’de edit_token okuma izni kapatıldı; vitrin yazma/silme/yayından kaldırma RPC’leri misafir tokenı veya giriş yapmış gerçek sahip kontrolüyle güçlendirildi; geniş randevu ve booking ayarı politikaları kaldırıldı; uygulamadaki token geri alma sorguları temizlendi.
YARIM KALAN: İki ayrı test hesabıyla canlı kabul (A, B’nin vitrinini/randevusunu/ayarını değiştirememeli; kendi vitrini çalışmalı); kullanıcı test hesabı bilgilerini yarın paylaşacak.
SIRADAKİ ADIM: İki test hesabıyla saldırı senaryolarını ve sahip akışını canlıda doğrula; sonra kullanıcı isterse commit oluştur.
DOKUNULAN DOSYALAR: 20260717_close_store_authorization_gap.sql, store_publish_service.dart, store_editor_controller.dart, auth_service.dart, auth_screen.dart, store_repository.dart, supabase_store_repository.dart, store_publish_service_test.dart, store_authorization_contract_test.dart.
DİKKAT: Migration canlıya uygulandı; flutter test ve flutter analyze geçti. Commit/push yok.
