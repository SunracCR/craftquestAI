import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum BillingCycle { monthly, annual }

extension BillingCycleApi on BillingCycle {
  String get apiValue => this == BillingCycle.monthly ? 'monthly' : 'annual';
}

class BillingCycleSelector extends StatelessWidget {
  const BillingCycleSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<BillingCycle>(
      segments: [
        ButtonSegment(
          value: BillingCycle.monthly,
          label: Text(l10n.billingCycleMonthly),
        ),
        ButtonSegment(
          value: BillingCycle.annual,
          label: Text(l10n.billingCycleAnnual),
        ),
      ],
      selected: {value},
      onSelectionChanged: enabled
          ? (selection) {
              if (selection.isNotEmpty) {
                onChanged(selection.first);
              }
            }
          : null,
      showSelectedIcon: false,
    );
  }
}
