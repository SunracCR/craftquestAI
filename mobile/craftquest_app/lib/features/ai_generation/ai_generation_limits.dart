/// Debe coincidir con `AiGeneration` en appsettings.json del API.
abstract final class AiGenerationLimits {
  static const int maxPagesPerMaterial = 120;
  static const int maxPagesPerGeneration = 30;
  static const int maxUploadMb = 25;
  static const int retentionDays = 3;
}
