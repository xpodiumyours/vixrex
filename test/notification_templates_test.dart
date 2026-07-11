import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/notification_templates.dart';

void main() {
  test('onay template', () {
    final t = NotificationTemplates.forBookingAction(
      action: 'confirm',
      customerName: 'Ayşe',
      storeSlug: 'demo',
    );
    expect(t.title, contains('onay'));
    expect(t.body, contains('Ayşe'));
  });

  test('red template', () {
    final t = NotificationTemplates.forBookingAction(
      action: 'reject',
      customerName: 'Ali',
      storeSlug: 'demo',
    );
    expect(t.title, contains('red'));
  });

  test('pending template', () {
    final t = NotificationTemplates.forBookingAction(
      action: 'pending',
      customerName: 'Zeynep',
      storeSlug: 'magaza',
    );
    expect(t.title, contains('randevu'));
    expect(t.title.toLowerCase(), contains('yeni'));
  });
}