import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/features/sharing/data/models/sharing_models.dart';
import 'package:craftquest_app/features/sharing/data/sharing_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class InviteQuizUsersSheet extends StatefulWidget {
  const InviteQuizUsersSheet({
    super.key,
    required this.quizId,
    required this.scaffoldMessenger,
  });

  final String quizId;
  final ScaffoldMessengerState scaffoldMessenger;

  static Future<void> show(BuildContext context, {required String quizId}) {
    final messenger = ScaffoldMessenger.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InviteQuizUsersSheet(
        quizId: quizId,
        scaffoldMessenger: messenger,
      ),
    );
  }

  @override
  State<InviteQuizUsersSheet> createState() => _InviteQuizUsersSheetState();
}

class _InviteQuizUsersSheetState extends State<InviteQuizUsersSheet> {
  final _sharingRepo = getIt<SharingRepository>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _inlineMessage;
  bool _inlineIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _setInlineMessage(String message, {required bool isError}) {
    setState(() {
      _inlineMessage = message;
      _inlineIsError = isError;
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    widget.scaffoldMessenger.hideCurrentSnackBar();
    widget.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<String> _parseEmails(String raw) {
    return raw
        .split(RegExp(r'[,;\s]+'))
        .map((e) => e.trim())
        .where((e) => e.contains('@'))
        .toSet()
        .toList();
  }

  String _outcomeMessage(AppLocalizations l10n, InviteUserResultItemModel item) {
    return switch (item.outcome) {
      'invited' => l10n.quizInviteOutcomeInvited(item.displayName ?? item.email),
      'already_had_access' =>
        l10n.quizInviteOutcomeAlreadyHadAccess(item.displayName ?? item.email),
      'not_found' => l10n.quizInviteOutcomeNotFound(item.email),
      'invalid_email' => l10n.quizInviteOutcomeInvalidEmail(item.email),
      'slot_limit' => l10n.quizInviteOutcomeSlotLimit(item.displayName ?? item.email),
      'self' => l10n.quizInviteOutcomeSelf,
      _ => item.email,
    };
  }

  Future<void> _invite() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    final emails = _parseEmails(_emailController.text);
    if (emails.isEmpty) {
      _setInlineMessage(l10n.quizInviteEmailsRequired, isError: true);
      return;
    }

    setState(() {
      _submitting = true;
      _inlineMessage = null;
    });
    try {
      final result = await _sharingRepo.inviteUsersByEmail(
        quizId: widget.quizId,
        emails: emails,
      );
      if (!mounted) return;

      final invited = result.results.where((r) => r.outcome == 'invited').length;
      final issues = result.results.where((r) => r.outcome != 'invited').toList();

      if (invited > 0 && issues.isEmpty) {
        final message = l10n.quizInviteSuccessCount(invited);
        _setInlineMessage(message, isError: false);
        _showSnackBar(message, isError: false);
        _emailController.clear();
      } else if (invited > 0) {
        final success = l10n.quizInviteSuccessCount(invited);
        final issueSummary =
            issues.map((r) => _outcomeMessage(l10n, r)).join('\n');
        _setInlineMessage('$success\n$issueSummary', isError: false);
        _showSnackBar(success, isError: false);
        _emailController.clear();
      } else if (issues.isNotEmpty) {
        final summary = issues.map((r) => _outcomeMessage(l10n, r)).join('\n');
        _setInlineMessage(summary, isError: true);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final message = DioErrorMapper.map(e, l10n);
      _setInlineMessage(message, isError: true);
      _showSnackBar(message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.quizInviteTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.quizInviteSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            enabled: !_submitting,
            keyboardType: TextInputType.emailAddress,
            maxLines: 4,
            minLines: 2,
            onChanged: (_) {
              if (_inlineMessage != null) {
                setState(() => _inlineMessage = null);
              }
            },
            decoration: InputDecoration(
              labelText: l10n.quizInviteEmailsLabel,
              hintText: l10n.quizInviteEmailsHint,
              alignLabelWithHint: true,
            ),
          ),
          if (_inlineMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _inlineMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _inlineIsError
                        ? Theme.of(context).colorScheme.error
                        : AppColors.accentMint,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _invite,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.quizInviteAction),
          ),
        ],
      ),
    );
  }
}
