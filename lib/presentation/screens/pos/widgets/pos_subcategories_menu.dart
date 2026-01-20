import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_state.dart';

/// SubCategories menu widget for POS screen (Horizontal version)
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
    if (selectedCategoryId == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        final subCategories = productState.subCategories
            .where((sub) => sub.categoryId == selectedCategoryId)
            .toList();

        if (subCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final subCategory = subCategories[index];
              final isSelected = selectedSubCategoryId == subCategory.id;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  label: Text(subCategory.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    onSubCategorySelected(selected ? subCategory.id : null);
                  },
                  selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.secondary,
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: isSelected ? AppColors.secondary : AppColors.border,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
