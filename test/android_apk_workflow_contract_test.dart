import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android APK workflow is manual only', () {
    final workflow =
        File('.github/workflows/android-apk.yml').readAsStringSync();

    expect(workflow, contains('  workflow_dispatch:'));
    expect(workflow, isNot(contains('\n  push:')));
  });
}
