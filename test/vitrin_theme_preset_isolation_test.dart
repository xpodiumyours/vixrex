import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';

void main() {
  test('Sade ve Premium vitrin temaları uygulama markasından bağımsızdır', () {
    const legacyVitrinAccent = Color(0xFF00F0FF);

    expect(vitrinThemePresetFor('Sade').accent, legacyVitrinAccent);
    expect(vitrinThemePresetFor('Premium').accent, legacyVitrinAccent);
    expect(legacyVitrinAccent, isNot(AppColors.primary));
  });
}
