import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:craftquest_app/core/compliance/neutral_birth_date_fields.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_brand_header.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Pantalla neutral de edad (audiencia mixta Google Play).
///
/// Los campos nacen vacíos: no hay fecha ni edad preseleccionada.
class AgeScreen extends StatefulWidget {
  const AgeScreen({required this.onCompleted, super.key});

  final VoidCallback onCompleted;

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  final _storage = getIt<AgeCollectionStorage>();
  DateTime? _birthDate;
  bool _saving = false;

  Future<void> _continue() async {
    final birthDate = _birthDate;
    if (birthDate == null || _saving) {
      return;
    }

    setState(() => _saving = true);
    await _storage.saveDateOfBirth(birthDate);
    if (!mounted) {
      return;
    }
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: l10n.ageScreenTitle,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: AppSpacing.pageVertical,
        children: [
          AppBrandHeader(title: l10n.ageScreenTitle),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.ageScreenSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          NeutralBirthDateFields(
            onChanged: (date) => setState(() => _birthDate = date),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppGradientPrimaryButton(
            label: l10n.ageScreenContinue,
            isLoading: _saving,
            onPressed: _birthDate == null ? null : _continue,
          ),
        ],
      ),
    );
  }
}
