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
    final result = await _bookingService.fetchAppointments(storeSlug);
    result.when(
      success: (data) {
        _appointments = data;
        _errorMessage = null;
      },
      failure: (failure) {
        _errorMessage = failure.message;
      },
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> respondToAppointment(
    String apptId, {
    String? action,
    String? rescheduleAction,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _bookingService.respondToAppointment(
      appointmentId: apptId,
      action: action,
      rescheduleAction: rescheduleAction,
    );

    return result.when(
      success: (_) async {
        await fetchAppointments();
        return true;
      },
      failure: (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  List<dynamic> get pendingList {
    return _appointments.where((appt) {
      final status = appt['status'] as String? ?? '';
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
      try {
        final time = DateTime.parse(appt['appointment_time'] as String).toLocal();
        return time.year == today.year && time.month == today.month && time.day == today.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<dynamic> get upcomingList {
    final todayStart = DateTime.now();
    final todayLimit = DateTime(todayStart.year, todayStart.month, todayStart.day, 23, 59, 59);
    return _appointments.where((appt) {
      if (appt['status'] != 'confirmed') return false;
      try {
        final time = DateTime.parse(appt['appointment_time'] as String).toLocal();
        return time.isAfter(todayLimit);
      } catch (_) {
        return false;
      }
    }).toList();
  }
}
