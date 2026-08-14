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
        return ChatMessage.bot(
          vixRexMesajlari['kapak']!,
          quickReplies: const [
            QuickReply(
              label: 'Kapak şablonu seç',
              payload: 'action_cover',
              action: VixRexAction.openCoverTemplatePicker,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'fotograf':
        return ChatMessage.bot(
          vixRexMesajlari['fotograf']!,
          quickReplies: const [
            QuickReply(
              label: 'Galeriye git',
              payload: 'action_gallery',
              action: VixRexAction.scrollToGallery,
            ),
            QuickReply(
              label: 'Kapak şablonu seç',
              payload: 'action_cover',
              action: VixRexAction.openCoverTemplatePicker,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'aciklama':
        return ChatMessage.bot(
          vixRexMesajlari['aciklama']!,
          quickReplies: const [
            QuickReply(
              label: 'Açıklamaya git',
              payload: 'action_desc',
              action: VixRexAction.scrollToDesc,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'urun':
        return ChatMessage.bot(
          vixRexMesajlari['urun']!,
          quickReplies: const [
            QuickReply(
              label: 'Ürün alanına git',
              payload: 'action_products',
              action: VixRexAction.scrollToProducts,
            ),
            QuickReply(
              label: 'Fiş ile tara',
              payload: 'action_ocr',
              action: VixRexAction.openOcrScanner,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'xml_upload':
        return ChatMessage.bot(
          vixRexMesajlari['xml_upload']!,
          quickReplies: const [
            QuickReply(
              label: 'XML linkini paylaş',
              payload: 'action_xml',
              action: VixRexAction.openXmlUpload,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'qr':
        return ChatMessage.bot(
          snapshot?.isPublished == true
              ? vixRexMesajlari['qr_yayinda']!
              : vixRexMesajlari['qr_yayinda_degil']!,
          quickReplies: [
            if (snapshot?.isPublished == true) ...const [
              QuickReply(
                label: 'Linki kopyala',
                payload: 'copy_link',
                action: VixRexAction.copyLink,
              ),
              QuickReply(
                label: 'QR göster',
                payload: 'show_qr',
                action: VixRexAction.showQr,
              ),
              QuickReply(
                label: 'WhatsApp’ta paylaş',
                payload: 'share_wa',
                action: VixRexAction.shareWhatsapp,
              ),
            ] else
              const QuickReply(
                label: 'Vitrinime git',
                payload: 'open_vitrim',
                action: VixRexAction.openVitrim,
              ),
            const QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'randevu':
        return ChatMessage.bot(
          vixRexMesajlari['randevu']!,
          quickReplies: const [
            QuickReply(
              label: 'Kategoriye git',
              payload: 'action_category',
              action: VixRexAction.scrollToCategory,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'whatsapp':
        return ChatMessage.bot(
          vixRexMesajlari['whatsapp']!,
          quickReplies: const [
            QuickReply(
              label: 'WhatsApp alanına git',
              payload: 'action_wa',
              action: VixRexAction.scrollToWhatsapp,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'adres':
        return ChatMessage.bot(
          vixRexMesajlari['adres']!,
          quickReplies: const [
            QuickReply(
              label: 'Adrese git',
              payload: 'action_address',
              action: VixRexAction.scrollToAddress,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'yayinla':
        return ChatMessage.bot(
          vixRexMesajlari['yayinla']!,
          quickReplies: const [
            QuickReply(
              label: 'Yasal onaylara git',
              payload: 'action_legal',
              action: VixRexAction.scrollToLegal,
            ),
            QuickReply(
              label: 'Vitrinime git',
              payload: 'open_vitrim',
              action: VixRexAction.openVitrim,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'ocr_scan':
        return ChatMessage.bot(
          vixRexMesajlari['ocr_scan']!,
          quickReplies: const [
            QuickReply(
              label: 'Fiş/Fatura tara',
              payload: 'action_ocr',
              action: VixRexAction.openOcrScanner,
            ),
            QuickReply(
              label: 'Raf/Etiket tara',
              payload: 'action_ocr_shelf',
              action: VixRexAction.openOcrScannerShelf,
            ),
            QuickReply(label: 'Nasıl çalışır?', payload: 'ocr_info'),
          ],
        );

      case 'ocr_info':
        return ChatMessage.bot(
          vixRexMesajlari['ocr_info']!,
          quickReplies: [
            const QuickReply(label: 'Premium Bilgisi', payload: 'ocr_premium'),
            const QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'ocr_premium':
        return ChatMessage.bot(
          vixRexMesajlari['ocr_premium']!,
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'hesap':
        return ChatMessage.bot(
          vixRexMesajlari['hesap']!,
          quickReplies: const [
            QuickReply(
              label: 'Hesabımı güvenceye al',
              payload: 'action_auth',
              action: VixRexAction.openAuth,
            ),
            QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
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
