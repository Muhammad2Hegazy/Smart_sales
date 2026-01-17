import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../bloc/product/product_bloc.dart';
import '../../../bloc/product/product_state.dart';

/// SubCategories menu widget for POS screen
class POSSubCategoriesMenu extends StatelessWidget {
  final String? selectedCategoryId;
  final String? selectedSubCategoryId;
  final ValueChanged<String?> onSubCategorySelected;

  const POSSubCategoriesMenu({
    super.key,
    required this.selectedCategoryId,
    required this.selectedSubCategoryId,
    required this.onSubCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (selectedCategoryId == null) {
      return const SizedBox.shrink();
    }
    
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        final subCategories = productState.subCategories
            .where((sub) => sub.categoryId == selectedCategoryId)
            .toList();

        if (subCategories.isEmpty) {
          return Container(
            width: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.border),
              ),
            ),
            child: Center(
              child: Text(
                l10n.noSubcategories,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        return Container(
          width: 160,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.subCategory,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: subCategories.length,
                  itemBuilder: (context, index) {
                    final subCategory = subCategories[index];
                    final isSelected = selectedSubCategoryId == subCategory.id;
                    return InkWell(
                      onTap: () => onSubCategorySelected(
                        isSelected ? null : subCategory.id,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected
                                  ? AppColors.secondary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                subCategory.name,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.secondary,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

