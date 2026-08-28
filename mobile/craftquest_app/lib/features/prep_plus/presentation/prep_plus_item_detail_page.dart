import 'dart:async';

import 'package:craftquest_app/core/billing/checkout_refresh_notifier.dart';
import 'package:craftquest_app/core/billing/mobile_store_product_query.dart';
import 'package:craftquest_app/core/billing/purchase_flow_state.dart';
import 'package:craftquest_app/core/billing/purchase_orchestrator.dart';
import 'package:craftquest_app/core/billing/store_purchase_feedback.dart';
import 'package:craftquest_app/core/billing/paypal_checkout_launch.dart';
import 'package:craftquest_app/core/billing/payment_platform.dart';
import 'package:craftquest_app/core/navigation/web_entry_url_cleanup.dart';
import 'package:craftquest_app/core/compliance/parental_gate_dialog.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/network/dio_error_mapper.dart';
import 'package:craftquest_app/core/theme/app_colors.dart';
import 'package:craftquest_app/core/theme/app_spacing.dart';
import 'package:craftquest_app/core/widgets/app_bottom_bar.dart';
import 'package:craftquest_app/core/widgets/app_buttons.dart';
import 'package:craftquest_app/core/widgets/app_section_card.dart';
import 'package:craftquest_app/core/widgets/app_snackbar.dart';
import 'package:craftquest_app/core/widgets/app_states.dart';
import 'package:craftquest_app/core/widgets/edge_aware_scaffold.dart';
import 'package:craftquest_app/core/services/sound_service.dart';
import 'package:craftquest_app/features/analytics/presentation/quiz_analytics_page.dart';
import 'package:craftquest_app/features/billing/data/pending_paypal_payment_store.dart';
import 'package:craftquest_app/features/billing/presentation/paypal_return_launch.dart';
import 'package:craftquest_app/features/prep_plus/data/pending_prep_referral_store.dart';
import 'package:craftquest_app/features/prep_plus/data/models/prep_plus_models.dart';
import 'package:craftquest_app/features/prep_plus/data/prep_plus_repository.dart';
import 'package:craftquest_app/features/prep_plus/presentation/prep_plus_preview_page.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_checkout_processing_overlay.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_access_combo_card.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_item_hero.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_practice_options_panel.dart';
import 'package:craftquest_app/features/prep_plus/presentation/widgets/prep_plus_simulation_tile.dart';
import 'package:craftquest_app/features/practice/data/models/practice_models.dart';
import 'package:craftquest_app/features/practice/data/practice_sound_preference_store.dart';
import 'package:craftquest_app/features/practice/domain/practice_launch_options.dart';
import 'package:craftquest_app/features/practice/data/practice_preferences_repository.dart';
import 'package:craftquest_app/features/practice/data/practice_repository.dart';
import 'package:craftquest_app/features/practice/presentation/my_practice_attempts_page.dart';
import 'package:craftquest_app/features/practice/presentation/practice_navigation.dart';
import 'package:craftquest_app/features/practice/presentation/practice_session_feedback.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_package_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_session_checkpoint_repository.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_storage_bootstrap.dart';
import 'package:craftquest_app/features/offline_practice/data/offline_sync_repository.dart';
import 'package:craftquest_app/features/offline_practice/domain/offline_prep_access_reconciler.dart';
import 'package:craftquest_app/features/offline_practice/presentation/cubit/offline_practice_session_cubit.dart';
import 'package:craftquest_app/features/offline_practice/presentation/offline_practice_session_page.dart';
import 'package:craftquest_app/features/offline_practice/presentation/widgets/offline_quiz_actions_panel.dart';
import 'package:craftquest_app/core/utils/billing_plan_access.dart';
import 'package:craftquest_app/core/utils/share_text_helper.dart';
import 'package:craftquest_app/features/billing/data/billing_repository.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PrepPlusItemDetailPage extends StatefulWidget {
  const PrepPlusItemDetailPage({
    super.key,
    required this.catalogItemId,
    this.initialFromAccess,
    this.initialFromPreview,
    this.resumePendingWebCheckout = false,
    this.pendingWebPayPalCancelled = false,
    this.pendingWebPayPalOrderId,
  });

  final String catalogItemId;

  /// Datos ya conocidos desde Mis accesos para pintar sin esperar al API.
  final PrepMyAccessItemModel? initialFromAccess;

  /// Datos parciales desde preview pública (referido Prep+).
  final PrepItemDetailModel? initialFromPreview;

  /// En web, tras volver de PayPal: quedarse en esta pantalla esperando captura.
  final bool resumePendingWebCheckout;

  /// El usuario canceló el pago en PayPal y volvió a esta pantalla.
  final bool pendingWebPayPalCancelled;

  /// OrderId de PayPal (token de retorno) para confirmar el cobro en web.
  final String? pendingWebPayPalOrderId;

  @override
  State<PrepPlusItemDetailPage> createState() => _PrepPlusItemDetailPageState();
}

class _PrepPlusItemDetailPageState extends State<PrepPlusItemDetailPage> {
  static const _bestValueDurationDays = 183;
  static const _webPayPalCaptureRetryDelays = [
    Duration.zero,
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  final _repository = getIt<PrepPlusRepository>();
  final _referralStore = getIt<PendingPrepReferralStore>();
  final _orchestrator = getIt<PurchaseOrchestrator>();
  final _preferencesRepository = getIt<PracticePreferencesRepository>();
  final _soundPreferenceStore = getIt<PracticeSoundPreferenceStore>();
  PrepItemDetailModel? _item;
  String? _selectedOfferId;
  bool _loading = true;
  bool _loadingPreferences = false;
  bool _checkingOut = false;
  bool _refreshingAccessAfterCheckout = false;
  bool _downloadingOffline = false;
  bool _isOfflineDownloaded = false;
  String? _planCode;
  bool _randomizeQuestions = false;
  bool _showTimer = true;
  bool _enableSoundEffects = PracticeLaunchOptions.defaults.enableSoundEffects;
  String? _error;
  String? _pendingPayPalOrderId;
  Future<PracticeActiveSessionModel?>? _activeSessionPrefetch;
  List<ProductDetails> _storeProducts = [];
  bool _storeAvailable = false;
  bool _sharing = false;

  bool get _isCheckoutBusy => _checkingOut || _orchestrator.isBusy;

  bool get _showPrepAccessProcessingOverlay =>
      _isCheckoutBusy || _refreshingAccessAfterCheckout;

  bool get _shouldResumeWebPayPal =>
      kIsWeb && widget.resumePendingWebCheckout;

  static bool get _supportsStorePurchase =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _orchestrator.addListener(_onOrchestratorChanged);
    if (_shouldResumeWebPayPal && !widget.pendingWebPayPalCancelled) {
      _checkingOut = true;
    }
    final initial = widget.initialFromAccess;
    final previewInitial = widget.initialFromPreview;
    if (initial != null) {
      _item = PrepItemDetailModel.fromAccessItem(initial);
      _loading = false;
      if (initial.canPractice) {
        _warmPracticeLaunch(initial.quizId);
        unawaited(_loadPracticePreferences(initial.quizId));
        unawaited(_loadSoundPreferences());
      }
      if (!_shouldResumeWebPayPal) {
        unawaited(_load());
      }
    } else if (previewInitial != null) {
      _item = previewInitial;
      _loading = false;
      if (!_shouldResumeWebPayPal) {
        unawaited(_load());
      }
    } else if (!_shouldResumeWebPayPal) {
      unawaited(_load(fullScreenLoading: true));
    }
    unawaited(_loadBillingPlan());
    if (_shouldResumeWebPayPal) {
      unawaited(_completePendingWebPayPalReturn());
    }
  }

  Future<void> _loadBillingPlan() async {
    try {
      final billing = await getIt<BillingRepository>().getMyBilling();
      if (!mounted) return;
      setState(() => _planCode = billing.plan.code);
    } catch (_) {}
  }

  Future<void> _downloadForOffline(String quizId) async {
    if (!OfflinePlatformSupport.isSupported) {
      AppSnackBars.showError(OfflinePlatformSupport.unsupportedMessage);
      return;
    }
    if (!BillingPlanAccess.canDownloadOffline(_planCode)) {
      return;
    }
    if (_downloadingOffline) return;
    setState(() => _downloadingOffline = true);
    try {
      await getIt<OfflinePackageRepository>().downloadAndPersist(quizId: quizId);
      if (!mounted) return;
      setState(() => _isOfflineDownloaded = true);
      AppSnackBars.showSuccess('Cuestionario listo para practicar sin conexión.');
    } catch (error) {
      if (!mounted) return;
      AppSnackBars.showError(error.toString());
    } finally {
      if (mounted) setState(() => _downloadingOffline = false);
    }
  }

  Future<void> _refreshOfflineDownloadState(String quizId) async {
    try {
      final downloaded =
          await getIt<OfflinePackageRepository>().isQuizDownloaded(quizId);
      if (!mounted) return;
      setState(() => _isOfflineDownloaded = downloaded);
    } catch (_) {}
  }

  Future<void> _practiceOffline(String quizId, String title) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => OfflinePracticeSessionCubit(
            packageRepository: getIt<OfflinePackageRepository>(),
            syncRepository: getIt<OfflineSyncRepository>(),
            checkpointRepository: getIt<OfflineSessionCheckpointRepository>(),
            accessReconciler: getIt<OfflinePrepAccessReconciler>(),
            quizId: quizId,
            showElapsedTimer: _showTimer,
            randomizeQuestions: _randomizeQuestions,
          )..load(),
          child: OfflinePracticeSessionPage(quizTitle: title),
        ),
      ),
    );
    await _refreshOfflineDownloadState(quizId);
  }

  Future<void> _confirmRemoveOfflineDownload(String quizId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.offlineDownloadsDeleteAction),
        content: Text(l10n.offlineDownloadsRemoveDialogMessageShort),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.offlineDownloadsRemoveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await getIt<OfflinePackageRepository>().deleteDownloadedQuiz(quizId);
    if (!mounted) return;
    setState(() => _isOfflineDownloaded = false);
    AppSnackBars.showSuccess(l10n.offlineDownloadsRemovedMessage);
  }

  @override
  void dispose() {
    _orchestrator.removeListener(_onOrchestratorChanged);
    super.dispose();
  }

  void _onOrchestratorChanged() {
    if (!mounted) {
      return;
    }
    final state = _orchestrator.state;
    if (state is PurchaseDeferred) {
      showStorePurchaseDeferred(context);
    } else if (state is PurchaseFailed) {
      showStorePurchaseFailure(context, state);
      _orchestrator.resetToIdle();
    } else if (state is PurchaseSucceeded && state.result is PrepPlusPurchaseResult) {
      // Compras en segundo plano (p. ej. al reanudar la app). Las iniciadas
      // desde esta pantalla las cierra _buyWithStore / _confirmPayPalCapture.
      if (!_isCheckoutBusy && !_checkingOut) {
        unawaited(_load(forceRefresh: true));
      }
    }
    setState(() {});
  }

  Future<void> _refreshAfterPrepCheckout({
    bool showSuccessMessage = false,
    AppLocalizations? l10n,
  }) async {
    if (!mounted || _refreshingAccessAfterCheckout) {
      return;
    }

    setState(() => _refreshingAccessAfterCheckout = true);
    try {
      await _clearReferralIfMatched();
      await _load(forceRefresh: true);
      unawaited(_repository.getMyAccesses(forceRefresh: true));
      getIt<CheckoutRefreshNotifier>().notifyCheckoutCompleted(
        affectsHomeTab: false,
      );
      consumeWebPayPalReturn();
      clearWebEntryDeepLinkUrl();
      if (!mounted || !showSuccessMessage) {
        return;
      }
      context.showSuccessSnackBar(
        (l10n ?? AppLocalizations.of(context)!).prepPlusAccessGranted,
      );
    } finally {
      if (mounted) {
        setState(() => _refreshingAccessAfterCheckout = false);
      }
    }
  }

  Future<void> _load({
    bool fullScreenLoading = false,
    bool forceRefresh = false,
  }) async {
    final hadItem = _item != null;
    if (fullScreenLoading || !hadItem) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final item = await _repository.getItem(
        widget.catalogItemId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _item = item;
        _selectedOfferId ??= _defaultOfferId(item.offers);
        _loading = false;
      });
      if (_supportsStorePurchase) {
        unawaited(_prefetchStoreProducts(item.offers));
      }
      if (item.canPractice) {
        _warmPracticeLaunch(item.quizId);
        unawaited(_refreshOfflineDownloadState(item.quizId));
        if (!hadItem) {
          unawaited(_loadPracticePreferences(item.quizId));
          unawaited(_loadSoundPreferences());
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (hadItem) {
        // Vista parcial (referido/acceso): no alarmar si el refresh en background falla.
        return;
      }
      setState(() {
        _error = _repository.mapError(e, l10n);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (hadItem) {
        return;
      }
      setState(() {
        _error = DioErrorMapper.genericMessage(AppLocalizations.of(context)!);
        _loading = false;
      });
    }
  }

  String? _defaultOfferId(List<PrepAccessOfferModel> offers) {
    if (offers.isEmpty) return null;
    PrepAccessOfferModel? pickPreferred(Iterable<PrepAccessOfferModel> candidates) {
      for (final o in candidates) {
        if (o.isLifetimeAccess) return o;
      }
      for (final o in candidates) {
        if (o.durationDays == _bestValueDurationDays) return o;
      }
      PrepAccessOfferModel longest = candidates.first;
      for (final o in candidates.skip(1)) {
        if (o.durationDays > longest.durationDays) longest = o;
      }
      return longest;
    }

    if (_supportsStorePurchase) {
      final storeOffers = offers
          .where(
            (o) =>
                !o.isFree &&
                o.nativeStoreProductId(
                      isIos: defaultTargetPlatform == TargetPlatform.iOS,
                    ) !=
                    null,
          )
          .toList();
      final fromStore = pickPreferred(storeOffers);
      if (fromStore != null) {
        return fromStore.offerId;
      }
    }

    return pickPreferred(offers)?.offerId;
  }

  Future<void> _prefetchStoreProducts(List<PrepAccessOfferModel> offers) async {
    if (!_supportsStorePurchase) return;

    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final ids = <String>{};
    for (final offer in offers) {
      if (offer.isFree) continue;
      final id = offer.nativeStoreProductId(isIos: isIos);
      if (id != null && id.isNotEmpty) {
        ids.add(id);
      }
    }

    final available = ids.isNotEmpty && await isMobileStoreAvailable();
    var products = <ProductDetails>[];
    if (available) {
      await _orchestrator.refreshStoreCatalog();
      final response = await queryMobileStoreProducts(ids);
      products = response.productDetails;
    }

    if (!mounted) return;
    setState(() {
      _storeAvailable = available;
      _storeProducts = products;
    });
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

  bool _pendingReferralMatchesItem(PendingPrepReferral pending) {
    if (pending.catalogItemId != null &&
        pending.catalogItemId == widget.catalogItemId) {
      return true;
    }

    final itemSlug = _item?.slug;
    if (itemSlug == null || itemSlug.isEmpty) {
      return false;
    }

    return itemSlug.toLowerCase() == pending.slug.toLowerCase();
  }

  Future<String?> _referralCodeForPurchase() async {
    final pending = await _referralStore.read();
    if (pending == null || pending.referralCode == null) {
      return null;
    }

    if (!_pendingReferralMatchesItem(pending)) {
      return null;
    }

    if (!pending.rewardEligible) {
      return null;
    }

    return pending.referralCode;
  }

  Future<void> _clearReferralIfMatched() async {
    final pending = await _referralStore.read();
    if (pending == null) {
      return;
    }

    if (_pendingReferralMatchesItem(pending)) {
      await _referralStore.clear();
    }
  }

  Future<void> _shareItem(BuildContext shareContext) async {
    if (_sharing) return;

    // Capturar el origen del popover en el tap (antes del await/setState).
    final shareOrigin = ShareTextHelper.shareOriginFromContext(shareContext);

    final l10n = AppLocalizations.of(context)!;
    final title = _item?.title ?? l10n.prepPlusItemDetailTitle;

    setState(() => _sharing = true);
    try {
      final referral =
          await _repository.getOrCreateReferralCode(widget.catalogItemId);
      if (!mounted) return;

      if (referral.shareUrl.trim().isEmpty) {
        context.showErrorSnackBar(l10n.genericRequestErrorMessage);
        return;
      }

      final message = l10n.prepPlusShareLinkMessage(title, referral.shareUrl);
      final outcome = await ShareTextHelper.shareText(
        message,
        sharePositionOrigin: shareOrigin,
      );
      if (!mounted) return;

      if (outcome == ShareTextOutcome.copied) {
        context.showSuccessSnackBar(l10n.shareCodeLinkCopied);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_repository.mapError(e, l10n));
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(l10n.genericRequestErrorMessage);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
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
        setState(() => _pendingPayPalOrderId = null);
        await _refreshAfterPrepCheckout(showSuccessMessage: true, l10n: l10n);
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
    final storeProductId = _supportsStorePurchase
        ? offer.nativeStoreProductId(
            isIos: defaultTargetPlatform == TargetPlatform.iOS,
          )
        : null;

    if (_supportsStorePurchase &&
        storeProductId != null &&
        storeProductId.isNotEmpty) {
      await _buyWithStore(offer, storeProductId);
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
    var redirectedToPayPal = false;
    setState(() => _checkingOut = true);
    try {
      final referralCode = await _referralCodeForPurchase();
      final order = await _repository.createPayPalOrder(
        catalogItemId: widget.catalogItemId,
        offerId: offer.offerId,
        referralCode: referralCode,
      );
      if (!mounted) return;

      if (order.mockMode) {
        await _repository.capturePayPalOrder(order.orderId);
        if (!mounted) return;
        setState(() => _pendingPayPalOrderId = null);
        await _refreshAfterPrepCheckout(showSuccessMessage: true, l10n: l10n);
        return;
      }

      if (!kIsWeb) {
        setState(() => _pendingPayPalOrderId = order.orderId);
      }

      if (order.approvalUrl != null && order.approvalUrl!.isNotEmpty) {
        final uri = Uri.parse(order.approvalUrl!);
        await getIt<PendingPayPalPaymentStore>().save(
          PendingPayPalPayment(
            flow: PendingPayPalPaymentFlow.prep,
            id: order.orderId,
            createdAt: DateTime.now().toUtc(),
            catalogItemId: widget.catalogItemId,
            offerId: offer.offerId,
          ),
        );
        final launched = await openPayPalApprovalUrl(context, uri, l10n: l10n);
        if (!mounted) return;
        if (launched && kIsWeb) {
          redirectedToPayPal = true;
        } else if (launched && !kIsWeb) {
          context.showInfoSnackBar(l10n.paypalAwaitingCapture);
        }
      } else if (!order.mockMode) {
        context.showErrorSnackBar(l10n.paypalReturnError);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted && !redirectedToPayPal) {
        setState(() => _checkingOut = false);
      }
    }
  }

  Future<void> _completePendingWebPayPalReturn() async {
    if (!_shouldResumeWebPayPal) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    if (widget.pendingWebPayPalCancelled) {
      await getIt<PendingPayPalPaymentStore>().clear();
      consumeWebPayPalReturn();
      clearWebEntryDeepLinkUrl();
      if (!mounted) return;
      context.showInfoSnackBar(l10n.paypalReturnCancelled);
      await _load(fullScreenLoading: _item == null);
      if (mounted) {
        setState(() => _checkingOut = false);
      }
      return;
    }

    if (!_checkingOut && mounted) {
      setState(() => _checkingOut = true);
    }

    try {
      final pending = await getIt<PendingPayPalPaymentStore>().read();
      final orderId = widget.pendingWebPayPalOrderId ?? pending?.id;
      if (orderId == null || orderId.isEmpty) {
        if (!mounted) return;
        context.showErrorSnackBar(l10n.paypalReturnError);
        await _load(fullScreenLoading: _item == null);
        return;
      }

      final granted = await _capturePrepPayPalOrderWithRetries(orderId);
      if (!mounted) return;
      if (granted) {
        setState(() => _pendingPayPalOrderId = null);
        await _refreshAfterPrepCheckout(showSuccessMessage: true, l10n: l10n);
      } else {
        context.showErrorSnackBar(l10n.paypalReturnError);
        await _load(fullScreenLoading: _item == null);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
      await _load(fullScreenLoading: _item == null);
    } catch (_) {
      if (!mounted) return;
      context.showErrorSnackBar(l10n.paypalReturnError);
      await _load(fullScreenLoading: _item == null);
    } finally {
      if (mounted) {
        setState(() => _checkingOut = false);
      }
    }
  }

  Future<bool> _capturePrepPayPalOrderWithRetries(String orderId) async {
    Object? lastError;
    for (var i = 0; i < _webPayPalCaptureRetryDelays.length; i++) {
      final delay = _webPayPalCaptureRetryDelays[i];
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      try {
        final result = await _repository.capturePayPalOrder(orderId);
        if (result.status == 'granted') {
          await getIt<PendingPayPalPaymentStore>().clear();
          return true;
        }
        lastError = result.message;
      } on DioException catch (e) {
        lastError = e;
        if (_isPayPalAlreadyGranted(e)) {
          await getIt<PendingPayPalPaymentStore>().clear();
          return true;
        }
        final canRetry = i < _webPayPalCaptureRetryDelays.length - 1 &&
            _isRetryablePrepCapture(e);
        if (!canRetry) {
          rethrow;
        }
      }
    }
    if (kDebugMode && lastError != null) {
      debugPrint('[Prep+] web PayPal capture did not grant: $lastError');
    }
    return false;
  }

  bool _isPayPalAlreadyGranted(DioException error) {
    final data = error.response?.data;
    final code = data is Map<String, dynamic>
        ? data['code']?.toString().toLowerCase() ?? ''
        : '';
    if (code.contains('already') || code.contains('validated')) {
      return true;
    }
    return error.response?.statusCode == 200;
  }

  bool _isRetryablePrepCapture(DioException error) {
    final status = error.response?.statusCode;
    if (status == null) {
      return true;
    }
    if (status >= 500 || status == 409) {
      return true;
    }
    final data = error.response?.data;
    final code = data is Map<String, dynamic>
        ? data['code']?.toString().toUpperCase() ?? ''
        : '';
    return code.contains('NOT_APPROVED') || code.contains('NOT_CAPTUREABLE');
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
        setState(() => _pendingPayPalOrderId = null);
        await _refreshAfterPrepCheckout(showSuccessMessage: true, l10n: l10n);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      context.showDioErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<void> _buyWithStore(
    PrepAccessOfferModel offer,
    String productId,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (!_storeAvailable) {
      final available = await isMobileStoreAvailable();
      if (!available) {
        if (!mounted) return;
        context.showErrorSnackBar(l10n.storeProductNotConfigured);
        return;
      }
      if (mounted) {
        setState(() => _storeAvailable = true);
      }
    }

    var product = pickStoreProduct(_storeProducts, productId);
    product ??= await findMobileStoreProduct(
      productId,
      cachedProducts: _storeProducts,
    );
    if (product == null) {
      if (!mounted) return;
      context.showErrorSnackBar(l10n.storeProductNotFound(productId));
      return;
    }

    final referralCode = await _referralCodeForPurchase();
    final result = await _orchestrator.buy(
      StorePurchaseRequest(
        kind: PurchaseProductKind.prepPlus,
        productId: product.id,
        product: product,
        catalogItemId: widget.catalogItemId,
        offerId: offer.offerId,
        referralCode: referralCode,
      ),
    );

    if (!mounted) return;
    _orchestrator.resetToIdle();

    if (result is PrepPlusPurchaseResult) {
      await _refreshAfterPrepCheckout(showSuccessMessage: true, l10n: l10n);
    }
  }

  Future<void> _openAccessOptionsSheet() async {
    final item = _item;
    if (item == null || item.offers.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    var sheetSelectedOfferId =
        _selectedOfferId ?? _defaultOfferId(item.offers);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppColors.radiusMd),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            PrepAccessOfferModel? sheetOffer;
            for (final o in item.offers) {
              if (o.offerId == sheetSelectedOfferId) {
                sheetOffer = o;
                break;
              }
            }

            final confirmLabel = item.canPractice
                ? l10n.prepPlusExtendAccessAction
                : item.userAccessState == 'expired'
                    ? l10n.prepPlusRenewAction
                    : (sheetOffer?.isFree ?? false)
                        ? l10n.prepPlusGetFreeAccessAction
                        : l10n.prepPlusBuyAction;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
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
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        children: [
                          for (final offer in item.offers)
                            PrepPlusAccessComboCard(
                              offer: offer,
                              selected: sheetSelectedOfferId == offer.offerId,
                              onTap: () => setSheetState(
                                () => sheetSelectedOfferId = offer.offerId,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: AppPrimaryButton(
                        label: confirmLabel,
                        isLoading: _isCheckoutBusy,
                        onPressed: _isCheckoutBusy || sheetOffer == null
                            ? null
                            : () async {
                                final offer = sheetOffer!;
                                setState(
                                  () => _selectedOfferId = offer.offerId,
                                );
                                Navigator.of(sheetContext).pop();
                                if (offer.isFree) {
                                  await _checkoutFree();
                                } else {
                                  await _buyPaid(offer);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString())
          .format(dt.toLocal());

  bool _showExtendAccessLink(PrepItemDetailModel item) =>
      item.canPractice &&
      !item.isLifetimeAccess &&
      item.userAccessState != 'owned' &&
      item.offers.isNotEmpty;

  bool _showPurchaseBottomBar(PrepItemDetailModel item) {
    if (item.canPractice) return false;
    if (item.isLifetimeAccess || item.userAccessState == 'owned') return false;
    if (item.offers.isEmpty) return false;
    return item.canPurchase || item.userAccessState == 'expired';
  }

  String _purchaseActionLabel(AppLocalizations l10n, PrepItemDetailModel item) {
    if (item.userAccessState == 'expired') {
      return l10n.prepPlusRenewAction;
    }
    if (item.offers.any((o) => o.isFree)) {
      return l10n.prepPlusGetFreeAccessAction;
    }
    return l10n.prepPlusBuyAction;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        EdgeAwareScaffold(
      appBar: craftQuestAppBar(
        title: _item?.title ?? l10n.prepPlusItemDetailTitle,
        actions: _item == null
            ? null
            : [
                Builder(
                  builder: (shareContext) => IconButton(
                    icon: _sharing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_outlined),
                    tooltip: l10n.prepPlusShareAction,
                    onPressed:
                        _sharing ? null : () => _shareItem(shareContext),
                  ),
                ),
              ],
      ),
      bottomBar: _buildBottomBar(l10n),
      body: _loading
          ? const AppLoadingView()
          : _error != null
              ? AppErrorView(
                  message: _error!,
                  retryLabel: l10n.retry,
                  onRetry: () => _load(fullScreenLoading: true),
                )
              : _item == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: AppSpacing.listBottom,
                      children: [
                        PrepPlusItemHero(
                          categoryName: _item!.categoryName,
                          questionCount: _item!.questionCount,
                          description: _item!.description,
                          tags: _item!.tags,
                          userAccessState: _item!.userAccessState,
                          canPractice: _item!.canPractice,
                          isLifetimeAccess: _item!.isLifetimeAccess,
                          accessExpiresAt: _item!.accessExpiresAt,
                          formatDate: _formatDate,
                          onCountdownTap: _openAccessOptionsSheet,
                        ),
                        if (_showExtendAccessLink(_item!))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.sm,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _openAccessOptionsSheet,
                                child: Text(l10n.prepPlusExtendAccessAction),
                              ),
                            ),
                          ),
                        if (!_item!.canPractice) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: PrepPlusSimulationTile(
                              onTap: _openPreview,
                            ),
                          ),
                        ],
                        if (_item!.canPractice) ...[
                          const SizedBox(height: AppSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: PrepPlusPracticeOptionsPanel(
                              isLoading: _loadingPreferences,
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
                          if (_item!.canPractice)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                0,
                              ),
                              child: OfflineQuizActionsPanel(
                                isDownloaded: _isOfflineDownloaded,
                                isDownloading: _downloadingOffline,
                                canDownloadOffline: BillingPlanAccess
                                    .canDownloadOffline(_planCode),
                                isPlatformSupported:
                                    OfflinePlatformSupport.isSupported,
                                onDownload: () =>
                                    _downloadForOffline(_item!.quizId),
                                onPracticeOffline: () => _practiceOffline(
                                  _item!.quizId,
                                  _item!.title,
                                ),
                                onRemoveDownload: () =>
                                    _confirmRemoveOfflineDownload(
                                  _item!.quizId,
                                ),
                                onUpgradePrompt: () {},
                              ),
                            ),
                        ],
                        if (!_item!.canPurchase &&
                            _item!.userAccessState == 'none')
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              l10n.prepPlusNotAvailableForPurchase,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        if (_pendingPayPalOrderId != null && !kIsWeb)
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
                                    isLoading: _isCheckoutBusy,
                                    onPressed: _isCheckoutBusy
                                        ? null
                                        : _confirmPayPalCapture,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_item!.userAccessState != 'none') ...[
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _CompactProgressAction(
                                    icon: Icons.analytics_outlined,
                                    label: l10n.prepPlusProgressAnalyticsShort,
                                    color: AppColors.accentCool,
                                    onTap: () => _viewAnalytics(
                                      _item!.quizId,
                                      _item!.title,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _CompactProgressAction(
                                    icon: Icons.history_rounded,
                                    label: l10n.prepPlusProgressHistoryShort,
                                    color: AppColors.accentSky,
                                    onTap: () => _viewAttempts(
                                      _item!.quizId,
                                      _item!.title,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
        if (_showPrepAccessProcessingOverlay)
          PrepPlusCheckoutProcessingOverlay(
            message: l10n.prepPlusConfirmingAccess,
          ),
      ],
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

    if (_showPurchaseBottomBar(item)) {
      return AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: _purchaseActionLabel(l10n, item),
            isLoading: _isCheckoutBusy,
            onPressed: _isCheckoutBusy ? null : _openAccessOptionsSheet,
          ),
        ],
      );
    }

    return null;
  }
}

class _CompactProgressAction extends StatelessWidget {
  const _CompactProgressAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        side: BorderSide(
          color: AppColors.inputBorder.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
