import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/chatbot_service.dart';

/// Ürün ekleme olaylarını ortak Vixrex konuşmasına yazar.
/// Flutter ve Next.js aynı `assistant_conversations` tablosunu paylaştığı için
/// OCR/bulk/XML ile eklenen ürünler 15sn poll ile diğer tarafa düşer.
class ProductConversationLogger {
  const ProductConversationLogger._();

  /// `count` ürün `source` ile eklendiğinde ortak sohbete bir bot mesajı ekler.
  /// `scope` = `StoreEditorController.publishedInfo?.publicLink` veya `storeSlug`.
  /// Boşsa `local` scope’a düşer ama yine de Supabase’e senkronlanır
  /// (`VixrexConversationRepository.syncMessages` tek conversation’a yazar).
  static Future<void> log({
    required int count,
    required String source,
    String? scope,
    String? extra,
  }) async {
    if (count <= 0) return;
    final text = _buildText(count, source, extra);
    final service = ChatbotService();
    try {
      // Kalıcı hesap değilse bile yerel geçmişe yaz — Supabase senkronu sessizce atlar.
      final history = await service.loadHistory(scope: scope);
      history.add(ChatMessage.bot(text));
      await service.saveHistory(history, scope: scope);
    } catch (_) {
      // Loglama vitrin akışını asla kırmaz
    }
  }

  static String _buildText(int count, String source, String? extra) {
    final extraSuffix =
        extra != null && extra.isNotEmpty ? ' — $extra' : '';
    switch (source) {
      case 'ocr':
        return 'OCR ile $count ürün vitrine eklendi 📸${extra != null && extra.isNotEmpty ? " ($extra)" : ""}';
      case 'bulk':
        return 'Excel/CSV ile $count ürün eklendi 📊$extraSuffix';
      case 'xml':
        return 'XML ile $count ürün eklendi 🔗$extraSuffix';
      case 'silme':
        return '🗑️ $count ürün silindi$extraSuffix';
      case 'cogaltma':
        return '📋 $count ürün çoğaltıldı$extraSuffix';
      case 'kategori':
        return '🏷️ $count ürünün kategorisi değişti$extraSuffix';
      case 'fiyat':
        return '💰 $count ürünün fiyatı güncellendi$extraSuffix';
      case 'stok':
        return '📦 $count ürünün stok durumu değişti$extraSuffix';
      case 'gorunurluk':
        return '👁️ $count ürünün görünürlüğü değişti$extraSuffix';
      case 'baslik':
        return '✏️ $count ürün başlığı iyileştirildi$extraSuffix';
      case 'reorder':
        return '↕️ Ürün sıralaması güncellendi$extraSuffix';
      case 'tek_urun':
        if (extra != null && extra.isNotEmpty) return '✅ $extra';
        return '✅ $count ürün kaydedildi';
      case 'manuel':
        return '$count ürün eklendi ✅$extraSuffix';
      default:
        return '$count ürün vitrine eklendi$extraSuffix';
    }
  }
}
