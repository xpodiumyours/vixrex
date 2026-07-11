import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/instagram_sync_service.dart';
import 'package:vixrex/theme/app_colors.dart';

class InstagramSyncSection extends StatefulWidget {
  final String storeSlug;
  final String editToken;
  final String defaultCategory;
  final ValueChanged<Product> onProductImported;
  final ValueChanged<String> onMessage;
  /// Bağlantı kurulunca Instagram kullanıcı adını vitrin alanına yazar.
  final ValueChanged<String>? onConnectedUsername;
  final InstagramSyncService service;

  const InstagramSyncSection({
    super.key,
    required this.storeSlug,
    required this.editToken,
    required this.defaultCategory,
    required this.onProductImported,
    required this.onMessage,
    this.onConnectedUsername,
    this.service = const InstagramSyncService(),
  });

  @override
  State<InstagramSyncSection> createState() => _InstagramSyncSectionState();
}

class _InstagramSyncSectionState extends State<InstagramSyncSection>
    with WidgetsBindingObserver {
  InstagramConnectionStatus? _status;
  bool _isLoading = true;
  bool _isWorking = false;
  bool _authorizationOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _authorizationOpened) {
      _refreshStatus(showError: false);
    }
  }

  Future<void> _refreshStatus({bool showError = true}) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final status = await widget.service.getStatus(
        storeSlug: widget.storeSlug,
        editToken: widget.editToken,
      );
      if (!mounted) return;
      setState(() {
        _status = status;
        _isLoading = false;
        if (status.connected) _authorizationOpened = false;
      });
      final username = status.username?.trim();
      if (status.connected &&
          username != null &&
          username.isNotEmpty &&
          widget.onConnectedUsername != null) {
        widget.onConnectedUsername!(username);
      }
    } on InstagramSyncException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (showError) widget.onMessage(error.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (showError) {
        widget.onMessage('Instagram bağlantısı şu an kontrol edilemiyor.');
      }
    }
  }

  Future<void> _connect() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final authorizationUrl = await widget.service.createAuthorizationUrl(
        storeSlug: widget.storeSlug,
        editToken: widget.editToken,
      );
      final opened = await launchUrl(
        authorizationUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!opened) {
        widget.onMessage('Instagram bağlantı ekranı açılamadı.');
        return;
      }
      setState(() => _authorizationOpened = true);
      widget.onMessage('Instagram onayından sonra bağlantıyı kontrol edin.');
    } on InstagramSyncException catch (error) {
      widget.onMessage(error.userMessage);
    } catch (_) {
      widget.onMessage('Instagram bağlantısı başlatılamadı.');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _disconnect() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await widget.service.disconnect(
        storeSlug: widget.storeSlug,
        editToken: widget.editToken,
      );
      if (!mounted) return;
      setState(() {
        _status = const InstagramConnectionStatus(
          connected: false,
          status: 'disconnected',
        );
        _authorizationOpened = false;
      });
      widget.onMessage('Instagram bağlantısı kaldırıldı.');
    } on InstagramSyncException catch (error) {
      widget.onMessage(error.userMessage);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _openMediaPicker() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final media = await widget.service.listMedia(
        storeSlug: widget.storeSlug,
        editToken: widget.editToken,
      );
      if (!mounted) return;
      if (media.isEmpty) {
        widget.onMessage('Aktarılabilecek Instagram fotoğrafı bulunamadı.');
        return;
      }

      final product = await showModalBottomSheet<Product>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => _InstagramMediaSheet(
              media: media,
              service: widget.service,
              storeSlug: widget.storeSlug,
              editToken: widget.editToken,
              defaultCategory: widget.defaultCategory,
            ),
      );
      if (product != null) {
        widget.onProductImported(product);
      }
    } on InstagramSyncException catch (error) {
      widget.onMessage(error.userMessage);
    } catch (_) {
      widget.onMessage('Instagram fotoğrafları alınamadı.');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _status?.connected == true;
    final username = _status?.username;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: AppColors.cardBorderDark),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.secondary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instagram’dan Ürün Aktar',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    connected
                        ? username == null
                            ? 'Instagram hesabı bağlı'
                            : '@$username bağlı'
                        : _authorizationOpened
                        ? 'Onaydan sonra bağlantıyı kontrol edin.'
                        : 'Fotoğrafı seçin, fiyatı girin; ürün hazır olsun.',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (connected)
              IconButton(
                onPressed: _isWorking ? null : _disconnect,
                tooltip: 'Instagram bağlantısını kaldır',
                icon: const Icon(Icons.link_off_rounded, size: 19),
                color: AppColors.mutedText,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.primary,
            backgroundColor: AppColors.inputBg,
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed:
                  _isWorking
                      ? null
                      : connected
                      ? _openMediaPicker
                      : _authorizationOpened
                      ? _refreshStatus
                      : _connect,
              icon:
                  _isWorking
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        connected
                            ? Icons.add_photo_alternate_outlined
                            : _authorizationOpened
                            ? Icons.refresh_rounded
                            : Icons.link_rounded,
                        size: 18,
                      ),
              label: Text(
                connected
                    ? 'Fotoğraf Seç'
                    : _authorizationOpened
                    ? 'Bağlantıyı Kontrol Et'
                    : 'Instagram’a Bağla',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.focusedBorder),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InstagramMediaSheet extends StatefulWidget {
  final List<InstagramMediaItem> media;
  final InstagramSyncService service;
  final String storeSlug;
  final String editToken;
  final String defaultCategory;

  const _InstagramMediaSheet({
    required this.media,
    required this.service,
    required this.storeSlug,
    required this.editToken,
    required this.defaultCategory,
  });

  @override
  State<_InstagramMediaSheet> createState() => _InstagramMediaSheetState();
}

class _InstagramMediaSheetState extends State<_InstagramMediaSheet> {
  final _priceController = TextEditingController();
  late final TextEditingController _categoryController;
  int? _selectedIndex;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(
      text:
          widget.defaultCategory.trim().isEmpty
              ? 'Instagram Koleksiyonu'
              : widget.defaultCategory.trim(),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _importSelected() async {
    final index = _selectedIndex;
    if (index == null || _isImporting) return;
    setState(() => _isImporting = true);

    try {
      final product = await widget.service.importProduct(
        storeSlug: widget.storeSlug,
        editToken: widget.editToken,
        mediaId: widget.media[index].id,
        price: _priceController.text,
        category: _categoryController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(product);
    } on InstagramSyncException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
      setState(() => _isImporting = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf ürüne aktarılamadı.')),
      );
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.88;
    final selected =
        _selectedIndex == null ? null : widget.media[_selectedIndex!];

    return SafeArea(
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.disabled,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instagram Fotoğrafı Seç',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Şimdilik yalnızca fotoğraf gönderileri desteklenir.',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Kapat',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorderDark),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 640 ? 4 : 3;
                  return GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: widget.media.length,
                    itemBuilder: (context, index) {
                      final item = widget.media[index];
                      final isSelected = _selectedIndex == index;
                      return InkWell(
                        onTap: () => setState(() => _selectedIndex = index),
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, _, _) => const ColoredBox(
                                      color: AppColors.inputBg,
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                              ),
                            ),
                            if (isSelected)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primaryDark,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primaryDark,
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (selected != null) ...[
              const Divider(height: 1, color: AppColors.cardBorderDark),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + mediaQuery.viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    if (selected.caption.trim().isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selected.caption.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.softText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Fiyat (isteğe bağlı)',
                              hintText: 'Örn: 1.250 TL',
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Koleksiyon',
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isImporting ? null : _importSelected,
                        icon:
                            _isImporting
                                ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _isImporting ? 'Aktarılıyor...' : 'Ürüne Aktar',
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
