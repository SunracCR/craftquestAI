/// Client-side mirrors of server [AiGenerationOptions] for upload UX.
abstract final class AiGenerationLimits {
  static const int maxPagesPerMaterial = 120;
  static const int maxUploadMb = 25;
  static const int retentionDays = 3;

  /// Pages above this add +1 credit surcharge (aligned with backend AiOptions).
  static const int creditsSurchargeMediumDocumentPages = 20;

  /// Pages above this add +2 credit surcharge.
  static const int creditsSurchargeLargeDocumentPages = 60;

  static int documentSizeSurcharge(int pageCount) {
    if (pageCount > creditsSurchargeLargeDocumentPages) return 2;
    if (pageCount > creditsSurchargeMediumDocumentPages) return 1;
    return 0;
  }

  static int previewGenerationCredits(int questionCount, int pageCount) =>
      2 + (questionCount / 10).ceil() + documentSizeSurcharge(pageCount);
}
