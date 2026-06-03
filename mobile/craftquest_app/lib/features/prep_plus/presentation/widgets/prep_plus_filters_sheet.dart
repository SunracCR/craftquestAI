import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PrepPlusFiltersResult {
  const PrepPlusFiltersResult({
    required this.priceFilter,
    required this.accessFilter,
    this.institutionTag,
  });

  final String priceFilter;
  final String accessFilter;
  final String? institutionTag;
}

Future<PrepPlusFiltersResult?> showPrepPlusFiltersSheet(
  BuildContext context, {
  required bool showInstitutionFilter,
  required String priceFilter,
  required String accessFilter,
  String? institutionTag,
}) {
  return showModalBottomSheet<PrepPlusFiltersResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PrepPlusFiltersSheet(
      showInstitutionFilter: showInstitutionFilter,
      initialPrice: priceFilter,
      initialAccess: accessFilter,
      initialInstitution: institutionTag,
    ),
  );
}

class _PrepPlusFiltersSheet extends StatefulWidget {
  const _PrepPlusFiltersSheet({
    required this.showInstitutionFilter,
    required this.initialPrice,
    required this.initialAccess,
    this.initialInstitution,
  });

  final bool showInstitutionFilter;
  final String initialPrice;
  final String initialAccess;
  final String? initialInstitution;

  @override
  State<_PrepPlusFiltersSheet> createState() => _PrepPlusFiltersSheetState();
}

class _PrepPlusFiltersSheetState extends State<_PrepPlusFiltersSheet> {
  late String _price;
  late String _access;
  late final TextEditingController _institutionController;

  @override
  void initState() {
    super.initState();
    _price = widget.initialPrice;
    _access = widget.initialAccess;
    _institutionController =
        TextEditingController(text: widget.initialInstitution ?? '');
  }

  @override
  void dispose() {
    _institutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.prepPlusFiltersTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.prepPlusFilterPriceLabel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              _priceChip('all', l10n.prepPlusFilterAll),
              _priceChip('free', l10n.prepPlusFilterFree),
              _priceChip('paid', l10n.prepPlusFilterPaid),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.prepPlusFilterAccessLabel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              _accessChip('all', l10n.prepPlusFilterAll),
              _accessChip('none', l10n.prepPlusAccessNone),
              _accessChip('active', l10n.prepPlusAccessActive),
              _accessChip('expired', l10n.prepPlusAccessExpired),
            ],
          ),
          if (widget.showInstitutionFilter) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _institutionController,
              decoration: InputDecoration(
                labelText: l10n.prepPlusFilterInstitutionLabel,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                PrepPlusFiltersResult(
                  priceFilter: _price,
                  accessFilter: _access,
                  institutionTag: widget.showInstitutionFilter
                      ? _institutionController.text.trim().isEmpty
                          ? null
                          : _institutionController.text.trim()
                      : null,
                ),
              );
            },
            child: Text(l10n.prepPlusFiltersApply),
          ),
        ],
      ),
    );
  }

  Widget _priceChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _price == value,
      onSelected: (_) => setState(() => _price = value),
      selectedColor: AppColors.accentGold.withValues(alpha: 0.35),
    );
  }

  Widget _accessChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _access == value,
      onSelected: (_) => setState(() => _access = value),
      selectedColor: AppColors.accentGold.withValues(alpha: 0.35),
    );
  }
}
