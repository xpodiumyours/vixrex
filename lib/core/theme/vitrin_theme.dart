import 'package:flutter/material.dart';

/// VitrinX Pro Tema Sabitleri
/// Uygulamanın genel renk paleti, boyutlandırma ve stil tanımları.
class VitrinTheme {
  VitrinTheme._();

  // Renk Paleti
  static const Color primaryColor = Color(0xFF6C63FF); // Modern Mor
  static const Color secondaryColor = Color(0xFF2A2D3E); // Koyu Arka Plan
  static const Color accentColor = Color(0xFF00D2FC); // Canlı Mavi
  static const Color successColor = Color(0xFF00C851);
  static const Color errorColor = Color(0xFFFF4444);
  static const Color cardBgColor = Color(0xFFFFFFFF);
  static const Color scaffoldBgColor = Color(0xFFF5F7FA);

  // Gradyanlar
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF5A52D5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFF009ACD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Boyutlar & Radyuslar
  static const double defaultRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double cardRadius = 20.0;
  static const double smallRadius = 8.0;

  // Gölgeler
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  // Metin Stilleri (Örnek)
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: secondaryColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF6B7280),
    height: 1.5,
  );
}

/// VitrinX Pro Tarzı Buton Bileşeni
/// Gradyan arka plan, gölge ve yumuşak animasyonlar içerir.
class VitrinButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double height;

  const VitrinButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        elevation: isSecondary ? 0 : 4,
        shadowColor: isSecondary ? Colors.transparent : VitrinTheme.primaryColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(VitrinTheme.buttonRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(VitrinTheme.buttonRadius),
          splashColor: Colors.white.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSecondary
                  ? null
                  : VitrinTheme.primaryGradient,
              color: isSecondary ? Colors.white : null,
              border: isSecondary
                  ? Border.all(color: VitrinTheme.primaryColor, width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(VitrinTheme.buttonRadius),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isSecondary ? VitrinTheme.primaryColor : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSecondary ? VitrinTheme.primaryColor : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// VitrinX Pro Tarzı Kart Bileşeni
/// Yuvarlatılmış köşeler, derinlik hissi veren gölge ve temiz beyaz arka plan.
class VitrinCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  const VitrinCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? VitrinTheme.cardBgColor,
        borderRadius: BorderRadius.circular(VitrinTheme.cardRadius),
        boxShadow: VitrinTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VitrinTheme.cardRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// VitrinX Pro Tarzı Küçük Kart (Chip/Özet bilgiler için)
class VitrinSmallCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const VitrinSmallCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(VitrinTheme.smallRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VitrinTheme.smallRadius),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
