import 'dart:async';

import 'package:craftquest_app/core/compliance/age_collection_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_brand_header.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pantalla neutral de edad (audiencia mixta Google Play).
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

  @override
  void initState() {
    super.initState();
    unawaited(_loadStoredDate());
  }

  Future<void> _loadStoredDate() async {
    final stored = await _storage.getDateOfBirth();
    if (!mounted || stored == null) {
      return;
    }
    setState(() => _birthDate = stored);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.ageScreenBirthDateLabel,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

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

  bool get _isMinor {
    final birthDate = _birthDate;
    if (birthDate == null) {
      return false;
    }
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (birthDate.month > today.month ||
        (birthDate.month == today.month && birthDate.day > today.day)) {
      age--;
    }
    return age < AgeCollectionStorage.minimumAgeWithoutParentalConsent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formattedDate = _birthDate == null
        ? l10n.ageScreenBirthDateLabel
        : DateFormat.yMMMMd(locale).format(_birthDate!);

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
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(formattedDate),
          ),
          if (_isMinor) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.ageScreenMinorNotice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accentCool,
                  ),
            ),
          ],
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
