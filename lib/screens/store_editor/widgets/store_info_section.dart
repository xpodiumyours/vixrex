import 'package:flutter/material.dart';
import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/models/store_data.dart';
import '../store_editor_controller.dart';
import 'editor_ui_components.dart';

class StoreInfoSection extends StatefulWidget {
  final StoreEditorController controller;
  final Map<StoreScoreTarget, GlobalKey> scoreTargetKeys;

  const StoreInfoSection({
    super.key,
    required this.controller,
    required this.scoreTargetKeys,
  });

  @override
  State<StoreInfoSection> createState() => _StoreInfoSectionState();
}

class _StoreInfoSectionState extends State<StoreInfoSection> {
  final List<String> categories = const [
    'Giyim & Butik',
    'Gıda & Fırın',
    'Kozmetik',
    'Dekorasyon',
    'Elektronik',
    'Kırtasiye',
    'Diğer',
  ];

  final List<String> businessTypes = const [
    'Butik',
    'İç giyim',
    'Kozmetik',
    'Hediyelik',
    'Market',
    'Telefon aksesuarı',
    'Kafe / Lokanta',
    'Kuaför',
    'Diğer',
  ];

  final List<String> platforms = const [
    'Trendyol',
    'Hepsiburada',
    'N11',
    'Amazon',
    'Çiçeksepeti',
    'Shopier',
    'Diğer',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final data = controller.data;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            EditCard(
              title: 'Temel Bilgiler',
              children: [
                ScoreTargetAnchor(
                  target: StoreScoreTarget.storeName,
                  controller: controller,
                  scoreTargetKeys: widget.scoreTargetKeys,
                  child: EditorTextField(
                    label: 'Mağaza adı',
                    initial: data.name,
                    onChanged: controller.handleStoreNameChanged,
                  ),
                ),
                const SizedBox(height: 16),
                EditorDropdown(
                  label: 'Kategori',
                  value:
                      categories.contains(data.kategori)
                          ? data.kategori
                          : 'Diğer',
                  items: categories,
                  onChanged: (v) {
                    setState(() {
                      data.kategori = v!;
                      if (data.businessType.isEmpty ||
                          categories.contains(data.businessType)) {
                        data.businessType = v;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                EditorDropdown(
                  label: 'İşletme türü',
                  value:
                      businessTypes.contains(data.businessType)
                          ? data.businessType
                          : (businessTypes.contains(data.kategori)
                              ? data.kategori
                              : 'Diğer'),
                  items:
                      businessTypes.contains(data.businessType)
                          ? businessTypes
                          : [...businessTypes, data.businessType],
                  onChanged: (v) {
                    setState(() {
                      data.businessType = v!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ScoreTargetAnchor(
                  target: StoreScoreTarget.description,
                  controller: controller,
                  scoreTargetKeys: widget.scoreTargetKeys,
                  child: EditorTextField(
                    label: 'Kısa açıklama (Mağaza Altı)',
                    initial: data.description,
                    maxLines: 2,
                    hintText: 'İşletmenizi kısaca anlatın',
                    onChanged: (v) => data.description = v,
                  ),
                ),
                const SizedBox(height: 16),
                EditorTextField(
                  label: 'Günlük Duyuru / Durum',
                  initial: data.status,
                  hintText: 'Örn: Bugün taze börekler çıktı! veya %20 indirim!',
                  prefixIcon: Icons.campaign_rounded,
                  onChanged: (v) => data.status = v,
                ),
                const SizedBox(height: 16),
                EditorTextField(
                  label: 'Çalışma Saatleri',
                  initial: data.workingHours,
                  hintText: 'Örn: Pzt-Cmt: 09:00 - 20:00, Pazar: Kapalı',
                  prefixIcon: Icons.access_time_rounded,
                  onChanged: (v) => data.workingHours = v,
                ),
              ],
            ),
            const SizedBox(height: 24),
            EditCard(
              title: 'Kurumsal Bilgiler',
              children: [
                ScoreTargetAnchor(
                  target: StoreScoreTarget.about,
                  controller: controller,
                  scoreTargetKeys: widget.scoreTargetKeys,
                  child: EditorTextField(
                    label: 'Hakkımızda Metni',
                    initial: data.corporateBio,
                    maxLines: 4,
                    onChanged: (v) => data.corporateBio = v,
                  ),
                ),
                const SizedBox(height: 12),
                EditorTextField(
                  label: 'Referans / yorum linki',
                  initial: data.referencesLink,
                  prefixIcon: Icons.verified_rounded,
                  hintText:
                      'Örn: Google yorumları, Instagram öne çıkanlar veya web sayfanız',
                  onChanged: (v) => data.referencesLink = v,
                ),
              ],
            ),
            const SizedBox(height: 24),
            EditCard(
              title: 'İletişim & Sosyal',
              children: [
                ScoreTargetAnchor(
                  target: StoreScoreTarget.whatsapp,
                  controller: controller,
                  scoreTargetKeys: widget.scoreTargetKeys,
                  child: EditorTextField(
                    label: 'WhatsApp',
                    initial: data.whatsapp,
                    prefixIcon: Icons.phone_rounded,
                    hintText: 'Örn: 05xx xxx xx xx',
                    onChanged: (v) => data.whatsapp = v,
                  ),
                ),
                const SizedBox(height: 12),
                ScoreTargetAnchor(
                  target: StoreScoreTarget.social,
                  controller: controller,
                  scoreTargetKeys: widget.scoreTargetKeys,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EditorTextField(
                        label: 'Instagram',
                        initial: data.instagram,
                        prefixIcon: Icons.camera_alt_rounded,
                        hintText: 'Örn: instagram.com/magazaniz',
                        onChanged: (v) => data.instagram = v,
                      ),
                      const SizedBox(height: 12),
                      EditorTextField(
                        label: 'Web sitesi',
                        initial: data.website,
                        prefixIcon: Icons.language_rounded,
                        hintText: 'Örn: www.magazaniz.com',
                        onChanged: (v) => data.website = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ScoreTargetAnchor(
                  target: StoreScoreTarget.address,
                  controller: controller,
                  scoreTargetKeys: widget.scoreTargetKeys,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EditorTextField(
                        label: 'Adres',
                        controller: controller.addressCtrl,
                        prefixIcon: Icons.location_on_rounded,
                        maxLines: 2,
                        hintText: 'Örn: Mahalle, cadde, ilçe',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child:
                              controller.isLocating
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFFFF4D00),
                                              ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : IconButton(
                                    icon: const Icon(
                                      Icons.my_location_rounded,
                                      size: 20,
                                    ),
                                    color: const Color(0xFFFF4D00),
                                    disabledColor: const Color(
                                      0xFF64748B,
                                    ).withAlpha((0.4 * 255).round()),
                                    onPressed:
                                        controller.kvkkConsent &&
                                                !controller.isLocating
                                            ? controller.getCurrentLocation
                                            : null,
                                    tooltip: 'Konumumu Kullan',
                                  ),
                        ),
                        onChanged: (v) => data.address = v,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: controller.kvkkConsent,
                              activeColor: const Color(0xFFFF4D00),
                              onChanged: (val) {
                                controller.setKvkkConsent(val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                controller.setKvkkConsent(
                                  !controller.kvkkConsent,
                                );
                              },
                              child: const Text(
                                'Konum verilerimin KVKK kapsamında işlenmesine açık rıza veriyorum.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed:
                              () => Navigator.pushNamed(
                                context,
                                LegalConfig.privacyPath,
                              ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF4D00),
                            padding: const EdgeInsets.only(left: 32, top: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'KVKK ve gizlilik metnini görüntüle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (controller.locationStatusMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          controller.locationStatusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                controller.latitude != null
                                    ? Colors.green.shade700
                                    : controller.pendingMapsLatitude != null
                                    ? Colors.orange.shade800
                                    : Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (controller.pendingMapsLatitude != null &&
                            controller.pendingMapsLongitude != null)
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: controller.openPendingLocationInMaps,
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: const Text("Google Maps'te Kontrol Et"),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF4D00),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: controller.confirmPendingLocation,
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: const Text('Bu Konumu Kullan'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ScoreTargetAnchor(
              target: StoreScoreTarget.marketplace,
              controller: controller,
              scoreTargetKeys: widget.scoreTargetKeys,
              child: EditCard(
                title: 'Pazaryeri Linkleri',
                onAction: () {
                  setState(() {
                    data.marketplaceLinks.add(
                      MarketplaceLink(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                      ),
                    );
                  });
                },
                children: [
                  ...List.generate(
                    data.marketplaceLinks.length,
                    (index) => _buildMarketplaceLinkItem(index),
                  ),
                  if (data.marketplaceLinks.isEmpty)
                    Center(
                      child: Text(
                        'Henüz link eklenmedi.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarketplaceLinkItem(int index) {
    final controller = widget.controller;
    final data = controller.data;
    final link = data.marketplaceLinks[index];
    const cardBorder = Color.fromRGBO(15, 23, 42, 0.10);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.045 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: EditorDropdown(
                  label: 'Platform',
                  value: link.platform,
                  items: platforms,
                  onChanged: (v) {
                    setState(() {
                      link.platform = v!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    data.marketplaceLinks.removeAt(index);
                  });
                },
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EditorTextField(
            label: 'Mağaza Linki',
            initial: link.url,
            prefixIcon: Icons.link_rounded,
            onChanged: (v) {
              link.url = v;
            },
          ),
        ],
      ),
    );
  }
}
