import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android APK workflow is manual only', () {
    final workflow =
        File('.github/workflows/android-apk.yml').readAsStringSync();

    expect(workflow, contains('  workflow_dispatch:'));
    expect(workflow, isNot(contains('\n  push:')));
  });

  test('Android APK workflow uses Node 24 action majors', () {
    final workflow =
        File('.github/workflows/android-apk.yml').readAsStringSync();

    expect(workflow, contains('uses: actions/checkout@v6'));
    expect(workflow, contains('uses: actions/setup-java@v5'));
    expect(workflow, contains('uses: actions/upload-artifact@v6'));
    expect(workflow, isNot(contains('uses: actions/checkout@v4')));
    expect(workflow, isNot(contains('uses: actions/setup-java@v4')));
    expect(workflow, isNot(contains('uses: actions/upload-artifact@v4')));
  });
}
