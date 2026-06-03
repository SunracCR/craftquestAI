class UserBillingModel {
  const UserBillingModel({
    required this.plan,
    required this.subscription,
    required this.usage,
    required this.entitlements,
    required this.credits,
  });

  factory UserBillingModel.fromJson(Map<String, dynamic> json) {
    return UserBillingModel(
      plan: PlanModel.fromJson(json['plan'] as Map<String, dynamic>),
      subscription: SubscriptionModel.fromJson(
        json['subscription'] as Map<String, dynamic>,
      ),
      usage: BillingUsageModel.fromJson(json['usage'] as Map<String, dynamic>),
      entitlements: PlanEntitlementsModel.fromJson(
        json['entitlements'] as Map<String, dynamic>,
      ),
      credits: CreditBalancesModel.fromJson(
        json['credits'] as Map<String, dynamic>,
      ),
    );
  }

  final PlanModel plan;
  final SubscriptionModel subscription;
  final BillingUsageModel usage;
  final PlanEntitlementsModel entitlements;
  final CreditBalancesModel credits;
}

class SubscriptionModel {
  const SubscriptionModel({
    required this.status,
    required this.startedAt,
    this.endsAt,
    this.billingCycle = 'monthly',
    this.autoRenewEnabled = true,
    this.cancelAtPeriodEnd = false,
    this.lastPaymentAt,
    this.nextBillingAt,
    this.providerCode,
    this.isRecurring = false,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      status: json['status'] as String? ?? 'active',
      startedAt: DateTime.parse(json['startedAt'] as String),
      endsAt: json['endsAt'] != null
          ? DateTime.parse(json['endsAt'] as String)
          : null,
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      autoRenewEnabled: json['autoRenewEnabled'] as bool? ?? true,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
      lastPaymentAt: json['lastPaymentAt'] != null
          ? DateTime.parse(json['lastPaymentAt'] as String)
          : null,
      nextBillingAt: json['nextBillingAt'] != null
          ? DateTime.parse(json['nextBillingAt'] as String)
          : null,
      providerCode: json['providerCode'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
    );
  }

  final String status;
  final DateTime startedAt;
  final DateTime? endsAt;
  final String billingCycle;
  final bool autoRenewEnabled;
  final bool cancelAtPeriodEnd;
  final DateTime? lastPaymentAt;
  final DateTime? nextBillingAt;
  final String? providerCode;
  final bool isRecurring;

  bool get isPaidRecurring =>
      isRecurring && billingCycle.isNotEmpty && status == 'active';

  /// Periodo pagado vigente con renovación desactivada (puede reactivarse).
  bool get canResumeAutoRenew {
    if (!isPaidRecurring || status != 'active') {
      return false;
    }
    if (autoRenewEnabled && !cancelAtPeriodEnd) {
      return false;
    }
    final periodEnd = endsAt ?? nextBillingAt;
    if (periodEnd == null) {
      return false;
    }
    return periodEnd.isAfter(DateTime.now().toUtc());
  }
}

class ReactivateAutoRenewModel {
  const ReactivateAutoRenewModel({
    required this.autoRenewEnabled,
    this.nextRenewalAt,
    this.providerCode,
    this.manageInStore = false,
    this.requiresResubscribe = false,
  });

  factory ReactivateAutoRenewModel.fromJson(Map<String, dynamic> json) {
    return ReactivateAutoRenewModel(
      autoRenewEnabled: json['autoRenewEnabled'] as bool? ?? false,
      nextRenewalAt: json['nextRenewalAt'] != null
          ? DateTime.parse(json['nextRenewalAt'] as String)
          : null,
      providerCode: json['providerCode'] as String?,
      manageInStore: json['manageInStore'] as bool? ?? false,
      requiresResubscribe: json['requiresResubscribe'] as bool? ?? false,
    );
  }

  final bool autoRenewEnabled;
  final DateTime? nextRenewalAt;
  final String? providerCode;
  final bool manageInStore;
  final bool requiresResubscribe;
}

class PlanModel {
  const PlanModel({
    required this.code,
    required this.name,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  final String code;
  final String name;
}

class BillingUsageModel {
  const BillingUsageModel({
    required this.quizzesCreated,
    required this.shareCodesCreatedThisMonth,
  });

  factory BillingUsageModel.fromJson(Map<String, dynamic> json) {
    return BillingUsageModel(
      quizzesCreated: json['quizzesCreated'] as int? ?? 0,
      shareCodesCreatedThisMonth:
          json['shareCodesCreatedThisMonth'] as int? ?? 0,
    );
  }

  final int quizzesCreated;
  final int shareCodesCreatedThisMonth;
}

class PlanEntitlementsModel {
  const PlanEntitlementsModel({
    this.maxQuizzes,
    this.maxQuestionsPerQuiz,
    required this.monthlyAiCredits,
    required this.monthlyShareCodes,
    this.maxRedeemedSharedQuizzes,
    required this.currentRedeemedSharedQuizzes,
    this.canInviteUsersDirectly = false,
  });

  factory PlanEntitlementsModel.fromJson(Map<String, dynamic> json) {
    return PlanEntitlementsModel(
      maxQuizzes: json['maxQuizzes'] as int?,
      maxQuestionsPerQuiz: json['maxQuestionsPerQuiz'] as int?,
      monthlyAiCredits: json['monthlyAiCredits'] as int? ?? 0,
      monthlyShareCodes: json['monthlyShareCodes'] as int? ?? 0,
      maxRedeemedSharedQuizzes: json['maxRedeemedSharedQuizzes'] as int?,
      currentRedeemedSharedQuizzes:
          json['currentRedeemedSharedQuizzes'] as int? ?? 0,
      canInviteUsersDirectly:
          json['canInviteUsersDirectly'] as bool? ?? false,
    );
  }

  final int? maxQuizzes;
  final int? maxQuestionsPerQuiz;
  final int monthlyAiCredits;
  final int monthlyShareCodes;
  final int? maxRedeemedSharedQuizzes;
  final int currentRedeemedSharedQuizzes;
  final bool canInviteUsersDirectly;
}

class CreditBalancesModel {
  const CreditBalancesModel({
    required this.aiCredits,
    required this.shareCodeCredits,
  });

  factory CreditBalancesModel.fromJson(Map<String, dynamic> json) {
    return CreditBalancesModel(
      aiCredits: json['aiCredits'] as int? ?? 0,
      shareCodeCredits: json['shareCodeCredits'] as int? ?? 0,
    );
  }

  final int aiCredits;
  final int shareCodeCredits;
}

class UpgradeablePlanModel {
  const UpgradeablePlanModel({
    required this.code,
    required this.name,
    this.monthlyPrice,
    this.annualPrice,
    this.googlePlayProductId,
    this.googlePlayAnnualProductId,
    this.appStoreProductId,
    this.appStoreAnnualProductId,
    this.requiresContactSales = false,
    this.monthlyAiCredits = 0,
    this.monthlyShareCodes = 0,
  });

  factory UpgradeablePlanModel.fromJson(Map<String, dynamic> json) {
    return UpgradeablePlanModel(
      code: json['code'] as String,
      name: json['name'] as String,
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble(),
      annualPrice: (json['annualPrice'] as num?)?.toDouble(),
      googlePlayProductId: json['googlePlayProductId'] as String?,
      googlePlayAnnualProductId:
          json['googlePlayAnnualProductId'] as String?,
      appStoreProductId: json['appStoreProductId'] as String?,
      appStoreAnnualProductId: json['appStoreAnnualProductId'] as String?,
      requiresContactSales: json['requiresContactSales'] as bool? ?? false,
      monthlyAiCredits: json['monthlyAiCredits'] as int? ?? 0,
      monthlyShareCodes: json['monthlyShareCodes'] as int? ?? 0,
    );
  }

  final String code;
  final String name;
  final double? monthlyPrice;
  final double? annualPrice;
  final String? googlePlayProductId;
  final String? googlePlayAnnualProductId;
  final String? appStoreProductId;
  final String? appStoreAnnualProductId;
  final bool requiresContactSales;
  final int monthlyAiCredits;
  final int monthlyShareCodes;

  String? storeProductId({
    required bool isIos,
    required String billingCycle,
  }) {
    final annual = billingCycle == 'annual';
    if (isIos) {
      return annual
          ? (appStoreAnnualProductId ?? appStoreProductId)
          : appStoreProductId;
    }
    return annual
        ? (googlePlayAnnualProductId ?? googlePlayProductId)
        : googlePlayProductId;
  }

  bool get isInstitutionPlan =>
      requiresContactSales || code.toLowerCase() == 'institution';
}

class PayPalOrderModel {
  const PayPalOrderModel({
    required this.purchaseId,
    required this.orderId,
    this.approvalUrl,
    required this.mockMode,
  });

  factory PayPalOrderModel.fromJson(Map<String, dynamic> json) {
    return PayPalOrderModel(
      purchaseId: json['purchaseId'].toString(),
      orderId: json['orderId'] as String,
      approvalUrl: json['approvalUrl'] as String?,
      mockMode: json['mockMode'] as bool? ?? false,
    );
  }

  final String purchaseId;
  final String orderId;
  final String? approvalUrl;
  final bool mockMode;
}

class PayPalSubscriptionModel {
  const PayPalSubscriptionModel({
    required this.purchaseId,
    required this.subscriptionId,
    this.approvalUrl,
    required this.mockMode,
  });

  factory PayPalSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return PayPalSubscriptionModel(
      purchaseId: json['purchaseId'].toString(),
      subscriptionId: json['subscriptionId'] as String,
      approvalUrl: json['approvalUrl'] as String?,
      mockMode: json['mockMode'] as bool? ?? false,
    );
  }

  final String purchaseId;
  final String subscriptionId;
  final String? approvalUrl;
  final bool mockMode;
}

class PayPalSubscriptionActivationModel {
  const PayPalSubscriptionActivationModel({
    required this.planCode,
    required this.status,
    this.currentPeriodEnd,
    required this.autoRenewEnabled,
    required this.mockMode,
  });

  factory PayPalSubscriptionActivationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PayPalSubscriptionActivationModel(
      planCode: json['planCode'] as String,
      status: json['status'] as String,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'] as String)
          : null,
      autoRenewEnabled: json['autoRenewEnabled'] as bool? ?? true,
      mockMode: json['mockMode'] as bool? ?? false,
    );
  }

  final String planCode;
  final String status;
  final DateTime? currentPeriodEnd;
  final bool autoRenewEnabled;
  final bool mockMode;
}

class CancelAutoRenewModel {
  const CancelAutoRenewModel({
    required this.accessUntil,
    required this.autoRenewEnabled,
    this.providerCode,
    this.manageInStore = false,
  });

  factory CancelAutoRenewModel.fromJson(Map<String, dynamic> json) {
    return CancelAutoRenewModel(
      accessUntil: DateTime.parse(json['accessUntil'] as String),
      autoRenewEnabled: json['autoRenewEnabled'] as bool? ?? false,
      providerCode: json['providerCode'] as String?,
      manageInStore: json['manageInStore'] as bool? ?? false,
    );
  }

  final DateTime accessUntil;
  final bool autoRenewEnabled;
  final String? providerCode;
  final bool manageInStore;
}

class AiCreditPackModel {
  const AiCreditPackModel({
    required this.code,
    required this.name,
    required this.credits,
    required this.price,
    required this.currencyCode,
    this.googlePlayProductId,
    this.appStoreProductId,
  });

  factory AiCreditPackModel.fromJson(Map<String, dynamic> json) {
    return AiCreditPackModel(
      code: json['code'] as String,
      name: json['name'] as String,
      credits: json['credits'] as int,
      price: (json['price'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      googlePlayProductId: json['googlePlayProductId'] as String?,
      appStoreProductId: json['appStoreProductId'] as String?,
    );
  }

  final String code;
  final String name;
  final int credits;
  final double price;
  final String currencyCode;
  final String? googlePlayProductId;
  final String? appStoreProductId;

  String? storeProductId({required bool isIos}) =>
      isIos ? appStoreProductId : googlePlayProductId;
}

class PayPalAiCreditCaptureModel {
  const PayPalAiCreditCaptureModel({
    required this.packCode,
    required this.creditsGranted,
    required this.aiCreditsBalance,
    required this.status,
    this.mockMode = false,
  });

  factory PayPalAiCreditCaptureModel.fromJson(Map<String, dynamic> json) {
    return PayPalAiCreditCaptureModel(
      packCode: json['packCode'] as String,
      creditsGranted: json['creditsGranted'] as int,
      aiCreditsBalance: json['aiCreditsBalance'] as int,
      status: json['status'] as String,
      mockMode: json['mockMode'] as bool? ?? false,
    );
  }

  final String packCode;
  final int creditsGranted;
  final int aiCreditsBalance;
  final String status;
  final bool mockMode;
}

class PayPalCaptureModel {
  const PayPalCaptureModel({
    required this.planCode,
    required this.status,
  });

  factory PayPalCaptureModel.fromJson(Map<String, dynamic> json) {
    return PayPalCaptureModel(
      planCode: json['planCode'] as String,
      status: json['status'] as String,
    );
  }

  final String planCode;
  final String status;
}

class PurchaseHistoryItemModel {
  const PurchaseHistoryItemModel({
    required this.purchaseId,
    required this.productCode,
    this.productDisplayName,
    required this.productType,
    required this.providerCode,
    this.amount,
    this.currencyCode,
    required this.status,
    this.purchasedAt,
    required this.createdAt,
  });

  factory PurchaseHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseHistoryItemModel(
      purchaseId: json['purchaseId'].toString(),
      productCode: json['productCode'] as String? ?? '',
      productDisplayName: json['productDisplayName'] as String?,
      productType: json['productType'] as String? ?? '',
      providerCode: json['providerCode'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] as String?,
      status: json['status'] as String? ?? 'pending',
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.parse(json['purchasedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String purchaseId;
  final String productCode;
  final String? productDisplayName;
  final String productType;
  final String providerCode;
  final double? amount;
  final String? currencyCode;
  final String status;
  final DateTime? purchasedAt;
  final DateTime createdAt;

  DateTime get occurredAt => purchasedAt ?? createdAt;

  String get title =>
      productDisplayName?.trim().isNotEmpty == true
          ? productDisplayName!.trim()
          : productCode;
}

class VerifyPurchaseModel {
  const VerifyPurchaseModel({
    required this.planCode,
    required this.status,
    this.billingCycle = 'monthly',
    this.currentPeriodEnd,
    this.autoRenewEnabled = true,
  });

  factory VerifyPurchaseModel.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseModel(
      planCode: json['planCode'] as String,
      status: json['status'] as String,
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'] as String)
          : null,
      autoRenewEnabled: json['autoRenewEnabled'] as bool? ?? true,
    );
  }

  final String planCode;
  final String status;
  final String billingCycle;
  final DateTime? currentPeriodEnd;
  final bool autoRenewEnabled;
}
