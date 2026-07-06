import 'package:flutter/material.dart';
import 'package:vixrex/services/booking_service.dart';

class AppointmentTrackerController extends ChangeNotifier {
  final String token;
  final String storeSlug;
  final BookingService _bookingService;

  bool _isLoading = true;
  dynamic _appointment;
  String? _errorMsg;

  // Reschedule state
  bool _isRescheduling = false;
  DateTime? _newDate;
  String? _newSlotTime;
  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isSubmittingReschedule = false;

  AppointmentTrackerController({
    required this.token,
    required this.storeSlug,
    BookingService? bookingService,
  }) : _bookingService = bookingService ?? const BookingService();

  bool get isLoading => _isLoading;
  dynamic get appointment => _appointment;
  String? get errorMsg => _errorMsg;

  bool get isRescheduling => _isRescheduling;
  DateTime? get newDate => _newDate;
  String? get newSlotTime => _newSlotTime;
  List<dynamic> get availableSlots => _availableSlots;
  bool get isLoadingSlots => _isLoadingSlots;
  bool get isSubmittingReschedule => _isSubmittingReschedule;

  set isRescheduling(bool val) {
    _isRescheduling = val;
    notifyListeners();
  }

  set newDate(DateTime? date) {
    _newDate = date;
    notifyListeners();
  }

  set newSlotTime(String? time) {
    _newSlotTime = time;
    notifyListeners();
  }

  Future<void> fetchAppointment() async {
    final result = await _bookingService.getAppointmentByToken(token);
    result.when(
      success: (res) {
        if (res == null) {
          _errorMsg = 'Randevu bulunamadı veya geçersiz takip kodu.';
        } else {
          _appointment = res;
          _errorMsg = null;
        }
      },
      failure: (failure) {
        _errorMsg = failure.message;
      },
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> cancelAppointment() async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    final result = await _bookingService.cancelAppointmentByToken(token);
    return result.when(
      success: (_) async {
        await fetchAppointment();
        return true;
      },
      failure: (failure) {
        _isLoading = false;
        _errorMsg = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> fetchSlots(DateTime date) async {
    _isLoadingSlots = true;
    _availableSlots = [];
    notifyListeners();

    final result = await _bookingService.getAvailableSlots(
      storeSlug: storeSlug,
      date: date,
    );

    result.when(
      success: (slots) {
        _availableSlots = slots;
      },
      failure: (failure) {
        _errorMsg = failure.message;
      },
    );
    _isLoadingSlots = false;
    notifyListeners();
  }

  Future<bool> submitReschedule() async {
    if (_newDate == null || _newSlotTime == null) return false;

    _isSubmittingReschedule = true;
    _errorMsg = null;
    notifyListeners();

    final datePart = '${_newDate!.year}-${_newDate!.month.toString().padLeft(2, '0')}-${_newDate!.day.toString().padLeft(2, '0')}';
    final apptTime = DateTime.parse('$datePart $_newSlotTime:00');

    final result = await _bookingService.requestReschedule(
      token: token,
      newTime: apptTime,
    );

    return result.when(
      success: (_) async {
        _isSubmittingReschedule = false;
        _isRescheduling = false;
        _newDate = null;
        _newSlotTime = null;
        _isLoading = true;
        notifyListeners();

        await fetchAppointment();
        return true;
      },
      failure: (failure) {
        _isSubmittingReschedule = false;
        _errorMsg = failure.message;
        notifyListeners();
        return false;
      },
    );
  }
}
