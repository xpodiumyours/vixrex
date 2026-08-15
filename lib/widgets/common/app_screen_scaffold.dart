import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Ekranların ortak iskeleti — AppBar, zemin, güvenli alan ve içerik
/// boşluğu tek yerden gelir.
///
/// Varsayılan zemin [AppColors.bgEditor]'dir (raporun baskın kullanımı).
/// Başlık stili tema `appBarTheme.titleTextStyle`'ından gelir — ekran
/// kendi `TextStyle` literal'ini tanımlamaz.
class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.body,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 32),
    this.backgroundColor = AppColors.bgEditor,
  });

  /// AppBar başlığı. Null ise AppBar yine çizilir, başlıksız kalır.
  final String? title;

  /// AppBar'ın sol tarafı — özel geri/kapat davranışı gereken ekranlar için.
  /// Null ise standart Flutter geri ok davranışı kullanılır.
  final Widget? leading;

  /// AppBar sağ taraf aksiyonları.
  final List<Widget>? actions;

  /// AppBar altına eklenen sekme çubuğu vb.
  final PreferredSizeWidget? bottom;

  /// İçerik. Genellikle ListView veya SingleChildScrollView.
  final Widget? body;

  /// İçerik boşluğu — tüm ekranların aynı düzeni paylaşması için.
  final EdgeInsetsGeometry padding;

  /// Ekran zemini. Varsayılan [AppColors.bgEditor].
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: title == null ? null : Text(title!),
        leading: leading,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        actions: actions,
        bottom: bottom,
      ),
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: body ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
