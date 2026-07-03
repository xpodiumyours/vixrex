import 'package:flutter/material.dart';

import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';

/// Her intent yalnızca payload döndürür; yanıt metni ve quick-reply’ler
/// [ChatbotConfig.responseFor] içinde yönetilir.
class ChatbotIntent {
  final List<String> keywords;
  final String payload;

  const ChatbotIntent({
    required this.keywords,
    required this.payload,
  });
}

abstract final class ChatbotConfig {
  static const greetingPayload = 'greeting';

  /// Kullanıcı mesajını analiz edip eşleşen payload’ı döndürür.
  static String resolveIntent(String message) {
    final lower = message.toLowerCase().trim();

    final intents = [
      ChatbotIntent(
        keywords: ['merhaba', 'selam', 'nasılsın', 'naber', 'hey'],
        payload: 'greeting',
      ),
      ChatbotIntent(
        keywords: ['görünüm', 'tema', 'renk', 'tasarım', 'şablon', 'tema değiştir', 'tasarim'],
        payload: 'theme',
      ),
      ChatbotIntent(
        keywords: ['fotograf', 'resim', 'foto', 'galeri', 'gorsel', 'yukle'],
        payload: 'fotograf',
      ),
      ChatbotIntent(
        keywords: [
          'hazir gorsel', 'hazır görsel', 'sablon', 'şablon', 'hazir sablon',
          'hazır şablon', 'kategori gorseli', 'kategori görseli', 'hazir resim',
          'hazır resim', 'otomatik doldur', 'sablon kullan', 'şablon kullan',
        ],
        payload: 'auto_fill_images',
      ),
      ChatbotIntent(
        keywords: ['ürün', 'hizmet', 'ekle', 'fiyat', 'fiyatlarım', 'katalog', 'ürünlerim', 'hizmetlerim'],
        payload: 'urun',
      ),
      ChatbotIntent(
        keywords: ['vitrimin', 'düzenle', 'güncelle', 'vitrin', 'değiştir', 'ekle', 'form'],
        payload: 'vitrin_duzenle',
      ),
      ChatbotIntent(
        keywords: ['link', 'adres', 'url', 'bağlantı', 'baglanti', 'public'],
        payload: 'link',
      ),
      ChatbotIntent(
        keywords: ['qr', 'karekod', 'kare kod'],
        payload: 'qr',
      ),
      ChatbotIntent(
        keywords: ['xrex', 'chatbot', 'asistan', 'robot', 'bot', 'sen kimsin', 'x-rex'],
        payload: 'xrex',
      ),
      ChatbotIntent(
        keywords: ['yardım', 'help', 'destek', 'nasıl', 'nasıl yapılır', 'ipucu', 'öneri', 'ipucu', 'ne yapabilirsin'],
        payload: 'yardim',
      ),
      ChatbotIntent(
        keywords: ['sil', 'kaldır', 'temizle', 'iptal'],
        payload: 'sil',
      ),
      ChatbotIntent(
        keywords: ['galeri ekle', 'foto ekle', 'resim ekle'],
        payload: 'fotograf',
      ),
    ];

    for (final intent in intents) {
      for (final keyword in intent.keywords) {
        if (lower.contains(keyword)) {
          return intent.payload;
        }
      }
    }

    return 'unknown';
  }

  /// Payload’a göre yanıt mesajı ve hızlı cevaplar üretir.
  static ChatMessage responseFor(
    String payload,
    XrexProfileSnapshot? snapshot, {
    bool hasShared = false,
  }) {
    // Yardımcı fonksiyon
    List<QuickReply> mainMenuReplies(
      XrexProfileSnapshot? snapshot, {
      required bool hasShared,
    }) {
      final replies = <QuickReply>[
        const QuickReply(
          label: 'Vitrinim Nerede?',
          payload: 'vitrin_duzenle',
          action: XrexAction.openVitrim,
        ),
        const QuickReply(
          label: 'Nasıl Kullanırım?',
          payload: 'yardim',
        ),
        const QuickReply(
          label: 'Fotoğraf Nasıl Eklerim?',
          payload: 'fotograf',
        ),
        if (snapshot?.isPublished == true && !hasShared)
          const QuickReply(
            label: 'Paylaş',
            payload: 'paylas',
            action: XrexAction.shareWhatsapp,
          ),
      ];
      return replies;
    }

    switch (payload) {
      case 'greeting':
        return ChatMessage.bot(
          'Merhaba! Size nasıl yardımcı olabilirim? Aşağıdaki seçeneklerden birine tıklayabilir veya sorunuzu yazabilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'theme':
        return ChatMessage.bot(
          'Vitrinim ekranındaki "Görünüm" sekmesinden dilediğiniz renk temasını seçebilirsiniz. Canlı önizlemesi sayesinde değişiklikleri anında görebilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'fotograf':
        return ChatMessage.bot(
          'Vitrinim → Galeri veya Kapak Fotoğrafı bölümlerinden dilediğiniz fotoğrafları ekleyebilirsiniz. Ayrıca kategorine özel hazır görseller de kullanabilirsin!',
          quickReplies: [
            ...mainMenuReplies(snapshot, hasShared: hasShared),
            if (snapshot?.category != null && snapshot!.category.isNotEmpty)
              QuickReply(
                label: 'Hazır Görselleri Kullan',
                payload: 'auto_fill_images',
                action: XrexAction.openAutoFillDialog,
              ),
          ],
        );

      case 'auto_fill_images':
        if (snapshot?.category == null || snapshot!.category.isEmpty) {
          return ChatMessage.bot(
            'Hazır görselleri kullanmak için önce vitrininde bir kategori seçmelisin. Kategori seçimi vitrin formunun en altında yer alır.',
            quickReplies: [
              QuickReply(
                label: 'Kategoriye Git',
                payload: 'scroll_category',
                action: XrexAction.scrollToCategory,
              ),
              ...mainMenuReplies(snapshot, hasShared: hasShared),
            ],
          );
        }
        final categoryLabel = snapshot.category;
        return ChatMessage.bot(
          '$categoryLabel kategorin için özenle seçilmiş hazır görseller mevcut! Tek tıkla kapak fotoğrafı, galeri ve ürün şablonlarını vitrinine ekleyebilirsin.',
          quickReplies: [
            QuickReply(
              label: 'Hazır Görselleri Kullan',
              payload: 'apply_auto_fill',
              action: XrexAction.openAutoFillDialog,
            ),
            QuickReply(
              label: 'Galeriye Git',
              payload: 'scroll_gallery',
              action: XrexAction.scrollToGallery,
            ),
            ...mainMenuReplies(snapshot, hasShared: hasShared),
          ],
        );

      case 'urun':
        return ChatMessage.bot(
          snapshot != null
              ? 'Vitrinim → Ürünler sekmesine giderek ürün veya hizmetlerinizi fotoğraflarıyla birlikte ekleyebilirsiniz.'
              : 'Önce vitrinim ekranına gitmeniz gerekiyor.',
          quickReplies: [
            ...mainMenuReplies(snapshot, hasShared: hasShared),
            const QuickReply(
              label: 'Vitrinime Git',
              payload: 'vitrin_duzenle',
              action: XrexAction.openVitrim,
            ),
          ],
        );

      case 'vitrin_duzenle':
        return ChatMessage.bot(
          snapshot != null
              ? 'Vitrinim sekmesinden vitrininizi dilediğiniz gibi düzenleyebilirsiniz.'
              : 'Vitrinim sekmesine giderek vitrininizi oluşturabilirsiniz.',
          quickReplies: [
            const QuickReply(
              label: 'Vitrinime Git',
              payload: 'vitrin_duzenle',
              action: XrexAction.openVitrim,
            ),
            ...mainMenuReplies(snapshot, hasShared: hasShared),
          ],
        );

      case 'link':
        return ChatMessage.bot(
          snapshot?.publicLink != null && snapshot!.publicLink.isNotEmpty
              ? 'Vitrininizin bağlantısı: ${snapshot.publicLink}'
              : 'Bağlantınızı paylaşmak için vitrininizi yayınlamış olmanız gerekiyor.',
          quickReplies: [
            if (snapshot?.publicLink != null && snapshot!.publicLink.isNotEmpty)
              const QuickReply(
                label: 'Linki Kopyala',
                payload: 'link_kopyala',
                action: XrexAction.copyLink,
              ),
            ...mainMenuReplies(snapshot, hasShared: hasShared),
          ],
        );

      case 'qr':
        return ChatMessage.bot(
          snapshot != null
              ? 'QR kodunuzu görüntülemek için Vitrinim sekmesine gidebilirsiniz.'
              : 'Önce vitrinim ekranına gitmeniz gerekiyor.',
          quickReplies: [
            const QuickReply(
              label: 'QR Göster',
              payload: 'qr_goster',
              action: XrexAction.showQr,
            ),
            ...mainMenuReplies(snapshot, hasShared: hasShared),
          ],
        );

      case 'xrex':
        return ChatMessage.bot(
          'Ben X-Rex, dijital vitrin asistanınızım! Size vitrin oluşturma, düzenleme, paylaşım ve optimizasyon konularında yardımcı olabilirim.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'yardim':
        return ChatMessage.bot(
          'Size şu konularda yardımcı olabilirim:\n'
          '• Vitrin oluşturma ve düzenleme\n'
          '• Tema ve görünüm ayarları\n'
          '• Fotoğraf ve ürün ekleme\n'
          '• Vitrin paylaşımı ve bağlantı alma\n'
          'Hangi konuda yardım almak istersiniz?',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'sil':
        return ChatMessage.bot(
          'Silmek istediğiniz öğeyi belirtir misiniz? Genel ayarlar için Ayarlar sekmesine gidebilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      default:
        return ChatMessage.bot(
          'Anladığımdan emin değilim. Size en iyi şekilde yardımcı olabilmem için aşağıdaki seçeneklerden birine tıklayabilir veya sorunuzu daha detaylı yazabilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );
    }
  }
}
