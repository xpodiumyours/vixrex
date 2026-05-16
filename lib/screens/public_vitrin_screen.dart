import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';

class PublicVitrinScreen extends StatefulWidget {
  final String slug;

  const PublicVitrinScreen({super.key, required this.slug});

  @override
  State<PublicVitrinScreen> createState() => _PublicVitrinScreenState();
}

class _PublicVitrinScreenState extends State<PublicVitrinScreen> {
  late final Future<StoreData?> _storeFuture;

  @override
  void initState() {
    super.initState();
    _storeFuture = _fetchStore();
  }

  Future<StoreData?> _fetchStore() async {
    final response =
        await Supabase.instance.client
            .from('stores')
            .select()
            .eq('slug', widget.slug)
            .eq('is_published', true)
            .maybeSingle();

    if (response == null) return null;
    return _storeDataFromSupabase(response);
  }

  StoreData _storeDataFromSupabase(Map<String, dynamic> data) {
    final description = _readString(data['description']);

    return StoreData(
      name: _readString(data['name']),
      businessType: _readString(data['business_type'], fallback: 'Butik'),
      description: description,
      whatsapp: _readString(data['whatsapp']),
      instagram: _readString(data['instagram']),
      website: _readString(data['website']),
      address: _readString(data['address']),
      theme: _readString(data['theme'], fallback: 'Sade'),
      status: _readString(data['status'], fallback: 'Açık'),
      isEsnafMode: true,
      corporateBio: description,
      marketplaceLinks: _parseMarketplaceLinks(data['marketplace_links']),
    );
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  List<MarketplaceLink> _parseMarketplaceLinks(Object? rawLinks) {
    try {
      final decodedLinks = rawLinks is String ? jsonDecode(rawLinks) : rawLinks;

      if (decodedLinks is! List) return [];

      return decodedLinks
          .whereType<Map>()
          .map(
            (link) => MarketplaceLink(
              id: UniqueKey().toString(),
              platform: _readString(link['platform']),
              url: _readString(link['url']),
            ),
          )
          .where(
            (link) =>
                link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
          )
          .toList();
    } catch (error) {
      debugPrint('Marketplace links parse error: $error');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoreData?>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PublicVitrinStateView(
            title: 'Vitrin yükleniyor...',
            icon: Icons.hourglass_empty_rounded,
            showLoader: true,
          );
        }

        if (snapshot.hasError) {
          debugPrint('Public vitrin load error: ${snapshot.error}');
          return const _PublicVitrinStateView(
            title: 'Vitrin yüklenirken bir sorun oluştu.',
            icon: Icons.info_outline_rounded,
          );
        }

        final storeData = snapshot.data;
        if (storeData == null) {
          return const _PublicVitrinStateView(
            title: 'Vitrin bulunamadı.',
            icon: Icons.search_off_rounded,
          );
        }

        return _PublicVitrinShell(
          child: VitrinView(storeData: storeData, publicMode: true),
        );
      },
    );
  }
}

class _PublicVitrinShell extends StatelessWidget {
  final Widget child;

  const _PublicVitrinShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 640;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 0,
                vertical: isDesktop ? 24 : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isDesktop ? 28 : 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow:
                            isDesktop
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 30,
                                    offset: const Offset(0, 16),
                                  ),
                                ]
                                : null,
                      ),
                      child: child,
                    ),
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

class _PublicVitrinStateView extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool showLoader;

  const _PublicVitrinStateView({
    required this.title,
    required this.icon,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF5A1F), size: 26),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                if (showLoader) ...[
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF5A1F),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
