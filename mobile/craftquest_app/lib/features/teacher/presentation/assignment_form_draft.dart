/// Instantánea del formulario de asignación mientras se crea un cuestionario.
class AssignmentFormDraft {
  const AssignmentFormDraft({
    required this.title,
    required this.instructions,
    required this.maxAttempts,
    required this.startsAt,
    required this.dueAt,
    required this.showAnswersMode,
    this.selectedQuizId,
  });

  final String title;
  final String instructions;
  final String maxAttempts;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final String showAnswersMode;
  final String? selectedQuizId;
}
