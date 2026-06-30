namespace CraftQuest.Domain.Constants;

/// <summary>
/// Stable API error codes for Preparación+ (mapped to localized messages in the mobile app).
/// </summary>
public static class PrepPlusErrorCodes
{
    public const string CategoryNotFound = "PREP_CATEGORY_NOT_FOUND";
    public const string CategoryHasSubcategories = "PREP_CATEGORY_HAS_SUBCATEGORIES";
    public const string CategoryHasItems = "PREP_CATEGORY_HAS_ITEMS";
    public const string QuizNotFound = "PREP_QUIZ_NOT_FOUND";
    public const string QuizNotEligible = "PREP_QUIZ_NOT_ELIGIBLE";
    public const string QuizAlreadyInCatalog = "PREP_QUIZ_ALREADY_IN_CATALOG";
    public const string CatalogItemNotFound = "PREP_CATALOG_ITEM_NOT_FOUND";
    public const string SampleCountRequired = "PREP_SAMPLE_COUNT_REQUIRED";
    public const string SampleQuestionsNotInQuiz = "PREP_SAMPLE_QUESTIONS_NOT_IN_QUIZ";
    public const string InvalidCategoryType = "PREP_INVALID_CATEGORY_TYPE";
    public const string NameSlugRequired = "PREP_NAME_SLUG_REQUIRED";
    public const string ParentCategoryNotFound = "PREP_PARENT_CATEGORY_NOT_FOUND";
    public const string SubcategoryTypeMismatch = "PREP_SUBCATEGORY_TYPE_MISMATCH";
    public const string CategorySelfParent = "PREP_CATEGORY_SELF_PARENT";
    public const string SlugDuplicate = "PREP_SLUG_DUPLICATE";
    public const string CategoryInactive = "PREP_CATEGORY_INACTIVE";
    public const string ItemRequiresSubcategory = "PREP_ITEM_REQUIRES_SUBCATEGORY";
    public const string InstitutionTagGeographicOnly = "PREP_INSTITUTION_TAG_GEOGRAPHIC_ONLY";
    public const string CategoryHierarchyBroken = "PREP_CATEGORY_HIERARCHY_BROKEN";
    public const string OffersRequired = "PREP_OFFERS_REQUIRED";
    public const string InvalidDuration = "PREP_INVALID_DURATION";
    public const string PriceNegative = "PREP_PRICE_NEGATIVE";
    public const string OfferDurationDuplicate = "PREP_OFFER_DURATION_DUPLICATE";
    public const string ActiveOfferRequiredPublish = "PREP_ACTIVE_OFFER_REQUIRED_PUBLISH";
    public const string SamplesRequiredPublish = "PREP_SAMPLES_REQUIRED_PUBLISH";
    public const string QuizNoQuestions = "PREP_QUIZ_NO_QUESTIONS";
    public const string ListingEndBeforeStart = "PREP_LISTING_END_BEFORE_START";
    public const string PreviewNotAvailable = "PREP_PREVIEW_NOT_AVAILABLE";
    public const string PreviewInvalidQuestion = "PREP_PREVIEW_INVALID_QUESTION";
    public const string PreviewInvalidAnswerOption = "PREP_PREVIEW_INVALID_ANSWER_OPTION";
    public const string ItemNotAvailable = "PREP_ITEM_NOT_AVAILABLE";
    public const string OfferNotFound = "PREP_OFFER_NOT_FOUND";
    public const string OfferIsFree = "PREP_OFFER_IS_FREE";
    public const string PayPalPurchaseNotFound = "PREP_PAYPAL_PURCHASE_NOT_FOUND";
    public const string MobilePlatformInvalid = "PREP_MOBILE_PLATFORM_INVALID";
    public const string StoreProductMismatch = "PREP_STORE_PRODUCT_MISMATCH";
    public const string OfferNoLongerExists = "PREP_OFFER_NO_LONGER_EXISTS";
    public const string InvalidProductCode = "PREP_INVALID_PRODUCT_CODE";
    public const string GooglePlayNotConfigured = "PREP_GOOGLE_PLAY_NOT_CONFIGURED";
    public const string AppStoreNotConfigured = "PREP_APP_STORE_NOT_CONFIGURED";
}
