import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

/// Masaüstü kabuğunun sol menüsü.
class ShellSidebar extends StatelessWidget {
  const ShellSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onSearchChanged,
    this.quickActions = const [],
    this.version = 'v1.0.0',
    this.width = 220,
  });

  final List<ShellSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<String> onSearchChanged;
  final List<ShellSidebarQuickAction> quickActions;
  final String version;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacing20,
              vertical: AppColors.spacing24,
            ),
            child: Row(
              children: [
                // Maskot kendi basina durur — arkasina renkli kutu KOYULMAZ,
                // yoksa yapistirilmis bir rozet gibi gorunuyor.
                Image.asset(
                  ShellSidebarItem.maskotYolu,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: AppColors.spacing12),
                const Text('Vixrex', style: AppTextStyles.sectionTitle),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.spacing12,
              AppColors.spacing16,
              AppColors.spacing12,
              AppColors.spacing8,
            ),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Vitrin veya ürün ara',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: onSearchSubmitted,
              onChanged: onSearchChanged,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.spacing12,
                vertical: AppColors.spacing4,
              ),
              children: [
                for (var index = 0; index < items.length; index++)
                  _SidebarRow(
                    item: items[index],
                    isSelected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                if (quickActions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Text(
                      'MAĞAZA YÖNETİMİ',
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
                  for (final action in quickActions)
                    _SidebarQuickActionRow(action: action),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppColors.spacing16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(version, style: AppTextStyles.labelSmall),
            ),
          ),
        ],
      ),
    );
  }
}

class ShellSidebarItem {
  const ShellSidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.gorselYolu,
  });

  /// Vixrex maskotu — Vixrex'i temsil eden tek simge bu. Yerine soyut bir
  /// ikon (assistant, konuşma balonu) KOYULMAZ: maskot aynı zamanda
  /// uygulamanın logosu, web ile aynı görünmeli.
  static const String maskotYolu = 'assets/images/vixrex_maskot_ikon.png';

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Doluysa [icon]/[selectedIcon] yerine bu görsel çizilir.
  final String? gorselYolu;
}

class ShellSidebarQuickAction {
  const ShellSidebarQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;
}

class _SidebarQuickActionRow extends StatelessWidget {
  const _SidebarQuickActionRow({required this.action});

  final ShellSidebarQuickAction action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: action.highlighted ? AppColors.brandSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppColors.radius12),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(AppColors.radius12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacing12,
              vertical: 10,
            ),
            decoration:
                action.highlighted
                    ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppColors.radius12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    )
                    : null,
            child: Row(
              children: [
                Icon(
                  action.icon,
                  color:
                      action.highlighted
                          ? AppColors.secondary
                          : AppColors.mutedText,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 12.5,
                      color:
                          action.highlighted
                              ? AppColors.darkText
                              : AppColors.mutedText,
                      fontWeight:
                          action.highlighted
                              ? FontWeight.w800
                              : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ShellSidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? AppColors.brandSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppColors.radius12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radius12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacing12,
              vertical: 11,
            ),
            decoration:
                isSelected
                    ? const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.primary, width: 3),
                      ),
                    )
                    : null,
            child: Row(
              children: [
                if (item.gorselYolu != null)
                  Opacity(
                    opacity: isSelected ? 1 : 0.7,
                    child: Image.asset(
                      item.gorselYolu!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color:
                        isSelected ? AppColors.secondary : AppColors.mutedText,
                    size: 20,
                  ),
                const SizedBox(width: AppColors.spacing12),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 13,
                      color:
                          isSelected ? AppColors.darkText : AppColors.mutedText,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
