import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/appointment_tracker_screen.dart';
import 'package:vixrex/widgets/booking_wizard_sheet.dart';
import 'package:vixrex/widgets/vitrin_view.dart';

void main() {
  group('Booking Wizard Sheet Widget Tests', () {
    late StoreData mockStoreData;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockStoreData = StoreData(
        name: 'Güzellik Deneme',
        slug: 'guzellik-deneme',
        kategori: 'kuafor',
        offerings: [
          StoreOffering(
            id: 'srv-1',
            title: 'Fön Çekimi',
            description: 'Klasik fön işlemi',
            price: '150 TL',
            durationMinutes: 30,
            isBookable: true,
          ),
          StoreOffering(
            id: 'srv-2',
            title: 'Saç Boyama',
            description: 'Dip boyama dahil değil',
            price: '800 TL',
            durationMinutes: 90,
            isBookable: false,
          ),
        ],
        bookingSettings: BookingSettings(isEnabled: true, capacity: 2),
      );
    });

    testWidgets(
      'Sadece randevuya açık (isBookable: true) hizmetleri listeler',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder:
                            (_) => BookingWizardSheet(storeData: mockStoreData),
                      );
                    },
                    child: const Text('Randevu Al'),
                  );
                },
              ),
            ),
          ),
        );

        // Open the sheet
        await tester.tap(find.text('Randevu Al'));
        await tester.pumpAndSettle();

        // Check step header and title
        expect(find.text('Hizmet Seçimi'), findsOneWidget);
        expect(find.text('1/4'), findsOneWidget);

        // Verify bookable service is listed
        expect(find.text('Fön Çekimi'), findsOneWidget);
        expect(find.text('150 TL'), findsOneWidget);
        expect(find.text('30 dk'), findsOneWidget);

        // Verify non-bookable service is NOT listed
        expect(find.text('Saç Boyama'), findsNothing);
      },
    );
  });

  group('Appointment Tracker Screen Widget Tests', () {
    testWidgets('Supabase başlatılmamışken takip ekranı hata mesajı verir', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppointmentTrackerScreen(
            token: 'test-token-xyz',
            storeSlug: 'guzellik-deneme',
          ),
        ),
      );

      await tester.pump();

      // Assert error fallback UI is shown
      expect(
        find.text('Randevu detayları yüklenirken bir hata oluştu.'),
        findsOneWidget,
      );
      expect(find.text('Vitrine Dön'), findsOneWidget);
    });
  });

  group('Booking CTA Button Visibility Tests', () {
    testWidgets(
      'Kategori Kuaför veya Kozmetik olmasa dahi randevu sistemi aktifse Randevu Al butonu gösterilir',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: VitrinView(
                  storeData: StoreData(
                    name: 'Teknik Servis Mağazası',
                    kategori: 'teknik_servis',
                    bookingSettings: BookingSettings(isEnabled: true),
                  ),
                  publicMode: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Randevu Al'), findsOneWidget);
      },
    );

    testWidgets('Randevu sistemi kapalıyken Randevu Al butonu gizlenir', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VitrinView(
                storeData: StoreData(
                  name: 'Teknik Servis Mağazası',
                  kategori: 'teknik_servis',
                  bookingSettings: BookingSettings(isEnabled: false),
                ),
                publicMode: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Randevu Al'), findsNothing);
    });
  });
}
