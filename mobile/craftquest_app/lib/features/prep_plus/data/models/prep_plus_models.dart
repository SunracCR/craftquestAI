import 'package:craftquest_app/features/teacher/data/models/teacher_review_models.dart';

class PrepCategoryModel {
  const PrepCategoryModel({
    required this.categoryId,
    this.parentCategoryId,
    required this.categoryType,
    required this.slug,
    required this.name,
    this.description,
    this.countryCode,
    this.iconKey,
    required this.publishedItemCount,
    this.children = const [],
  });

  factory PrepCategoryModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return PrepCategoryModel(
      categoryId: json['categoryId'] as String,
      parentCategoryId: json['parentCategoryId'] as String?,
      categoryType: json['categoryType'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      countryCode: json['countryCode'] as String?,
      iconKey: json['iconKey'] as String?,
      publishedItemCount: json['publishedItemCount'] as int? ?? 0,
      children: childrenJson
          .map((e) => PrepCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String categoryId;
  final String? parentCategoryId;
  final String categoryType;
  final String slug;
  final String name;
  final String? description;
  final String? countryCode;
  final String? iconKey;
  final int publishedItemCount;
  final List<PrepCategoryModel> children;

  bool get isGeographic => categoryType == 'geographic';
  bool get isThematic => categoryType == 'thematic';
}

class PrepBrowseItemModel {
  const PrepBrowseItemModel({
    required this.catalogItemId,
    required this.quizId,
    this.slug,
    required this.title,
    this.description,
    required this.questionCount,
    this.tags = const [],
    this.institutionTag,
    required this.hasFreeOffer,
    this.lowestPaidPrice,
    this.currencyCode,
    required this.userAccessState,
    this.accessExpiresAt,
    required this.canPurchase,
  });

  factory PrepBrowseItemModel.fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tags'] as List<dynamic>? ?? [];
    return PrepBrowseItemModel(
      catalogItemId: json['catalogItemId'] as String,
      quizId: json['quizId'] as String,
      slug: json['slug'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      questionCount: json['questionCount'] as int? ?? 0,
      tags: tagsJson.map((e) => e as String).toList(),
      institutionTag: json['institutionTag'] as String?,
      hasFreeOffer: json['hasFreeOffer'] as bool? ?? false,
      lowestPaidPrice: (json['lowestPaidPrice'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] as String?,
      userAccessState: json['userAccessState'] as String? ?? 'none',
      accessExpiresAt: json['accessExpiresAt'] != null
          ? DateTime.parse(json['accessExpiresAt'] as String)
          : null,
      canPurchase: json['canPurchase'] as bool? ?? false,
    );
  }

  final String catalogItemId;
  final String quizId;
  final String? slug;
  final String title;
  final String? description;
  final int questionCount;
  final List<String> tags;
  final String? institutionTag;
  final bool hasFreeOffer;
  final double? lowestPaidPrice;
  final String? currencyCode;
  final String userAccessState;
  final DateTime? accessExpiresAt;
  final bool canPurchase;
}

class PrepAccessOfferModel {
  const PrepAccessOfferModel({
    required this.offerId,
    required this.durationDays,
    required this.priceAmount,
    required this.currencyCode,
    required this.isFree,
    required this.isActive,
    this.storeProductId,
  });

  factory PrepAccessOfferModel.fromJson(Map<String, dynamic> json) {
    return PrepAccessOfferModel(
      offerId: json['offerId'] as String,
      durationDays: json['durationDays'] as int,
      priceAmount: (json['priceAmount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      isFree: json['isFree'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      storeProductId: json['storeProductId'] as String?,
    );
  }

  final String offerId;
  final int durationDays;
  final double priceAmount;
  final String currencyCode;
  final bool isFree;
  final bool isActive;
  final String? storeProductId;
}

class PrepItemDetailModel {
  const PrepItemDetailModel({
    required this.catalogItemId,
    required this.quizId,
    this.slug,
    required this.title,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.rootCategoryType,
    this.tags = const [],
    this.institutionTag,
    required this.questionCount,
    required this.canPurchase,
    this.listingEndsAt,
    required this.userAccessState,
    this.accessExpiresAt,
    required this.canPractice,
    this.offers = const [],
  });

  factory PrepItemDetailModel.fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tags'] as List<dynamic>? ?? [];
    final offersJson = json['offers'] as List<dynamic>? ?? [];
    return PrepItemDetailModel(
      catalogItemId: json['catalogItemId'] as String,
      quizId: json['quizId'] as String,
      slug: json['slug'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      rootCategoryType: json['rootCategoryType'] as String,
      tags: tagsJson.map((e) => e as String).toList(),
      institutionTag: json['institutionTag'] as String?,
      questionCount: json['questionCount'] as int? ?? 0,
      canPurchase: json['canPurchase'] as bool? ?? false,
      listingEndsAt: json['listingEndsAt'] != null
          ? DateTime.parse(json['listingEndsAt'] as String)
          : null,
      userAccessState: json['userAccessState'] as String? ?? 'none',
      accessExpiresAt: json['accessExpiresAt'] != null
          ? DateTime.parse(json['accessExpiresAt'] as String)
          : null,
      canPractice: json['canPractice'] as bool? ?? false,
      offers: offersJson
          .map((e) => PrepAccessOfferModel.fromJson(e as Map<String, dynamic>))
          .where((o) => o.isActive)
          .toList(),
    );
  }

  /// Vista parcial desde un acceso activo/expirado (pintado instantáneo en detalle).
  factory PrepItemDetailModel.fromAccessItem(PrepMyAccessItemModel access) {
    return PrepItemDetailModel(
      catalogItemId: access.catalogItemId,
      quizId: access.quizId,
      title: access.title,
      categoryId: '',
      categoryName: '',
      rootCategoryType: 'geographic',
      questionCount: access.questionCount,
      canPurchase: access.canPurchase,
      userAccessState: access.canPractice ? 'active' : 'expired',
      accessExpiresAt: access.expiresAt,
      canPractice: access.canPractice,
    );
  }

  final String catalogItemId;
  final String quizId;
  final String? slug;
  final String title;
  final String? description;
  final String categoryId;
  final String categoryName;
  final String rootCategoryType;
  final List<String> tags;
  final String? institutionTag;
  final int questionCount;
  final bool canPurchase;
  final DateTime? listingEndsAt;
  final String userAccessState;
  final DateTime? accessExpiresAt;
  final bool canPractice;
  final List<PrepAccessOfferModel> offers;
}

class PrepPreviewQuestionModel {
  const PrepPreviewQuestionModel({
    required this.questionId,
    required this.questionType,
    required this.text,
    this.answerOptions = const [],
  });

  factory PrepPreviewQuestionModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['answerOptions'] as List<dynamic>? ?? [];
    return PrepPreviewQuestionModel(
      questionId: json['questionId'] as String,
      questionType: json['questionType'] as String,
      text: json['text'] as String,
      answerOptions: optionsJson
          .map((e) => PrepPreviewOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String questionId;
  final String questionType;
  final String text;
  final List<PrepPreviewOptionModel> answerOptions;
}

class PrepPreviewOptionModel {
  const PrepPreviewOptionModel({
    required this.answerOptionId,
    required this.stableKey,
    this.text,
  });

  factory PrepPreviewOptionModel.fromJson(Map<String, dynamic> json) {
    return PrepPreviewOptionModel(
      answerOptionId: json['answerOptionId'] as String,
      stableKey: json['stableKey'] as String,
      text: json['text'] as String?,
    );
  }

  final String answerOptionId;
  final String stableKey;
  final String? text;
}

class PrepPreviewModel {
  const PrepPreviewModel({
    required this.catalogItemId,
    required this.sampleQuestions,
    this.finishPackage,
  });

  factory PrepPreviewModel.fromJson(Map<String, dynamic> json) {
    final samples = json['sampleQuestions'] as List<dynamic>? ?? [];
    final packageJson = json['finishPackage'] as Map<String, dynamic>?;
    return PrepPreviewModel(
      catalogItemId: json['catalogItemId'] as String,
      sampleQuestions: samples
          .map((e) => PrepPreviewQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      finishPackage: packageJson != null
          ? PrepPreviewFinishPackageModel.fromJson(packageJson)
          : null,
    );
  }

  final String catalogItemId;
  final List<PrepPreviewQuestionModel> sampleQuestions;
  final PrepPreviewFinishPackageModel? finishPackage;
}

class PrepPreviewFinishPackageModel {
  const PrepPreviewFinishPackageModel({
    required this.quizId,
    required this.questions,
  });

  factory PrepPreviewFinishPackageModel.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    return PrepPreviewFinishPackageModel(
      quizId: json['quizId'] as String,
      questions: questionsJson
          .map(
            (e) => PrepPreviewQuestionFinishModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String quizId;
  final List<PrepPreviewQuestionFinishModel> questions;
}

class PrepPreviewQuestionFinishModel {
  const PrepPreviewQuestionFinishModel({
    required this.questionId,
    required this.points,
    required this.scoringPolicy,
    required this.supportsMultipleCorrectAnswers,
    required this.correctAnswerOptionIds,
    this.questionMediaUrl,
    this.answerOptionMediaUrls = const [],
    this.justificationText,
    this.justificationSources = const [],
  });

  factory PrepPreviewQuestionFinishModel.fromJson(Map<String, dynamic> json) {
    final correctIds = json['correctAnswerOptionIds'] as List<dynamic>? ?? [];
    final mediaJson = json['answerOptionMediaUrls'] as List<dynamic>? ?? [];
    final sourcesJson = json['justificationSources'] as List<dynamic>? ?? [];
    return PrepPreviewQuestionFinishModel(
      questionId: json['questionId'] as String,
      points: (json['points'] as num).toDouble(),
      scoringPolicy: json['scoringPolicy'] as String? ?? 'strict',
      supportsMultipleCorrectAnswers:
          json['supportsMultipleCorrectAnswers'] as bool? ?? false,
      correctAnswerOptionIds: correctIds.map((e) => e as String).toList(),
      questionMediaUrl: json['questionMediaUrl'] as String?,
      answerOptionMediaUrls: mediaJson
          .map(
            (e) => PrepPreviewAnswerOptionMediaModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      justificationText: json['justificationText'] as String?,
      justificationSources: sourcesJson
          .map(
            (e) => PrepPreviewJustificationSourceModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String questionId;
  final double points;
  final String scoringPolicy;
  final bool supportsMultipleCorrectAnswers;
  final List<String> correctAnswerOptionIds;
  final String? questionMediaUrl;
  final List<PrepPreviewAnswerOptionMediaModel> answerOptionMediaUrls;
  final String? justificationText;
  final List<PrepPreviewJustificationSourceModel> justificationSources;
}

class PrepPreviewAnswerOptionMediaModel {
  const PrepPreviewAnswerOptionMediaModel({
    required this.answerOptionId,
    required this.mediaUrl,
  });

  factory PrepPreviewAnswerOptionMediaModel.fromJson(Map<String, dynamic> json) {
    return PrepPreviewAnswerOptionMediaModel(
      answerOptionId: json['answerOptionId'] as String,
      mediaUrl: json['mediaUrl'] as String,
    );
  }

  final String answerOptionId;
  final String mediaUrl;
}

class PrepPreviewJustificationSourceModel {
  const PrepPreviewJustificationSourceModel({
    this.title,
    this.sourceUrl,
    this.snippet,
    this.pageNumber,
    this.isPrimary = false,
  });

  factory PrepPreviewJustificationSourceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PrepPreviewJustificationSourceModel(
      title: json['title'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      snippet: json['snippet'] as String?,
      pageNumber: json['pageNumber'] as int?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  final String? title;
  final String? sourceUrl;
  final String? snippet;
  final int? pageNumber;
  final bool isPrimary;
}

class PrepPreviewFinishResultModel {
  const PrepPreviewFinishResultModel({
    required this.catalogItemId,
    required this.scoreObtained,
    required this.scorePossible,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.omittedAnswers,
    required this.review,
  });

  factory PrepPreviewFinishResultModel.fromJson(Map<String, dynamic> json) {
    return PrepPreviewFinishResultModel(
      catalogItemId: json['catalogItemId'] as String,
      scoreObtained: (json['scoreObtained'] as num).toDouble(),
      scorePossible: (json['scorePossible'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      correctAnswers: json['correctAnswers'] as int,
      incorrectAnswers: json['incorrectAnswers'] as int,
      omittedAnswers: json['omittedAnswers'] as int,
      review: TeacherPracticeReviewModel.fromJson(
        json['review'] as Map<String, dynamic>,
      ),
    );
  }

  final String catalogItemId;
  final double scoreObtained;
  final double scorePossible;
  final double percentage;
  final int correctAnswers;
  final int incorrectAnswers;
  final int omittedAnswers;
  final TeacherPracticeReviewModel review;
}

class PrepMyAccessItemModel {
  const PrepMyAccessItemModel({
    required this.catalogItemId,
    required this.quizId,
    required this.title,
    required this.questionCount,
    required this.grantedAt,
    required this.expiresAt,
    required this.canPractice,
    required this.canPurchase,
    this.lastPracticedAt,
  });

  factory PrepMyAccessItemModel.fromJson(Map<String, dynamic> json) {
    return PrepMyAccessItemModel(
      catalogItemId: json['catalogItemId'] as String,
      quizId: json['quizId'] as String,
      title: json['title'] as String,
      questionCount: json['questionCount'] as int? ?? 0,
      grantedAt: DateTime.parse(json['grantedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      canPractice: json['canPractice'] as bool? ?? false,
      canPurchase: json['canPurchase'] as bool? ?? false,
      lastPracticedAt: json['lastPracticedAt'] != null
          ? DateTime.parse(json['lastPracticedAt'] as String)
          : null,
    );
  }

  final String catalogItemId;
  final String quizId;
  final String title;
  final int questionCount;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final bool canPractice;
  final bool canPurchase;
  final DateTime? lastPracticedAt;
}

class PrepMyAccessesModel {
  const PrepMyAccessesModel({
    this.active = const [],
    this.expired = const [],
  });

  factory PrepMyAccessesModel.fromJson(Map<String, dynamic> json) {
    final activeJson = json['active'] as List<dynamic>? ?? [];
    final expiredJson = json['expired'] as List<dynamic>? ?? [];
    return PrepMyAccessesModel(
      active: activeJson
          .map((e) => PrepMyAccessItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      expired: expiredJson
          .map((e) => PrepMyAccessItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<PrepMyAccessItemModel> active;
  final List<PrepMyAccessItemModel> expired;
}

class PrepCheckoutResultModel {
  const PrepCheckoutResultModel({
    required this.status,
    this.purchaseId,
    this.accessExpiresAt,
    required this.requiresPayment,
    this.message,
  });

  factory PrepCheckoutResultModel.fromJson(Map<String, dynamic> json) {
    return PrepCheckoutResultModel(
      status: json['status'] as String,
      purchaseId: json['purchaseId'] as String?,
      accessExpiresAt: json['accessExpiresAt'] != null
          ? DateTime.parse(json['accessExpiresAt'] as String)
          : null,
      requiresPayment: json['requiresPayment'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  final String status;
  final String? purchaseId;
  final DateTime? accessExpiresAt;
  final bool requiresPayment;
  final String? message;
}

class PrepReferralCodeModel {
  const PrepReferralCodeModel({
    required this.code,
    required this.shareUrl,
    required this.slug,
  });

  factory PrepReferralCodeModel.fromJson(Map<String, dynamic> json) {
    return PrepReferralCodeModel(
      code: json['code'] as String,
      shareUrl: json['shareUrl'] as String,
      slug: json['slug'] as String,
    );
  }

  final String code;
  final String shareUrl;
  final String slug;
}

class PrepPublicPreviewModel {
  const PrepPublicPreviewModel({
    required this.catalogItemId,
    required this.slug,
    required this.title,
    this.description,
    required this.categoryName,
    required this.rootCategoryType,
    required this.questionCount,
    required this.hasFreeOffer,
    this.lowestPaidPrice,
    this.currencyCode,
    this.bestOfferDurationDays,
  });

  factory PrepPublicPreviewModel.fromJson(Map<String, dynamic> json) {
    return PrepPublicPreviewModel(
      catalogItemId: json['catalogItemId'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryName: json['categoryName'] as String,
      rootCategoryType: json['rootCategoryType'] as String,
      questionCount: json['questionCount'] as int? ?? 0,
      hasFreeOffer: json['hasFreeOffer'] as bool? ?? false,
      lowestPaidPrice: (json['lowestPaidPrice'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] as String?,
      bestOfferDurationDays: json['bestOfferDurationDays'] as int?,
    );
  }

  final String catalogItemId;
  final String slug;
  final String title;
  final String? description;
  final String categoryName;
  final String rootCategoryType;
  final int questionCount;
  final bool hasFreeOffer;
  final double? lowestPaidPrice;
  final String? currencyCode;
  final int? bestOfferDurationDays;
}

class PrepCatalogItemSlugModel {
  const PrepCatalogItemSlugModel({
    required this.catalogItemId,
    required this.slug,
  });

  factory PrepCatalogItemSlugModel.fromJson(Map<String, dynamic> json) {
    return PrepCatalogItemSlugModel(
      catalogItemId: json['catalogItemId'] as String,
      slug: json['slug'] as String,
    );
  }

  final String catalogItemId;
  final String slug;
}
