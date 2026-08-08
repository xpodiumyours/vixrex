import 'package:flutter/material.dart';
import 'package:vixrex/config/turkey_cities_config.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/utils/text_utils.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

class LocationEditorSection extends StatefulWidget {
  final String? selectedProvinceCode;
  final String? selectedProvinceName;
  final String? selectedDistrictCode;
  final String? selectedDistrictName;
  final String? provinceError;
  final String? districtError;
  final String? addressError;
  final TextEditingController addressController;
  final TextEditingController heroLocationTextController;
  final TextEditingController mapLabelController;

  final double? latitude;
  final double? longitude;
  final double? locationAccuracyMeters;
  final String? locationStatusMessage;
  final bool isLocating;

  final void Function(String? provinceCode, String? provinceName)
  onProvinceChanged;
  final void Function(String? districtCode, String? districtName)
  onDistrictChanged;
  final void Function(String address) onAddressChanged;
  final ValueChanged<String> onHeroLocationTextChanged;
  final ValueChanged<String> onMapLabelChanged;
  final void Function({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? statusMessage,
    String? address,
    String? provinceCode,
    String? provinceName,
    String? districtCode,
    String? districtName,
  })
  onLocationUpdated;
  final void Function(bool locating) onLocatingStateChanged;

  const LocationEditorSection({
    super.key,
    required this.selectedProvinceCode,
    required this.selectedProvinceName,
    required this.selectedDistrictCode,
    required this.selectedDistrictName,
    required this.provinceError,
    required this.districtError,
    required this.addressError,
    required this.addressController,
    required this.heroLocationTextController,
    required this.mapLabelController,
    required this.latitude,
    required this.longitude,
    required this.locationAccuracyMeters,
    required this.locationStatusMessage,
    required this.isLocating,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onAddressChanged,
    required this.onHeroLocationTextChanged,
    required this.onMapLabelChanged,
    required this.onLocationUpdated,
    required this.onLocatingStateChanged,
  });

  @override
  State<LocationEditorSection> createState() => _LocationEditorSectionState();
}

class _LocationEditorSectionState extends State<LocationEditorSection> {
  static const Color primaryColor = AppColors.primary;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;
  static const Color softText = AppColors.softText;
  static const Color cardBorder = AppColors.cardBorderDark;
  static const Color inputBg = AppColors.inputBg;

  bool _isInternalLocating = false;

  /// GPS'ten çözülen ama HENÜZ YAZILMAMIŞ adres önerisi.
  ///
  /// NEDEN VAR (2026-08-08):
  /// Kod koordinatı alıp adresi sessizce yazıyordu. Tarayıcının verdiği
  /// koordinat bazen 30 metre, bazen 20 KM sapıyor — hangisi olduğu
  /// önceden bilinemiyor. Casper 8 Ağustos'ta Çekmeköy'deyken vitrinine
  /// "Ümraniye, Adem Yavuz Mahallesi" yazıldı.
  ///
  /// Sabit bir sapma eşiği bunu çözmüyor: eşik dar olursa hiç konum
  /// alınamıyor, geniş olursa yanlış adres yazılıyor. İki denemede de
  /// bunu yaşadık.
  ///
  /// Doğru yer kararı verecek olan ESNAF. Adres çözülür, gösterilir,
  /// onaylanmadan hiçbir alana yazılmaz.
  _AdresOnerisi? _bekleyenOneri;

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isInternalLocating = true;
      });
    }
    widget.onLocatingStateChanged(true);
    widget.onLocationUpdated(statusMessage: 'Konum aranıyor...');

    try {
      final result = await const LocationService().getCurrentLocation();
      if (!mounted) return;

      if (!result.isSuccess && !result.hasApproximatePosition) {
        widget.onLocationUpdated(statusMessage: result.errorMessage);
        return;
      }

      final position = result.position ?? result.approximatePosition!;

      // ONAYA KADAR HİÇBİR ŞEY YAZILMAZ — koordinat da adres de.
      //
      // Bu noktada iki kez yanlış yaptım (2026-08-07/08):
      // önce eşiği 10 metre yapıp her şeyi reddettim (esnaf boş ekrana
      // baktı), sonra eşiği gevşetip adresi koşulsuz yazdırdım (20 km
      // sapmalı adres vitrine düştü). Sabit eşik bu işi çözmüyor:
      // tarayıcı bazen 30 metre, bazen 20 km sapıyor ve hangisi olduğu
      // önceden bilinemiyor.
      //
      // Karar esnafa bırakıldı: adres çözülür, gösterilir, onaylanmadan
      // yazılmaz. Sapma da kartta yazar; esnaf ikisine birden bakar.
      widget.onLocationUpdated(statusMessage: 'Adres çözümleniyor...');

      final geoAddress = await const LocationService()
          .getAddressFromCoordinates(position.latitude, position.longitude);

      if (!mounted) return;

      String? updatedProvinceCode = widget.selectedProvinceCode;
      String? updatedProvinceName = widget.selectedProvinceName;
      String? updatedDistrictCode = widget.selectedDistrictCode;
      String? updatedDistrictName = widget.selectedDistrictName;
      String? newAddress = geoAddress;

      if (geoAddress != null && geoAddress.isNotEmpty) {
        // Auto-detect Province and District
        final normalizedAddress = TextUtils.normalizeTurkish(geoAddress);
        Province? matchedProvince;
        for (final province in turkeyProvinces) {
          final normalizedProvince = TextUtils.normalizeTurkish(province.name);
          if (normalizedAddress.contains(normalizedProvince)) {
            matchedProvince = province;
            break;
          }
        }

        if (matchedProvince != null) {
          updatedProvinceCode = matchedProvince.code;
          updatedProvinceName = matchedProvince.name;

          final districts = turkeyDistricts[matchedProvince.code] ?? [];
          String? matchedDistrict;
          for (final district in districts) {
            final normalizedDistrict = TextUtils.normalizeTurkish(district);
            if (normalizedAddress.contains(normalizedDistrict)) {
              matchedDistrict = district;
              break;
            }
          }
          if (matchedDistrict != null) {
            updatedDistrictCode = matchedDistrict;
            updatedDistrictName = matchedDistrict;
          } else {
            updatedDistrictCode = null;
            updatedDistrictName = null;
          }
        }
      }

      // HİÇBİR ALANA YAZILMAZ — önce esnafa gösterilir.
      setState(() {
        _bekleyenOneri = _AdresOnerisi(
          adres: newAddress ?? '',
          ilKodu: updatedProvinceCode,
          ilAdi: updatedProvinceName,
          ilceKodu: updatedDistrictCode,
          ilceAdi: updatedDistrictName,
          enlem: position.latitude,
          boylam: position.longitude,
          sapmaMetre: position.accuracy,
        );
      });
      widget.onLocationUpdated(statusMessage: null);
    } finally {
      if (mounted) {
        setState(() {
          _isInternalLocating = false;
        });
        widget.onLocatingStateChanged(false);
      }
    }
  }

  /// Esnaf "burası" dedi — ancak şimdi yazılır.
  void _oneriyiKabulEt() {
    final o = _bekleyenOneri;
    if (o == null) return;
    widget.onLocationUpdated(
      latitude: o.enlem,
      longitude: o.boylam,
      accuracy: o.sapmaMetre,
      address: o.adres,
      provinceCode: o.ilKodu,
      provinceName: o.ilAdi,
      districtCode: o.ilceKodu,
      districtName: o.ilceAdi,
      statusMessage: 'Konum kaydedildi.',
    );
    setState(() => _bekleyenOneri = null);
  }

  /// Esnaf "burası değil" dedi — hiçbir şey yazılmaz, alanlar elle
  /// doldurulur. Yanlış adres, boş adresten beterdir.
  void _oneriyiReddet() {
    setState(() => _bekleyenOneri = null);
    widget.onLocationUpdated(
      statusMessage: 'Konum kullanılmadı. İl, ilçe ve adresi elle yaz.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocatingActive = widget.isLocating || _isInternalLocating;
    final districts =
        widget.selectedProvinceCode != null
            ? (turkeyDistricts[widget.selectedProvinceCode] ?? [])
            : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown: İl
        Row(
          children: [
            const Text(
              'İl',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: widget.selectedProvinceCode,
          dropdownColor: inputBg,
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'İl seçiniz',
            hintStyle: const TextStyle(color: softText, fontSize: 13),
            errorText: widget.provinceError,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            filled: true,
            fillColor: inputBg,
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
              vertical: 12,
            ),
          ),
          items:
              turkeyProvinces.map((province) {
                return DropdownMenuItem<String>(
                  value: province.code,
                  child: Text(province.name),
                );
              }).toList(),
          onChanged: (code) {
            final found = turkeyProvinces.firstWhere(
              (p) => p.code == code,
              orElse: () => const Province('', ''),
            );
            widget.onProvinceChanged(
              code,
              found.name.isNotEmpty ? found.name : null,
            );
          },
        ),
        const SizedBox(height: 14),

        // Dropdown: İlçe
        Row(
          children: [
            const Text(
              'İlçe',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: widget.selectedDistrictCode,
          dropdownColor: inputBg,
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText:
                widget.selectedProvinceCode == null
                    ? 'Önce il seçiniz'
                    : 'İlçe seçiniz',
            hintStyle: const TextStyle(color: softText, fontSize: 13),
            errorText: widget.districtError,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            filled: true,
            fillColor: inputBg,
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
              vertical: 12,
            ),
          ),
          items:
              districts.map((district) {
                return DropdownMenuItem<String>(
                  value: district,
                  child: Text(district),
                );
              }).toList(),
          onChanged:
              widget.selectedProvinceCode == null
                  ? null
                  : (val) {
                    widget.onDistrictChanged(val, val);
                  },
        ),
        const SizedBox(height: 14),

        // TextField: Açık Adres
        Row(
          children: [
            const Text(
              'Açık Adres (Mahalle, Cadde, Sokak, No)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.addressController,
          onChanged: widget.onAddressChanged,
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Örn: Çatalmeşe Mah. 207. Sokak No: 12',
            hintStyle: const TextStyle(color: softText, fontSize: 13),
            errorText: widget.addressError,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            filled: true,
            fillColor: inputBg,
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
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: OutlinedButton(
            onPressed: isLocatingActive ? null : _getCurrentLocation,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color:
                    isLocatingActive ? const Color(0xFF0EA5E9) : primaryColor,
                width: isLocatingActive ? 1.8 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child:
                isLocatingActive
                    ? const _ScanningLocationWidget()
                    : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'GPS ile Konumumu Al',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
        // ONAY KARTI — adres yazılmadan önce esnafa sorulur.
        if (_bekleyenOneri != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Konumunu buldum. Burası mı?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _bekleyenOneri!.adres.isEmpty
                      ? 'Adres çözülemedi'
                      : _bekleyenOneri!.adres,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'yaklaşık ${_bekleyenOneri!.sapmaMetre.toStringAsFixed(0)} m sapma',
                  style: const TextStyle(fontSize: 11, color: mutedText),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _oneriyiKabulEt,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text(
                          'Evet, burası',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _oneriyiReddet,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: mutedText,
                          side: const BorderSide(color: cardBorder),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text(
                          'Hayır, elle yazayım',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (widget.locationStatusMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.locationStatusMessage!,
            style: const TextStyle(
              color: mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (widget.latitude != null && widget.longitude != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 4),
              Text(
                'Koordinat kaydedildi (${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)})',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        EditorTextField(
          label: 'Hero Konum Metni',
          controller: widget.heroLocationTextController,
          hint: 'Örn: Kadıköy, İstanbul',
          icon: Icons.place_outlined,
          maxLength: 60,
          onChanged: widget.onHeroLocationTextChanged,
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: 'Harita Kartı Etiketi',
          controller: widget.mapLabelController,
          hint: 'Örn: Atatürk Cad. No:24',
          icon: Icons.map_outlined,
          maxLength: 120,
          onChanged: widget.onMapLabelChanged,
        ),
      ],
    );
  }
}

class _ScanningLocationWidget extends StatefulWidget {
  const _ScanningLocationWidget();

  @override
  State<_ScanningLocationWidget> createState() =>
      _ScanningLocationWidgetState();
}

class _ScanningLocationWidgetState extends State<_ScanningLocationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withAlpha(140),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: Color(0xFF0EA5E9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'GPS Taranıyor...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// GPS'ten çözülen, onay bekleyen adres.
///
/// Esnaf "Evet, burası" demeden hiçbir alana yazılmaz. Tarayıcının
/// verdiği koordinat bazen 30 metre bazen 20 KM sapıyor; hangisi olduğu
/// önceden bilinemiyor. Kararı veren esnaf olmalı — 2026-08-08.
class _AdresOnerisi {
  const _AdresOnerisi({
    required this.adres,
    required this.ilKodu,
    required this.ilAdi,
    required this.ilceKodu,
    required this.ilceAdi,
    required this.enlem,
    required this.boylam,
    required this.sapmaMetre,
  });

  final String adres;
  final String? ilKodu;
  final String? ilAdi;
  final String? ilceKodu;
  final String? ilceAdi;
  final double enlem;
  final double boylam;
  final double sapmaMetre;
}
