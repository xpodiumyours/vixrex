import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// Vixrex — Vixrex'in kural tabanlı kullanıcı rehberi.
/// Tüm yanıtlar Türkçedir. API bağlantısı yoktur; kural tabanlı çalışır.
abstract final class ChatbotConfig {
  static const String botName = 'Vixrex';
  static const String botSubtitle = 'Vixrex Rehberi';
  static const String systemStatus = 'AKTİF';

  /// Eski unpublished davet key (sekme artık onboarding gömer; stale temizlik için).
  static const String setupInviteStateKey = 'setup_invite';

  static const QuickReply setupInviteReply = QuickReply(
    label: 'Evet, Oluşturalım',
    payload: 'start_setup',
    action: VixRexAction.openVitrim,
  );

  /// Onboarding ile aynı üslup — rehberde field CTA (“İşletme Adı Ekle”) yok.
  static ChatMessage get setupInviteMessage => ChatMessage.bot(
    vixRexMesajlari['setup_invite']!,
    quickReplies: const [setupInviteReply],
    snapshotStateKey: setupInviteStateKey,
    uretilmis: true,
  );

  // ─── Genel Karşılama (snapshot yokken) ──────────────────────────────────
  static ChatMessage get welcomeMessage => setupInviteMessage;

  // ─── Snapshot Tabanlı Karşılama Mesajları ────────────────────────────────

  /// Vitrin durumuna göre kişiselleştirilmiş karşılama mesajı üretir.
  static ChatMessage snapshotWelcome(
    VixRexProfileSnapshot snapshot, {
    required bool hasShared,
  }) {
    if (!snapshot.isPublished) return setupInviteMessage;

    final recommendation = VixRexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    final link = snapshot.publicLink.trim();
    // Boş geçmişte tek karşılama (kazanım + link bir kez).
    final warmIntro =
        'Harika, buraya kadar geldik.\n\n'
        'Vitrinin yayında — adın, WhatsApp’ın ve konumun tek yerde.'
        '${link.isEmpty ? '' : '\n\n$link'}\n\n'
        '${recommendation.description}';
    return ChatMessage.bot(
      warmIntro,
      quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
      snapshotStateKey: recommendation.id,
      uretilmis: true,
    );
  }

  /// Kurulum handoff sonrası: kazanım/link TEKRAR YAZILMAZ, yalnız sıradaki adım.
  static ChatMessage nextStepTip(
    VixRexProfileSnapshot snapshot, {
    required bool hasShared,
  }) {
    if (!snapshot.isPublished) return setupInviteMessage;

    final recommendation = VixRexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    return ChatMessage.bot(
      recommendation.description,
      quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
      snapshotStateKey: recommendation.id,
      uretilmis: true,
    );
  }

  /// Eski rehber history’deki field-setup CTA’ları (İşletme Adı Ekle vb.).
  static bool isStaleUnpublishedSetupTip(ChatMessage message) {
    final key = message.snapshotStateKey?.trim() ?? '';
    if (key == setupInviteStateKey) return false;
    if (key.startsWith('setup_') || key == 'publish' || key == 'welcome') {
      return true;
    }
    return message.quickReplies.any(
      (q) =>
          q.label == 'İşletme Adı Ekle' ||
          q.label == 'WhatsApp Ekle' ||
          q.label == 'Adres Ekle' ||
          q.label == 'Onayları İncele' ||
          q.label == 'Vitrinimi Aç' ||
          q.label == 'Yayınla' ||
          q.label == 'Vitrin oluştur' ||
          q.label == 'Başla',
    );
  }

  // ─── Ana Menü Quick Reply'ları ───────────────────────────────────────────
  /// Tek (veya en fazla iki) küçük hap — 7’li şerit yok.
  static List<QuickReply> mainMenuReplies(
    VixRexProfileSnapshot? snapshot, {
    bool hasShared = false,
  }) {
    if (snapshot == null || !snapshot.isPublished) {
      return const [setupInviteReply];
    }

    final recommendation = VixRexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    return [
      QuickReply(
        label: recommendation.buttonLabel,
        payload: 'action_step',
        action: recommendation.action,
      ),
    ];
  }

  static List<QuickReply> get helpReplies => mainMenuReplies(null);

  // ─── Intent Tanımları ────────────────────────────────────────────────────
  /// Anahtar kelime → payload eşlemesi artık şemadan (Faz B, Tek Asistan
  /// planı) geliyor; elle liste tutulmaz. Yeni bir anahtar kelime
  /// shared/vixrex_mesajlar.json'a yazılır, sonra `dart run
  /// tool/mesaj_semasi_uret.dart` çalıştırılır.
  static final List<ChatbotIntent> intents = [
    for (final i in vixRexIntentSemasi)
      ChatbotIntent(keywords: i.anahtarKelimeler, payload: i.payload),
  ];

  // ─── Tablodan Yanıt (tek kaynak: shared/vixrex_mesajlar.json → yanitlar)
  /// Etiket/payload kablolaması şemadan gelir; istemciye özgü aksiyon
  /// eşlemesi burada kalır. Duruma bağlı dallanma (snapshot, yayın)
  /// çağıran tarafta yapılır, tabloda değil.
  static VixRexAction _actionFor(String name) {
    return VixRexAction.values.firstWhere(
      (e) => e.name == name,
      orElse: () => VixRexAction.none,
    );
  }

  static ChatMessage _yanitFromTable(
    String tableKey, {
    VixRexProfileSnapshot? snapshot,
    bool hasShared = false,
  }) {
    final yanit = vixRexYanitlar[tableKey];
    if (yanit == null) {
      return ChatMessage.bot(
        vixRexMesajlari['anlasilamadi']!,
        quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
      );
    }
    return ChatMessage.bot(
      vixRexMesajlari[yanit.mesaj]!,
      quickReplies: [
        for (final h in yanit.hizli)
          QuickReply(
            label: h.etiket,
            payload: h.payload,
            action: _actionFor(h.aksiyon),
          ),
      ],
    );
  }

  // ─── Intent → Yanıt Tablosu ─────────────────────────────────────────────
  static ChatMessage responseFor(
    String payload, {
    VixRexProfileSnapshot? snapshot,
    bool hasShared = false,
  }) {
    switch (payload) {
      case 'merhaba':
        return snapshot == null
            ? welcomeMessage
            : snapshotWelcome(snapshot, hasShared: hasShared);

      case 'vixrex_info':
        return ChatMessage.bot(
          vixRexMesajlari['vixrex_info']!,
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'membership_info':
        return ChatMessage.bot(
          vixRexMesajlari['membership_info']!,
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'vitrin_kurulum':
        return ChatMessage.bot(
          vixRexMesajlari['vitrin_kurulum']!,
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'kapak':
      case 'fotograf':
      case 'aciklama':
      case 'urun':
      case 'xml_upload':
      case 'randevu':
      case 'whatsapp':
      case 'adres':
      case 'yayinla':
        return _yanitFromTable(
          payload,
          snapshot: snapshot,
          hasShared: hasShared,
        );

      case 'qr':
        return _yanitFromTable(
          snapshot?.isPublished == true ? 'qr_yayinda' : 'qr_yayinda_degil',
          snapshot: snapshot,
          hasShared: hasShared,
        );

      case 'ocr_scan':
      case 'ocr_info':
        return _yanitFromTable(
          payload,
          snapshot: snapshot,
          hasShared: hasShared,
        );

      case 'ocr_premium':
        return ChatMessage.bot(
          vixRexMesajlari['ocr_premium']!,
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'hesap':
        return _yanitFromTable(
          payload,
          snapshot: snapshot,
          hasShared: hasShared,
        );

      default:
        return ChatMessage.bot(
          vixRexMesajlari['anlasilamadi']!,
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );
    }
  }
}

// ─── Intent sınıfı ─────────────────────────────────────────────────────────
class ChatbotIntent {
  final List<String> keywords;
  final String payload;
  const ChatbotIntent({required this.keywords, required this.payload});
}
