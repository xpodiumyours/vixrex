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

  test('Android workflow builds APK and AAB with one release identity', () {
    final workflow =
        File('.github/workflows/android-apk.yml').readAsStringSync();

    expect(workflow, contains('flutter build apk --release'));
    expect(workflow, contains('flutter build appbundle --release'));
    expect(
      RegExp(
        r'--build-number="\$\{\{ steps\.version\.outputs\.build_number \}\}"',
      ).allMatches(workflow).length,
      2,
    );
    expect(
      RegExp(
        r'--build-name="\$\{\{ steps\.version\.outputs\.version_name \}\}"',
      ).allMatches(workflow).length,
      2,
    );
    expect(
      workflow,
      contains('build/app/outputs/bundle/release/app-release.aab'),
    );
  });

  test('Android workflow validates AAB before publishing it', () {
    final workflow =
        File('.github/workflows/android-apk.yml').readAsStringSync();

    expect(workflow, contains('BUNDLETOOL_VERSION: "1.18.3"'));
    expect(
      workflow,
      contains(
        'BUNDLETOOL_SHA256: '
        'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29',
      ),
    );
    expect(workflow, contains(r'validate --bundle="$AAB_SRC"'));
    expect(workflow, contains('--xpath=/manifest/@package'));
    expect(workflow, contains('--xpath=/manifest/@android:versionCode'));
    expect(
      workflow,
      contains('--xpath=/manifest/uses-sdk/@android:targetSdkVersion'),
    );
    expect(workflow, contains(r'test "$AAB_TARGET_SDK" -ge 35'));
    expect(workflow, contains(r'jarsigner -verify "$AAB_SRC"'));
    expect(workflow, contains("grep -Fxq 'jar verified.'"));
    expect(
      workflow,
      contains('Manifest is missing when reading via JarInputStream'),
    );
    expect(
      workflow,
      contains('is signed in JarFile but is not signed in JarInputStream'),
    );
    expect(
      workflow,
      contains(
        'jar is unsigned|unsigned entr|digest error|invalid signature|'
        'securityexception|unable to open jar|not parsable',
      ),
    );
    expect(workflow, contains(r'test "$APK_CERT_SHA256" = "$AAB_CERT_SHA256"'));
    expect(
      workflow,
      contains(
        'EXPECTED_UPLOAD_CERT_SHA256: '
        '295af3e289e13bc9fea273f224fa7c1fcb1879472790d48ed3eea8239c0ffc24',
      ),
    );
  });

  test(
    'Android workflow publishes separate checksummed APK and AAB artifacts',
    () {
      final workflow =
          File('.github/workflows/android-apk.yml').readAsStringSync();

      expect(workflow, contains('name: vixrex-android-'));
      expect(workflow, contains('name: vixrex-play-aab-'));
      expect(workflow, contains('dist/app-release.apk.sha256'));
      expect(workflow, contains('dist/app-release.aab.sha256'));
      expect(
        workflow,
        contains(
          'sha256sum --check --strict '
          'app-release.apk.sha256 app-release.aab.sha256',
        ),
      );
      expect(workflow, contains('if-no-files-found: error'));
    },
  );
}
