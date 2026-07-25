import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Flutter panel içinde `/v/*` açılınca müşteri UI'sı (Next.js) dışarıda açılır.
/// Dosya silmeden çift vitrin yüzünü keser.
class PublicSiteRedirectScreen extends StatefulWidget {
  final String publicPath;

  const PublicSiteRedirectScreen({
    super.key,
    required this.publicPath,
  });

  factory PublicSiteRedirectScreen.fromPath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return PublicSiteRedirectScreen(publicPath: normalized);
  }

  @override
  State<PublicSiteRedirectScreen> createState() =>
      _PublicSiteRedirectScreenState();
}

class _PublicSiteRedirectScreenState extends State<PublicSiteRedirectScreen> {
  bool _launchFailed = false;
  late final String _url;

  @override
  void initState() {
    super.initState();
    _url = PublicSiteConfig.buildPublicLink(widget.publicPath);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPublicSite());
  }

  Future<void> _openPublicSite() async {
    final uri = Uri.tryParse(_url);
    var launched = false;
    if (uri != null) {
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }
    }
    if (!mounted) return;
    setState(() => _launchFailed = !launched);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        backgroundColor: AppColors.bgEditor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkText),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/app');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.open_in_new_rounded,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _launchFailed
                    ? 'Müşteri vitrini açılamadı.'
                    : 'Müşteri vitrinine yönlendiriliyor…',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _openPublicSite,
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('Vitrini Aç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
