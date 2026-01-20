import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/models/item.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_state.dart';
import 'pos_item_tile.dart';

/// Items grid widget for POS screen
class POSItemsGrid extends StatelessWidget {
  final String? selectedCategoryId;
  final String? selectedSubCategoryId;
  final String searchQuery;
  final Function(Item) onItemTap;

  const POSItemsGrid({
    super.key,
    this.selectedCategoryId,
    this.selectedSubCategoryId,
    this.searchQuery = '',
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        // Filter items based on category, subcategory and search query
        List<Item> items = productState.items;

        if (selectedSubCategoryId != null) {
          items = items.where((item) => item.subCategoryId == selectedSubCategoryId).toList();
        } else if (selectedCategoryId != null) {
          // Filter by all subcategories in this category
          final subCatIds = productState.subCategories
              .where((sub) => sub.categoryId == selectedCategoryId)
              .map((sub) => sub.id)
              .toSet();
          items = items.where((item) => subCatIds.contains(item.subCategoryId)).toList();
        }

        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          items = items.where((item) =>
            item.name.toLowerCase().contains(query) ||
            (item.barcode?.toLowerCase().contains(query) ?? false)
          ).toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.noItemsFound,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.xs),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisExtent: 120,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return POSItemTile(
              item: item,
              onTap: () => onItemTap(item),
            );
          },
        );
      },
    );
  }
}
