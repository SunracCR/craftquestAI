class PrepAdminLinkableQuizModel {
  const PrepAdminLinkableQuizModel({
    required this.quizId,
    required this.title,
    this.description,
    required this.publicationStatus,
    required this.questionCount,
    required this.createdByUserId,
    required this.createdByDisplayName,
  });

  factory PrepAdminLinkableQuizModel.fromJson(Map<String, dynamic> json) {
    return PrepAdminLinkableQuizModel(
      quizId: json['quizId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      publicationStatus: json['publicationStatus'] as String,
      questionCount: json['questionCount'] as int? ?? 0,
      createdByUserId: json['createdByUserId'] as String,
      createdByDisplayName: json['createdByDisplayName'] as String,
    );
  }

  final String quizId;
  final String title;
  final String? description;
  final String publicationStatus;
  final int questionCount;
  final String createdByUserId;
  final String createdByDisplayName;
}

class PrepAdminCategoryModel {
  const PrepAdminCategoryModel({
    required this.categoryId,
    this.parentCategoryId,
    required this.categoryType,
    required this.slug,
    required this.name,
    this.description,
    this.countryCode,
    this.iconKey,
    required this.sortOrder,
    required this.isActive,
    this.children = const [],
  });

  factory PrepAdminCategoryModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return PrepAdminCategoryModel(
      categoryId: json['categoryId'] as String,
      parentCategoryId: json['parentCategoryId'] as String?,
      categoryType: json['categoryType'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      countryCode: json['countryCode'] as String?,
      iconKey: json['iconKey'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      children: childrenJson
          .map((e) => PrepAdminCategoryModel.fromJson(e as Map<String, dynamic>))
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
  final int sortOrder;
  final bool isActive;
  final List<PrepAdminCategoryModel> children;
}

class PrepAdminItemSummaryModel {
  const PrepAdminItemSummaryModel({
    required this.catalogItemId,
    required this.quizId,
    required this.categoryId,
    required this.categoryName,
    required this.displayTitle,
    required this.isPublished,
    required this.isDeleted,
    required this.questionCount,
    required this.activeOfferCount,
    required this.sampleQuestionCount,
  });

  factory PrepAdminItemSummaryModel.fromJson(Map<String, dynamic> json) {
    return PrepAdminItemSummaryModel(
      catalogItemId: json['catalogItemId'] as String,
      quizId: json['quizId'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      displayTitle: json['displayTitle'] as String,
      isPublished: json['isPublished'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      questionCount: json['questionCount'] as int? ?? 0,
      activeOfferCount: json['activeOfferCount'] as int? ?? 0,
      sampleQuestionCount: json['sampleQuestionCount'] as int? ?? 0,
    );
  }

  final String catalogItemId;
  final String quizId;
  final String categoryId;
  final String categoryName;
  final String displayTitle;
  final bool isPublished;
  final bool isDeleted;
  final int questionCount;
  final int activeOfferCount;
  final int sampleQuestionCount;
}

class PrepAdminOfferModel {
  const PrepAdminOfferModel({
    required this.offerId,
    required this.durationDays,
    required this.priceAmount,
    required this.currencyCode,
    required this.isFree,
    required this.isActive,
    this.storeProductId,
  });

  factory PrepAdminOfferModel.fromJson(Map<String, dynamic> json) {
    return PrepAdminOfferModel(
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

class PrepAdminSampleModel {
  const PrepAdminSampleModel({
    required this.questionId,
    required this.sortOrder,
    required this.promptPreview,
  });

  factory PrepAdminSampleModel.fromJson(Map<String, dynamic> json) {
    return PrepAdminSampleModel(
      questionId: json['questionId'] as String,
      sortOrder: json['sortOrder'] as int,
      promptPreview: json['promptPreview'] as String,
    );
  }

  final String questionId;
  final int sortOrder;
  final String promptPreview;
}

class PrepAdminItemDetailModel {
  const PrepAdminItemDetailModel({
    required this.catalogItemId,
    required this.quizId,
    required this.quizTitle,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    this.titleOverride,
    this.description,
    this.institutionTag,
    this.listingStartsAt,
    this.listingEndsAt,
    required this.isPublished,
    required this.isDeleted,
    required this.questionCount,
    this.tags = const [],
    this.offers = const [],
    this.sampleQuestions = const [],
  });

  factory PrepAdminItemDetailModel.fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tags'] as List<dynamic>? ?? [];
    final offersJson = json['offers'] as List<dynamic>? ?? [];
    final samplesJson = json['sampleQuestions'] as List<dynamic>? ?? [];
    return PrepAdminItemDetailModel(
      catalogItemId: json['catalogItemId'] as String,
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryType: json['categoryType'] as String,
      titleOverride: json['titleOverride'] as String?,
      description: json['description'] as String?,
      institutionTag: json['institutionTag'] as String?,
      listingStartsAt: json['listingStartsAt'] != null
          ? DateTime.parse(json['listingStartsAt'] as String)
          : null,
      listingEndsAt: json['listingEndsAt'] != null
          ? DateTime.parse(json['listingEndsAt'] as String)
          : null,
      isPublished: json['isPublished'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      questionCount: json['questionCount'] as int? ?? 0,
      tags: tagsJson.map((e) => e as String).toList(),
      offers: offersJson
          .map((e) => PrepAdminOfferModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sampleQuestions: samplesJson
          .map((e) => PrepAdminSampleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String catalogItemId;
  final String quizId;
  final String quizTitle;
  final String categoryId;
  final String categoryName;
  final String categoryType;
  final String? titleOverride;
  final String? description;
  final String? institutionTag;
  final DateTime? listingStartsAt;
  final DateTime? listingEndsAt;
  final bool isPublished;
  final bool isDeleted;
  final int questionCount;
  final List<String> tags;
  final List<PrepAdminOfferModel> offers;
  final List<PrepAdminSampleModel> sampleQuestions;
}

/// Subcategoría seleccionable (hoja del árbol).
class PrepAdminSubcategoryOption {
  const PrepAdminSubcategoryOption({
    required this.categoryId,
    required this.label,
    required this.isGeographic,
  });

  final String categoryId;
  final String label;
  final bool isGeographic;
}
