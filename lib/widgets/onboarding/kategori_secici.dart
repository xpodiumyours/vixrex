import 'package:flutter/material.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Kategori ızgarası — kurulum sohbetinde "ne iş yapıyorsun" adımı.
///
/// Faz D (Tek Asistan planı): `vixrex_onboarding_chat_screen.dart`'ın
/// akordeon-dışı tek büyük çizim bloğu buraya taşındı.
///
/// İkonlu ikili ızgara.
///
/// ÖNCEKİ HÂLİ: `Wrap` kutuları ortalayıp sığdığı kadar yan yana
/// diziyordu; satırlar 5/3/3/2/2 diye kırılıyor, kutular farklı
/// genişlikte çıkıyordu. Casper'ın ifadesi (2026-08-07): "bu kategori
/// çekmesi hiç UI UX mu deniyor artık".
///
/// ŞİMDİ: her hücre aynı genişlik ve yükseklikte, ikonuyla.
///
/// YÜKSEKLİK NEDEN SINIRLI: bu ızgara sohbetin ALTINDAKİ sabit panelde
/// duruyor, panel kaydırmıyor. Sınır kaldırılırsa 19 kategori 700 pikseli
/// aşıp taşar. Sınır kalır, ama eskiden devamı olduğuna dair hiçbir işaret
/// yoktu — 5 kategori görünmez kalıyordu. Alttaki solma o yüzden var:
/// içeriğin sürdüğünü söyler.
class KategoriSecici extends StatelessWidget {
  const KategoriSecici({
    super.key,
    required this.onSelected,
    this.busy = false,
  });

  final ValueChanged<String> onSelected;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 272),
      child: ShaderMask(
        shaderCallback:
            (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.88, 1.0],
            ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: BusinessCategoryConfig.categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            // Geniş ve alçak hücre: ikon üstte, ad altta.
            childAspectRatio: 2.35,
          ),
          itemBuilder: (context, index) {
            final kategori = BusinessCategoryConfig.categories[index];
            return InkWell(
              onTap: busy ? null : () => onSelected(kategori.label),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(kategori.icon, size: 20, color: AppColors.primary),
                    const SizedBox(height: 5),
                    Text(
                      kategori.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
