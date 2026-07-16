import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// Vixrex — Vixrex'in kural tabanlı kullanıcı rehberi.
/// Tüm yanıtlar Türkçedir. API bağlantısı yoktur; kural tabanlı çalışır.
abstract final class ChatbotConfig {
  static const String botName = 'Vixrex';
  static const String botSubtitle = 'Vixrex Rehberi';
  static const String systemStatus = 'AKTİF';

  // ─── Genel Karşılama (snapshot yokken) ──────────────────────────────────
  static ChatMessage get welcomeMessage => ChatMessage.bot(
        'Merhaba! Ben $botName, Vixrex rehberiyim.\n\n'
        'Vitrinini kurman, yayınlaman ve müşterilerine duyurman için sıradaki doğru adımı gösteririm.\n\n'
        'Nasıl yardımcı olayım?',
        quickReplies: [
          const QuickReply(
            label: 'Vitrin oluştur',
            payload: 'start_setup',
            action: VixRexAction.openVitrim,
          ),
          ...mainMenuReplies(null),
        ],
      );

  // ─── Snapshot Tabanlı Karşılama Mesajları ────────────────────────────────

  /// Vitrin durumuna göre kişiselleştirilmiş karşılama mesajı üretir.
  static ChatMessage snapshotWelcome(
    VixRexProfileSnapshot snapshot, {
    required bool hasShared,
  }) {
    final recommendation = VixRexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    return ChatMessage.bot(
      '${recommendation.title}. ${recommendation.description}',
      quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
      snapshotStateKey: recommendation.id,
    );
  }

  // ─── Ana Menü Quick Reply'ları ───────────────────────────────────────────
  static List<QuickReply> mainMenuReplies(
    VixRexProfileSnapshot? snapshot, {
    bool hasShared = false,
  }) {
    if (snapshot == null) {
      return const [
        QuickReply(label: 'Vixrex Ne İşe Yarar?', payload: 'vixrex_info'),
        QuickReply(label: 'Üyelik / Kullanım', payload: 'membership_info'),
      ];
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
      if (snapshot.isPublished) ...const [
        QuickReply(
          label: 'Linki Kopyala',
          payload: 'copy_link',
          action: VixRexAction.copyLink,
        ),
        QuickReply(
          label: 'QR Göster',
          payload: 'show_qr',
          action: VixRexAction.showQr,
        ),
      ],
      const QuickReply(
        label: 'Ürün ekle (tara)',
        payload: 'ocr_scan',
        action: VixRexAction.openOcrScanner,
      ),
      const QuickReply(
        label: 'Kapak şablonu',
        payload: 'kapak',
        action: VixRexAction.openCoverTemplatePicker,
      ),
      const QuickReply(label: 'Vixrex Ne İşe Yarar?', payload: 'vixrex_info'),
      const QuickReply(label: 'Üyelik / Kullanım', payload: 'membership_info'),
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
