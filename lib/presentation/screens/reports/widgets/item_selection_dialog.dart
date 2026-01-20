import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bloc/product/product_bloc.dart';
import '../../../bloc/product/product_state.dart';

class ItemSelectionDialog extends StatelessWidget {
  final AppLocalizations l10n;

  const ItemSelectionDialog({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.items.isEmpty) {
          return AlertDialog(
            title: Text(l10n.selectItem),
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
          title: Text(l10n.selectItem),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return ListTile(
                  title: Text(item.name),
                  onTap: () => Navigator.pop(context, item),
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

