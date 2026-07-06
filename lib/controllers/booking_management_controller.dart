import 'package:flutter/material.dart';
import 'package:vixrex/services/booking_service.dart';

class BookingManagementController extends ChangeNotifier {
  final String storeSlug;
  final BookingService _bookingService;

  bool _isLoading = true;
  List<dynamic> _appointments = [];
  String? _errorMessage;

  BookingManagementController({
    required this.storeSlug,
    BookingService? bookingService,
  }) : _bookingService = bookingService ?? const BookingService();

  bool get isLoading => _isLoading;
  List<dynamic> get appointments => _appointments;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAppointments() async {
    try {
      final res = await _bookingService.fetchAppointments(storeSlug);
      _appointments = res;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Randevular yüklenirken bir hata oluştu.';
      notifyListeners();
    }
  }

  Future<bool> respondToAppointment(
    String apptId, {
    String? action,
    String? rescheduleAction,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _bookingService.respondToAppointment(
        appointmentId: apptId,
        action: action,
        rescheduleAction: rescheduleAction,
      );
      await fetchAppointments();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<dynamic> get pendingList {
    return _appointments.where((appt) {
      final status = appt['status'] as String;
      final hasPendingReschedule = (appt['appointment_reschedule_requests'] as List?)?.any(
            (r) => r['status'] == 'pending',
          ) ??
          false;
      return status == 'pending' || hasPendingReschedule;
    }).toList();
  }

  List<dynamic> get todayList {
    final today = DateTime.now();
    return _appointments.where((appt) {
      if (appt['status'] != 'confirmed') return false;
      final time = DateTime.parse(appt['appointment_time']).toLocal();
      return time.year == today.year && time.month == today.month && time.day == today.day;
    }).toList();
  }

  List<dynamic> get upcomingList {
    final todayStart = DateTime.now();
    final todayLimit = DateTime(todayStart.year, todayStart.month, todayStart.day, 23, 59, 59);
    return _appointments.where((appt) {
      if (appt['status'] != 'confirmed') return false;
      final time = DateTime.parse(appt['appointment_time']).toLocal();
      return time.isAfter(todayLimit);
    }).toList();
  }
}
