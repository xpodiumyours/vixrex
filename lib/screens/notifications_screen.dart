import 'package:flutter/material.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/models/in_app_notification.dart';
import 'package:vixrex/services/notification_inbox_service.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Randevu bildirim geçmişi — empty state dahil Complete.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _inbox = const NotificationInboxService();
  List<InAppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _inbox.list();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _open(InAppNotification item) async {
    await _inbox.markRead(item.id);
    if (!mounted) return;
    final slug = item.storeSlug?.trim();
    if (slug != null && slug.isNotEmpty) {
      await AppRouter.navigateToBookingManagement(context, slug: slug);
    }
    await _load();
  }

  Future<void> _markAll() async {
    await _inbox.markAllRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.bgEditor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        actions: [
          if (_items.any((e) => !e.read))
            TextButton(
              onPressed: _markAll,
              child: const Text('Tümünü okundu'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Henüz bildirim yok. Yeni randevu talepleri ve durum güncellemeleri burada görünür.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Material(
                        color: item.read
                            ? AppColors.surface
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _open(item),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: AppColors.darkText,
                                          fontSize: 13,
                                          fontWeight: item.read
                                              ? FontWeight.w700
                                              : FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (!item.read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
