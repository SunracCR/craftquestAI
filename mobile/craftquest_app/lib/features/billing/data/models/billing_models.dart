class UserBillingModel {
  const UserBillingModel({
    required this.plan,
    required this.usage,
    required this.entitlements,
    required this.credits,
  });

  factory UserBillingModel.fromJson(Map<String, dynamic> json) {
    return UserBillingModel(
      plan: PlanModel.fromJson(json['plan'] as Map<String, dynamic>),
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
  final BillingUsageModel usage;
  final PlanEntitlementsModel entitlements;
  final CreditBalancesModel credits;
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
    required this.monthlyShareCodes,
    this.maxRedeemedSharedQuizzes,
    required this.currentRedeemedSharedQuizzes,
    this.canInviteUsersDirectly = false,
  });

  factory PlanEntitlementsModel.fromJson(Map<String, dynamic> json) {
    return PlanEntitlementsModel(
      maxQuizzes: json['maxQuizzes'] as int?,
      maxQuestionsPerQuiz: json['maxQuestionsPerQuiz'] as int?,
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
    this.googlePlayProductId,
    this.appStoreProductId,
  });

  factory UpgradeablePlanModel.fromJson(Map<String, dynamic> json) {
    return UpgradeablePlanModel(
      code: json['code'] as String,
      name: json['name'] as String,
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble(),
      googlePlayProductId: json['googlePlayProductId'] as String?,
      appStoreProductId: json['appStoreProductId'] as String?,
    );
  }

  final String code;
  final String name;
  final double? monthlyPrice;
  final String? googlePlayProductId;
  final String? appStoreProductId;
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

class VerifyPurchaseModel {
  const VerifyPurchaseModel({
    required this.planCode,
    required this.status,
  });

  factory VerifyPurchaseModel.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseModel(
      planCode: json['planCode'] as String,
      status: json['status'] as String,
    );
  }

  final String planCode;
  final String status;
}
