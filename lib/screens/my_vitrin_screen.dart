import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';
import 'package:vitrinx/screens/vitrin_editor_screen.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/store_publish_payload_builder.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/utils/gallery_image_file_validator.dart';
import 'package:vitrinx/utils/token_generator.dart';

class MyVitrinScreen extends StatefulWidget {
  final String? initialName;
  final VoidCallback? onPublished;
  final VoidCallback? onOpenExplore;

  const MyVitrinScreen({
    super.key,
    this.initialName,
    this.onPublished,
    this.onOpenExplore,
  });

  @override
  State<MyVitrinScreen> createState() => _MyVitrinScreenState();
}

class _MyVitrinScreenState extends State<MyVitrinScreen> {
  static const Color primaryColor = Color(0xFFFF4D00);
  static const Color bgColor = Color(0xFFF6F8FC);
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF64748B);
  static const Color softText = Color(0xFF334155);
  static const Color cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
  static const Color inputBg = Color(0xFFF1F5F9);

  final _storage = const StoreLocalStorageService();
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _descriptionController = TextEditingController();

  StoreData _data = StoreData(isEsnafMode: false, isStore: false);
  PublishedVitrinInfo? _publishedInfo;
  Uint8List? _coverBytes;
  String? _coverUrl;
  String? _coverFileName;
  String _coverExtension = 'jpg';
  String _coverContentType = 'image/jpeg';
  String? _nameError;
  bool _isLoading = true;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    try {
      final savedData = await _storage.loadVitrinData();
      final publishedInfo = await _storage.loadPublishedVitrinInfo();
      final data = savedData ?? StoreData(isEsnafMode: false, isStore: false);
      final initialName = widget.initialName?.trim() ?? '';
      if (data.name.trim().isEmpty && initialName.isNotEmpty) {
        data.name = initialName;
      }

      if (!mounted) return;
      setState(() {
        _data = data..isStore = false;
        _publishedInfo = publishedInfo;
        _nameController.text =
            _data.name.trim().isNotEmpty
                ? _data.name
                : (publishedInfo?.name ?? initialName);
        _whatsappController.text = _data.whatsapp;
        _descriptionController.text = _data.description;
        _coverUrl = _data.coverImageUrl;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('MyVitrinScreen load error: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCoverPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final validation = GalleryImageFileValidator.validate(
      bytes: file.bytes,
      reportedSize: file.size,
    );

    if (!validation.isValid || file.bytes == null) {
      _showSnackBar(
        'Fotoğraf eklenemedi. JPG, PNG veya WEBP ve en fazla 15 MB olmalı.',
      );
      return;
    }

    setState(() {
      _coverBytes = file.bytes;
      _coverFileName = file.name;
      _coverExtension = validation.fileInfo!.extension;
      _coverContentType = validation.fileInfo!.contentType;
    });
  }

  Future<void> _publishVitrin() async {
    if (_isPublishing) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Vitrin adı zorunludur');
      _showSnackBar('Vitrinini yayına almak için sadece ad yazman yeterli.');
      return;
    }

    setState(() {
      _isPublishing = true;
      _nameError = null;
    });

    try {
      final slug = const StorePublishPayloadBuilder().generateSlug(name);
      var coverUrl = _coverUrl?.trim() ?? '';

      if (_coverBytes != null) {
        try {
          coverUrl = await const StoreShelfUploadService().uploadShelfImage(
            _coverBytes!,
            '$slug/cover',
            fileExtension: _coverExtension,
            contentType: _coverContentType,
          );
        } catch (error) {
          debugPrint('Cover upload skipped: $error');
          _showSnackBar('Fotoğraf yüklenemedi ama vitrin yayını devam ediyor.');
          coverUrl = _coverUrl?.trim() ?? '';
        }
      }

      final data =
          _data
            ..name = name
            ..whatsapp = _whatsappController.text.trim()
            ..description = _descriptionController.text.trim()
            ..isStore = false
            ..shelfImageUrl = coverUrl
            ..galleryItems =
                coverUrl.isEmpty
                    ? <StoreGalleryItem>[]
                    : [StoreGalleryItem(id: 'cover', imageUrl: coverUrl)];

      await _storage.saveVitrinData(data);
      final editToken = await _loadOrCreateEditToken();
      final result = await const StorePublishService().publishStore(
        data,
        editToken: editToken,
      );
      final publicLink = PublicSiteConfig.buildPublicLink(result.publicPath);

      await _storage.savePublishedVitrinInfo(
        slug: result.slug,
        publicLink: publicLink,
        name: data.name,
        editToken: editToken,
      );

      if (!mounted) return;
      setState(() {
        _data = data..slug = result.slug;
        _publishedInfo = PublishedVitrinInfo(
          slug: result.slug,
          publicLink: publicLink,
          name: data.name,
          editToken: editToken,
        );
        _coverUrl = coverUrl;
        _coverBytes = null;
        _coverFileName = null;
      });
      widget.onPublished?.call();
      _showSnackBar('Vitrinin yayında! Keşfet’te görünürsün.');
    } catch (error) {
      debugPrint('My vitrin publish error: $error');
      if (!mounted) return;
      _showSnackBar(
        error is StorePublishException
            ? error.message
            : 'Vitrin yayına alınamadı. Supabase ayarlarını kontrol edin.',
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<String> _loadOrCreateEditToken() async {
    final savedToken = await _storage.loadVitrinEditToken();
    if (savedToken != null && savedToken.trim().isNotEmpty) {
      return savedToken;
    }

    final token = TokenGenerator.generate();
    await _storage.saveVitrinEditToken(token);
    return token;
  }

  Future<void> _copyLink() async {
    final link = _publishedInfo?.publicLink;
    if (link == null || link.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    _showSnackBar('Vitrin linki kopyalandı.');
  }

  Future<void> _openEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VitrinEditorScreen()),
    );
    if (mounted) {
      await _loadState();
      widget.onPublished?.call();
    }
  }

  void _openPublicVitrin() {
    final slug = _publishedInfo?.slug;
    if (slug == null || slug.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicVitrinScreen(slug: slug)),
    );
  }

  void _showQrSheet() {
    final link = _publishedInfo?.publicLink;
    if (link == null || link.trim().isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR Göster',
                style: TextStyle(
                  color: darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                ),
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                link,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final hasPublishedVitrin = _publishedInfo?.isComplete == true;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 720;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: isDesktop ? 28 : 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child:
                      hasPublishedVitrin
                          ? _buildPublishedView()
                          : _buildSetupView(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Vitrinini 30 saniyede yayına al',
          style: TextStyle(
            color: darkText,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'İşletme adını yaz, bir fotoğraf ekle, linkin ve QR kodun hazır olsun.',
          style: TextStyle(
            color: mutedText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        _buildSetupCard(),
      ],
    );
  }

  Widget _buildSetupCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            label: 'İşletme / vitrin adı',
            controller: _nameController,
            hint: 'Örn: Aymira Butik',
            icon: Icons.storefront_rounded,
            errorText: _nameError,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildCoverPicker(),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'WhatsApp',
            controller: _whatsappController,
            hint: '05xx xxx xx xx',
            icon: Icons.chat_bubble_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Kısa açıklama',
            controller: _descriptionController,
            hint: 'Bugün vitrinde ne var?',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishVitrin,
              icon:
                  _isPublishing
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.rocket_launch_rounded, size: 19),
              label: Text(
                _isPublishing ? 'Yayına alınıyor...' : 'Vitrinimi Yayına Al',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Linkin oluşur, Keşfet’te görünürsün.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedView() {
    final info = _publishedInfo!;
    final cover = _coverUrl?.trim() ?? '';
    final name =
        _data.name.trim().isNotEmpty ? _data.name.trim() : info.name.trim();
    final description = _data.description.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Vitrinin yayında',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Linkin, QR kodun ve Keşfet görünürlüğün hazır.',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onOpenExplore,
              icon: const Icon(Icons.travel_explore_rounded),
              color: primaryColor,
              tooltip: 'Keşfet',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: cardBorder),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          decoration: _cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    cover.isNotEmpty
                        ? Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  _buildCoverPlaceholder(),
                        )
                        : _buildCoverPlaceholder(),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFDF5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Keşfet’te yayında',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name.isEmpty ? 'Vitrinim' : name,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      info.publicLink,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPublishedActions(),
      ],
    );
  }

  Widget _buildPublishedActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth =
            constraints.maxWidth < 520
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildActionButton(
              width: buttonWidth,
              label: 'Vitrini Düzenle',
              icon: Icons.edit_rounded,
              onPressed: _openEditor,
            ),
            _buildActionButton(
              width: buttonWidth,
              label: 'Yayındaki Vitrini Aç',
              icon: Icons.open_in_new_rounded,
              onPressed: _openPublicVitrin,
            ),
            _buildActionButton(
              width: buttonWidth,
              label: 'Linki Kopyala',
              icon: Icons.copy_rounded,
              onPressed: _copyLink,
            ),
            _buildActionButton(
              width: buttonWidth,
              label: 'QR Göster',
              icon: Icons.qr_code_2_rounded,
              onPressed: _showQrSheet,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required double width,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          backgroundColor: Colors.white,
          side: const BorderSide(color: cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPicker() {
    final hasCover =
        _coverBytes != null || (_coverUrl?.trim().isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapak fotoğrafı',
          style: TextStyle(
            color: softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCoverPhoto,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                hasCover
                    ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_coverBytes != null)
                          Image.memory(_coverBytes!, fit: BoxFit.cover)
                        else
                          Image.network(
                            _coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _buildCoverPlaceholder(),
                          ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: _coverBadge(
                            _coverFileName == null
                                ? 'Fotoğrafı değiştir'
                                : _coverFileName!,
                          ),
                        ),
                      ],
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          color: primaryColor,
                          size: 34,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fotoğraf ekle',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'İsteğe bağlı',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Widget _coverBadge(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEFE7), Color(0xFFF8FAFC)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_rounded, color: primaryColor, size: 38),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: mutedText, size: 18),
            hintText: hint,
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.62),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: inputBg,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}
