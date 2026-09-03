import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/assistant_handoff.dart';
import 'package:vixrex/services/auth_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/utils/address_validator.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

/// Kurulum sohbetinin adım makinesi.
///
/// Faz D (Tek Asistan planı): `vixrex_onboarding_chat_screen.dart`'ın adım
/// geçişleri, girdi doğrulaması ve kaydetme çağrıları buraya taşındı.
/// Plan kuralı: bu sınıf **widget bilmez** — `BuildContext`, `Navigator`,
/// `ScaffoldMessenger` almaz. Ekrana yalnız `onBotMessage`/`onUserMessage`
/// geri çağrıları üzerinden konuşur, adım/hata/meşguliyet değişince
/// `notifyListeners()` çağırır — `StoreEditorController`/`MyVitrinState` ile
/// aynı `ChangeNotifier` deseni.
///
/// Sohbet satırlarının kendisi (`_lines`, kaydırma, render) ekranda kalır —
/// bu, `ListView` ve `ScrollController`'a bağlı sunum durumu, iş kuralı
/// değil. `onPersistTranscript` bu yüzden dışarıdan enjekte edilir: geçmişi
/// depoya yazmak ekranın transkript listesine bakmayı gerektirir.
enum VixRexOnboardingStep {
  welcome,

  /// "Hazır Vitrin Seç"ten gelen niyet sorusu (Web C1 paritesi, 2026-09-03).
  /// Sıfırdan-yolundaki [category] adımından FARKLI: profil kategorisini
  /// değil, Keşfet ön-filtresini seçer; editöre hiçbir şey yazmaz.
  templateNiyet,
  name,
  category,
  whatsapp,
  location,
  legal,
  publishing,
  done,
}

class VixRexOnboardingController extends ChangeNotifier {
  VixRexOnboardingController({
    required StoreEditorController editorController,
    required void Function(String text, {String? publicLink}) onBotMessage,
    required void Function(String text) onUserMessage,
    required Future<void> Function() onPersistTranscript,
    void Function()? onRequestFocus,
    void Function(String? kategoriEtiketi)? onChooseReadyTemplate,
  }) : _editor = editorController,
       _onBotMessage = onBotMessage,
       _onUserMessage = onUserMessage,
       _onPersistTranscript = onPersistTranscript,
       _onRequestFocus = onRequestFocus,
       _onChooseReadyTemplate = onChooseReadyTemplate;

  String _katalogMesaji(String mesaj) =>
      '${vixRexMesajlari['${mesaj}_baslik']}\n'
      '${vixRexMesajlari['${mesaj}_aciklama']}';

  String _akisMesaji(String id) {
    final adim = vixRexAsistanAkisi.firstWhere((adim) => adim.id == id);
    return _katalogMesaji(adim.mesaj);
  }

  final StoreEditorController _editor;
  final void Function(String text, {String? publicLink}) _onBotMessage;
  final void Function(String text) _onUserMessage;
  final Future<void> Function() _onPersistTranscript;
  final void Function()? _onRequestFocus;
  // Bu sınıf widget bilmez (yukarıdaki sınıf yorumu) — "Hazır Vitrin Seç"
  // ekranına gitmek bir Navigator çağrısı gerektirir, o yüzden burada
  // NAVİGE ETMEYİZ, yalnız ekrana haber veririz. Ekran (screen) bunu
  // AppRouter.pushReadyTemplatePicker ile karşılar. Seçilen kategori
  // etiketi (ızgara/free-text çözümünden) parametreyle taşınır; null ise
  // Keşfet süzgeçsiz açılır.
  final void Function(String? kategoriEtiketi)? _onChooseReadyTemplate;

  bool _disposed = false;

  VixRexOnboardingStep _step = VixRexOnboardingStep.welcome;
  VixRexOnboardingStep get step => _step;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  String? _publicLink;
  String? get publicLink => _publicLink;

  String? get repairedPublicLink {
    final raw = _publicLink?.trim() ?? '';
    if (raw.isEmpty) return null;
    return PublicSiteConfig.repairPublicLink(raw);
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── Açılış ────────────────────────────────────────────────────────────

  Future<void> bootstrap({
    required Future<void>? sharedInitialization,
    required bool ownsController,
    required String? initialName,
  }) async {
    if (sharedInitialization != null) {
      await sharedInitialization;
    } else if (ownsController) {
      await _editor.initialize(initialName);
    }
    if (_disposed) return;
    // Kayıtlı ilerleme var mı? Diskten AYRI bir okuma yapmaz —
    // editor'ün o anki hafızasına bakar. Böylece hem eski bir oturumdan
    // hem de aynı uygulama açıkken başka bir ekrandan gelen ilerleme de
    // doğru yakalanır (2026-08-12 bulgusu, tek oturum).
    final hasSavedVitrin = _editor.data.name.trim().isNotEmpty;
    if (hasSavedVitrin) {
      _resumeSavedVitrin();
      return;
    }
    _onBotMessage(_katalogMesaji('welcome'));
    _notify();
  }

  void _resumeSavedVitrin() {
    final snapshot = VixRexProfileSnapshot.from(
      _editor.data,
      _editor.publishedInfo,
    );
    final storeName = snapshot.storeName;

    _onBotMessage(
      'Tekrar hoş geldin, $storeName.\n\n'
      'Kayıtlı vitrinin bulundu. Yeni bir vitrin oluşturmuyoruz; '
      'kaldığın yerden devam ediyoruz.',
    );

    switch (snapshot.nextMissingField) {
      case VixRexNextStep.name:
        _step = VixRexOnboardingStep.name;
        _onBotMessage(_akisMesaji('name'));
        _onRequestFocus?.call();
      case VixRexNextStep.category:
        _step = VixRexOnboardingStep.category;
        _onBotMessage(_akisMesaji('category'));
      case VixRexNextStep.whatsapp:
        _step = VixRexOnboardingStep.whatsapp;
        _onBotMessage(_akisMesaji('whatsapp'));
        _onRequestFocus?.call();
      case VixRexNextStep.address:
        _step = VixRexOnboardingStep.location;
        _onBotMessage(_akisMesaji('location'));
      case VixRexNextStep.legal:
        _step = VixRexOnboardingStep.legal;
        _onBotMessage(_akisMesaji('legal'));
      case VixRexNextStep.publish:
        _step = VixRexOnboardingStep.legal;
        _onBotMessage(_akisMesaji('publish'));
      case VixRexNextStep.share:
        _publicLink = snapshot.publicLink;
        _step = VixRexOnboardingStep.done;
        _onBotMessage(
          'Vitrinin yayında. Şimdi görünümünü ve ürünlerini geliştirmeye '
          'devam edebiliriz.',
          publicLink: repairedPublicLink,
        );
    }
    _notify();
  }

  // ── Karşılama ─────────────────────────────────────────────────────────

  /// "Sıfırdan Oluştur" — eski tek yol, adı değişti ama davranışı aynı.
  Future<void> chooseScratch() async {
    _onUserMessage('Sıfırdan oluşturalım');
    _error = null;
    _notify();

    final existingName = _editor.data.name.trim();
    if (existingName.length >= 2) {
      _onUserMessage(existingName);
      _step = VixRexOnboardingStep.whatsapp;
      _notify();
      _onBotMessage(_akisMesaji('whatsapp'));
      _onRequestFocus?.call();
      return;
    }

    _step = VixRexOnboardingStep.name;
    _notify();
    _onBotMessage(_akisMesaji('name'));
    _onRequestFocus?.call();
  }

  /// "Hazır Vitrin Seç" — niyet sorusu adımını açar (Web C1 paritesi).
  /// Eskiden adım değişmeden Keşfet'e geçiliyordu; artık soru önce
  /// sorulur: ekran ızgara + serbest metin + geri çizer. Keşfet'e geçiş,
  /// kategori seçilince ([selectTemplateCategory]) ya da serbest metin
  /// gönderilince ([submitTemplateFreeText]) olur. Kiralama tamamlanınca
  /// kullanıcı zaten tarayıcıya geçip Vixrex Asistan'da devam ediyor
  /// (bkz. AppRouter.navigateToRentDemo) — bu sohbetin işi burada biter.
  /// "Uygun olan yok" derse ekran [chooseScratch]'ı çağırıp eski yola döner.
  void chooseReadyTemplate() {
    _onUserMessage('Hazır bir vitrin görmek istiyorum');
    _onBotMessage(
      '${vixRexMesajlari['niyet_kategori_baslik']}\n'
      '${vixRexMesajlari['niyet_kategori_aciklama']}',
    );
    _step = VixRexOnboardingStep.templateNiyet;
    _notify();
    _onRequestFocus?.call();
  }

  /// Niyet ızgarasından kategori seçimi — Keşfet bu etiketle ön-filtreli
  /// açılır. Profil kategorisine DOKUNMAZ (sıfırdan-yolundaki
  /// [selectCategory] ile karıştırma).
  void selectTemplateCategory(String label) {
    _onUserMessage(label);
    _onBotMessage('$label işletmesine uygun hazır vitrinleri buldum.');
    _notify();
    _onChooseReadyTemplate?.call(label);
  }

  /// "‹ Geri" — soruyu kapatıp karşılamaya döner, sohbete satır eklenmez
  /// (Web'deki `setNiyetKategoriSoruluyor(false)` karşılığı).
  void cancelTemplateNiyet() {
    _step = VixRexOnboardingStep.welcome;
    _notify();
  }

  /// Serbest niyet metni — kategori çözülürse ön-filtreli, çözülmezse
  /// süzgeçsiz Keşfet açılır. Yönlendirme asla engellenmez (Web paritesi:
  /// DB yazımı orada da best-effort). `true` döner ⇒ ekran kutuyu temizler.
  Future<bool> submitTemplateFreeText(String raw) async {
    final metin = raw.trim();
    if (metin.isEmpty) return false;
    _onUserMessage(metin);
    _onBotMessage(vixRexMesajlari['niyet_ack']!);
    _notify();
    _onChooseReadyTemplate?.call(templateKategoriCoz(metin));
    return true;
  }

  /// Serbest metinden kategori etiketi çözümü (best-effort) — ızgara
  /// etiketiyle birebir eşleşme (Türkçe I/İ duyarsız). Web'deki
  /// `resolveBusinessCategory` karşılığı; oradaki kadar esnek değil
  /// (bulanık eşleşme yok) — bulunamazsa null döner, Keşfet süzgeçsiz
  /// açılır. Sessiz daraltmadan iyidir: yanlış filtre boş liste gösterir.
  String? templateKategoriCoz(String metin) {
    final normal = _kucukHarf(metin);
    if (normal.isEmpty) return null;
    for (final kategori in BusinessCategoryConfig.categories) {
      if (_kucukHarf(kategori.label) == normal) return kategori.label;
    }
    return null;
  }

  /// Türkçe I/İ duyarsız küçük harf (Web'deki NFD normalizasyonunun en
  /// küçük karşılığı — ızgara etiketi eşleşmesi için yeterli).
  static String _kucukHarf(String s) =>
      s.trim().replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

  void declineWelcome() {
    _onUserMessage('Şimdilik bakınıyorum');
    _onBotMessage('Tamam. Hazır olunca buradayım.');
    _step = VixRexOnboardingStep.welcome;
    _notify();
  }

  // ── Girdi gönderimi (metin kutusu) ───────────────────────────────────

  /// `true` döner ⇒ ekran metin kutusunu temizler. Doğrulama başarısız
  /// olursa `false` döner — kullanıcı yazdığını düzeltebilsin diye kutu
  /// temizlenmez.
  Future<bool> onSend(String text) {
    switch (_step) {
      case VixRexOnboardingStep.name:
        return submitName(text);
      case VixRexOnboardingStep.templateNiyet:
        return submitTemplateFreeText(text);
      case VixRexOnboardingStep.whatsapp:
        return submitWhatsapp(text);
      case VixRexOnboardingStep.location:
        return submitLocationText(text);
      default:
        return Future.value(false);
    }
  }

  Future<bool> submitName(String raw) async {
    final name = raw.trim();
    if (name.length < 2) {
      _error = 'İşletme adını en az 2 karakter yaz.';
      _notify();
      return false;
    }
    _onUserMessage(name);
    _editor.updateName(name);
    await _editor.saveLocally();
    _step = VixRexOnboardingStep.category;
    _error = null;
    _notify();
    // Kategori şemada ZORUNLU (lib/config/vitrin_alanlari.g.dart).
    // Eskiden hiç sorulmuyordu; sohbetle açılan her vitrin "Diğer" kalıyor,
    // kategoriye bağlı hiçbir şey (butonlar, bölüm başlıkları, kategoriye
    // özel hazır görseller) çalışmıyordu.
    _onBotMessage(_akisMesaji('category'));
    return true;
  }

  /// Kategori seçimi — 19 kategori, tek dokunuş. Yazdırmıyoruz: esnaf
  /// "kuaför" yerine "Kuafor" yazınca eşleşme kaybolur.
  Future<void> selectCategory(String label) async {
    _onUserMessage(label);
    _editor.selectCategory(label);
    await _editor.saveLocally();
    if (_disposed) return;
    _step = VixRexOnboardingStep.whatsapp;
    _error = null;
    _notify();
    _onBotMessage(_akisMesaji('whatsapp'));
    _onRequestFocus?.call();
  }

  Future<bool> submitWhatsapp(String raw) async {
    final normalized = WhatsAppLinkHelper.normalizeTurkeyMobile(raw);
    if (normalized == null) {
      _error = WhatsAppLinkHelper.invalidNumberMessage;
      _notify();
      return false;
    }
    _onUserMessage(raw.trim());
    _editor.updateWhatsapp(normalized);
    await _editor.saveLocally();
    _step = VixRexOnboardingStep.location;
    _error = null;
    _notify();
    _onBotMessage(_akisMesaji('location'));
    return true;
  }

  Future<bool> submitLocationText(String raw) async {
    final text = raw.trim();
    if (text.length < 3) return false;
    _onUserMessage(text);
    _editor.updateAddressText(text);
    await _editor.saveLocally();
    _notify();
    return true;
  }

  /// Konum adımında hangi zorunlu alan eksik — sırayla ilki.
  ///
  /// Doğrulama zaten `confirmLocationFromEditor` içinde vardı ve boş
  /// alanla geçmiyordu. Sorun görsel: düğme hazır görünüyor, basınca
  /// reddediyordu. Casper (2026-08-07): "zorunluluk işareti var,
  /// karşılığı yok". Aynı kural artık düğmenin görünümünü de belirliyor —
  /// iki ayrı doğruluk olmasın diye tek yerde.
  String? get konumEksigi {
    final data = _editor.data;
    if (data.provinceCode.trim().isEmpty) return 'İl seç';
    if (data.districtName.trim().isEmpty) return 'İlçe seç';
    return AddressValidator.hataMesaji(data.address) == null
        ? null
        : 'Açık adresi yaz';
  }

  Future<void> confirmLocationFromEditor() async {
    final data = _editor.data;
    if (data.provinceCode.trim().isEmpty || data.districtName.trim().isEmpty) {
      _error = 'İl ve ilçe gerekli. GPS ile bul ya da listeden seç.';
      _notify();
      return;
    }
    // Adres ayrı kontrol edilir: eskiden yalnız "boş değil" bakılıyordu ve
    // "asd" yazan esnaf vitrinini öyle yayınlayabiliyordu. Yarım adres,
    // adres olmamasından beterdir — müşteri yola çıkar, bulamaz.
    final adresHatasi = AddressValidator.hataMesaji(data.address);
    if (adresHatasi != null) {
      _error = adresHatasi;
      _notify();
      return;
    }
    final label =
        '${data.districtName}, ${data.provinceName} — ${data.address}';
    _onUserMessage(label);
    await _editor.saveLocally();
    if (_disposed) return;
    _step = VixRexOnboardingStep.legal;
    _error = null;
    _notify();
    _onBotMessage(_akisMesaji('legal'));
  }

  // ── Hesap bağlama ─────────────────────────────────────────────────────

  /// Vitrin anonim bir hesaba bağlıysa true — yani cihaz kaybolursa
  /// erişim de kaybolur.
  bool get hesapKorumasiz {
    final kullanici = Supabase.instance.client.auth.currentUser;
    return kullanici != null && kullanici.isAnonymous;
  }

  /// Vitrini kalıcı bir hesaba bağlar.
  ///
  /// Anonim hesap CİHAZA bağlıdır. Esnaf telefonunu değiştirse ya da
  /// tarayıcı verisini silse vitrinine bir daha erişemez. Bu adım
  /// yayından SONRA çıkar — o ana kadar korunacak bir şey yok, kimseyi
  /// formla karşılamayız.
  Future<void> hesabiBagla() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    _notify();
    final sonuc = await const AuthService().hesabiGoogleaBagla();
    if (_disposed) return;
    _busy = false;
    if (sonuc.isFailure) {
      _error = sonuc.failure!.message;
      _notify();
      return;
    }
    _notify();
    _onBotMessage(
      'Tamam, vitrinin artık hesabına bağlı.\n'
      'Telefonunu değiştirsen de buradan devam edersin.',
    );
  }

  // ── Yasal onay + yayın ────────────────────────────────────────────────

  Future<void> acceptLegalAndPublish() async {
    if (_busy) return;
    if (!_editor.isLegalPublishReady) {
      _error = 'Yayın için aşağıdaki yasal onayları işaretle.';
      _notify();
      return;
    }
    _onUserMessage('Yayınla');
    _busy = true;
    _error = null;
    _step = VixRexOnboardingStep.publishing;
    _notify();
    _onBotMessage('Vitrinin hazırlanıyor…');

    try {
      await _editor.saveLocally();
      final link = await _editor.publish();
      if (_disposed) return;
      if (link == null || link.trim().isEmpty) {
        _busy = false;
        _step = VixRexOnboardingStep.legal;
        _error = 'Yayın tamamlanamadı. Tekrar dene.';
        _notify();
        _onBotMessage('Bir sorun oluştu. Tekrar deneyebilirsin.');
        return;
      }
      _publicLink = link.trim();

      // Tamamlanma mesajları HANDOFF'A YAZILMADAN ÖNCE eklenir — aksi
      // halde kaydedilen konuşma bu son iki mesajı hiç görmez
      // (CodeRabbit bulgusu, 2026-08-12).
      _onBotMessage(
        'İşte bu kadar.\nArtık dijitalde varsın.\n\n'
        'İşletme adına özel vitrinin hazır. Web siten var — domain masrafın yok.',
        publicLink: repairedPublicLink,
      );
      // TEK ASİSTAN — SERT DEVİR YOK (C2). Burası eskiden link verip
      // "VixRex rehberinde devam et" diyordu; artık aynı asistan vitrini
      // kendisi açıyor ve birlikte devam ediyor.
      _onBotMessage(
        'Şimdi birlikte güzelleştirelim.\n'
        'Vitrinini açıyorum — değiştirmek istediğin yazıya tıkla, ben '
        'oradan hallederim. Kapak görselini de kategorine özel hazır '
        'görsellerden seçebilirsin.',
      );

      // Konuşma geçmişini HEMEN kalıcı depoya yaz — bekletilmez (2026-08-12
      // bulgusu: publish() sonrası ekran devri, geçmiş yazılmadan
      // gerçekleşebiliyordu). Yayın KESİN başarılı oldu — bu adımın hatası
      // kendi try/catch'inde kalır, dış catch'e düşüp "yayın tamamlanamadı"
      // yanılgısı yaratmaz.
      try {
        await _onPersistTranscript();
      } catch (e) {
        if (kDebugMode) debugPrint('_handoffTranscriptToRehber hata: $e');
      }
      if (_disposed) return;

      _busy = false;
      _step = VixRexOnboardingStep.done;
      _notify();
    } catch (e) {
      if (_disposed) return;
      _busy = false;
      _step = VixRexOnboardingStep.legal;
      _error = e.toString().replaceFirst('StorePublishException: ', '');
      _notify();
      _onBotMessage(
        'Yayın şu an tamamlanamadı.\n'
        'Tekrar dene. Devam etmezse ekrandaki kırmızı hata metnini bana gönder.',
      );
    }
  }

  // ── Sahip modunda vitrini aç ──────────────────────────────────────────

  /// Vitrini SAHİP olarak açar — yani Vixrex Asistan'lı hâliyle.
  ///
  /// Düz yayın linki müşteri görünümüdür; orada asistan yoktur ve esnaf
  /// "hani birlikte düzenleyecektik" diye kalır. Sahip oturumu kısa
  /// ömürlü tek kullanımlık kodla açılır (openOwnerPreview).
  ///
  /// [visibleMessages] ekranın transkript listesinden gelir — bu sınıf
  /// kendi mesaj geçmişini tutmaz (bkz. dosya başı notu).
  Future<void> openOwnerWorkspace({
    required Iterable<AssistantHandoffMessage> visibleMessages,
  }) async {
    _busy = true;
    _notify();
    try {
      final owner = await _editor.openOwnerPreview(
        assistantHandoff: AssistantHandoffV1.completedOnboarding(
          visibleMessages: visibleMessages,
        ),
      );
      if (_disposed) return;
      final uri = Uri.tryParse(owner.url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        _onBotMessage(
          'Vitrin açılamadı. Aşağıdaki linkten kendin açabilirsin.',
        );
        return;
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && !_disposed) {
        _onBotMessage(
          'Tarayıcı açılamadı. Aşağıdaki linkten kendin açabilirsin.',
        );
      }
    } catch (e) {
      if (_disposed) return;
      // Mesaj "aşağıdaki linkten görüntüleyebilirsin" diyordu ama link hiç
      // eklenmiyordu — kullanıcının tıklayacağı hiçbir şey olmadığı için
      // "yönlendirmiyor" gibi görünüyordu (2026-08-12 bulgusu, canlıda
      // ekran görüntüsüyle doğrulandı).
      _onBotMessage(
        'Vitrini düzenleme modunda açamadım ($e). Aşağıdaki linkten '
        'görüntüleyebilir, sonra Vitrinim sekmesinden Önizle ile tekrar '
        'deneyebilirsin.',
        publicLink: repairedPublicLink,
      );
      if (kDebugMode) debugPrint('openOwnerPreview failed: $e');
    } finally {
      if (!_disposed) {
        _busy = false;
        _notify();
      }
    }
  }
}
