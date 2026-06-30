import 'dart:async';

import 'package:craftquest_app/core/billing/payment_platform.dart';
import 'package:craftquest_app/core/compliance/parental_gate_dialog.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_page_header.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/core/services/sound_service.dart';
import 'package:craftquest_app/core/widgets/app_section_title.dart';
import 'package:craftquest_app/features/analytics/presentation/quiz_analytics_page.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_preview_page.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_access_combo_card.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/data/practice_sound_preference_store.dart';
import 'package:craftquest_app/features/practice/domain/practice_launch_options.dart';
import 'package:craftquest_app/features/practice/data/practice_preferences_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/practice/presentation/my_practice_attempts_page.dart';
import 'package:craftquest_app/features/practice/presentation/practice_navigation.dart';
import 'package:craftquest_app/features/practice/presentation/practice_session_feedback.dart';
import 'package:craftquest_app/features/practice/presentation/widgets/practice_launch_options_card.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PrepPlusItemDetailPage extends StatefulWidget {
  const PrepPlusItemDetailPage({super.key, required this.catalogItemId});

  final String catalogItemId;

  @override
  State<PrepPlusItemDetailPage> createState() => _PrepPlusItemDetailPageState();
}

class _PrepPlusItemDetailPageState extends State<PrepPlusItemDetailPage> {
  static const _bestValueDurationDays = 183;

  final _repository = getIt<PrepPlusRepository>();
  final _preferencesRepository = getIt<PracticePreferencesRepository>();
  final _soundPreferenceStore = getIt<PracticeSoundPreferenceStore>();
  PrepItemDetailModel? _item;
  String? _selectedOfferId;
  bool _loading = true;
  bool _loadingPreferences = false;
  bool _checkingOut = false;
  bool _randomizeQuestions = false;
  bool _showTimer = true;
  bool _enableSoundEffects = PracticeLaunchOptions.defaults.enableSoundEffects;
  String? _error;
  String? _pendingPayPalOrderId;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Future<PracticeActiveSessionModel?>? _activeSessionPrefetch;

  static bool get _supportsStorePurchase =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_supportsStorePurchase) {
      _purchaseSub =
          InAppPurchase.instance.purchaseStream.listen(_onPurchaseUpdate);
    }
    _load();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await _repository.getItem(widget.catalogItemId);
      if (!mounted) return;
      setState(() {
        _item = item;
        _selectedOfferId = _defaultOfferId(item.offers);
        _loading = false;
      });
      if (item.canPractice) {
        _warmPracticeLaunch(item.quizId);
        unawaited(_loadPracticePreferences(item.quizId));
        unawaited(_loadSoundPreferences());
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = _repository.mapError(e, l10n);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.genericMessage(AppLocalizations.of(context)!);
        _loading = false;
      });
    }
  }

  String? _defaultOfferId(List<PrepAccessOfferModel> offers) {
    if (offers.isEmpty) return null;
    for (final o in offers) {
      if (o.durationDays == _bestValueDurationDays) return o.offerId;
    }
    PrepAccessOfferModel longest = offers.first;
    for (final o in offers.skip(1)) {
      if (o.durationDays > longest.durationDays) longest = o;
    }
    return longest.offerId;
  }

  void _warmPracticeLaunch(String quizId) {
    _activeSessionPrefetch =
        getIt<PracticeRepository>().getActiveSessionForQuiz(quizId);
  }

  PracticeLaunchOptions get _currentLaunchOptions => PracticeLaunchOptions(
        randomizeQuestions: _randomizeQuestions,
        showTimer: _showTimer,
        enableSoundEffects: _enableSoundEffects,
      );

  Future<void> _loadPracticePreferences(String quizId) async {
    if (!mounted) return;
    setState(() => _loadingPreferences = true);
    try {
      final prefs = await _preferencesRepository.getPreferences(quizId);
      if (!mounted) return;
      setState(() {
        _showTimer = prefs.showElapsedTimer;
        _randomizeQuestions = prefs.randomizeQuestions;
        _loadingPreferences = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPreferences = false);
    }
  }

  Future<void> _loadSoundPreferences() async {
    try {
      final prefs = await _soundPreferenceStore.load();
      if (!mounted) return;
      setState(() => _enableSoundEffects = prefs.enableSoundEffects);
    } catch (_) {}
  }

  Future<void> _persistShowTimerPreference(String quizId) async {
    try {
      await _preferencesRepository.savePreferences(
        quizId: quizId,
        randomizeQuestions: _randomizeQuestions,
        showElapsedTimer: _showTimer,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    }
  }

  Future<void> _updateRandomizeQuestions(String quizId, bool value) async {
    final previous = _randomizeQuestions;
    setState(() => _randomizeQuestions = value);
    try {
      await _preferencesRepository.savePreferences(
        quizId: quizId,
        randomizeQuestions: value,
        showElapsedTimer: _showTimer,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _randomizeQuestions = previous);
      context.showDioErrorSnackBar(e);
    }
  }

  void _updateShowTimer(String quizId, bool value) {
    setState(() => _showTimer = value);
    _persistShowTimerPreference(quizId);
  }

  Future<void> _updateSoundEffects(bool value) async {
    setState(() => _enableSoundEffects = value);
    await _soundPreferenceStore.saveSoundEffects(value);
    if (value) {
      PracticeSessionFeedback.previewEnabled(getIt<SoundService>());
    }
  }

  Future<void> _viewAnalytics(String quizId, String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizAnalyticsPage(
          quizId: quizId,
          quizTitle: title,
          personalMode: true,
        ),
      ),
    );
  }

  Future<void> _viewAttempts(String quizId, String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyPracticeAttemptsPage(
          quizId: quizId,
          quizTitle: title,
        ),
      ),
    );
  }

  Future<void> _startPractice(PrepItemDetailModel item) async {
    final practiceRepo = getIt<PracticeRepository>();
    await openPracticeSession(
      context,
      quizId: item.quizId,
      quizTitle: item.title,
      launchOptions: _currentLaunchOptions,
      launchOptionsResolved: true,
      activeSessionPrefetch: _activeSessionPrefetch ??
          practiceRepo.getActiveSessionForQuiz(item.quizId),
    );
    if (mounted) await _load();
  }

  Widget _historyMenuDivider() => Divider(
        height: 1,
        indent: AppSpacing.md,
        endIndent: AppSpacing.md,
        color: AppColors.textSecondary.withValues(alpha: 0.12),
      );

  void _openPreview() {
    final item = _item;
    if (item == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrepPlusPreviewPage(
          catalogItemId: widget.catalogItemId,
          title: item.title,
        ),
      ),
    );
  }

  PrepAccessOfferModel? get _selectedOffer {
    final item = _item;
    if (item == null || _selectedOfferId == null) return null;
    for (final o in item.offers) {
      if (o.offerId == _selectedOfferId) return o;
    }
    return null;
  }

  Future<void> _checkoutFree() async {
    final offer = _selectedOffer;
    if (offer == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _checkingOut = true);
    try {
      final result = await _repository.checkout(
        catalogItemId: widget.catalogItemId,
        offerId: offer.offerId,
      );
      if (!mounted) return;

      if (result.status == 'granted') {
        context.showSuccessSnackBar(
          AppLocalizations.of(context)!.prepPlusAccessGranted,
        );
        setState(() => _pendingPayPalOrderId = null);
        await _load();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repository.mapError(e, l10n));
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(DioErrorMapper.genericMessage(l10n));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<void> _buyPaid(PrepAccessOfferModel offer) async {
    if (!await showParentalGate(context)) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;

    if (_supportsStorePurchase &&
        offer.storeProductId != null &&
        offer.storeProductId!.isNotEmpty) {
      await _buyWithStore(offer);
      return;
    }

    if (PaymentPlatform.supportsPayPalCheckout) {
      await _buyWithPayPal(offer);
      return;
    }

    context.showErrorSnackBar(l10n.prepPlusStoreProductMissing);
  }

  Future<void> _buyWithPayPal(PrepAccessOfferModel offer) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _checkingOut = true);
    try {
      final order = await _repository.createPayPalOrder(
        catalogItemId: widget.catalogItemId,
        offerId: offer.offerId,
      );
      if (!mounted) return;

      setState(() => _pendingPayPalOrderId = order.orderId);

      if (order.mockMode) {
        await _repository.capturePayPalOrder(order.orderId);
        if (!mounted) return;
        context.showSuccessSnackBar(l10n.prepPlusAccessGranted);
        setState(() => _pendingPayPalOrderId = null);
        await _load();
        return;
      }

      if (order.approvalUrl != null && order.approvalUrl!.isNotEmpty) {
        final uri = Uri.parse(order.approvalUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!mounted) return;
          context.showInfoSnackBar(l10n.paypalAwaitingCapture);
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<void> _confirmPayPalCapture() async {
    final orderId = _pendingPayPalOrderId;
    if (orderId == null) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _checkingOut = true);
    try {
      final result = await _repository.capturePayPalOrder(orderId);
      if (!mounted) return;
      if (result.status == 'granted') {
        context.showSuccessSnackBar(l10n.prepPlusAccessGranted);
        setState(() => _pendingPayPalOrderId = null);
        await _load();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<void> _buyWithStore(PrepAccessOfferModel offer) async {
    final l10n = AppLocalizations.of(context)!;
    final productId = offer.storeProductId!;

    if (!await InAppPurchase.instance.isAvailable()) {
      if (!mounted) return;
      context.showErrorSnackBar(l10n.storeProductNotConfigured);
      return;
    }

    final response =
        await InAppPurchase.instance.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      if (!mounted) return;
      context.showErrorSnackBar(l10n.storeProductNotFound(productId));
      return;
    }

    setState(() => _checkingOut = true);
    final product = response.productDetails.first;
    await InAppPurchase.instance.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    final l10n = AppLocalizations.of(context)!;
    final offer = _selectedOffer;
    if (offer == null) return;

    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          final platform = defaultTargetPlatform == TargetPlatform.iOS
              ? 'app_store'
              : 'google_play';
          final token = purchase.verificationData.serverVerificationData;
          final result = await _repository.verifyMobilePurchase(
            catalogItemId: widget.catalogItemId,
            offerId: offer.offerId,
            platform: platform,
            productId: purchase.productID,
            purchaseToken: token.isNotEmpty ? token : purchase.purchaseID ?? '',
            transactionId: purchase.purchaseID,
          );
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
          if (!mounted) return;
          if (result.status == 'granted') {
            context.showSuccessSnackBar(l10n.prepPlusAccessGranted);
            await _load();
          }
        } catch (e) {
          if (!mounted) return;
          context.showErrorSnackBar(l10n.purchaseVerificationFailed);
        } finally {
          if (mounted) setState(() => _checkingOut = false);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) setState(() => _checkingOut = false);
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _checkingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EdgeAwareScaffold(
      appBar: craftQuestAppBar(title: _item?.title ?? l10n.prepPlusItemDetailTitle),
      bottomBar: _buildBottomBar(l10n),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                )
              : _item == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: AppSpacing.listBottom,
                      children: [
                        AppPageHeader(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _item!.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _item!.categoryName,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.prepPlusQuestionCount(_item!.questionCount),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_item!.description != null &&
                                    _item!.description!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    _item!.description!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                if (_item!.accessExpiresAt != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: AppSpacing.sm),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (_item!.canPractice
                                                ? AppColors.accentMint
                                                : AppColors.textSecondary)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                          AppColors.radiusSm,
                                        ),
                                        border: Border.all(
                                          color: (_item!.canPractice
                                                  ? AppColors.accentMint
                                                  : AppColors.inputBorder)
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        _item!.canPractice
                                            ? l10n.prepPlusAccessUntil(
                                                _formatDate(
                                                  _item!.accessExpiresAt!,
                                                ),
                                              )
                                            : l10n.prepPlusAccessExpired,
                                        style: TextStyle(
                                          color: _item!.canPractice
                                              ? AppColors.accentMint
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (_item!.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.sm,
                            ),
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: _item!.tags
                                  .map(
                                    (t) => Chip(
                                      label: Text(t),
                                      visualDensity: VisualDensity.compact,
                                      side: BorderSide(
                                        color: AppColors.inputBorder
                                            .withValues(alpha: 0.6),
                                      ),
                                      backgroundColor:
                                          AppColors.surfaceSecondary.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: _PrepPlusSimulationCta(
                            onTap: _openPreview,
                            l10n: l10n,
                          ),
                        ),
                        if (_item!.canPractice) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: _loadingPreferences
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : PracticeLaunchOptionsCard(
                                    randomizeQuestions: _randomizeQuestions,
                                    showTimer: _showTimer,
                                    enableSoundEffects: _enableSoundEffects,
                                    onRandomizeQuestionsChanged: (value) =>
                                        _updateRandomizeQuestions(
                                      _item!.quizId,
                                      value,
                                    ),
                                    onShowTimerChanged: (value) =>
                                        _updateShowTimer(_item!.quizId, value),
                                    onSoundEffectsChanged: _updateSoundEffects,
                                  ),
                          ),
                        ],
                        if (_item!.offers.isNotEmpty &&
                            (_item!.canPurchase ||
                                _item!.userAccessState == 'expired')) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.xs,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.prepPlusAccessCombosTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.prepPlusAccessCombosSubtitle,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final offer in _item!.offers)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: PrepPlusAccessComboCard(
                                offer: offer,
                                selected: _selectedOfferId == offer.offerId,
                                onTap: () => setState(
                                  () => _selectedOfferId = offer.offerId,
                                ),
                              ),
                            ),
                        ],
                        if (!_item!.canPurchase && _item!.userAccessState == 'none')
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              l10n.prepPlusNotAvailableForPurchase,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        if (_pendingPayPalOrderId != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md,
                              0,
                            ),
                            child: AppSectionCard(
                              variant: AppCardVariant.highlight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l10n.paypalAwaitingCapture,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppPrimaryButton(
                                    label: l10n.prepPlusConfirmPayPalPayment,
                                    isLoading: _checkingOut,
                                    onPressed: _checkingOut
                                        ? null
                                        : _confirmPayPalCapture,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_item!.userAccessState != 'none')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.md,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppSectionTitle(
                                  title: l10n.prepPlusProgressSectionTitle,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AppSectionCard(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    children: [
                                      AppActionTile(
                                        icon: Icons.analytics_rounded,
                                        label: l10n.myQuizAnalyticsAction,
                                        iconColor: AppColors.accentCool,
                                        iconBackgroundColor: AppColors.accentCool
                                            .withValues(alpha: 0.2),
                                        onTap: () => _viewAnalytics(
                                          _item!.quizId,
                                          _item!.title,
                                        ),
                                      ),
                                      _historyMenuDivider(),
                                      AppActionTile(
                                        icon: Icons.history_rounded,
                                        label: l10n.prepPlusViewHistory,
                                        iconColor: AppColors.accentSky,
                                        iconBackgroundColor: AppColors.accentSky
                                            .withValues(alpha: 0.2),
                                        onTap: () => _viewAttempts(
                                          _item!.quizId,
                                          _item!.title,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget? _buildBottomBar(AppLocalizations l10n) {
    final item = _item;
    if (item == null) return null;

    if (item.canPractice) {
      return AppBottomActionBar(
        children: [
          AppPrimaryButton(
          label: l10n.prepPlusPracticeAction,
          onPressed: () => _startPractice(item),
        ),
        ],
      );
    }

    if ((item.canPurchase || item.userAccessState == 'expired') &&
        _selectedOffer != null &&
        _pendingPayPalOrderId == null) {
      final offer = _selectedOffer!;
      return AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: item.userAccessState == 'expired'
                ? l10n.prepPlusRenewAction
                : (offer.isFree
                    ? l10n.prepPlusGetFreeAccessAction
                    : l10n.prepPlusBuyAction),
            isLoading: _checkingOut,
            onPressed: _checkingOut
                ? null
                : () async {
                    if (offer.isFree) {
                      await _checkoutFree();
                    } else {
                      await _buyPaid(offer);
                    }
                  },
          ),
        ],
      );
    }

    return null;
  }

  String _formatDate(DateTime dt) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(dt.toLocal());
}

class _PrepPlusSimulationCta extends StatelessWidget {
  const _PrepPlusSimulationCta({
    required this.onTap,
    required this.l10n,
  });

  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        side: BorderSide(
          color: AppColors.accentGold.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.accentGold.withValues(alpha: 0.12),
                AppColors.accentCool.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.accentGold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.prepPlusPreviewSimulationCtaTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.prepPlusPreviewSimulationCtaSubtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accentGold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
