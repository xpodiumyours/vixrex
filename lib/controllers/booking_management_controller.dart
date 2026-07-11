import 'package:flutter/material.dart';
import 'package:vixrex/services/booking_service.dart';
import 'package:vixrex/services/notification_inbox_service.dart';
import 'package:vixrex/services/push_notification_service.dart';

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
    await result.when(
      success: (data) async {
        _appointments = data;
        _errorMessage = null;
        await _detectNewPending(data);
      },
      failure: (failure) async {
        _errorMessage = failure.message;
      },
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _detectNewPending(List<dynamic> data) async {
    final pending = data.whereType<Map>().where((appt) {
      final map = Map<String, dynamic>.from(appt);
      final status = (map['status'] as String?) ?? '';
      final hasPendingReschedule =
          (map['appointment_reschedule_requests'] as List?)?.any(
                (r) => r is Map && r['status'] == 'pending',
              ) ??
              false;
      return status == 'pending' || hasPendingReschedule;
    }).map((e) => Map<String, dynamic>.from(e)).toList();

    final seen =
        await const NotificationInboxService().getSeenPendingIds(storeSlug);
    final fresh = pending.where((a) {
      final id = (a['id'] ?? '').toString();
      return id.isNotEmpty && !seen.contains(id);
    }).toList();

    if (fresh.isNotEmpty) {
      await PushNotificationService.instance.recordNewPendingAppointments(
        storeSlug: storeSlug,
        newAppointments: fresh,
      );
    }

    final allIds = pending
        .map((a) => (a['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    await const NotificationInboxService().setSeenPendingIds(storeSlug, allIds);
  }

  Future<bool> respondToAppointment(
    String apptId, {
    String? action,
    String? rescheduleAction,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    Map<String, dynamic>? apptMap;
    for (final a in _appointments) {
      if (a is Map && a['id'] == apptId) {
        apptMap = Map<String, dynamic>.from(a);
        break;
      }
    }
    final customerName =
        (apptMap?['customer_name'] ?? 'Müşteri').toString();

    final result = await _bookingService.respondToAppointment(
      appointmentId: apptId,
      action: action,
      rescheduleAction: rescheduleAction,
    );

    return await result.when(
      success: (_) async {
        final eventAction = action ?? rescheduleAction ?? 'update';
        await PushNotificationService.instance.recordBookingStatusChange(
          storeSlug: storeSlug,
          customerName: customerName,
          action: eventAction,
        );
        await fetchAppointments();
        return true;
      },
      failure: (failure) async {
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
      final hasPendingReschedule =
          (appt['appointment_reschedule_requests'] as List?)?.any(
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
        final time =
            DateTime.parse(appt['appointment_time'] as String).toLocal();
        return time.year == today.year &&
            time.month == today.month &&
            time.day == today.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<dynamic> get upcomingList {
    final todayStart = DateTime.now();
    final todayLimit = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day,
      23,
      59,
      59,
    );
    return _appointments.where((appt) {
      if (appt['status'] != 'confirmed') return false;
      try {
        final time =
            DateTime.parse(appt['appointment_time'] as String).toLocal();
        return time.isAfter(todayLimit);
      } catch (_) {
        return false;
      }
    }).toList();
  }
}
