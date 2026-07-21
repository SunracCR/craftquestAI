/// Estimates how many typical AI quiz generations fit in a credit balance.
///
/// Reference: ~40 questions from a small document costs 6 credits
/// (2 base + ceil(40/10) × 1, no page surcharge).
abstract final class AiGenerationAllowance {
  static const int referenceCreditsPerGeneration = 6;

  static int estimateGenerations(int credits) {
    if (credits <= 0) {
      return 0;
    }
    return credits ~/ referenceCreditsPerGeneration;
  }
}
