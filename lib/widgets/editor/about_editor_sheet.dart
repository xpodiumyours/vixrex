import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

class AboutEditorSheet extends StatefulWidget {
  final StoreData storeData;

  const AboutEditorSheet({super.key, required this.storeData});

  @override
  State<AboutEditorSheet> createState() => _AboutEditorSheetState();
}

class _AboutEditorSheetState extends State<AboutEditorSheet> {
  late final TextEditingController _kicker;
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _imageUrl;
  late final TextEditingController _caption;
  late final List<TextEditingController> _valueTitles;
  late final List<TextEditingController> _valueDescriptions;

  @override
  void initState() {
    super.initState();
    final data = widget.storeData;
    _kicker = TextEditingController(text: data.aboutKicker);
    _title = TextEditingController(text: data.aboutTitle);
    _body = TextEditingController(text: data.corporateBio);
    _imageUrl = TextEditingController(text: data.aboutImageUrl);
    _caption = TextEditingController(text: data.aboutImageCaption);

    final values = List<StoreAboutValue>.from(data.aboutValues);
    while (values.length < 3) {
      values.add(StoreAboutValue(id: 'about-value-${values.length + 1}'));
    }
    _valueTitles =
        values
            .take(3)
            .map((v) => TextEditingController(text: v.title))
            .toList();
    _valueDescriptions =
        values
            .take(3)
            .map((v) => TextEditingController(text: v.description))
            .toList();
  }

  @override
  void dispose() {
    _kicker.dispose();
    _title.dispose();
    _body.dispose();
    _imageUrl.dispose();
    _caption.dispose();
    for (final c in _valueTitles) {
      c.dispose();
    }
    for (final c in _valueDescriptions) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final values = <StoreAboutValue>[];
    for (var i = 0; i < 3; i++) {
      final title = _valueTitles[i].text.trim();
      if (title.isEmpty) continue;
      values.add(
        StoreAboutValue(
          id: 'about-value-${i + 1}',
          title: title,
          description: _valueDescriptions[i].text.trim(),
        ),
      );
    }

    Navigator.of(context).pop(<String, dynamic>{
      'kicker': _kicker.text.trim(),
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'imageUrl': _imageUrl.text.trim(),
      'imageCaption': _caption.text.trim(),
      'values': values,
    });
  }

  void _clear() {
    Navigator.of(context).pop(<String, dynamic>{
      'kicker': '',
      'title': '',
      'body': '',
      'imageUrl': '',
      'imageCaption': '',
      'values': <StoreAboutValue>[],
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
                'Hakkımızda',
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
                label: 'Üst etiket',
                controller: _kicker,
                hint: 'Örn: Atmosfer’in hikâyesi',
                icon: Icons.label_outline_rounded,
              ),
              const SizedBox(height: 12),
              EditorTextField(
                label: 'Başlık',
                controller: _title,
                hint: 'Kısa, güçlü bir cümle',
                icon: Icons.title_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              EditorTextField(
                label: 'Hikâye',
                controller: _body,
                hint: 'İşletmeni anlatan metin',
                icon: Icons.notes_rounded,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              EditorTextField(
                label: 'Görsel bağlantısı',
                controller: _imageUrl,
                hint: 'https://...',
                icon: Icons.image_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              EditorTextField(
                label: 'Görsel alt yazı',
                controller: _caption,
                hint: 'Örn: Küçük seriler, özenli seçimler',
                icon: Icons.short_text_rounded,
              ),
              const SizedBox(height: 18),
              const Text(
                'Değer kartları (en fazla 3)',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < 3; i++) ...[
                EditorTextField(
                  label: 'Kart ${i + 1} başlık',
                  controller: _valueTitles[i],
                  hint: 'Örn: Seçili koleksiyon',
                  icon: Icons.star_outline_rounded,
                ),
                const SizedBox(height: 8),
                EditorTextField(
                  label: 'Kart ${i + 1} açıklama',
                  controller: _valueDescriptions[i],
                  hint: 'Kısa açıklama',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                if (i < 2) const SizedBox(height: 14),
              ],
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Kaydet'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clear,
                child: const Text('Hakkımızda’yı temizle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
