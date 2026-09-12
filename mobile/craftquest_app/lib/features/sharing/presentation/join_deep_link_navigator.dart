import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/navigation/web_entry_url_cleanup.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_detail_page.dart';
import 'package:craftquest_app/features/sharing/data/pending_join_code_store.dart';
import 'package:craftquest_app/features/sharing/data/sharing_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Redeems a join code silently and opens the quiz detail page.
class JoinDeepLinkNavigator {
  JoinDeepLinkNavigator(
    this._sharingRepository,
    this._pendingJoinCodeStore,
  );

  final SharingRepository _sharingRepository;
  final PendingJoinCodeStore _pendingJoinCodeStore;
  String? _inFlightCode;

  Future<bool> openQuizFromJoinCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || _inFlightCode == normalized) {
      return false;
    }

    _inFlightCode = normalized;
    try {
      final result = await _sharingRepository.redeemCode(normalized);
      await _pendingJoinCodeStore.clear();
      clearWebEntryDeepLinkUrl();

      final navigator = rootNavigatorKey.currentState;
      if (navigator == null) {
        return false;
      }

      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          if (result.alreadyInSharedList) {
            AppSnackBars.showInfo(
              l10n.redeemCodeAlreadyInShared(result.quizTitle),
            );
          } else {
            AppSnackBars.showSuccess(l10n.redeemCodeSuccess(result.quizTitle));
          }
        }
      }

      await navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => QuizDetailPage(
            quizId: result.quizId,
            quizTitle: result.quizTitle,
            publicationStatus: 'published',
            isOwner: false,
          ),
        ),
      );
      return true;
    } on DioException catch (e) {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.showDioErrorSnackBar(e);
      } else {
        AppSnackBars.showError(
          _sharingRepository.mapError(e),
        );
      }
      return false;
    } finally {
      if (_inFlightCode == normalized) {
        _inFlightCode = null;
      }
    }
  }
}
