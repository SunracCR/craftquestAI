import 'dart:async';

import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/features/auth/presentation/login_page.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PrepPlusPublicPreviewPage extends StatefulWidget {
  const PrepPlusPublicPreviewPage({
    super.key,
    required this.slug,
    this.initialPreview,
  });

  final String slug;
  final PrepPublicPreviewModel? initialPreview;

  @override
  State<PrepPlusPublicPreviewPage> createState() =>
      _PrepPlusPublicPreviewPageState();
}

class _PrepPlusPublicPreviewPageState extends State<PrepPlusPublicPreviewPage> {
  final _repository = getIt<PrepPlusRepository>();

  PrepPublicPreviewModel? _preview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPreview;
    if (initial != null) {
      _preview = initial;
      _loading = false;
    }
    unawaited(_load());
  }

  Future<void> _load() async {
    if (_preview == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final preview = await _repository.getPublicPreview(widget.slug);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (_preview != null) {
        return;
      }
      setState(() {
        _error = _repository.mapError(e, AppLocalizations.of(context));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_preview != null) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(context)!.prepPlusNotAvailableForPurchase;
        _loading = false;
      });
    }
  }

  void _openLogin() {
    final catalogItemId = _preview?.catalogItemId;
    if (catalogItemId != null && catalogItemId.isNotEmpty) {
      unawaited(_repository.prefetchItem(catalogItemId));
    }

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: l10n.navPrepPlusLabel,
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: Padding(
        padding: AppSpacing.pageVertical,
        child: _loading
            ? const AppLoadingView()
            : _error != null
                ? AppErrorView(
                    message: _error!,
                    retryLabel: l10n.retry,
                    onRetry: _load,
                  )
                : _buildContent(l10n, _preview!),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, PrepPublicPreviewModel preview) {
    final priceLabel = preview.hasFreeOffer
        ? l10n.prepPlusHasFreeOffer
        : preview.lowestPaidPrice != null
            ? '${preview.currencyCode ?? 'USD'} ${preview.lowestPaidPrice!.toStringAsFixed(2)}'
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          preview.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          preview.categoryName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.prepPlusPublicPreviewQuestions(preview.questionCount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (priceLabel != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            priceLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accentGold,
                ),
          ),
        ],
        if (preview.description != null && preview.description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            preview.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const Spacer(),
        AppGradientPrimaryButton(
          label: l10n.prepPlusPublicPreviewSignIn,
          onPressed: _openLogin,
        ),
      ],
    );
  }
}
