import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

class FeaturedCampaignSheet extends StatefulWidget {
  final StoreData storeData;

  const FeaturedCampaignSheet({super.key, required this.storeData});

  @override
  State<FeaturedCampaignSheet> createState() => _FeaturedCampaignSheetState();
}

class _FeaturedCampaignSheetState extends State<FeaturedCampaignSheet> {
  late final TextEditingController _label;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _priceNote;
  late final TextEditingController _imageUrl;

  @override
  void initState() {
    super.initState();
    final data = widget.storeData;
    _label = TextEditingController(text: data.featuredBannerLabel);
    _title = TextEditingController(text: data.featuredBannerTitle);
    _description = TextEditingController(text: data.featuredBannerDescription);
    _priceNote = TextEditingController(text: data.featuredBannerPriceText);
    _imageUrl = TextEditingController(text: data.featuredBannerImageUrl);
  }

  @override
  void dispose() {
    _label.dispose();
    _title.dispose();
    _description.dispose();
    _priceNote.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(<String, String>{
      'label': _label.text.trim(),
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'priceText': _priceNote.text.trim(),
      'imageUrl': _imageUrl.text.trim(),
    });
  }

  void _clear() {
    Navigator.of(context).pop(<String, String>{
      'label': '',
      'title': '',
      'description': '',
      'priceText': '',
      'imageUrl': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Öne Çıkan Kampanya',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Boş bırakırsan vitrinde bu bölüm gizlenir.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 18),
              EditorTextField(
                label: 'Etiket',
                controller: _label,
                hint: 'Örn: Yeni Sezon',
                icon: Icons.label_outline_rounded,
              ),
              const SizedBox(height: 12),
              EditorTextField(
                label: 'Başlık',
                controller: _title,
                hint: 'Örn: Sonbahar / Kış Koleksiyonu',
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 12),
              EditorTextField(
                label: 'Açıklama',
                controller: _description,
                hint: 'Kısa kampanya metni',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              EditorTextField(
                label: 'Fiyat notu',
                controller: _priceNote,
                hint: 'Örn: 349 TL’den başlayan fiyatlarla',
                icon: Icons.sell_outlined,
              ),
              const SizedBox(height: 12),
              EditorTextField(
                label: 'Görsel bağlantısı',
                controller: _imageUrl,
                hint: 'https://...',
                icon: Icons.image_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Kaydet'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clear,
                child: const Text('Kampanyayı temizle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
