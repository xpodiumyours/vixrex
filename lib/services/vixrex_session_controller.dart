import 'package:vixrex/controllers/store_editor_controller.dart';

/// Vixrex Asistan'ın TEK oturumu — uygulama açıkken hangi ekrandan
/// (landing, HomeShell/Vitrinim, HomeShell/Vixrex sekmesi) sohbet açılırsa
/// açılsın aynı [StoreEditorController]'ı paylaşır.
///
/// NEDEN VAR (2026-08-12 bulgusu): Landing'deki kompakt sohbet kendi
/// geçici `StoreEditorController`'ını yaratıyordu; kullanıcı orada isim/
/// WhatsApp/konum yazıp bitirmeden çıkınca ya da ana "Vitrinimi Hazırla"
/// düğmesine geçince, HomeShell tamamen YENİ bir controller ile sıfırdan
/// başlıyordu — girilenler hiçbir yere kaydedilmediği için kayboluyordu.
/// Artık tek controller, ilk açan ekran başlatır, sonrakiler aynısını
/// kullanır — sohbet nereden açılırsa açılsın kaldığı yerden devam eder.
class VixRexSessionController {
  VixRexSessionController._();

  static final StoreEditorController controller = StoreEditorController();

  static Future<void>? _initFuture;

  /// Tek seferlik başlatma. İlk çağıran [initialName]'i belirler; sonraki
  /// çağrılar aynı Future'ı paylaşır (initialize() ikinci kez çalışmaz).
  ///
  /// Controller zaten başlatıldıktan SONRA bir ekran isim getirirse (örn.
  /// landing'deki ayrı isim kutusu, kompakt sohbetten önce doldurulmadıysa)
  /// ve controller'da hâlâ isim yoksa, o isim burada uygulanır — kullanıcının
  /// yazdığı hiçbir şey sessizce atlanmaz.
  static Future<void> ensureInitialized([String? initialName]) async {
    await (_initFuture ??= controller.initialize(initialName));
    final trimmed = initialName?.trim();
    if (trimmed != null &&
        trimmed.isNotEmpty &&
        controller.data.name.trim().isEmpty) {
      controller.setName(trimmed);
    }
  }
}
