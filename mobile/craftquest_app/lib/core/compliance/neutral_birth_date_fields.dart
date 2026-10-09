import 'package:craftquest_app/core/compliance/neutral_birth_date.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Día, mes y año vacíos. No precarga una edad ni un año de ejemplo.
class NeutralBirthDateFields extends StatefulWidget {
  const NeutralBirthDateFields({
    required this.onChanged,
    this.initialDate,
    super.key,
  });

  final ValueChanged<DateTime?> onChanged;
  final DateTime? initialDate;

  @override
  State<NeutralBirthDateFields> createState() => _NeutralBirthDateFieldsState();
}

class _NeutralBirthDateFieldsState extends State<NeutralBirthDateFields> {
  final _dayController = TextEditingController();
  final _yearController = TextEditingController();
  int? _month;
  bool _invalid = false;
  bool _dirty = false;
  DateTime? _lastEmitted;

  @override
  void initState() {
    super.initState();
    _applyDate(widget.initialDate);
    _lastEmitted = widget.initialDate;
    _dayController.addListener(_onEdited);
    _yearController.addListener(_onEdited);
  }

  @override
  void didUpdateWidget(covariant NeutralBirthDateFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialDate;
    if (_dirty || next == null || next == oldWidget.initialDate) {
      return;
    }
    _dayController.removeListener(_onEdited);
    _yearController.removeListener(_onEdited);
    _applyDate(next);
    _lastEmitted = next;
    _invalid = false;
    _dayController.addListener(_onEdited);
    _yearController.addListener(_onEdited);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _applyDate(DateTime? date) {
    _dayController.text = date == null ? '' : date.day.toString();
    _yearController.text = date == null ? '' : date.year.toString();
    _month = date?.month;
  }

  void _onEdited() {
    _dirty = true;
    _emit();
  }

  void _onMonthChanged(int? month) {
    _dirty = true;
    setState(() => _month = month);
    _emit();
  }

  void _emit() {
    final dayText = _dayController.text;
    final yearText = _yearController.text;
    final parsed = NeutralBirthDate.parse(
      dayText: dayText,
      yearText: yearText,
      month: _month,
    );
    final invalid = NeutralBirthDate.isComplete(
          dayText: dayText,
          yearText: yearText,
          month: _month,
        ) &&
        parsed == null;
    if (invalid != _invalid) {
      setState(() => _invalid = invalid);
    }
    if (parsed == _lastEmitted) {
      return;
    }
    _lastEmitted = parsed;
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final monthFormat = DateFormat.MMMM(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _dayController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(labelText: l10n.birthDateDayLabel),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: 3,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.birthDateMonthLabel,
                ),
                isEmpty: _month == null,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _month,
                    isExpanded: true,
                    hint: const SizedBox(height: 24),
                    items: [
                      for (var month = 1; month <= 12; month++)
                        DropdownMenuItem(
                          value: month,
                          child: Text(
                            monthFormat.format(DateTime(2000, month)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _onMonthChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: l10n.birthDateYearLabel,
                ),
              ),
            ),
          ],
        ),
        if (_invalid) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.birthDateInvalid,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ],
      ],
    );
  }
}

/// Diálogo para corregir una fecha ya guardada. Sin fecha previa, los campos
/// quedan vacíos.
Future<DateTime?> showNeutralBirthDateDialog(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => _NeutralBirthDateDialog(initialDate: initialDate),
  );
}

class _NeutralBirthDateDialog extends StatefulWidget {
  const _NeutralBirthDateDialog({required this.initialDate});

  final DateTime? initialDate;

  @override
  State<_NeutralBirthDateDialog> createState() => _NeutralBirthDateDialogState();
}

class _NeutralBirthDateDialogState extends State<_NeutralBirthDateDialog> {
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.correctBirthDateAction),
      content: NeutralBirthDateFields(
        initialDate: widget.initialDate,
        onChanged: (date) => setState(() => _date = date),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.parentalGateCancel),
        ),
        TextButton(
          onPressed: _date == null
              ? null
              : () => Navigator.of(context).pop(_date),
          child: Text(l10n.ageScreenContinue),
        ),
      ],
    );
  }
}
