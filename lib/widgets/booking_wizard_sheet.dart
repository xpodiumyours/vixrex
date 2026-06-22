import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

class BookingWizardSheet extends StatefulWidget {
  final StoreData storeData;

  const BookingWizardSheet({super.key, required this.storeData});

  @override
  State<BookingWizardSheet> createState() => _BookingWizardSheetState();
}

class _BookingWizardSheetState extends State<BookingWizardSheet> {
  int _currentStep = 1; // 1: Service, 2: Date, 3: Slot, 4: Details, 5: Success
  StoreOffering? _selectedService;
  DateTime? _selectedDate;
  String? _selectedSlotTime;

  // Form Fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _kvkkConsent = false;

  // State
  bool _isLoadingSlots = false;
  List<dynamic> _availableSlots = [];
  bool _isSubmitting = false;
  String? _createdToken;
  String? _errorMsg;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // 30 days calculation
  List<DateTime> get _availableDates {
    final list = <DateTime>[];
    final today = DateTime.now();
    final settings = widget.storeData.bookingSettings;
    if (settings == null) return [];

    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      final dow = date.weekday.toString(); // 1 = Monday, 7 = Sunday
      final dowConfig = settings.workingHours[dow];
      if (dowConfig != null && (dowConfig['active'] ?? false) == true) {
        list.add(date);
      }
    }
    return list;
  }

  Future<void> _fetchSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
      _errorMsg = null;
    });

    try {
      final client = Supabase.instance.client;
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await client.rpc('get_public_booking_slots', params: {
        'p_store_slug': widget.storeData.slug,
        'p_date': dateStr,
      });

      if (mounted) {
        setState(() {
          _availableSlots = res as List<dynamic>;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch slots error: $e');
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
          _errorMsg = 'Saat dilimleri yüklenirken bir hata oluştu.';
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final notes = _notesController.text.trim();

    if (name.isEmpty || phone.isEmpty || !_kvkkConsent || _selectedDate == null || _selectedSlotTime == null || _selectedService == null) {
      setState(() => _errorMsg = 'Lütfen tüm zorunlu alanları doldurun ve onay verin.');
      return;
    }

    if (!WhatsAppLinkHelper.isValidTurkeyMobile(phone)) {
      setState(() => _errorMsg = WhatsAppLinkHelper.invalidNumberMessage);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      final client = Supabase.instance.client;
      final datePart = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final apptTime = DateTime.parse('$datePart $_selectedSlotTime:00').toUtc().toIso8601String();

      final res = await client.rpc('create_appointment_request', params: {
        'p_store_slug': widget.storeData.slug,
        'p_customer_name': name,
        'p_customer_phone': phone,
        'p_customer_notes': notes,
        'p_service_title': _selectedService!.title,
        'p_service_price': _selectedService!.price,
        'p_service_duration': _selectedService!.durationMinutes,
        'p_appointment_time': apptTime,
      });

      final token = res['token'] as String;
      final apptId = res['appointment_id'] as String;

      // Save token locally in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedTokens = prefs.getStringList('booking_tokens') ?? [];
      savedTokens.add('$apptId:$token');
      await prefs.setStringList('booking_tokens', savedTokens);

      if (mounted) {
        setState(() {
          _createdToken = token;
          _isSubmitting = false;
          _currentStep = 5;
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('Create appointment error: $e');
      String msg = 'Talebiniz oluşturulamadı.';
      if (e.message.contains('DAILY_LIMIT_EXCEEDED')) {
        msg = 'Günlük randevu limiti sınırına ulaştınız.';
      } else if (e.message.contains('CAPACITY_FULL')) {
        msg = 'Seçtiğiniz saat diliminde yer kalmadı. Lütfen başka bir saat seçin.';
      } else if (e.message.contains('STORE_BUSY_TRY_AGAIN')) {
        msg = 'Sistem şu an meşgul. Lütfen tekrar deneyin.';
      }
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMsg = msg;
        });
      }
    } catch (e) {
      debugPrint('Create appointment unexpected error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMsg = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
        });
      }
    }
  }

  String _formatDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final monthNames = {
      1: 'Oca',
      2: 'Şub',
      3: 'Mar',
      4: 'Nis',
      5: 'May',
      6: 'Haz',
      7: 'Tem',
      8: 'Ağu',
      9: 'Eyl',
      10: 'Eki',
      11: 'Kas',
      12: 'Ara'
    };
    return '$day ${monthNames[date.month]}';
  }

  String _formatDayName(DateTime date) {
    final dayNames = {
      1: 'Pzt',
      2: 'Sal',
      3: 'Çar',
      4: 'Per',
      5: 'Cum',
      6: 'Cmt',
      7: 'Paz',
    };
    return dayNames[date.weekday]!;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final bookableServices = widget.storeData.offerings.where((o) => o.isBookable).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_currentStep > 1 && _currentStep < 5)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                          _errorMsg = null;
                        });
                      },
                    ),
                  Expanded(
                    child: Text(
                      _stepTitle,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.darkText),
                      textAlign: _currentStep == 5 ? TextAlign.center : TextAlign.start,
                    ),
                  ),
                  if (_currentStep < 5)
                    Text(
                      '$_currentStep/4',
                      style: const TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                ],
              ),
            ),
            const Divider(height: 24, color: AppColors.border),
            // Content area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildStepContent(bookableServices),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 1:
        return 'Hizmet Seçimi';
      case 2:
        return 'Tarih Seçimi';
      case 3:
        return 'Saat Seçimi';
      case 4:
        return 'İletişim Bilgileri';
      case 5:
        return 'Talep Alındı!';
      default:
        return 'Randevu Al';
    }
  }

  Widget _buildStepContent(List<StoreOffering> services) {
    switch (_currentStep) {
      case 1:
        return _buildServiceStep(services);
      case 2:
        return _buildDateStep();
      case 3:
        return _buildSlotStep();
      case 4:
        return _buildDetailsStep();
      case 5:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildServiceStep(List<StoreOffering> services) {
    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Bu işletmede randevuya açık hizmet bulunmamaktadır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: services.map((srv) {
        final isSelected = _selectedService?.id == srv.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceSoft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.6 : 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              srv.title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (srv.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(srv.description, style: const TextStyle(color: AppColors.softText, fontSize: 12)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 13, color: AppColors.mutedText),
                    const SizedBox(width: 4),
                    Text('${srv.durationMinutes} dk', style: const TextStyle(color: AppColors.mutedText, fontSize: 12, fontWeight: FontWeight.bold)),
                    if (srv.price.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.payments_rounded, size: 13, color: AppColors.mutedText),
                      const SizedBox(width: 4),
                      Text(srv.price, style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedService = srv;
                _currentStep = 2;
                _errorMsg = null;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateStep() {
    final dates = _availableDates;

    if (dates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'İşletmenin önümüzdeki 30 gün boyunca aktif çalışma saati bulunmamaktadır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final isSelected = _selectedDate?.year == date.year && _selectedDate?.month == date.month && _selectedDate?.day == date.day;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = date;
              _currentStep = 3;
              _errorMsg = null;
            });
            _fetchSlots(date);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceSoft : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.6 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDayName(date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primaryDark : AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateLabel(date),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotStep() {
    if (_isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_availableSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Seçilen tarihte müsait randevu saati bulunmamaktadır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        final timeStr = slot['time'] as String;
        final slotsLeft = slot['slots_left'] as int;
        final hasPending = slot['has_pending'] as bool;
        final isFull = slotsLeft == 0;
        final isSelected = _selectedSlotTime == timeStr;

        Color cardBg = Colors.white;
        Color borderCol = AppColors.border;
        Color textCol = AppColors.darkText;
        Color subTextCol = AppColors.mutedText;
        String statusLabel = '$slotsLeft yer';

        if (isFull) {
          cardBg = AppColors.bgEditor;
          textCol = AppColors.disabled;
          subTextCol = AppColors.disabled;
          final confirmedList = slot['confirmed_names'] as List?;
          statusLabel = (confirmedList != null && confirmedList.isNotEmpty)
              ? confirmedList.join(', ')
              : 'Dolu';
        } else if (hasPending) {
          cardBg = Colors.amber.withValues(alpha: 0.1);
          borderCol = Colors.amber.withValues(alpha: 0.3);
          textCol = Colors.orange;
          subTextCol = Colors.orange;
          statusLabel = 'Geçici ayrıldı';
        } else if (isSelected) {
          cardBg = AppColors.surfaceSoft;
          borderCol = AppColors.primary;
          textCol = AppColors.primaryDark;
          subTextCol = AppColors.primaryDark;
        }

        return InkWell(
          onTap: isFull || hasPending
              ? null
              : () {
                  setState(() {
                    _selectedSlotTime = timeStr;
                    _currentStep = 4;
                    _errorMsg = null;
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol, width: isSelected ? 1.6 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: subTextCol,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Service and Time Summary card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedService!.title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.darkText),
              ),
              const SizedBox(height: 4),
              Text(
                'Tarih: ${_formatDayName(_selectedDate!)} ${_formatDateLabel(_selectedDate!)} saat $_selectedSlotTime',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.softText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Ad Soyad *',
            hintText: 'Örn: Ahmet Ozan',
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Telefon Numarası *',
            hintText: '05xx xxx xx xx',
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Not (İsteğe bağlı)',
            hintText: 'Belirtmek istediğiniz özel bir durum var mı?',
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _kvkkConsent,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _kvkkConsent = val ?? false;
                });
              },
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  'Kişisel verilerimin işlenmesini ve isim maskeleme (A*** O***) yöntemiyle public takvimde gösterilmesini kabul ediyorum.',
                  style: TextStyle(color: AppColors.softText, fontSize: 11, height: 1.4, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Randevu Talebi Oluştur', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    final trackingLink = '${PublicSiteConfig.buildPublicLink('/v/${widget.storeData.slug}')}#randevu_token=$_createdToken';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
        const SizedBox(height: 16),
        const Text(
          'Randevu talebiniz başarıyla alındı!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.darkText),
        ),
        const SizedBox(height: 8),
        const Text(
          'İşletme randevunuzu onayladığında veya güncellediğinde WhatsApp üzerinden bilgilendirileceksiniz. Aşağıdaki takip bağlantısı üzerinden randevu durumunuzu dilediğiniz an kontrol edebilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.softText, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                trackingLink,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.softText),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: trackingLink));
                  _showSnackBar('Takip linki kopyalandı.');
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Linki Kopyala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
