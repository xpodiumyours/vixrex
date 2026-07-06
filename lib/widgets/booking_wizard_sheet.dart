import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

import 'package:vixrex/widgets/booking/booking_service_step.dart';
import 'package:vixrex/widgets/booking/booking_date_step.dart';
import 'package:vixrex/widgets/booking/booking_slot_step.dart';
import 'package:vixrex/widgets/booking/booking_details_step.dart';
import 'package:vixrex/widgets/booking/booking_success_step.dart';

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
    } catch (_) {
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMsg = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
        });
      }
    }
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
        return BookingServiceStep(
          services: services,
          selectedService: _selectedService,
          onServiceSelected: (srv) {
            setState(() {
              _selectedService = srv;
              _currentStep = 2;
              _errorMsg = null;
            });
          },
        );
      case 2:
        return BookingDateStep(
          dates: _availableDates,
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
              _currentStep = 3;
              _errorMsg = null;
            });
            _fetchSlots(date);
          },
        );
      case 3:
        return BookingSlotStep(
          isLoadingSlots: _isLoadingSlots,
          availableSlots: _availableSlots,
          selectedSlotTime: _selectedSlotTime,
          onSlotSelected: (time) {
            setState(() {
              _selectedSlotTime = time;
              _currentStep = 4;
              _errorMsg = null;
            });
          },
        );
      case 4:
        return BookingDetailsStep(
          selectedService: _selectedService!,
          selectedDate: _selectedDate!,
          selectedSlotTime: _selectedSlotTime!,
          nameController: _nameController,
          phoneController: _phoneController,
          notesController: _notesController,
          kvkkConsent: _kvkkConsent,
          onKvkkConsentChanged: (val) {
            setState(() {
              _kvkkConsent = val;
            });
          },
          isSubmitting: _isSubmitting,
          onSubmit: _submitRequest,
        );
      case 5:
        final trackingLink = '${PublicSiteConfig.buildPublicLink('/v/${widget.storeData.slug}')}#randevu_token=$_createdToken';
        return BookingSuccessStep(
          trackingLink: trackingLink,
          onCopyPressed: _showSnackBar,
          onClose: () => Navigator.pop(context),
        );
      default:
        return const SizedBox();
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
