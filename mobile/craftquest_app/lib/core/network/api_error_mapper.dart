import 'package:craftquest_app/core/utils/billing_display.dart';
import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';
import 'package:craftquest_app/features/ai_generation/ai_generation_limits.dart';
import 'package:craftquest_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

/// Maps API problem details ([errorCode] + metadata) to localized user messages.
abstract final class ApiErrorMapper {
  static const planLimitErrorCodes = {
    'QUESTION_LIMIT_REACHED',
    'QUIZ_LIMIT_REACHED',
    'QUIZ_OVER_PLAN_LIMIT',
  };

  static const upgradePromptErrorCodes = {
    ...planLimitErrorCodes,
    'AI_CREDITS_INSUFFICIENT',
  };

  static bool isAiCreditsInsufficient(DioException error) {
    final data = error.response?.data;
    if (data is! Map<String, dynamic>) {
      return false;
    }
    return _errorCodeFrom(data) == 'AI_CREDITS_INSUFFICIENT';
  }

  static String? tryGetAiJobId(DioException error) {
    final data = error.response?.data;
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final errorCode = data['errorCode'] as String?;
    if (errorCode != 'GENERATION_ALREADY_IN_PROGRESS') {
      return null;
    }

    final aiJobId = data['aiJobId'];
    if (aiJobId is String && aiJobId.isNotEmpty) {
      return aiJobId;
    }

    return null;
  }

  static String? tryGetTargetQuizId(DioException error) {
    final data = error.response?.data;
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final targetQuizId = data['targetQuizId'];
    if (targetQuizId is String && targetQuizId.isNotEmpty) {
      return targetQuizId;
    }

    return null;
  }

  static bool isPlanLimitError(DioException error) {
    final data = error.response?.data;
    if (data is! Map<String, dynamic>) {
      return false;
    }

    final errorCode = _errorCodeFrom(data);
    if (errorCode != null && upgradePromptErrorCodes.contains(errorCode)) {
      return true;
    }

    final title = data['title'] as String?;
    if (title == null) {
      return false;
    }

    return RegExp(
      r'(Question|Quiz) limit reached',
      caseSensitive: false,
    ).hasMatch(title);
  }
  static String mapAiJobFailure(AiJobModel job, AppLocalizations l10n) {
    if (job.errorCode != null && job.errorCode!.isNotEmpty) {
      final mapped = mapProblemDetails(
        {
          'errorCode': job.errorCode,
          if (job.errorMessage != null) 'title': job.errorMessage,
        },
        l10n,
      );
      if (mapped != null) {
        return mapped;
      }

      final legacy = _mapLegacyEnglishTitle(job.errorMessage, l10n);
      if (legacy != null) {
        return legacy;
      }
    }

    return mapAiJobErrorMessage(job.errorMessage, l10n) ?? l10n.aiGenerationFailed;
  }

  static String? mapAiJobErrorMessage(String? message, AppLocalizations l10n) {
    if (message == null || message.isEmpty) {
      return l10n.aiGenerationFailed;
    }

    final lower = message.toLowerCase();
    if (lower.contains('resource_exhausted')
        || lower.contains('prepayment credits')
        || lower.contains('"code": 429')
        || lower.contains('quota is exhausted')
        || lower.contains('quota exhausted')
        || lower.contains('gemini api quota')) {
      return l10n.errorAiGeminiQuotaExhausted;
    }

    if (lower.contains('no longer available')
        || lower.contains('gemini model is unavailable')
        || lower.contains('gemini-2.0-flash')
        || lower.contains('"code": 404')
        || lower.contains('not_found')) {
      return l10n.errorAiGeminiModelUnavailable;
    }

    if (lower.contains('invalid cqif json')
        || lower.contains('could not be converted')
        || lower.contains('quiz format')) {
      return l10n.errorAiGenerationInvalidOutput;
    }

    if (lower.contains('high demand')
        || lower.contains('temporarily overloaded')
        || lower.contains('gemini is temporarily overloaded')
        || lower.contains('"code": 503')
        || lower.contains('"status": "unavailable"')) {
      return l10n.errorAiGeminiOverloaded;
    }

    if (lower.contains('api_key_invalid')
        || lower.contains('api key expired')
        || lower.contains('api key was reported as leaked')
        || lower.contains('permission_denied')
        || lower.contains('"code": 403')
        || (lower.contains('"code": 400') &&
            (lower.contains('api key') || lower.contains('api_key')))) {
      return l10n.errorAiGeminiApiKeyInvalid;
    }

    if (message.startsWith('Gemini quiz generation failed:')
        || message.startsWith('Gemini request failed:')) {
      return l10n.aiGenerationFailed;
    }

    final legacy = _mapLegacyEnglishTitle(message, l10n);
    if (legacy != null) {
      return legacy;
    }

    return message.length > 280 ? '${message.substring(0, 280)}…' : message;
  }

  static bool isMaterialNotSelectableTextFailure(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    return raw.startsWith('MATERIAL_NOT_SELECTABLE_TEXT');
  }

  static bool isMaterialPageLimitFailure(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    if (raw.startsWith('MATERIAL_PAGE_LIMIT_EXCEEDED')) return true;
    return RegExp(
      r'Document exceeds maximum of \d+ pages',
      caseSensitive: false,
    ).hasMatch(raw);
  }

  static Map<String, dynamic>? problemDetailsFrom(DioException error) {
    final data = error.response?.data;
    return data is Map<String, dynamic> ? data : null;
  }

  /// Maps a raw API [title] (often English) to a localized message when possible.
  static String? mapApiTitle(String? title, AppLocalizations l10n) =>
      _mapLegacyEnglishTitle(title, l10n);

  static String? _errorCodeFrom(Map<String, dynamic> data) {
    final direct = data['errorCode'];
    if (direct is String && direct.isNotEmpty) {
      return direct;
    }

    final extensions = data['extensions'];
    if (extensions is Map) {
      final nested = extensions['errorCode'];
      if (nested is String && nested.isNotEmpty) {
        return nested;
      }
    }

    return null;
  }

  /// Actionable steps when upload or processing fails for study materials.
  static String? mapMaterialUploadGuidance(
    Map<String, dynamic> data,
    AppLocalizations l10n,
  ) {
    final errorCode = data['errorCode'] as String?;
    if (errorCode == null || errorCode.isEmpty) {
      return null;
    }

    return switch (errorCode) {
      'MATERIAL_NOT_SELECTABLE_TEXT' => l10n.errorMaterialNotSelectableTextGuidance,
      'MATERIAL_NEEDS_OCR' => l10n.errorMaterialNeedsOcrGuidance,
      'MATERIAL_PAGE_LIMIT_EXCEEDED' => l10n.errorMaterialPageLimitGuidance(
          _asInt(data['maxPages']) ?? AiGenerationLimits.maxPagesPerMaterial,
          AiGenerationLimits.maxPagesPerGeneration,
        ),
      'MATERIAL_TOO_LARGE' => l10n.errorMaterialTooLargeGuidance,
      _ => null,
    };
  }

  static String? mapMaterialFailureGuidance(
    String? raw,
    AppLocalizations l10n,
  ) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parts = raw.split('|');
    final code = parts.first.trim();
    final maxPages = parts.length > 1 ? int.tryParse(parts[1].trim()) : null;

    if (!code.contains('_') && code != code.toUpperCase()) {
      return null;
    }

    return mapMaterialUploadGuidance(
      {
        'errorCode': code,
        if (maxPages != null) 'maxPages': maxPages,
      },
      l10n,
    );
  }

  /// Maps [StudyMaterialDetailDto.errorMessage] from failed processing (code or legacy English).
  static String mapMaterialProcessingFailure(
    String? raw,
    AppLocalizations l10n,
  ) {
    if (raw == null || raw.isEmpty) {
      return l10n.aiGenerationFailed;
    }

    final parts = raw.split('|');
    final code = parts.first.trim();
    final maxPages = parts.length > 1 ? int.tryParse(parts[1].trim()) : null;

    if (code.contains('_') || code == code.toUpperCase()) {
      final mapped = mapProblemDetails(
        {
          'errorCode': code,
          if (maxPages != null) 'maxPages': maxPages,
        },
        l10n,
      );
      if (mapped != null) {
        return mapped;
      }
    }

    final legacy = _mapLegacyEnglishTitle(raw, l10n)
        ?? _mapMaterialEnglishMessage(raw, l10n);
    return legacy ?? raw;
  }

  static String? mapProblemDetails(
    Map<String, dynamic> data,
    AppLocalizations l10n,
  ) {
    final errorCode = _errorCodeFrom(data);
    if (errorCode == null || errorCode.isEmpty) {
      return _mapLegacyEnglishTitle(data['title'] as String?, l10n);
    }

    switch (errorCode) {
      case 'QUESTION_LIMIT_REACHED':
        final max = _asInt(data['maxQuestionsPerQuiz']);
        if (max == null) return null;
        return l10n.errorQuestionLimitReached(
          max,
          _planLabel(
            planName: data['planName'] as String?,
            planCode: data['planCode'] as String?,
            l10n: l10n,
          ),
        );
      case 'QUIZ_LIMIT_REACHED':
        final max = _asInt(data['maxQuizzes']);
        if (max == null) return null;
        return l10n.errorQuizLimitReached(
          max,
          _planLabel(
            planName: data['planName'] as String?,
            planCode: data['planCode'] as String?,
            l10n: l10n,
          ),
        );
      case 'QUIZ_OVER_PLAN_LIMIT':
        final max = _asInt(data['maxQuizzes']);
        final current = _asInt(data['currentQuizzes']);
        if (max == null || current == null) return null;
        return l10n.errorQuizOverPlanLimit(
          max,
          current,
          _planLabel(
            planName: data['planName'] as String?,
            planCode: data['planCode'] as String?,
            l10n: l10n,
          ),
        );
      case 'AI_CREDITS_INSUFFICIENT':
        return l10n.errorAiCreditsInsufficient;
      case 'AI_CREDIT_PACKS_NOT_AVAILABLE':
        return l10n.errorAiCreditPacksNotAvailable;
      case 'MATERIAL_NEEDS_OCR':
        return l10n.errorMaterialNeedsOcr;
      case 'MATERIAL_NOT_SELECTABLE_TEXT':
        return l10n.errorMaterialNotSelectableText;
      case 'MATERIAL_TOO_LARGE':
        return l10n.errorMaterialTooLarge;
      case 'MATERIAL_PAGE_LIMIT_EXCEEDED':
        return l10n.errorMaterialPageLimitExceeded(
          _asInt(data['maxPages']) ?? 120,
        );
      case 'GENERATION_PAGE_RANGE_TOO_LARGE':
        return l10n.errorGenerationPageRangeExceeded(
          _asInt(data['maxPages']) ?? 30,
        );
      case 'GENERATION_SCOPE_EMPTY':
        return l10n.errorGenerationScopeEmpty;
      case 'GENERATION_SCOPE_TOO_LARGE':
        return l10n.errorMaterialTooLarge;
      case 'GENERATION_ALREADY_IN_PROGRESS':
        return l10n.errorGenerationAlreadyInProgress;
      case 'GENERATION_TIMEOUT':
      case 'GENERATION_STALE_ABORTED':
        return l10n.aiGenerationProgressTakingLong;
      case 'AI_NOT_CONFIGURED':
        return l10n.errorAiNotConfigured;
      case 'AI_GEMINI_QUOTA_EXHAUSTED':
        return l10n.errorAiGeminiQuotaExhausted;
      case 'AI_GEMINI_MODEL_UNAVAILABLE':
        return l10n.errorAiGeminiModelUnavailable;
      case 'AI_GEMINI_OVERLOADED':
        return l10n.errorAiGeminiOverloaded;
      case 'AI_GENERATION_INVALID_OUTPUT':
        return l10n.errorAiGenerationInvalidOutput;
      case 'AI_GENERATION_CHUNK_FAILED':
        return l10n.errorAiGenerationInvalidOutput;
      case 'AI_GENERATION_NO_VALID_QUESTIONS':
      case 'AI_GENERATION_IMPORT_EMPTY':
        return l10n.errorAiGenerationInvalidOutput;
      case 'GENERATION_JOB_NOT_RETRYABLE':
        return l10n.errorGenerationJobNotRetryable;
      case 'GUEST_NOT_ALLOWED':
        return l10n.errorGuestNotAllowed;
      case 'GROUP_ACCESS_DENIED':
        final className = data['className'] as String?;
        if (className != null && className.trim().isNotEmpty) {
          return l10n.errorGroupAccessDenied(className.trim());
        }
        return l10n.errorGroupAccessDeniedGeneric;
      case 'SHARED_QUIZ_SLOT_LIMIT':
        return l10n.errorSharedQuizSlotLimit(
          _asInt(data['max']) ?? 2,
        );
      case 'CANNOT_REDEEM_OWN_QUIZ':
        return l10n.errorCannotRedeemOwnQuiz;
      case 'DIRECT_INVITE_NOT_ALLOWED':
        return l10n.errorDirectInviteNotAllowed;
      case 'ACTIVE_PRACTICE_SESSION':
        return l10n.errorActivePracticeSession;
      case 'CURRENT_PASSWORD_INCORRECT':
        return l10n.currentPasswordIncorrectError;
      case 'EMAIL_NOT_VERIFIED':
        return l10n.errorEmailNotVerified;
      case 'INVALID_VERIFICATION_TOKEN':
        return l10n.errorInvalidVerificationToken;
      case 'INVALID_PASSWORD_CHANGE_TOKEN':
        return l10n.errorInvalidPasswordChangeToken;
      case 'PASSWORD_CHANGE_UNAVAILABLE':
        return l10n.passwordChangeUnavailableError;
      case 'INVALID_EMAIL':
        return l10n.teacherClassInvalidEmailError;
      case 'INVALID_DISPLAY_NAME':
        return l10n.profileNameInvalidMessage;
      case 'USER_NOT_FOUND':
        return l10n.teacherClassMemberNotFoundError;
      case 'CLASS_MEMBER_ALREADY_EXISTS':
        return l10n.teacherClassMemberAlreadyExistsError;
      case 'CLASS_MUST_BE_ARCHIVED':
        return l10n.teacherClassDeleteRequiresArchiveError;
      case 'CLASS_NOT_ARCHIVED':
        return l10n.teacherClassNotArchivedError;
      case 'ASSIGNMENT_NOT_YET_OPEN':
        return l10n.studentAssignmentNotYetOpenError;
      case 'ASSIGNMENT_NOT_OPEN':
        return l10n.studentAssignmentClosedLabel;
      case 'ASSIGNMENT_PAST_DUE':
        return l10n.studentAssignmentPastDueLabel;
      case 'ASSIGNMENT_MAX_ATTEMPTS':
        return l10n.studentAssignmentMaxAttemptsLabel;
      case 'ASSIGNMENT_NOT_EDITABLE':
        return l10n.teacherAssignmentNotEditableError;
      case 'ASSIGNMENT_MAX_ATTEMPTS_BELOW_EXISTING':
        return l10n.teacherAssignmentMaxAttemptsBelowExistingError;
      case 'ASSIGNMENT_INVALID_DATE_RANGE':
        return l10n.teacherAssignmentInvalidDateRangeError;
      case 'PREP_CATEGORY_NOT_FOUND':
        return l10n.errorPrepCategoryNotFound;
      case 'PREP_CATEGORY_HAS_SUBCATEGORIES':
        return l10n.errorPrepCategoryHasSubcategories;
      case 'PREP_CATEGORY_HAS_ITEMS':
        return l10n.errorPrepCategoryHasItems;
      case 'PREP_QUIZ_NOT_FOUND':
        return l10n.errorPrepQuizNotFound;
      case 'PREP_QUIZ_NOT_ELIGIBLE':
        return l10n.errorPrepQuizNotEligible;
      case 'PREP_QUIZ_ALREADY_IN_CATALOG':
        return l10n.errorPrepQuizAlreadyInCatalog;
      case 'PREP_CATALOG_ITEM_NOT_FOUND':
        return l10n.errorPrepCatalogItemNotFound;
      case 'PREP_SAMPLE_COUNT_REQUIRED':
        return l10n.errorPrepSampleCountRequired(
          _asInt(data['requiredCount']) ?? 3,
        );
      case 'PREP_SAMPLE_QUESTIONS_NOT_IN_QUIZ':
        return l10n.errorPrepSampleQuestionsNotInQuiz;
      case 'PREP_INVALID_CATEGORY_TYPE':
        return l10n.errorPrepInvalidCategoryType;
      case 'PREP_NAME_SLUG_REQUIRED':
        return l10n.errorPrepNameSlugRequired;
      case 'PREP_PARENT_CATEGORY_NOT_FOUND':
        return l10n.errorPrepParentCategoryNotFound;
      case 'PREP_SUBCATEGORY_TYPE_MISMATCH':
        return l10n.errorPrepSubcategoryTypeMismatch;
      case 'PREP_CATEGORY_SELF_PARENT':
        return l10n.errorPrepCategorySelfParent;
      case 'PREP_SLUG_DUPLICATE':
        return l10n.errorPrepSlugDuplicate;
      case 'PREP_CATEGORY_INACTIVE':
        return l10n.errorPrepCategoryInactive;
      case 'PREP_ITEM_REQUIRES_SUBCATEGORY':
        return l10n.errorPrepItemRequiresSubcategory;
      case 'PREP_INSTITUTION_TAG_GEOGRAPHIC_ONLY':
        return l10n.errorPrepInstitutionTagGeographicOnly;
      case 'PREP_CATEGORY_HIERARCHY_BROKEN':
        return l10n.errorPrepCategoryHierarchyBroken;
      case 'PREP_OFFERS_REQUIRED':
        return l10n.errorPrepOffersRequired;
      case 'PREP_INVALID_DURATION':
        return l10n.errorPrepInvalidDuration;
      case 'PREP_PRICE_NEGATIVE':
        return l10n.errorPrepPriceNegative;
      case 'PREP_OFFER_DURATION_DUPLICATE':
        return l10n.errorPrepOfferDurationDuplicate;
      case 'PREP_ACTIVE_OFFER_REQUIRED_PUBLISH':
        return l10n.errorPrepActiveOfferRequiredPublish;
      case 'PREP_SAMPLES_REQUIRED_PUBLISH':
        return l10n.errorPrepSamplesRequiredPublish(
          _asInt(data['requiredCount']) ?? 3,
        );
      case 'PREP_QUIZ_NO_QUESTIONS':
        return l10n.errorPrepQuizNoQuestions;
      case 'PREP_LISTING_END_BEFORE_START':
        return l10n.errorPrepListingEndBeforeStart;
      case 'PREP_PREVIEW_NOT_AVAILABLE':
        return l10n.errorPrepPreviewNotAvailable;
      case 'PREP_ITEM_NOT_AVAILABLE':
        return l10n.errorPrepItemNotAvailable;
      case 'PREP_OFFER_NOT_FOUND':
        return l10n.errorPrepOfferNotFound;
      case 'PREP_OFFER_IS_FREE':
        return l10n.errorPrepOfferIsFree;
      case 'PREP_PAYPAL_PURCHASE_NOT_FOUND':
        return l10n.errorPrepPayPalPurchaseNotFound;
      case 'PREP_MOBILE_PLATFORM_INVALID':
        return l10n.errorPrepMobilePlatformInvalid;
      case 'PREP_STORE_PRODUCT_MISMATCH':
        return l10n.errorPrepStoreProductMismatch;
      case 'PREP_OFFER_NO_LONGER_EXISTS':
        return l10n.errorPrepOfferNoLongerExists;
      case 'PREP_INVALID_PRODUCT_CODE':
        return l10n.errorPrepInvalidProductCode;
      case 'PREP_GOOGLE_PLAY_NOT_CONFIGURED':
        return l10n.errorPrepGooglePlayNotConfigured;
      case 'PREP_APP_STORE_NOT_CONFIGURED':
        return l10n.errorPrepAppStoreNotConfigured;
      default:
        return _mapLegacyEnglishTitle(data['title'] as String?, l10n);
    }
  }

  static String? _mapLegacyEnglishTitle(String? title, AppLocalizations l10n) {
    if (title == null || title.isEmpty) {
      return null;
    }

    switch (title.trim()) {
      case 'Current password is incorrect.':
        return l10n.currentPasswordIncorrectError;
      case 'Password change is not available for this account.':
        return l10n.passwordChangeUnavailableError;
      case 'Invalid email or password.':
        return l10n.loginInvalidCredentials;
      case 'Invalid email address.':
        return l10n.teacherClassInvalidEmailError;
      case 'Invalid display name.':
        return l10n.profileNameInvalidMessage;
      case 'No user found with that email address.':
        return l10n.teacherClassMemberNotFoundError;
      case 'This user is already a member of the class.':
        return l10n.teacherClassMemberAlreadyExistsError;
      case 'Only archived classes can be deleted. Archive the class first.':
        return l10n.teacherClassDeleteRequiresArchiveError;
      case 'Class is not archived.':
        return l10n.teacherClassNotArchivedError;
      case 'This assignment has not opened yet.':
        return l10n.studentAssignmentNotYetOpenError;
      case 'This assignment is past its due date.':
        return l10n.studentAssignmentPastDueLabel;
      case 'You have reached the maximum number of attempts for this assignment.':
        return l10n.studentAssignmentMaxAttemptsLabel;
      case 'Only active assignments can be edited.':
        return l10n.teacherAssignmentNotEditableError;
      case 'Max attempts cannot be lower than existing student attempts.':
        return l10n.teacherAssignmentMaxAttemptsBelowExistingError;
      case 'Due date cannot be before the start date.':
        return l10n.teacherAssignmentInvalidDateRangeError;
      case 'Category not found.':
        return l10n.errorPrepCategoryNotFound;
      case 'Catalog item not found.':
        return l10n.errorPrepCatalogItemNotFound;
      case 'Quiz not found.':
        return l10n.errorPrepQuizNotFound;
      case 'This quiz is already in the Preparación+ catalog.':
        return l10n.errorPrepQuizAlreadyInCatalog;
      case 'Offer not found.':
        return l10n.errorPrepOfferNotFound;
      case 'This item is not available for purchase.':
        return l10n.errorPrepItemNotAvailable;
      case 'Preview is not available for this item.':
        return l10n.errorPrepPreviewNotAvailable;
      case 'This offer is free. Use checkout without payment.':
        return l10n.errorPrepOfferIsFree;
      case 'An unexpected error occurred.':
        return l10n.genericRequestErrorMessage;
      case 'Image file is required.':
        return l10n.imageUploadFileRequired;
      case 'Unsupported image file type.':
        return l10n.imageUploadUnsupportedType;
      case 'File is empty.':
        return l10n.imageUploadFileRequired;
    }

    final prepSampleRequired = RegExp(
      r'^Exactly (\d+) sample questions are required\.$',
      caseSensitive: false,
    ).firstMatch(title);
    if (prepSampleRequired != null) {
      final count = int.tryParse(prepSampleRequired.group(1)!);
      if (count != null) {
        return l10n.errorPrepSampleCountRequired(count);
      }
    }

    final prepSamplesPublish = RegExp(
      r'^Configure exactly (\d+) sample questions before publishing\.$',
      caseSensitive: false,
    ).firstMatch(title);
    if (prepSamplesPublish != null) {
      final count = int.tryParse(prepSamplesPublish.group(1)!);
      if (count != null) {
        return l10n.errorPrepSamplesRequiredPublish(count);
      }
    }

    final questionLimit = RegExp(
      r"Question limit reached \((\d+)\) for plan '([^']+)'\.",
      caseSensitive: false,
    ).firstMatch(title);
    if (questionLimit != null) {
      final max = int.tryParse(questionLimit.group(1)!);
      final planCode = questionLimit.group(2)!;
      if (max != null) {
        return l10n.errorQuestionLimitReached(
          max,
          _planLabel(planCode: planCode, l10n: l10n),
        );
      }
    }

    final quizLimit = RegExp(
      r"Quiz limit reached \((\d+)\) for plan '([^']+)'\.",
      caseSensitive: false,
    ).firstMatch(title);
    if (quizLimit != null) {
      final max = int.tryParse(quizLimit.group(1)!);
      final planCode = quizLimit.group(2)!;
      if (max != null) {
        return l10n.errorQuizLimitReached(
          max,
          _planLabel(planCode: planCode, l10n: l10n),
        );
      }
    }

    return _mapMaterialEnglishMessage(title, l10n);
  }

  static String? _mapMaterialEnglishMessage(String title, AppLocalizations l10n) {
    final fileSizeLimit = RegExp(
      r'File exceeds maximum size of (\d+) bytes',
      caseSensitive: false,
    ).firstMatch(title);
    if (fileSizeLimit != null) {
      return l10n.imageTooLargeForUpload;
    }

    final pageLimit = RegExp(
      r'Document exceeds maximum of (\d+) pages',
      caseSensitive: false,
    ).firstMatch(title);
    if (pageLimit != null) {
      final max = int.tryParse(pageLimit.group(1)!);
      if (max != null) {
        return l10n.errorMaterialPageLimitExceeded(max);
      }
    }

    final rangeLimit = RegExp(
      r'Page range exceeds maximum of (\d+) pages per generation',
      caseSensitive: false,
    ).firstMatch(title);
    if (rangeLimit != null) {
      final max = int.tryParse(rangeLimit.group(1)!);
      if (max != null) {
        return l10n.errorGenerationPageRangeExceeded(max);
      }
    }

    return null;
  }

  static String _planLabel({
    String? planName,
    String? planCode,
    required AppLocalizations l10n,
  }) {
    return BillingDisplay.localizedPlanName(
      l10n,
      code: planCode,
      name: planName,
    );
  }

  static int? _asInt(Object? value) => switch (value) {
        int v => v,
        num v => v.toInt(),
        String v => int.tryParse(v),
        _ => null,
      };
}
