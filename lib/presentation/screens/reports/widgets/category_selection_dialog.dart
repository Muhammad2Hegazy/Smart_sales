import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blocs/product/product_bloc.dart';
import '../../../blocs/product/product_state.dart';

class CategorySelectionDialog extends StatelessWidget {
  final AppLocalizations l10n;

  const CategorySelectionDialog({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.categories.isEmpty) {
          return AlertDialog(
            title: Text(l10n.selectCategory),
            content: Text(l10n.noItemsFound),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text(l10n.selectCategory),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return ListTile(
                  title: Text(category.name),
                  onTap: () => Navigator.pop(context, category),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }
}

