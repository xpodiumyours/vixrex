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
        'Merhaba, ben Vixrex.\n\n'
        'Sana dijital bir vitrin oluşturmamı ister misin?',
        quickReplies: const [setupInviteReply],
        snapshotStateKey: setupInviteStateKey,
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
  static const List<ChatbotIntent> intents = [
    ChatbotIntent(
      keywords: ['merhaba', 'selam', 'nasil', 'baslat', 'baslayalim', 'yardim', 'ne yapabilirsin'],
      payload: 'merhaba',
    ),
    ChatbotIntent(
      keywords: ['vixrex', 'nedir', 'ne işe yarar', 'nasil calisir', 'kurulum', 'vitrin'],
      payload: 'vixrex_info',
    ),
    ChatbotIntent(
      keywords: ['ucret', 'fiyat', 'para', 'komisyon', 'ucretsiz', 'odeme', 'bedava', 'uyelik', 'kullanim'],
      payload: 'membership_info',
    ),
    ChatbotIntent(
      keywords: ['kapak', 'sablon', 'kapak foto', 'cover'],
      payload: 'kapak',
    ),
    ChatbotIntent(
      keywords: ['fotograf', 'resim', 'foto', 'galeri', 'gorsel', 'yukle'],
      payload: 'fotograf',
    ),
    ChatbotIntent(
      keywords: ['aciklama', 'hakkinda', 'bio', 'tanitim yazisi'],
      payload: 'aciklama',
    ),
    ChatbotIntent(
      keywords: ['urun', 'hizmet', 'menu', 'katalog', 'fiyat listesi'],
      payload: 'urun',
    ),
    ChatbotIntent(
      keywords: ['qr', 'kod', 'link', 'paylas', 'baglanti', 'url'],
      payload: 'qr',
    ),
    ChatbotIntent(
      keywords: ['randevu', 'rezervasyon', 'saat', 'takvim', 'musteri kabul'],
      payload: 'randevu',
    ),
    ChatbotIntent(
      keywords: ['whatsapp', 'telefon', 'numara', 'iletisim', 'mesaj'],
      payload: 'whatsapp',
    ),
    ChatbotIntent(
      keywords: ['adres', 'konum', 'harita', 'nerede', 'yol tarifi', 'lokasyon'],
      payload: 'adres',
    ),
    ChatbotIntent(
      keywords: ['yayinla', 'canli', 'aktif', 'yayinda', 'goster', 'acik'],
      payload: 'yayinla',
    ),
    ChatbotIntent(
      keywords: ['fatura', 'fis', 'tara', 'etiket', 'otomatik', 'ocr'],
      payload: 'ocr_scan',
    ),
    ChatbotIntent(
      keywords: ['premium', 'sinirsiz', 'ucretli'],
      payload: 'ocr_premium',
    ),
    ChatbotIntent(
      keywords: [
        'hesap',
        'giris',
        'uye ol',
        'kayit',
        'guvence',
        'hesabimi',
        'login',
      ],
      payload: 'hesap',
    ),
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
          'Vixrex ile işletme bilgilerini tek yerde toplar, vitrinini yayınlar ve link, QR veya WhatsApp ile müşterilerine duyurursun.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );
        
      case 'membership_info':
        return ChatMessage.bot(
          'Temel vitrin oluşturma şu an ücretsizdir. Gelişmiş özellikler uygulama içinde ayrıca gösterilecektir.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'vitrin_kurulum':
        return ChatMessage.bot(
          'Vitrin kurulumu için yalnızca İşletme Adı, WhatsApp, Adres ve Yasal Onay adımlarını tamamlamanız yeterlidir.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'kapak':
        return ChatMessage.bot(
          'Hazır kapak şablonundan birini seç — vitrinin hemen daha profesyonel görünür.',
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
          'Galeriye görsel ekle veya kapak şablonu seç. İkisi de mevcut Vitrinim editöründen açılır.',
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
          'Kısa bir işletme açıklaması ekle — müşteri seni daha çabuk anlar.',
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
          'Ürün/hizmet ekle: elle yaz veya fiş/etiket tarayıcıyı kullan. İkisi de mevcut uygulama yolları.',
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

      case 'qr':
        return ChatMessage.bot(
          snapshot?.isPublished == true
              ? 'Linkini kopyala, QR göster veya WhatsApp ile paylaş — hepsi mevcut paylaşım yolları.'
              : 'Önce vitrinini yayınla; sonra QR ve link hazır olur.',
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
          'Randevu, uygun kategoride mevcut editör paketinden açılır. Kategori alanına gidip kontrol edebilirsin.',
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
          'WhatsApp numaran Vitrinim iletişim alanında. Oradan güncelle.',
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
          'Konumunu Vitrinim adres alanından güncelle — GPS veya elle.',
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
          'Yayın için yasal onaylar ve Yayınla butonu Vitrinim’de. Oradan devam et.',
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
          'Fiş/fatura veya raf etiketi ile ürün aktar — mevcut tarayıcıyı aç.',
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
          'Nasıl Çalışır:\n'
          '1. Fotoğrafınızı çekin veya galeriden seçin\n'
          '2. Ürünler otomatik olarak tanınır\n'
          '3. Ürünleri onaylayın veya düzenleyin\n'
          '4. Onaylanan ürünler vitrininize eklenir\n\n'
          'Not: Bu özellik premium gerektirir.',
          quickReplies: [
            const QuickReply(label: 'Premium Bilgisi', payload: 'ocr_premium'),
            const QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'ocr_premium':
        return ChatMessage.bot(
          'Premium üyelik ile:\n'
          '• Fotoğraftan sınırsız ürün çıkarma\n'
          '• Faturadan otomatik ürün kaydı\n'
          '• Toplu Excel yükleme\n'
          '• Barkod tarama\n\n'
          'Ücretsiz deneme: Günde 3 ücretsiz OCR hakkı.\n'
          'Premium için uygulama içinden satın alma yapabilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'hesap':
        return ChatMessage.bot(
          'Vitrinini güvenceye almak için giriş yap / üye ol. '
          'Mevcut Auth ekranı açılır; vitrin token ile hesaba bağlanır.',
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
          'Üzgünüm, bunu tam anlayamadım. Aşağıdaki seçeneklerden birini deneyebilirsiniz:',
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
