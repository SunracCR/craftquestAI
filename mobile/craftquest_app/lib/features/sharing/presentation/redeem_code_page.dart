import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_brand_header.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/quizzes/presentation/quiz_detail_page.dart';
import 'package:craftquest_app/features/sharing/data/sharing_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class RedeemCodePage extends StatefulWidget {
  const RedeemCodePage({
    super.key,
    this.initialCode,
    this.autoRedeem = false,
  });

  final String? initialCode;

  /// When true (typically from a join deep link), redeems immediately and opens the quiz.
  final bool autoRedeem;

  @override
  State<RedeemCodePage> createState() => _RedeemCodePageState();
}

class _RedeemCodePageState extends State<RedeemCodePage> {
  final _repository = getIt<SharingRepository>();
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _showAutoRedeemLoading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCode?.trim();
    if (initial != null && initial.isNotEmpty) {
      _codeController.text = initial.toUpperCase();
    }

    if (widget.autoRedeem && initial != null && initial.isNotEmpty) {
      _showAutoRedeemLoading = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _redeem(openQuizOnSuccess: true),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem({bool openQuizOnSuccess = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      context.showErrorSnackBar(l10n.redeemCodeRequired);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _repository.redeemCode(code);
      if (!mounted) return;

      if (openQuizOnSuccess) {
        if (!result.alreadyInSharedList) {
          context.showSuccessSnackBar(l10n.redeemCodeSuccess(result.quizTitle));
        }
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => QuizDetailPage(
              quizId: result.quizId,
              quizTitle: result.quizTitle,
              publicationStatus: 'published',
              isOwner: false,
            ),
          ),
        );
        return;
      }

      if (result.alreadyInSharedList) {
        context.showInfoSnackBar(l10n.redeemCodeAlreadyInShared(result.quizTitle));
      } else {
        context.showSuccessSnackBar(l10n.redeemCodeSuccess(result.quizTitle));
      }
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _showAutoRedeemLoading = false);
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_showAutoRedeemLoading && _loading) {
      return EdgeAwareScaffold(
        appBar: craftQuestAppBar(title: l10n.redeemCodeTitle),
        body: ListView(
          padding: AppSpacing.pageVertical,
          children: [
            AppBrandHeader(
              title: l10n.redeemCodeTitle,
              subtitle: l10n.redeemCodeOpeningQuiz,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: l10n.redeemCodeTitle),
      bottomBar: AppBottomActionBar(
        children: [
          AppGradientPrimaryButton(
            label: l10n.redeemCodeAction,
            isLoading: _loading,
            onPressed: _redeem,
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.pageVertical,
        children: [
          AppBrandHeader(
            title: l10n.redeemCodeTitle,
            subtitle: l10n.redeemCodeSubtitle,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.redeemCodeLabel),
          ),
        ],
      ),
    );
  }
}
