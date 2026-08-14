import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/form_accordion_section.dart';
import 'package:vixrex/widgets/editor/vitrin_completion_meter.dart';

void main() {
  testWidgets('kapalı form bölümü içeriği çizmeden açılma olayını iletir', (
    tester,
  ) async {
    var toggleCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormAccordionSection(
            index: 0,
            title: 'Kimlik',
            filledCount: 1,
            totalCount: 4,
            isOpen: false,
            isRequired: true,
            onToggle: () => toggleCount++,
            child: const Text('Bölüm içeriği'),
          ),
        ),
      ),
    );

    expect(find.text('1 / 4 alan dolu · zorunlu'), findsOneWidget);
    expect(find.text('Bölüm içeriği'), findsNothing);

    await tester.tap(find.text('Kimlik'));
    expect(toggleCount, 1);
  });

  testWidgets('tamamlanma ölçeri yüzdeyi sınırlar ve eksiği açıklar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VitrinCompletionMeter(
            percent: 120,
            missingRequiredLabels: ['WhatsApp', 'Adres'],
          ),
        ),
      ),
    );

    expect(find.text('%100 hazır'), findsOneWidget);
    expect(
      find.text('Yayına çıkmak için WhatsApp ve Adres alanları kaldı.'),
      findsOneWidget,
    );
  });

  test('asistan hedefi önce ilgili akordeon bölümünü açar', () {
    final controller = StoreEditorController(initialData: StoreData());
    final state = MyVitrinState(controller: controller);

    expect(state.openSectionIndex, MyVitrinState.identitySectionIndex);

    state.scrollToVixRexAction(VixRexAction.scrollToCover);
    expect(state.openSectionIndex, MyVitrinState.visualsSectionIndex);

    state.scrollToVixRexAction(VixRexAction.scrollToProducts);
    expect(state.openSectionIndex, MyVitrinState.contentSectionIndex);

    state.scrollToVixRexAction(VixRexAction.scrollToAddress);
    expect(state.openSectionIndex, MyVitrinState.locationSectionIndex);

    state.scrollToVixRexAction(VixRexAction.scrollToLegal);
    expect(state.openSectionIndex, MyVitrinState.locationSectionIndex);

    state.dispose();
    controller.dispose();
  });
}
