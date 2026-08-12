import 'package:flutter/material.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

/// Hero konum metni ve harita kartı etiketi — vitrin GÖRÜNÜMÜNÜ inceltmek
/// için manuel panele eklenen ileri seviye alanlar (PR #70, 2026-08-09).
/// Zorunlu değildir, boş kalırsa vitrin normal adresi kullanır.
///
/// NEDEN AYRI MODÜL (2026-08-12, mimari bulgu): Bu iki alan eskiden
/// `LocationEditorSection`'ın içinde, bir `showAdvancedFields` bayrağıyla
/// koşullu olarak çiziliyordu. `LocationEditorSection` zaten 400 satırı
/// aşan bir modül; AGENTS.md'nin mimari büyüme yasağı böyle bir modüle
/// yeni sorumluluk eklenmesini yasaklıyor. Alan çifti kendi sahip
/// modülüne taşındı — `LocationEditorSection` yalnız il/ilçe/adres/GPS'i
/// bilir, bu widget'ın varlığından habersizdir. Gösterip göstermeme
/// kararı artık `FormLocationInfo` (küçük, sahiplik ataması yapan
/// bileşen) seviyesinde veriliyor.
class AdvancedLocationFields extends StatelessWidget {
  const AdvancedLocationFields({
    super.key,
    required this.heroLocationTextController,
    required this.mapLabelController,
    required this.onHeroLocationTextChanged,
    required this.onMapLabelChanged,
  });

  final TextEditingController heroLocationTextController;
  final TextEditingController mapLabelController;
  final ValueChanged<String> onHeroLocationTextChanged;
  final ValueChanged<String> onMapLabelChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorTextField(
          label: 'Hero Konum Metni',
          controller: heroLocationTextController,
          hint: 'Örn: Kadıköy, İstanbul',
          icon: Icons.place_outlined,
          maxLength: 60,
          onChanged: onHeroLocationTextChanged,
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: 'Harita Kartı Etiketi',
          controller: mapLabelController,
          hint: 'Örn: Atatürk Cad. No:24',
          icon: Icons.map_outlined,
          maxLength: 120,
          onChanged: onMapLabelChanged,
        ),
      ],
    );
  }
}
