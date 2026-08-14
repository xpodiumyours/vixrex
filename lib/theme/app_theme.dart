import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

/// Uygulamanın tek tema kaynağı.
///
/// `main.dart` içindeki 200 satırlık `ThemeData` buraya taşındı; main yalnızca
/// `theme: AppTheme.dark(_systemUiOverlayStyle)` çağırır. Ekranlar kendi
/// `TextStyle`, radius veya buton stilini tanımlamaz — hepsi buradan miras alır.
///
/// Yuvarlaklık sözleşmesi: kart 16, alan ve çip 12, çember 999.
/// Tipografi sözleşmesi: yalnız [AppTextStyles] kademeleri (24/18/16/14/12).
abstract final class AppTheme {
  /// Kart ve modal yuvarlaklığı — [AppCard] ile aynı değer.
  static const double radiusCard = AppColors.radius16;

  /// Form alanı, çip ve buton yuvarlaklığı.
  static const double radiusControl = AppColors.radius12;

  static ThemeData dark(SystemUiOverlayStyle overlayStyle) {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Outfit',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onPrimary,
        error: AppColors.error,
        shadow: Colors.black12,
      ),
      scaffoldBackgroundColor: AppColors.bgEditor,
      disabledColor: AppColors.disabled,
      iconTheme: const IconThemeData(color: AppColors.darkTextAlt, size: 20),

      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayTitle,
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.subTitle,
        titleSmall: AppTextStyles.formLabel,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.labelBold,
        labelSmall: AppTextStyles.labelSmall,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgEditor,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyle,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionTitle,
        iconTheme: const IconThemeData(color: AppColors.darkText, size: 22),
      ),

      // DEĞİŞTİ: 12 → 16. AppCard 16 kullanıyordu, tema 12 diyordu; Card
      // widget'ı ile AppCard yan yana durduğunda fark görünüyordu.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.inputBg,
        filled: true,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.mutedText),
        labelStyle: AppTextStyles.formLabel,
        helperStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.errorText,
        prefixIconColor: AppColors.mutedText,
        suffixIconColor: AppColors.mutedText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(
            color: AppColors.focusedBorder,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.primary,
      ),

      // YENİ: birincil aksiyon. Ekranlar FilledButton kullandığında artık
      // kendi styleFrom'unu yazmak zorunda değil.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceSoft,
          disabledForegroundColor: AppColors.mutedText,
          elevation: 0,
          // Yalnız yüksekliği sabitle. Size.fromHeight genişliği sonsuz yapar
          // ve Row içindeki butonlarda geçersiz BoxConstraints üretir.
          minimumSize: const Size(0, 48),
          textStyle: AppTextStyles.ctaButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceSoft,
          disabledForegroundColor: AppColors.mutedText,
          elevation: 0,
          minimumSize: const Size(0, 48),
          textStyle: AppTextStyles.ctaButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
        ),
      ),

      // DEĞİŞTİ: kenarlık ve metin artık marka mavisi değil. İkincil aksiyon
      // birincilin yanında ondan sakin durmalı; mavi çerçeve iki butonu
      // eşit ağırlıkta gösteriyordu.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextAlt,
          disabledForegroundColor: AppColors.disabled,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 46),
          textStyle: AppTextStyles.labelBold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
        ),
      ),

      // YENİ: hayalet aksiyon. Tanımsız olduğu için TextButton'lar
      // colorScheme.primary'ye düşüyordu; koyu zeminde okunurluğu zayıf.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          disabledForegroundColor: AppColors.disabled,
          minimumSize: const Size(0, 44),
          textStyle: AppTextStyles.labelBold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
        ),
      ),

      // DEĞİŞTİ: radius 20 → 12, zemin surfaceSoft → inputBg (form alanlarıyla
      // aynı yüzey), seçili çipte onay işareti kapalı.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.inputBg,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceSoft,
        showCheckmark: false,
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.darkTextAlt,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // DEĞİŞTİ: indicatorColor turquoiseSurface → primary %22.
      // home_shell_screen kendi NavigationBarTheme'ini sarıyordu; bu değerler
      // onunla aynı olduğu için oradaki yerel sarmalayıcı kaldırılabilir.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgEditor,
        indicatorColor: AppColors.primary.withValues(alpha: 0.22),
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.secondary, size: 22);
          }
          return const IconThemeData(color: AppColors.mutedText, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            );
          }
          return const TextStyle(color: AppColors.mutedText, fontSize: 11);
        }),
      ),

      // YENİ: app_settings'teki SwitchListTile başlık/alt başlık stilini elle
      // veriyordu; artık listede duran her satır aynı tipografiyi alır.
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.mutedText,
        textColor: AppColors.darkText,
        titleTextStyle: AppTextStyles.formLabel,
        subtitleTextStyle: AppTextStyles.labelSmall,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onPrimary;
          }
          return AppColors.mutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceSoft;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.border),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceSoft;
          }
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceSoft;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // YENİ: SnackBar'lar Material varsayılanıyla açık gri geliyordu —
      // koyu arayüzde tek açık yüzey oydu.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceSoft,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.darkText,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTextStyles.sectionTitle,
        contentTextStyle: AppTextStyles.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        dragHandleColor: AppColors.border,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppColors.radius20),
          ),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceSoft,
      ),

      // DEĞİŞTİ: border (#294D88) → blueSurface (#182E5B). Ayırıcı çizgi
      // kart kenarlığıyla aynı ağırlıkta olunca liste içi bölmeler kart
      // sınırı gibi okunuyordu.
      dividerTheme: const DividerThemeData(
        color: AppColors.blueSurface,
        thickness: 1,
        space: 1,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(radiusControl),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: AppTextStyles.caption.copyWith(color: AppColors.darkText),
      ),
    );
  }
}
