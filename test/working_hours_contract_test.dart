import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/working_hours.dart';

void main() {
  test('Flutter ortak 1-7 çalışma saatleri örneğini kayıpsız üretir', () {
    final fixture =
        jsonDecode(
              File('shared/working_hours_contract.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final hours = Map<String, dynamic>.from(fixture['working_hours'] as Map);

    final settings = BookingSettings.fromJson({'working_hours': hours});

    expect(settings.toJson()['working_hours'], hours);
    expect(
      settings.workingHours.keys,
      orderedEquals(['1', '2', '3', '4', '5', '6', '7']),
    );
  });
}
