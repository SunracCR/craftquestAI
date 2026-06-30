import 'dart:math';

import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Gate parental: operación matemática simple para verificar adulto.
Future<bool> showParentalGate(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _ParentalGateDialog(),
  );
  return result ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  late final _MathChallenge _challenge;
  final _answerController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _challenge = _MathChallenge.random();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submit() {
    final answer = int.tryParse(_answerController.text.trim());
    if (answer == _challenge.expectedAnswer) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _errorText = AppLocalizations.of(context)!.parentalGateWrongAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.parentalGateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.parentalGateSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _challenge.prompt,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _answerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.parentalGateAnswerLabel,
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.parentalGateCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.parentalGateConfirm),
        ),
      ],
    );
  }
}

class _MathChallenge {
  _MathChallenge({
    required this.prompt,
    required this.expectedAnswer,
  });

  final String prompt;
  final int expectedAnswer;

  static final _random = Random();

  factory _MathChallenge.random() {
    final a = _random.nextInt(9) + 2;
    final b = _random.nextInt(9) + 2;
    final useAddition = _random.nextBool();
    if (useAddition) {
      return _MathChallenge(
        prompt: '$a + $b',
        expectedAnswer: a + b,
      );
    }
    final larger = max(a, b);
    final smaller = min(a, b);
    return _MathChallenge(
      prompt: '$larger − $smaller',
      expectedAnswer: larger - smaller,
    );
  }
}
