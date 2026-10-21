import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../controllers/listings_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_text_styles.dart';

/// App-bar search for the Listings tab: debounced, searched on the server
/// (`search` param) together with the active filters.
class ListingsSearchField extends StatefulWidget {
  const ListingsSearchField({super.key});

  @override
  State<ListingsSearchField> createState() => _ListingsSearchFieldState();
}

class _ListingsSearchFieldState extends State<ListingsSearchField> {
  late final TextEditingController _text = TextEditingController(
    text: context.read<ListingsController>().query,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // clear button visibility
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => context.read<ListingsController>().setQuery(value),
    );
  }

  void _submit(String value) {
    _debounce?.cancel();
    context.read<ListingsController>().setQuery(value);
  }

  void _clear() {
    _text.clear();
    _submit('');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _text,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _submit,
              style: AppTextStyles.body,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search project, builder, location…',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                prefixIcon: Icon(
                  Iconsax.search_normal_1_copy,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                suffixIcon: _text.text.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: _clear,
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            context.read<ListingsController>().closeSearch();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(
            'Cancel',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
