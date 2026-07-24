import 'package:flutter/material.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/xml_feed_service.dart';
import 'package:vixrex/theme/app_colors.dart';

/// XML feed yönetimi ve senkronizasyon ekranı.
class XmlSyncScreen extends StatefulWidget {
  final String storeId;
  final String editToken;
  final List<ProductCategory> categories;

  const XmlSyncScreen({
    super.key,
    required this.storeId,
    required this.editToken,
    this.categories = const [],
  });

  static Future<bool?> show({
    required BuildContext context,
    required String storeId,
    required String editToken,
    List<ProductCategory> categories = const [],
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => XmlSyncScreen(
        storeId: storeId,
        editToken: editToken,
        categories: categories,
      ),
    );
  }

  @override
  State<XmlSyncScreen> createState() => _XmlSyncScreenState();
}

class _XmlSyncScreenState extends State<XmlSyncScreen> {
  final _feedService = XmlFeedService();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  List<XmlFeed> _feeds = [];
  bool _isLoading = true;
  String? _syncingFeedId;
  XmlSyncResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadFeeds() async {
    setState(() => _isLoading = true);
    try {
      _feeds = await _feedService.getFeeds(widget.storeId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feed listesi yüklenemedi: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addFeed() async {
    if (_nameController.text.trim().isEmpty || _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feed adı ve URL zorunludur.')),
      );
      return;
    }

    try {
      await _feedService.addFeed(
        storeId: widget.storeId,
        feedName: _nameController.text.trim(),
        feedUrl: _urlController.text.trim(),
      );
      _nameController.clear();
      _urlController.clear();
      await _loadFeeds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed eklendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feed eklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _syncFeed(XmlFeed feed) async {
    setState(() {
      _syncingFeedId = feed.id;
      _lastResult = null;
    });

    try {
      // XML'i indir ve parse et
      final parseResult = await _feedService.fetchAndParse(feed);
      if (!parseResult.isSuccess) {
        setState(() {
          _syncingFeedId = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(parseResult.errorMessage!)),
          );
        }
        return;
      }

      // Ürünleri senkronize et
      final syncResult = await _feedService.syncFeed(
        storeId: widget.storeId,
        editToken: widget.editToken,
        feed: feed,
        products: parseResult.products,
      );

      setState(() {
        _lastResult = syncResult;
        _syncingFeedId = null;
      });

      await _loadFeeds();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${syncResult.inserted} yeni, ${syncResult.updated} güncellendi',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _syncingFeedId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Senkronizasyon hatası: $e')),
        );
      }
    }
  }

  Future<void> _deleteFeed(XmlFeed feed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feed Sil'),
        content: Text('${feed.feedName} feed silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _feedService.deleteFeed(feed.id);
      await _loadFeeds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.rss_feed, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'XML Feed Yönetimi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.mutedText),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Yeni feed ekleme
            _buildAddFeedSection(),
            const SizedBox(height: 16),

            // Feed listesi
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _feeds.isEmpty
                      ? _buildEmptyState()
                      : _buildFeedList(),
            ),

            // Son senkronizasyon sonucu
            if (_lastResult != null) ...[
              const SizedBox(height: 12),
              _buildSyncResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddFeedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgEditor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Yeni Feed Ekle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Feed Adı (ör: Modacar Ürünleri)',
              hintStyle: const TextStyle(color: AppColors.mutedText),
              filled: true,
              fillColor: AppColors.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'XML Feed URL (ör: https://tedarikci.com/feed.xml)',
              hintStyle: const TextStyle(color: AppColors.mutedText),
              filled: true,
              fillColor: AppColors.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _addFeed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Feed Ekle'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rss_feed, size: 48, color: AppColors.mutedText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Henüz XML feed eklenmedi',
            style: TextStyle(fontSize: 16, color: AppColors.mutedText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tedarikçi firmaların XML feed adreslerini ekleyerek\nürünlerini otomatik olarak senkronize edebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.softText),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList() {
    return ListView.builder(
      itemCount: _feeds.length,
      itemBuilder: (context, index) {
        final feed = _feeds[index];
        final isSyncing = _syncingFeedId == feed.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgEditor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Feed ikonu
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: feed.isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.mutedText.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.rss_feed,
                  color: feed.isActive ? AppColors.primary : AppColors.mutedText,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Feed bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feed.feedName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feed.feedUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusChip(feed.lastSyncStatus),
                        const SizedBox(width: 8),
                        Text(
                          '${feed.productCount} ürün',
                          style: const TextStyle(fontSize: 11, color: AppColors.softText),
                        ),
                        if (feed.lastSyncedAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(feed.lastSyncedAt!),
                            style: const TextStyle(fontSize: 11, color: AppColors.softText),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Aksiyonlar
              if (isSyncing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _syncFeed(feed),
                      icon: const Icon(Icons.sync, size: 20),
                      color: AppColors.primary,
                      tooltip: 'Senkronize Et',
                    ),
                    IconButton(
                      onPressed: () => _deleteFeed(feed),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade400,
                      tooltip: 'Sil',
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'success':
        color = Colors.green;
        label = 'Başarılı';
        break;
      case 'error':
        color = Colors.red;
        label = 'Hata';
        break;
      default:
        color = Colors.orange;
        label = 'Bekliyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSyncResult() {
    final result = _lastResult!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isSuccess
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: result.isSuccess ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.isSuccess ? Icons.check_circle : Icons.error,
            color: result.isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.isSuccess ? 'Senkronizasyon Başarılı' : 'Senkronizasyon Hatası',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: result.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                if (result.isSuccess) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${result.inserted} yeni ürün eklendi, ${result.updated} güncellendi, ${result.skipped} atlandı',
                    style: const TextStyle(fontSize: 12, color: AppColors.darkText),
                  ),
                ],
                if (result.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.errorMessage!,
                    style: const TextStyle(fontSize: 12, color: AppColors.darkText),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}
