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
            width: 200,
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.white),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.subCategory,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected
                                  ? AppColors.secondary
                                  : Colors.transparent,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                subCategory.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.secondary,
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

