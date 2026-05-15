import 'package:flutter/material.dart';

class VitrinThemePreset {
  final String name;
  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color buttonText;
  final Color border;
  final Color qrBackground;
  final Color qrForeground;
  final bool isDark;

  const VitrinThemePreset({
    required this.name,
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.buttonText,
    required this.border,
    required this.qrBackground,
    required this.qrForeground,
    required this.isDark,
  });
}

const VitrinThemePreset sadeVitrinTheme = VitrinThemePreset(
  name: 'Sade',
  background: Color(0xFFF8FAFC),
  surface: Color(0xFFFFFFFF),
  surfaceSoft: Color(0xFFF1F5F9),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF475569),
  accent: Color(0xFFFF5A1F),
  buttonText: Color(0xFFFFFFFF),
  border: Color(0xFFD9E2EC),
  qrBackground: Color(0xFFFFFFFF),
  qrForeground: Color(0xFF111827),
  isDark: false,
);

const Map<String, VitrinThemePreset> vitrinThemePresets = {
  'Sade': sadeVitrinTheme,
  'Premium': VitrinThemePreset(
    name: 'Premium',
    background: Color(0xFF101827),
    surface: Color(0xFF182235),
    surfaceSoft: Color(0xFF223149),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    accent: Color(0xFFF6B756),
    buttonText: Color(0xFF111827),
    border: Color(0xFF344256),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF111827),
    isDark: true,
  ),
  'Zarif': VitrinThemePreset(
    name: 'Zarif',
    background: Color(0xFFFBF7F4),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF3E7DF),
    textPrimary: Color(0xFF241A16),
    textSecondary: Color(0xFF6B5549),
    accent: Color(0xFF9E6F56),
    buttonText: Color(0xFFFFFFFF),
    border: Color(0xFFE3D2C8),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF241A16),
    isDark: false,
  ),
  'Doğal': VitrinThemePreset(
    name: 'Doğal',
    background: Color(0xFFF5FAF4),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFE8F3E8),
    textPrimary: Color(0xFF102A18),
    textSecondary: Color(0xFF46614B),
    accent: Color(0xFF15803D),
    buttonText: Color(0xFFFFFFFF),
    border: Color(0xFFCFE1D0),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF102A18),
    isDark: false,
  ),
  'Gece': VitrinThemePreset(
    name: 'Gece',
    background: Color(0xFF08111F),
    surface: Color(0xFF111C2E),
    surfaceSoft: Color(0xFF1C2A3F),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFC7D2E1),
    accent: Color(0xFF60A5FA),
    buttonText: Color(0xFF06101E),
    border: Color(0xFF334155),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF0F172A),
    isDark: true,
  ),
  'Lüks': VitrinThemePreset(
    name: 'Lüks',
    background: Color(0xFF120A1F),
    surface: Color(0xFF1C102D),
    surfaceSoft: Color(0xFF2A1A42),
    textPrimary: Color(0xFFFDF7ED),
    textSecondary: Color(0xFFD8C7B0),
    accent: Color(0xFFD4AF37),
    buttonText: Color(0xFF171008),
    border: Color(0xFF4A365F),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF171008),
    isDark: true,
  ),
  'Sahil': VitrinThemePreset(
    name: 'Sahil',
    background: Color(0xFFF0FDFF),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFDDF7FB),
    textPrimary: Color(0xFF0B2830),
    textSecondary: Color(0xFF416A72),
    accent: Color(0xFF0891B2),
    buttonText: Color(0xFFFFFFFF),
    border: Color(0xFFBFE8EF),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF0B2830),
    isDark: false,
  ),
  'Güneş': VitrinThemePreset(
    name: 'Güneş',
    background: Color(0xFFFFF8ED),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFFFE8C7),
    textPrimary: Color(0xFF2B1B08),
    textSecondary: Color(0xFF7A4D1C),
    accent: Color(0xFFEA580C),
    buttonText: Color(0xFFFFFFFF),
    border: Color(0xFFF3D4AA),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF2B1B08),
    isDark: false,
  ),
};

VitrinThemePreset vitrinThemePresetFor(String name) {
  return vitrinThemePresets[name] ?? sadeVitrinTheme;
}
