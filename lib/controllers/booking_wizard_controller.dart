import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/booking_service.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

class BookingWizardController extends ChangeNotifier {
  final StoreData storeData;
  final BookingService _bookingService;

  int _currentStep = 1;
  StoreOffering? _selectedService;
  DateTime? _selectedDate;
  String? _selectedSlotTime;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();
  bool _kvkkConsent = false;

  bool _isLoadingSlots = false;
  List<dynamic> _availableSlots = [];
  bool _isSubmitting = false;
  String? _createdToken;
  String? _errorMsg;

  BookingWizardController({
    required this.storeData,
    BookingService? bookingService,
  }) : _bookingService = bookingService ?? BookingService();

  int get currentStep => _currentStep;
  StoreOffering? get selectedService => _selectedService;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedSlotTime => _selectedSlotTime;
  bool get kvkkConsent => _kvkkConsent;
  bool get isLoadingSlots => _isLoadingSlots;
  List<dynamic> get availableSlots => _availableSlots;
  bool get isSubmitting => _isSubmitting;
  String? get createdToken => _createdToken;
  String? get errorMsg => _errorMsg;

  set kvkkConsent(bool val) {
    _kvkkConsent = val;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 5) {
      _currentStep++;
      _errorMsg = null;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 1) {
      _currentStep--;
      _errorMsg = null;
      notifyListeners();
    }
  }

  void selectService(StoreOffering service) {
    _selectedService = service;
    _currentStep = 2;
    _errorMsg = null;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    _currentStep = 3;
    _errorMsg = null;
    notifyListeners();
    fetchSlots(date);
  }

  void selectSlot(String slotTime) {
    _selectedSlotTime = slotTime;
    _currentStep = 4;
    _errorMsg = null;
    notifyListeners();
  }

  List<DateTime> get availableDates {
    final list = <DateTime>[];
    final today = DateTime.now();
    final settings = storeData.bookingSettings;
    if (settings == null) return [];

    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      final dow = date.weekday.toString();
      final dowConfig = settings.workingHours[dow];
      if (dowConfig != null && (dowConfig['active'] ?? false) == true) {
        list.add(date);
      }
    }
    return list;
  }

  Future<void> fetchSlots(DateTime date) async {
    _isLoadingSlots = true;
    _availableSlots = [];
    _errorMsg = null;
    notifyListeners();

    final result = await _bookingService.getAvailableSlots(
      storeSlug: storeData.slug,
      date: date,
    );

    result.when(
      success: (slots) {
        _availableSlots = slots;
        _isLoadingSlots = false;
        notifyListeners();
      },
      failure: (failure) {
        _isLoadingSlots = false;
        _errorMsg = failure.message;
        notifyListeners();
      },
    );
  }

  Future<void> submitRequest(VoidCallback onSuccess) async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final notes = notesController.text.trim();

    if (name.isEmpty || phone.isEmpty || !_kvkkConsent || _selectedDate == null || _selectedSlotTime == null || _selectedService == null) {
      _errorMsg = 'Lütfen tüm zorunlu alanları doldurun ve onay verin.';
      notifyListeners();
      return;
    }

    if (!WhatsAppLinkHelper.isValidTurkeyMobile(phone)) {
      _errorMsg = WhatsAppLinkHelper.invalidNumberMessage;
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _errorMsg = null;
    notifyListeners();

    final datePart = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final apptTime = DateTime.parse('$datePart $_selectedSlotTime:00').toUtc().toIso8601String();

    final result = await _bookingService.createAppointmentRequest(
      storeSlug: storeData.slug,
      customerName: name,
      customerPhone: phone,
      customerNotes: notes,
      serviceTitle: _selectedService!.title,
      servicePrice: _selectedService!.price,
      serviceDuration: _selectedService!.durationMinutes,
      appointmentTime: apptTime,
    );

    result.when(
      success: (res) async {
        final token = res['token'] as String;
        final apptId = res['appointment_id'] as String;

        await _bookingService.saveAppointmentTokenLocally(
          appointmentId: apptId,
          token: token,
        );

        _createdToken = token;
        _isSubmitting = false;
        _currentStep = 5;
        notifyListeners();
        onSuccess();
      },
      failure: (failure) {
        _isSubmitting = false;
        _errorMsg = failure.message;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
