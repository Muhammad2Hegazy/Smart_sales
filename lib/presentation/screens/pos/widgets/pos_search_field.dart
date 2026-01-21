import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

class POSSearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const POSSearchField({
    super.key,
    required this.onChanged,
    this.controller,
  });

  @override
  State<POSSearchField> createState() => _POSSearchFieldState();
}

class _POSSearchFieldState extends State<POSSearchField> {
  late final TextEditingController _controller;
  late final bool _isInternalController;
  bool _showClearButton = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isInternalController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateClearButtonVisibility);
    _showClearButton = _controller.text.isNotEmpty;
  }

  void _updateClearButtonVisibility() {
    final show = _controller.text.isNotEmpty;
    if (show != _showClearButton) {
      setState(() => _showClearButton = show);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_updateClearButtonVisibility);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            widget.onChanged(value);
          });
        },
        decoration: InputDecoration(
          hintText: l10n.searchProducts,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _showClearButton
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                  tooltip: l10n.reset,
                  onPressed: () {
                    _controller.clear();
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    widget.onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}
