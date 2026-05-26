// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'CraftQuest';

  @override
  String get homeWelcome => 'Bienvenido a CraftQuest';

  @override
  String homeWelcomeUser(String name) {
    return 'Hola, $name';
  }

  @override
  String homeRoleLabel(String role) {
    return 'Rol: $role';
  }

  @override
  String get roleUnknown => 'sin rol';

  @override
  String get roleTeacherLabel => 'Profesor';

  @override
  String get roleStudentLabel => 'Estudiante';

  @override
  String get roleInstitutionAdminLabel => 'Admin institución';

  @override
  String get roleContentAdminLabel => 'Admin contenido';

  @override
  String get roleSuperAdminLabel => 'Superadmin';

  @override
  String get apiStatusLabel => 'Estado del API';

  @override
  String get apiStatusLoading => 'Conectando...';

  @override
  String get apiStatusError => 'No se pudo conectar al API';

  @override
  String get retry => 'Reintentar';

  @override
  String get noInternetBannerTitle => 'Sin conexión a internet';

  @override
  String get noInternetBannerMessage =>
      'Puedes seguir navegando, pero los datos no se actualizarán hasta que vuelva la red.';

  @override
  String get noInternetSnackBarMessage =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get genericRequestErrorMessage =>
      'No se pudo completar la solicitud. Inténtalo de nuevo en unos momentos.';

  @override
  String get errorHttpMethodNotAllowed =>
      'El servidor no admite esta operación. Reinicia la API e inténtalo de nuevo.';

  @override
  String errorQuestionLimitReached(int max, String plan) {
    return 'Has alcanzado el límite de $max preguntas por cuestionario en tu plan $plan.';
  }

  @override
  String errorQuizLimitReached(int max, String plan) {
    return 'Has alcanzado el límite de $max cuestionarios en tu plan $plan.';
  }

  @override
  String get billingPlanFreeName => 'Gratis';

  @override
  String get billingPlanProName => 'Pro';

  @override
  String get billingPlanPremiumName => 'Premium';

  @override
  String get billingPlanTeacherName => 'Profesor';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginSubtitle =>
      'Accede gratis a tu cuenta CraftQuest — entra o regístrate en segundos';

  @override
  String get loginAction => 'Entrar';

  @override
  String get loginRememberCredentials => 'Recordar usuario y contraseña';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerAction => 'Registrarse';

  @override
  String get goToRegister => '¿No tienes cuenta? Regístrate';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get displayNameLabel => 'Nombre para mostrar';

  @override
  String get fieldRequired => 'Este campo es obligatorio';

  @override
  String get passwordMinLength => 'Mínimo 8 caracteres';

  @override
  String get logoutAction => 'Cerrar sesión';

  @override
  String get navHomeLabel => 'Inicio';

  @override
  String get navProfileLabel => 'Perfil';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get selectAvatarTitle => 'Tu avatar';

  @override
  String get profileChangeAvatarAction => 'Cambiar avatar';

  @override
  String get profileEditNameAction => 'Editar nombre';

  @override
  String get profileNameUpdatedMessage => 'Nombre actualizado';

  @override
  String get profileNameInvalidMessage =>
      'Introduce un nombre entre 1 y 160 caracteres.';

  @override
  String get profileSaveAction => 'Guardar';

  @override
  String get profileAvatarPickerHint =>
      'Toca un icono para actualizar tu perfil';

  @override
  String get avatarUpdatedMessage => 'Avatar actualizado';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get languageUpdatedMessage => 'Idioma actualizado';

  @override
  String get securitySectionTitle => 'Seguridad';

  @override
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get changePasswordAction => 'Guardar contraseña';

  @override
  String get currentPasswordLabel => 'Contraseña actual';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get passwordChangedMessage => 'Contraseña actualizada';

  @override
  String get myQuizzesAction => 'Mis cuestionarios';

  @override
  String get quizzesTitle => 'Cuestionarios';

  @override
  String get quizzesEmpty => 'Aún no tienes cuestionarios';

  @override
  String get quizzesLoadError => 'No se pudieron cargar los cuestionarios';

  @override
  String get createQuizAction => 'Crear cuestionario';

  @override
  String get createQuizTitle => 'Nuevo cuestionario';

  @override
  String get createQuizNextStepTitle => 'Añade preguntas a tu cuestionario';

  @override
  String get createQuizNextStepSubtitle =>
      'Empieza creando una pregunta, importa desde un archivo o genera con IA.';

  @override
  String get createQuizAddQuestionsManually => 'Crear preguntas manualmente';

  @override
  String get createQuizImportQuestions => 'Importar preguntas';

  @override
  String get createQuizSkipQuestionsSetup => 'Hacerlo después';

  @override
  String get quizTitleLabel => 'Título';

  @override
  String get quizTitleTapToEdit => 'Toca el título para editarlo';

  @override
  String get quizDescriptionLabel => 'Descripción (opcional)';

  @override
  String quizListSubtitle(String status, int count) {
    return '$status · $count preguntas';
  }

  @override
  String get quizStatusDraft => 'Borrador';

  @override
  String get quizStatusPublished => 'Publicado';

  @override
  String get quizDetailTitle => 'Detalle del cuestionario';

  @override
  String get quizDetailImportAiDraftAction =>
      'Importar preguntas generadas por IA';

  @override
  String quizDetailImportAiDraftBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas generadas por IA listas para importar',
      one: '1 pregunta generada por IA lista para importar',
    );
    return '$_temp0';
  }

  @override
  String get quizListPendingAiDraft => 'Borrador IA listo para importar';

  @override
  String get addQuestionAction => 'Añadir pregunta';

  @override
  String get viewQuizQuestionsAction => 'Ver preguntas';

  @override
  String get publishQuizAction => 'Publicar';

  @override
  String get quizPublishedMessage => 'Cuestionario publicado';

  @override
  String get deleteQuizAction => 'Eliminar cuestionario';

  @override
  String get deleteQuizConfirmTitle => '¿Eliminar cuestionario?';

  @override
  String deleteQuizConfirmMessage(String title) {
    return 'Se eliminará \"$title\" y todas sus preguntas. Esta acción no se puede deshacer.';
  }

  @override
  String get quizDeletedMessage => 'Cuestionario eliminado';

  @override
  String get questionsEmpty => 'Sin preguntas todavía';

  @override
  String get quizDetailQuestionsSection => 'Preguntas del cuestionario';

  @override
  String quizQuestionsCount(int count) {
    return '$count preguntas';
  }

  @override
  String quizDetailOptionCount(int count) {
    return '$count opciones';
  }

  @override
  String quizDetailCorrectKeys(String keys) {
    return 'Respuesta correcta: $keys';
  }

  @override
  String quizDetailCorrectKeysPlural(String keys) {
    return 'Respuestas correctas: $keys';
  }

  @override
  String get questionTypeLabelSingleChoice => 'Selección única';

  @override
  String get questionTypeLabelMultipleChoice => 'Selección múltiple';

  @override
  String get questionTypeLabelTrueFalse => 'Falso / Verdadero';

  @override
  String get questionTypeLabelImageChoice => 'Opciones con imagen';

  @override
  String get questionTypeLabelImageBased => 'Basada en imagen';

  @override
  String questionListIndexLabel(int index) {
    return 'P$index';
  }

  @override
  String get editQuestionAction => 'Editar';

  @override
  String get deleteQuestionAction => 'Eliminar';

  @override
  String get editQuestionTitle => 'Editar pregunta';

  @override
  String get deleteQuestionConfirmTitle => '¿Eliminar pregunta?';

  @override
  String get deleteQuestionConfirmMessage =>
      'La pregunta se quitará del cuestionario. Esta acción no se puede deshacer.';

  @override
  String get questionDeletedMessage => 'Pregunta eliminada';

  @override
  String get questionSavedMessage => 'Pregunta guardada';

  @override
  String get addQuestionTitle => 'Nueva pregunta';

  @override
  String get questionTypeLabel => 'Tipo de pregunta';

  @override
  String get questionTextLabel => 'Enunciado';

  @override
  String get questionPointsLabel => 'Puntos';

  @override
  String get questionPointsHint =>
      'Puntaje si se responde bien (solo esta pregunta)';

  @override
  String questionPointsValue(String points) {
    return '$points pts';
  }

  @override
  String get questionInvalidPoints => 'Los puntos deben ser mayores que 0';

  @override
  String answerOptionLabel(String key) {
    return 'Opción $key';
  }

  @override
  String get correctAnswerKeyLabel => 'Respuesta correcta (key)';

  @override
  String get saveQuestionAction => 'Guardar pregunta';

  @override
  String get trueLabel => 'Verdadero';

  @override
  String get falseLabel => 'Falso';

  @override
  String get minTwoOptions => 'Indica al menos dos opciones';

  @override
  String get questionImageLabel => 'Imagen del enunciado';

  @override
  String get correctAnswersLabel => 'Respuestas correctas';

  @override
  String get selectCorrectAnswersHint =>
      'Selecciona una o más opciones correctas';

  @override
  String get imageChoiceHint =>
      'Adjunta una imagen en al menos una opción de respuesta';

  @override
  String get imageBasedQuestionHint =>
      'Sube la imagen o diagrama que acompaña el enunciado';

  @override
  String get requireQuestionImage =>
      'La pregunta basada en imagen requiere una imagen';

  @override
  String get requireOptionImage => 'Añade al menos una imagen en las opciones';

  @override
  String get selectAtLeastOneCorrect => 'Marca al menos una respuesta correcta';

  @override
  String correctIdsLabel(int count) {
    return '$count respuesta(s) correcta(s) por ID';
  }

  @override
  String get practiceOptionsTitle => 'Parámetros de práctica';

  @override
  String get practiceRandomizeQuestionsLabel => 'Orden aleatorio de preguntas';

  @override
  String get practiceRandomizeQuestionsHint =>
      'Las preguntas se muestran en un orden distinto en cada práctica';

  @override
  String get practiceShowTimerLabel => 'Mostrar tiempo transcurrido';

  @override
  String get practiceShowTimerHint =>
      'Muestra un reloj mientras respondes el cuestionario';

  @override
  String practiceElapsedLabel(String elapsed) {
    return 'Tiempo: $elapsed';
  }

  @override
  String get practiceDurationLabel => 'Tiempo empleado';

  @override
  String get practiceQuizAction => 'Practicar';

  @override
  String get practiceSessionTitle => 'Sesión de práctica';

  @override
  String practiceProgressLabel(int answered, int total) {
    return '$answered de $total respondidas';
  }

  @override
  String practiceProgressCompletedLabel(int done, int total) {
    return '$done de $total completadas';
  }

  @override
  String get practiceNavigateQuestionsLabel => 'Preguntas';

  @override
  String get practiceOpenQuestionMapAction => 'Mapa';

  @override
  String get practiceMapTitle => 'Mapa de preguntas';

  @override
  String get practiceMapFilterAll => 'Todas';

  @override
  String get practiceMapFilterPending => 'Pendientes';

  @override
  String get practiceMapFilterCompleted => 'Hechas';

  @override
  String get practiceMapEmptyFilter => 'No hay preguntas con este filtro';

  @override
  String get practiceNavLegendAnswered => 'Respondida';

  @override
  String get practiceNavLegendPending => 'Pendiente';

  @override
  String get practiceNavLegendCurrent => 'Actual';

  @override
  String practiceQuestionNavTooltip(int number) {
    return 'Pregunta $number';
  }

  @override
  String get practicePreviousQuestionAction => 'Anterior';

  @override
  String get practiceQuestionAnsweredLabel => 'Ya respondida';

  @override
  String get practiceUpdateAnswerAction => 'Actualizar respuesta';

  @override
  String get practiceAnswerEditHint =>
      'Puedes cambiar tu respuesta y pulsar Actualizar respuesta';

  @override
  String get practiceSavingAnswerHint => 'Guardando tu respuesta…';

  @override
  String practiceQuestionCounter(int current, int total) {
    return 'Pregunta $current de $total';
  }

  @override
  String get practiceSelectAnswer => 'Selecciona al menos una respuesta';

  @override
  String get practiceSubmitAnswerAction => 'Confirmar respuesta';

  @override
  String get practiceNextQuestionAction => 'Siguiente pregunta';

  @override
  String get practiceFinishAction => 'Finalizar práctica';

  @override
  String get practiceResumeTitle => 'Práctica en curso';

  @override
  String practiceResumeMessage(int answered, int total) {
    return 'Tienes una práctica guardada con $answered de $total preguntas respondidas. ¿Qué deseas hacer?';
  }

  @override
  String get practiceContinueAction => 'Continuar';

  @override
  String get practiceStartNewAction => 'Empezar de nuevo';

  @override
  String get practiceSaveAndExitAction => 'Guardar y salir';

  @override
  String get practiceInProgressChip => 'Práctica en curso';

  @override
  String practiceInProgressSubtitle(int answered, int total) {
    return '$answered/$total respondidas';
  }

  @override
  String get practiceFinishEarlyAction => 'Finalizar ahora';

  @override
  String get practiceNoQuestions => 'Este cuestionario no tiene preguntas';

  @override
  String get practiceResultTitle => 'Resultado';

  @override
  String practicePercentageLabel(double percentage) {
    return '$percentage%';
  }

  @override
  String practiceScoreLabel(double obtained, double possible) {
    return 'Puntuación: $obtained / $possible';
  }

  @override
  String practiceCorrectLabel(int count) {
    return 'Correctas: $count';
  }

  @override
  String practiceIncorrectLabel(int count) {
    return 'Incorrectas: $count';
  }

  @override
  String get practiceViewResultsAction => 'Ver resultados';

  @override
  String get practiceReviewHiddenByAssignment =>
      'Tu profesor configuró esta asignación para no mostrar las respuestas correctas. Solo puedes ver tu puntuación general.';

  @override
  String practiceReviewHiddenUntilDue(String date) {
    return 'Las respuestas correctas estarán disponibles después de la fecha límite ($date). Por ahora solo puedes ver tu puntuación general.';
  }

  @override
  String get practiceReviewHiddenUntilDueNoDate =>
      'Las respuestas correctas estarán disponibles después de la fecha límite. Por ahora solo puedes ver tu puntuación general.';

  @override
  String get practiceReviewHiddenTeacherOnly =>
      'Solo tu profesor puede ver las respuestas correctas. Puedes consultar tu puntuación general.';

  @override
  String get practiceBackHomeAction => 'Volver al inicio';

  @override
  String get importQuestionsAction => 'Importar preguntas';

  @override
  String get importQuestionsTitle => 'Importar preguntas';

  @override
  String get importExcelAction => 'Importar desde Excel';

  @override
  String get excelImportTitle => 'Importar Excel';

  @override
  String get excelImportSubtitle =>
      'Sube un archivo .xlsx con tus preguntas. Revisarás una vista previa antes de confirmar.';

  @override
  String get excelImportColumnsHint =>
      'Columnas: Pregunta, Tipo (incluye image_choice e image_based_question sin archivos de imagen), Opción A–E, Respuesta correcta (ej. B o A|C), Puntos y Sección (opcionales). Las imágenes se añaden después en la app.';

  @override
  String get excelImportDownloadTemplate => 'Descargar plantilla Excel';

  @override
  String get excelImportTemplateReady =>
      'Plantilla lista para guardar o compartir';

  @override
  String get excelImportTemplateFailed => 'No se pudo descargar la plantilla';

  @override
  String get excelImportDropHint => 'Arrastra tu archivo .xlsx aquí';

  @override
  String get excelImportDropSubhint =>
      'O elige un archivo desde tu dispositivo';

  @override
  String get excelImportPickFile => 'Elegir archivo';

  @override
  String get excelImportUploadAction => 'Subir y revisar';

  @override
  String get excelImportOnlyXlsx => 'Solo se admiten archivos .xlsx';

  @override
  String get excelImportFileTooLarge => 'El archivo supera el límite de 5 MB';

  @override
  String get excelImportReadFailed => 'No se pudo leer el archivo seleccionado';

  @override
  String get excelImportSelectFileFirst =>
      'Selecciona un archivo Excel primero';

  @override
  String get excelImportColumnsTitle => 'Formato de columnas';

  @override
  String get excelImportTemplateSection => 'Paso 1 · Plantilla';

  @override
  String get excelImportUploadSection => 'Paso 2 · Tu archivo';

  @override
  String get excelImportFileReady => 'Archivo listo para importar';

  @override
  String get excelImportChangeFile => 'Cambiar archivo';

  @override
  String get importImageMediaPending =>
      'Las imágenes no se importan desde el archivo. Podrás añadirlas después en la app al editar la pregunta.';

  @override
  String get importImagePendingBadge => 'Imagen pendiente en la app';

  @override
  String get importFormatLabel => 'Formato';

  @override
  String get importFormatJson => 'CQIF JSON';

  @override
  String get importFormatTxt => 'TXT CraftQuest';

  @override
  String get importContentLabel => 'Contenido';

  @override
  String get importContentHint => 'Pega aquí el JSON CQIF v2 o el archivo TXT';

  @override
  String get importContentRequired => 'Pega el contenido a importar';

  @override
  String get importProcessAction => 'Procesar importación';

  @override
  String get importNoValidQuestions => 'No hay preguntas válidas para importar';

  @override
  String get importPreviewTitle => 'Vista previa';

  @override
  String importSummaryLabel(int valid, int total, int errors) {
    return '$valid válidas de $total ($errors con error)';
  }

  @override
  String importErrorLine(int row, String message) {
    return 'Fila $row: $message';
  }

  @override
  String importQuestionTypeLabel(String type) {
    return 'Tipo: $type';
  }

  @override
  String importAnswerLine(String key, String text, String correct) {
    return '$key: $text$correct';
  }

  @override
  String get importConfirmAction => 'Confirmar e importar';

  @override
  String importConfirmSuccess(int count) {
    return '$count preguntas importadas';
  }

  @override
  String importPlanLimitPreviewNotice(
    String plan,
    int max,
    int current,
    int importable,
    int total,
  ) {
    return 'Tu plan $plan permite hasta $max preguntas por cuestionario (ya tienes $current). Solo se importarán $importable de $total del archivo.';
  }

  @override
  String importConfirmDisabledQuizFull(int current, int max) {
    return 'No puedes importar más preguntas: este cuestionario ya tiene $current y el límite del plan es $max por cuestionario.';
  }

  @override
  String importPlanLimitConfirmNotice(
    int imported,
    String plan,
    int max,
    int skipped,
  ) {
    return 'Se importaron $imported preguntas. En el plan $plan el máximo es $max por cuestionario; $skipped preguntas del archivo no se añadieron.';
  }

  @override
  String get teacherAttemptsAction => 'Ver intentos';

  @override
  String get teacherAttemptsTitle => 'Intentos de práctica';

  @override
  String get teacherAttemptsEmpty => 'Aún no hay intentos finalizados';

  @override
  String get teacherAttemptsFilterLabel => 'Estudiante';

  @override
  String get teacherAttemptsFilterAll => 'Todos los estudiantes';

  @override
  String get teacherAttemptsFilterEmpty =>
      'No hay intentos para este estudiante';

  @override
  String teacherAttemptsStudentsSummary(int students, int attempts) {
    return '$students estudiantes · $attempts intentos';
  }

  @override
  String get teacherAttemptsAttemptCountOne => '1 intento';

  @override
  String teacherAttemptsAttemptCountMany(int count) {
    return '$count intentos';
  }

  @override
  String teacherAttemptRowTitle(String date) {
    return '$date';
  }

  @override
  String teacherAttemptTitle(String name, String date) {
    return '$name · $date';
  }

  @override
  String teacherAttemptSubtitle(
    double obtained,
    double possible,
    String percent,
    String status,
  ) {
    return '$obtained/$possible ($percent%) · $status';
  }

  @override
  String teacherAttemptSubtitleWithDuration(String stats, String duration) {
    return '$stats · $duration';
  }

  @override
  String get teacherReviewTitle => 'Revisión del intento';

  @override
  String teacherReviewStudentLabel(String name) {
    return 'Estudiante: $name';
  }

  @override
  String teacherReviewScoreLabel(double obtained, double possible) {
    return 'Puntuación: $obtained / $possible';
  }

  @override
  String teacherReviewQuestionLabel(int order, String text) {
    return '$order. $text';
  }

  @override
  String teacherReviewAnswerStatus(
    String status,
    double awarded,
    double possible,
  ) {
    return '$status · $awarded/$possible pts';
  }

  @override
  String billingPlanLabel(String plan) {
    return 'Plan: $plan';
  }

  @override
  String get billingPlanChipLabel => 'Plan';

  @override
  String billingUsageLabel(int quizzes, String maxQuizzes) {
    return 'Cuestionarios: $quizzes/$maxQuizzes';
  }

  @override
  String get billingQuizzesUnlimited => 'Cuestionarios: Ilimitados';

  @override
  String billingCreditsLabel(int credits) {
    return 'Créditos IA este mes: $credits';
  }

  @override
  String get redeemCodeAction => 'Canjear código';

  @override
  String get redeemCodeTitle => 'Canjear código de acceso';

  @override
  String get redeemCodeSubtitle =>
      'Introduce el código compartido por tu profesor o compañero';

  @override
  String get redeemCodeLabel => 'Código';

  @override
  String get redeemCodeRequired => 'Introduce un código';

  @override
  String redeemCodeSuccess(String title) {
    return 'Acceso concedido a \"$title\"';
  }

  @override
  String redeemCodeAlreadyInShared(String title) {
    return 'Ya tienes «$title» en Mis compartidos.';
  }

  @override
  String get accessibleQuizzesAction => 'Cuestionarios compartidos';

  @override
  String get accessibleQuizzesTitle => 'Cuestionarios compartidos';

  @override
  String get accessibleQuizzesEmpty =>
      'No tienes cuestionarios compartidos. Canjea un código.';

  @override
  String accessibleQuizzesSharedBy(String name) {
    return 'Compartido por $name';
  }

  @override
  String accessibleQuizzesGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuestionarios',
      one: '1 cuestionario',
    );
    return '$_temp0';
  }

  @override
  String get accessibleQuizzesRemoveAction => 'Quitar de compartidos';

  @override
  String get accessibleQuizzesRemoveConfirmTitle => '¿Quitar de compartidos?';

  @override
  String accessibleQuizzesRemoveConfirmMessage(String title) {
    return 'Se quitará «$title» de tu lista. El cuestionario no se borra; puedes volver a canjearlo con el código si lo necesitas.';
  }

  @override
  String get accessibleQuizzesRemovedMessage =>
      'Cuestionario quitado de compartidos';

  @override
  String accessibleQuizzesSlotBanner(int current, int max) {
    return 'Cuestionarios compartidos: $current/$max';
  }

  @override
  String get accessibleQuizzesSlotFull =>
      'Cupo completo en plan Free. Quita uno para canjear otro código.';

  @override
  String errorSharedQuizSlotLimit(int max) {
    return 'Tu plan Free permite $max cuestionarios compartidos. Quita uno de Mis compartidos para canjear otro.';
  }

  @override
  String get errorCannotRedeemOwnQuiz =>
      'No puedes canjear el código de un cuestionario que tú creaste. Ábrelo desde Mis cuestionarios.';

  @override
  String get shareCodeViewAction => 'Ver código';

  @override
  String get shareCodeExistingHint =>
      'Este es el código permanente de este cuestionario.';

  @override
  String get myQuizAnalyticsAction => 'Mi analítica';

  @override
  String get myQuizAnalyticsTitle => 'Mi analítica de práctica';

  @override
  String get myPracticeAttemptsAction => 'Mis intentos';

  @override
  String get myPracticeAttemptsTitle => 'Mis intentos de práctica';

  @override
  String get myPracticeAttemptsEmpty =>
      'Aún no has completado ningún intento en este cuestionario.';

  @override
  String get myPracticeReviewTitle => 'Revisión de mi intento';

  @override
  String myQuizAnalyticsAttemptsLabel(int count) {
    return '$count intentos completados';
  }

  @override
  String myQuizAnalyticsAverageLabel(double percentage) {
    return 'Promedio: $percentage%';
  }

  @override
  String myQuizAnalyticsBestLabel(double percentage) {
    return 'Mejor: $percentage%';
  }

  @override
  String get createShareCodeAction => 'Generar código';

  @override
  String get shareCodeTitle => 'Código de acceso';

  @override
  String get shareCodeCreateTitle => 'Compartir cuestionario';

  @override
  String get shareCodeCreateTeacherSubtitle =>
      'Elige si cualquiera puede practicar o solo tu grupo.';

  @override
  String get shareCodeCreateStudentSubtitle =>
      'Se generará un código para que muchas personas practiquen (sin ver intentos ajenos).';

  @override
  String get shareCodeAudienceAnyone => 'Cualquiera';

  @override
  String get shareCodeAudienceAnyoneHint =>
      'Con o sin cuenta. Mismo código para todos.';

  @override
  String get shareCodeAudienceGroup => 'Solo mi grupo';

  @override
  String get shareCodeAudienceGroupHint =>
      'Solo estudiantes de la clase que elijas (requieren cuenta).';

  @override
  String get shareCodeSelectClassLabel => 'Clase';

  @override
  String shareCodeClassOption(String name, int count) {
    return '$name ($count estudiantes)';
  }

  @override
  String get shareCodeNoClasses =>
      'Aún no tienes clases. Crea una clase para compartir solo con tu grupo.';

  @override
  String get shareCodeGroupRequired =>
      'Selecciona una clase para compartir con el grupo.';

  @override
  String get shareCodeResultOpenHint =>
      'Válido para muchas personas. También sirve en «Practicar con código» sin cuenta.';

  @override
  String get shareCodeResultGroupHint =>
      'Solo miembros de la clase seleccionada, con cuenta.';

  @override
  String get shareCodeCopyAction => 'Copiar';

  @override
  String get shareCodeCopied => 'Código copiado';

  @override
  String get shareCodeCloseAction => 'Cerrar';

  @override
  String get quizInviteTitle => 'Invitar personas';

  @override
  String get quizInviteSubtitle =>
      'La persona debe tener cuenta en CraftQuest. Aparecerá el cuestionario en Mis compartidos (sin código).';

  @override
  String get quizInviteEmailsLabel => 'Correos';

  @override
  String get quizInviteEmailsHint => 'uno@correo.com, otro@correo.com';

  @override
  String get quizInviteAction => 'Invitar';

  @override
  String get quizInviteEmailsRequired => 'Introduce al menos un correo válido.';

  @override
  String quizInviteSuccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas invitadas',
      one: '1 persona invitada',
    );
    return '$_temp0';
  }

  @override
  String quizInviteOutcomeInvited(String name) {
    return '$name: invitado/a';
  }

  @override
  String quizInviteOutcomeAlreadyHadAccess(String name) {
    return '$name: ya tenía acceso';
  }

  @override
  String quizInviteOutcomeNotFound(String email) {
    return '$email: no hay cuenta con ese correo';
  }

  @override
  String quizInviteOutcomeInvalidEmail(String email) {
    return '$email: correo no válido';
  }

  @override
  String quizInviteOutcomeSlotLimit(String name) {
    return '$name: sin cupo en plan Free';
  }

  @override
  String get quizInviteOutcomeSelf => 'No puedes invitarte a ti mismo/a';

  @override
  String get errorDirectInviteNotAllowed =>
      'Las invitaciones directas requieren plan Pro o Profesor.';

  @override
  String get errorActivePracticeSession =>
      'Tienes una práctica en curso. Continúa o empieza de nuevo.';

  @override
  String get aiNormalizeAction => 'Normalizar con IA';

  @override
  String get aiImproveImportAction => 'Mejorar con IA';

  @override
  String get aiNormalizeSuccess => 'Normalización IA completada';

  @override
  String get quizAnalyticsAction => 'Analítica';

  @override
  String get quizAnalyticsTitle => 'Analítica del cuestionario';

  @override
  String quizAnalyticsSessionsLabel(int count) {
    return 'Intentos finalizados: $count';
  }

  @override
  String quizAnalyticsQuestionStats(int attempts, int correct, int incorrect) {
    return '$attempts intentos · $correct correctas · $incorrect incorrectas';
  }

  @override
  String quizAnalyticsOptionLabel(
    String key,
    String text,
    int count,
    double rate,
    String correct,
  ) {
    return '$key: $text — $count ($rate%)$correct';
  }

  @override
  String get attachImageAction => 'Adjuntar imagen';

  @override
  String get removeImageAction => 'Quitar imagen';

  @override
  String get viewFullImageAction => 'Ver imagen completa';

  @override
  String get closeAction => 'Cerrar';

  @override
  String get imageLoadError => 'No se pudo cargar la imagen';

  @override
  String get upgradePlanAction => 'Mejorar plan';

  @override
  String get upgradePlanTitle => 'Mejorar plan';

  @override
  String get upgradePlanSubtitle =>
      'Compara los planes y elige el que más te conviene.';

  @override
  String get upgradePlanAlreadyHighest =>
      'Ya tienes el plan más alto disponible. No hay más mejoras por ahora.';

  @override
  String get upgradeProHighlightQuizzes =>
      'Cuestionarios ilimitados (tu plan actual: máx. 5)';

  @override
  String get upgradeProHighlightQuestions =>
      'Sin límite de preguntas por cuestionario (tu plan actual: 65)';

  @override
  String get upgradeProHighlightAiCredits =>
      '150 créditos IA al mes (tu plan actual: 20)';

  @override
  String get upgradeProHighlightShared =>
      'Compartidos ilimitados al canjear o invitar';

  @override
  String get upgradeProHighlightDirectInvite =>
      'Invita a personas concretas por correo';

  @override
  String get upgradeTeacherHighlightIncludesPro => 'Todo lo incluido en Pro';

  @override
  String get upgradeTeacherHighlightAiCredits =>
      '360 créditos IA al mes para más generaciones';

  @override
  String get upgradeTeacherHighlightClasses => 'Clases y grupos de estudiantes';

  @override
  String get upgradeTeacherHighlightAssignments =>
      'Asignaciones con fechas, intentos y revisión';

  @override
  String get upgradeTeacherHighlightGroupShare =>
      'Comparte códigos solo con tu clase';

  @override
  String get upgradeTeacherHighlightTracking =>
      'Seguimiento de intentos y resultados por alumno';

  @override
  String get buyWithStoreAction => 'Comprar en la tienda';

  @override
  String get buyWithPayPalAction => 'Pagar con PayPal';

  @override
  String get paypalWebHint =>
      'En la web, PayPal es el método de pago recomendado.';

  @override
  String get paypalAwaitingCapture =>
      'Completa el pago en PayPal y confirma la captura.';

  @override
  String upgradeSuccess(String plan) {
    return 'Plan activado: $plan';
  }

  @override
  String get storeProductNotConfigured => 'Producto de tienda no configurado';

  @override
  String storeProductNotFound(String id) {
    return 'Producto no encontrado: $id';
  }

  @override
  String get purchaseFailed => 'La compra no se completó';

  @override
  String get purchaseVerificationFailed =>
      'No pudimos verificar tu compra. Inténtalo de nuevo en unos momentos.';

  @override
  String get contactSales => 'Contactar ventas';

  @override
  String get aiGenerationHubTitle => 'Generar con IA';

  @override
  String get aiGenerationHubSubtitle =>
      'Sube PDF o Word con texto seleccionable y crea un cuestionario revisable en minutos.';

  @override
  String get aiGenerationHubAction => 'Crear desde material';

  @override
  String get aiGenerationLibraryTitle => 'Biblioteca de materiales';

  @override
  String aiGenerationLibraryRetentionHint(int days) {
    return 'Los materiales se eliminan solos a los $days días. Puedes borrarlos antes con el icono de papelera.';
  }

  @override
  String aiGenerationLibraryExpiresOn(String date) {
    return 'Eliminación automática: $date';
  }

  @override
  String aiGenerationLibraryMaterialCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count materiales',
      one: '1 material',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerationLibraryStatusReady => 'Listo';

  @override
  String get aiGenerationLibraryStatusProcessing => 'Procesando';

  @override
  String get aiGenerationLibraryStatusFailed => 'Error';

  @override
  String get aiGenerationLibraryStatusPending => 'Pendiente';

  @override
  String aiGenerationLibraryUploaded(String date) {
    return 'Subido el $date';
  }

  @override
  String aiGenerationLibraryExpiresInDays(int days) {
    return 'Se elimina en $days días';
  }

  @override
  String get aiGenerationLibraryNeedsReview => 'Revisar texto';

  @override
  String get aiGenerationLibraryEmpty => 'Aún no tienes materiales guardados.';

  @override
  String get aiGenerationLibraryEmptySubtitle =>
      'Los PDF y Word que subas para generar con IA aparecerán aquí.';

  @override
  String get aiGenerationLibraryAction => 'Ver biblioteca';

  @override
  String get deleteStudyMaterialConfirmTitle => 'Eliminar material';

  @override
  String deleteStudyMaterialConfirmMessage(String title) {
    return 'Se eliminará \"$title\" y su texto extraído. El cuestionario generado se conservará. Esta acción no se puede deshacer.';
  }

  @override
  String get deleteStudyMaterialAction => 'Eliminar';

  @override
  String get studyMaterialDeletedMessage => 'Material eliminado';

  @override
  String get aiGenerationUploadTitle => 'Subir material';

  @override
  String get aiGenerationUploadSubtitle =>
      'Sube un PDF o Word con texto copiable. Revisarás el alcance de páginas antes de generar el cuestionario.';

  @override
  String get aiGenerationUploadHeroDrop => 'Arrastra tu PDF o Word aquí';

  @override
  String get aiGenerationUploadHeroPick =>
      'o elige un archivo desde tu dispositivo';

  @override
  String get aiGenerationUploadFormatGuideTitle =>
      'Consejos y límites de formato';

  @override
  String get aiGenerationUploadHint =>
      'PDF o DOCX con texto seleccionable, no escaneados (máx. 25 MB)';

  @override
  String aiGenerationUploadLimitsHint(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'Hasta $maxPagesPerFile páginas por archivo · hasta $maxPagesPerGeneration páginas por generación';
  }

  @override
  String aiGenerationUploadLimitsSteps(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'Si el documento es más largo, divídelo en varios archivos (cada uno con $maxPagesPerFile páginas o menos) o exporta solo el capítulo que necesitas. Después podrás generar el cuestionario por tramos de hasta $maxPagesPerGeneration páginas.';
  }

  @override
  String errorMaterialPageLimitGuidance(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'Qué puedes hacer: divide el PDF o Word en partes de $maxPagesPerFile páginas o menos (por capítulos o bloques) y súbelas por separado. En cada material, genera el quiz eligiendo hasta $maxPagesPerGeneration páginas a la vez.';
  }

  @override
  String get aiGenerationUploadAnotherFileAction => 'Subir otro archivo';

  @override
  String get aiGenerationDropHint => 'También puedes arrastrar archivos aquí';

  @override
  String get aiGenerationUploadAction => 'Subir y analizar';

  @override
  String get aiGenerationUploadFileReady => 'Archivo listo para subir';

  @override
  String get aiGenerationUploadChangeFile => 'Cambiar archivo';

  @override
  String get aiGenerationUploadRemoveFile => 'Quitar';

  @override
  String get aiGenerationProcessing => 'Analizando documento…';

  @override
  String get aiGenerationNeedsOcr =>
      'Poco texto detectado. Usa un PDF o Word con texto seleccionable, o revisa y pega el contenido.';

  @override
  String get aiGenerationReviewTextTitle => 'Revisar texto';

  @override
  String get aiGenerationReviewTextHint =>
      'El documento tiene poco texto extraíble. Corrige lo detectado o pega el contenido con texto seleccionable.';

  @override
  String get aiGenerationReviewTextSave => 'Guardar y continuar';

  @override
  String get aiGenerationReviewTextAction => 'Revisar texto';

  @override
  String get aiGenerationOutlineTitle => 'Alcance del material';

  @override
  String aiGenerationPageRange(int from, int to) {
    return 'Páginas $from–$to';
  }

  @override
  String aiGenerationPageRangeOfTotal(int from, int to, int total) {
    return 'Páginas $from–$to de $total';
  }

  @override
  String get aiGenerationPageRangeHelp =>
      'Elige qué páginas del documento usarán para generar el cuestionario. Arrastra cada extremo del control para acotar el tramo.';

  @override
  String aiGenerationPageRangeSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas en este tramo',
      one: '1 página en este tramo',
    );
    return '$_temp0';
  }

  @override
  String aiGenerationPageRangeOverLimit(int max) {
    return 'Máximo $max páginas por generación. Reduce el tramo seleccionado.';
  }

  @override
  String aiGenerationWordsInScopePurpose(int words) {
    return 'La IA generará preguntas a partir de aproximadamente $words palabras en ese tramo.';
  }

  @override
  String get aiGenerationTopicHint => 'Enfoque opcional (tema o apartado)';

  @override
  String aiGenerationWordsInScope(int words) {
    return '$words palabras en el alcance';
  }

  @override
  String get aiGenerationParamsTitle => 'Parámetros de generación';

  @override
  String aiGenerationMaterialLanguageNotice(String language) {
    return 'Las preguntas se generarán en $language según el idioma del material.';
  }

  @override
  String get aiGenerationPresetQuick => 'Repaso rápido';

  @override
  String get aiGenerationPresetStandard => 'Examen estándar';

  @override
  String get aiGenerationPresetDeep => 'Práctica profunda';

  @override
  String get aiGenerationQuestionCount => 'Número de preguntas';

  @override
  String aiGenerationQuestionCountOfMax(int count, int max) {
    return '$count de $max';
  }

  @override
  String get aiGenerationQuestionTypes => 'Tipos de pregunta';

  @override
  String get aiGenerationTypeSingleChoice => 'Opción única';

  @override
  String get aiGenerationTypeMultipleChoice => 'Opción múltiple';

  @override
  String get aiGenerationTypeTrueFalse => 'Verdadero / falso';

  @override
  String get aiGenerationDifficulty => 'Dificultad';

  @override
  String get aiGenerationDifficultyEasy => 'Fácil';

  @override
  String get aiGenerationDifficultyMedium => 'Media';

  @override
  String get aiGenerationDifficultyHard => 'Difícil';

  @override
  String get aiGenerationDifficultyMixed => 'Mixta';

  @override
  String aiGenerationCreditsCost(int credits, int available) {
    return 'Consumirá $credits créditos IA ($available disponibles)';
  }

  @override
  String get aiGenerationStartAction => 'Generar cuestionario';

  @override
  String get aiGenerationProgressTitle => 'Generando cuestionario';

  @override
  String get aiGenerationProgressSubtitle =>
      'La IA está creando preguntas a partir de tu material…';

  @override
  String get aiGenerationProgressDeferredRetry =>
      'El servicio de IA está saturado. Reintentaremos automáticamente en breve.';

  @override
  String aiGenerationProgressDeferredRetryMinutes(int minutes) {
    return 'Reintento automático en unos $minutes min. Puedes dejar esta pantalla abierta.';
  }

  @override
  String aiGenerationProgressAutoRetry(int attempt) {
    return 'Reintento automático $attempt en curso…';
  }

  @override
  String get aiGenerationCreditsNotConsumed =>
      'No se han descontado créditos de IA.';

  @override
  String get aiGenerationRetryAction => 'Reintentar generación';

  @override
  String get aiGenerationProgressTakingLong =>
      'Sigue en curso (puede tardar varios minutos). Si se interrumpió la API, reiníciala o pulsa Reintentar.';

  @override
  String get aiGenerationProgressStuck =>
      'La generación parece bloqueada en el servidor.';

  @override
  String get aiGenerationProgressStuckDetail =>
      'El trabajo lleva demasiado tiempo en «procesando» sin avanzar. Vuelve atrás y genera de nuevo; no se han descontado créditos si no terminó.';

  @override
  String get aiGenerationStuckGoBackAction => 'Volver y generar de nuevo';

  @override
  String get errorSessionExpired =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión e inténtalo de nuevo.';

  @override
  String get aiGenerationFailed => 'No se pudo generar el cuestionario';

  @override
  String get errorGenerationJobNotRetryable =>
      'Este trabajo de generación no se puede reintentar ahora.';

  @override
  String get errorGuestNotAllowed =>
      'Este código requiere una cuenta registrada. Crea una cuenta gratuita para continuar.';

  @override
  String errorGroupAccessDenied(String className) {
    return 'Este código es solo para miembros de la clase «$className».';
  }

  @override
  String get errorGroupAccessDeniedGeneric =>
      'Este código es solo para miembros de la clase del profesor.';

  @override
  String get errorAiGenerationInvalidOutput =>
      'La IA devolvió un formato inválido. Pulsa «Reintentar generación»; no se han descontado créditos.';

  @override
  String get aiGenerationFromQuizAction => 'Generar con IA desde material';

  @override
  String get importAiGeneratedBadge => 'Generada por IA';

  @override
  String get errorAiCreditsInsufficient =>
      'No tienes créditos IA suficientes para esta generación.';

  @override
  String get errorMaterialNeedsOcr =>
      'Hay poco texto extraíble. Usa PDF o Word con texto seleccionable, o revisa y pega el contenido.';

  @override
  String get errorMaterialNotSelectableText =>
      'Este archivo parece escaneado o sin texto seleccionable.';

  @override
  String get errorMaterialNotSelectableTextGuidance =>
      'Recomendaciones:\n• Abre el archivo y comprueba que puedes seleccionar y copiar párrafos (no solo hacer zoom).\n• Si es un escaneo: en Word, Archivo → Abrir el PDF y deja que reconozca el texto; revisa y guarda como DOCX.\n• Alternativa: OCR externo (Adobe, Google Drive), pega el texto en Word y súbelo como DOCX.\n• Exporta desde Word o Google Docs; evita PDFs hechos solo con fotos o «imprimir a imagen».\n• Vuelve a subir DOCX o PDF exportado desde Word con texto seleccionable.';

  @override
  String get errorMaterialNeedsOcrGuidance =>
      'Recomendaciones:\n• Usa un PDF o DOCX donde puedas seleccionar y copiar el texto.\n• Si el original es escaneado, conviértelo a Word con texto (ver pasos de OCR arriba) y súbelo como DOCX.\n• También puedes pegar el contenido en Word, guardar como DOCX y subir ese archivo.';

  @override
  String get errorMaterialTooLargeGuidance =>
      'Recomendaciones:\n• El límite es 25 MB por archivo.\n• Comprime imágenes embebidas en Word o exporta solo el capítulo que necesitas.\n• Divide el documento en varios archivos más pequeños si sigue siendo pesado.';

  @override
  String get aiGenerationUploadRecommendationsTitle => 'Recomendaciones';

  @override
  String get aiGenerationUploadSelectableTextHint =>
      'El PDF o Word debe permitir seleccionar y copiar texto. Los documentos escaneados no son válidos.';

  @override
  String get errorMaterialTooLarge =>
      'El archivo supera el tamaño máximo permitido.';

  @override
  String errorMaterialPageLimitExceeded(int maxPages) {
    return 'El documento supera el máximo de $maxPages páginas por archivo.';
  }

  @override
  String errorGenerationPageRangeExceeded(int maxPages) {
    return 'Solo puedes generar desde un máximo de $maxPages páginas por vez.';
  }

  @override
  String get errorGenerationScopeEmpty =>
      'No hay texto en el rango de páginas seleccionado.';

  @override
  String get errorGenerationAlreadyInProgress =>
      'Ya hay una generación en curso para este material.';

  @override
  String get errorAiNotConfigured =>
      'La generación con IA no está configurada en el servidor.';

  @override
  String get errorAiGeminiQuotaExhausted =>
      'Se agotaron los créditos de Gemini. Añade saldo en Google AI Studio (ai.google.dev) y vuelve a intentarlo.';

  @override
  String get errorAiGeminiModelUnavailable =>
      'El modelo de Gemini configurado ya no está disponible. Actualiza Ai:GeminiModel a gemini-2.5-flash y reinicia la API.';

  @override
  String get errorAiGeminiOverloaded =>
      'Gemini tiene mucha demanda ahora mismo. Espera unos minutos y vuelve a intentar la generación.';

  @override
  String get aiActivityTitle => 'Actividad IA';

  @override
  String get aiActivityAction => 'Actividad IA';

  @override
  String get aiActivityEmpty =>
      'No hay generaciones recientes. Al generar un cuestionario aparecerán aquí, aunque cierres la app.';

  @override
  String get aiActivityStatusDraftReady => 'Borrador listo';

  @override
  String get aiActivityStatusFailed => 'Error';

  @override
  String get aiActivityStatusCompleted => 'Completada';

  @override
  String get aiActivityReviewDraft =>
      'Toca para revisar e importar el borrador';

  @override
  String get aiActivityViewProgress => 'Toca para ver el progreso';

  @override
  String get aiActivityTapForDetails => 'Toca para ver el detalle';

  @override
  String get aiActivityUnknownMaterial => 'Material';

  @override
  String aiActivityPagesRange(int from, int to) {
    return 'Páginas $from–$to';
  }

  @override
  String get aiLibraryStatusDraftReady => 'Borrador listo';

  @override
  String get aiGenerationBackgroundSnack =>
      'Generación en segundo plano. Puedes salir; retómala en Actividad IA o en la biblioteca.';

  @override
  String get aiGenerationResumedSnack =>
      'Ya había una generación en curso para este material. Mostrando su progreso.';

  @override
  String aiGenerationProgressPercent(int percent) {
    return '$percent % completado';
  }

  @override
  String get aiJobStageQueued => 'En cola';

  @override
  String get aiJobStagePreparing => 'Preparando material';

  @override
  String get aiJobStageOutlining => 'Planificando temas';

  @override
  String get aiJobStageGenerating => 'Generando preguntas';

  @override
  String get aiJobStageMerging => 'Combinando resultados';

  @override
  String get aiJobStageValidating => 'Validando preguntas';

  @override
  String get aiJobStageImporting => 'Preparando borrador';

  @override
  String get aiJobStageCompleted => 'Completada';

  @override
  String get aiJobStageFailed => 'Error';

  @override
  String get aiActivityClearHistoryAction => 'Limpiar historial';

  @override
  String get aiActivityClearHistoryTitle => '¿Limpiar historial?';

  @override
  String get aiActivityClearHistoryMessage =>
      'Se quitarán las generaciones completadas y los errores antiguos. Se conservan las que están en curso y los borradores pendientes de revisar.';

  @override
  String aiActivityClearHistoryDone(int count) {
    return 'Se eliminaron $count entradas del historial.';
  }

  @override
  String get aiActivityClearHistoryNothing => 'No había entradas que limpiar.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get practiceStatusInProgress => 'En curso';

  @override
  String get guestCodeTitle => 'Practicar con código';

  @override
  String get guestCodeSubtitle =>
      'Introduce el código que te compartió tu profesor para practicar sin crear cuenta.';

  @override
  String get guestCodeAction => 'Empezar';

  @override
  String get guestCodeLabel => 'Código';

  @override
  String get guestCodeRequired => 'Introduce un código';

  @override
  String get guestCodePasteTooltip => 'Pegar';

  @override
  String get guestEphemeralNotice =>
      'Esta sesión es temporal. Al salir se borra todo.';

  @override
  String get guestPracticeWithCodeAction => 'Practicar con código';

  @override
  String get guestShellFreeBadge => 'Gratis';

  @override
  String get guestShellHeroHint =>
      'Practica ahora. Regístrate gratis para guardar tu progreso y desbloquear más.';

  @override
  String get guestShellSessionBadge => 'Sin cuenta';

  @override
  String get guestPracticeOptions => 'Opciones de práctica';

  @override
  String get guestStartPracticeAction => 'Practicar';

  @override
  String get guestAttemptsTitle => 'En esta visita';

  @override
  String get guestAttemptsEmpty =>
      'Todavía no has practicado en esta visita. ¡Empieza ahora!';

  @override
  String get guestLeaveAction => 'Salir';

  @override
  String get guestLeaveConfirmTitle => '¿Salir de la visita?';

  @override
  String get guestLeaveConfirmMessage =>
      'Se borrarán todos los intentos de esta visita. Esta acción no se puede deshacer.';

  @override
  String get guestRegisterAction => 'Crear cuenta gratis';

  @override
  String get guestTryAgainAction => 'Volver a practicar';

  @override
  String get guestResultStatCorrect => 'Correctas';

  @override
  String get guestResultStatIncorrect => 'Incorrectas';

  @override
  String get guestViewResultsAction => 'Ver resultados';

  @override
  String get guestTimerRegisteredOnlyHint =>
      'Solo para usuarios registrados. Crear cuenta es gratis.';

  @override
  String get guestRegisterCtaTitle => '¿Quieres guardar tus resultados?';

  @override
  String get guestRegisterBenefit1 =>
      'Historial permanente de todos tus intentos';

  @override
  String get guestRegisterBenefit2 => 'Crea tus propios cuestionarios con IA';

  @override
  String get guestRegisterBenefit3 =>
      'Plan Free: 5 cuestionarios y 20 créditos IA, gratis';

  @override
  String get guestExitPracticeTitle => '¿Salir de la práctica?';

  @override
  String get guestExitPracticeMessage =>
      'El progreso de esta sesión no se perderá: podrás reanudarla al volver.';

  @override
  String get guestExitPracticeConfirm => 'Salir';

  @override
  String get teacherTabLabel => 'Profesor';

  @override
  String get teacherDashboardTitle => 'Panel';

  @override
  String get teacherDashboardTotalStudents => 'Estudiantes';

  @override
  String get teacherDashboardActiveClasses => 'Clases';

  @override
  String get teacherDashboardPublishedQuizzes => 'Quizzes';

  @override
  String get teacherDashboardSessionsThisWeek => 'Esta semana';

  @override
  String get teacherDashboardActivityFeedTitle => 'Actividad reciente';

  @override
  String get teacherDashboardInsightsTitle => 'Análisis';

  @override
  String get teacherDashboardEmptyFeed =>
      'Aún sin actividad. ¡Comparte un quiz con tus estudiantes!';

  @override
  String get teacherDashboardEmptyInsights =>
      'Sin análisis aún. Vuelve cuando tus estudiantes empiecen a practicar.';

  @override
  String get teacherDashboardInventoryStudents => 'Estudiantes';

  @override
  String get teacherDashboardInventoryClasses => 'Clases';

  @override
  String get teacherDashboardInventoryQuizzes => 'Quizzes';

  @override
  String get teacherDashboardUrgentTitle => 'Requiere atención';

  @override
  String get teacherDashboardUrgentEmpty => 'No hay tareas urgentes por ahora.';

  @override
  String teacherDashboardUrgentDueLabel(String date) {
    return 'Vence $date';
  }

  @override
  String teacherDashboardUrgentPendingLabel(int pending, int total) {
    return '$pending de $total sin entregar';
  }

  @override
  String teacherDashboardActiveStudentsWeek(int count) {
    return 'Alumnos activos esta semana: $count';
  }

  @override
  String teacherInsightHighError(String errorRate, String questionText) {
    return 'Una pregunta tiene $errorRate% de errores: $questionText';
  }

  @override
  String teacherInsightMostActive(
    int sessionCount,
    int studentCount,
    String quizTitle,
  ) {
    return '$sessionCount prácticas esta semana ($studentCount alumnos) · $quizTitle';
  }

  @override
  String get teacherAssignmentAnalyticsTitle => 'Analítica de la tarea';

  @override
  String get teacherAssignmentAnalyticsAction => 'Ver analítica';

  @override
  String get teacherAssignmentAnalyticsRosterTitle => 'Alumnos';

  @override
  String get teacherAssignmentAnalyticsHardQuestionsTitle =>
      'Preguntas difíciles';

  @override
  String get teacherAssignmentAnalyticsDistributionTitle =>
      'Distribución de notas';

  @override
  String get teacherAssignmentAnalyticsNoAttempt => 'Sin intento';

  @override
  String teacherAssignmentAnalyticsCompletionLabel(int completed, int total) {
    return 'Entregaron $completed de $total';
  }

  @override
  String teacherAssignmentAnalyticsBestLabel(String score) {
    return 'Mejor: $score%';
  }

  @override
  String teacherAssignmentAnalyticsLastLabel(String score) {
    return 'Último: $score%';
  }

  @override
  String teacherAssignmentAnalyticsErrorRateLabel(String rate, int attempts) {
    return '$rate% error · $attempts intentos';
  }

  @override
  String get teacherClassAnalyticsActiveStudentsLabel => 'Alumnos con práctica';

  @override
  String get teacherClassAnalyticsAverageLabel => 'Promedio';

  @override
  String get teacherClassAnalyticsAssignmentsTitle => 'Asignaciones';

  @override
  String get studentAssignmentProgressTitle => 'Mi progreso';

  @override
  String get studentAssignmentProgressAction => 'Mi progreso';

  @override
  String get studentAssignmentProgressMyStats => 'Mis resultados';

  @override
  String get studentAssignmentProgressEvolutionTitle => 'Mi evolución';

  @override
  String get studentAssignmentProgressHardQuestionsTitle =>
      'Preguntas a repasar';

  @override
  String studentAssignmentProgressTrendUp(String points) {
    return 'Mejoraste $points pts respecto a tu primer intento';
  }

  @override
  String studentAssignmentProgressAttemptLabel(int number, String percent) {
    return 'Intento $number: $percent%';
  }

  @override
  String get practiceResultRepracticeTitle => 'Preguntas a repasar';

  @override
  String practiceResultTrendUp(String points) {
    return '+$points pts vs intento anterior';
  }

  @override
  String practiceResultTrendDown(String points) {
    return '$points pts vs intento anterior';
  }

  @override
  String get practiceResultReviewQuestionAction => 'Ver en revisión';

  @override
  String get analyticsPersonalOnlyLabel => 'Solo tus intentos';

  @override
  String get analyticsOnlyDifficultFilter => 'Solo difíciles';

  @override
  String analyticsPersonalAccuracyLabel(String percent) {
    return '$percent% acierto en tus intentos';
  }

  @override
  String scoreDistributionRange(int min, int max) {
    return '$min–$max%';
  }

  @override
  String get teacherClassesTitle => 'Mis clases';

  @override
  String get teacherClassesEmpty => 'Aún no has creado ninguna clase.';

  @override
  String get teacherClassCreateTitle => 'Nueva clase';

  @override
  String get teacherClassNameLabel => 'Nombre de la clase';

  @override
  String get teacherClassNameHint => 'Ej. Álgebra II — Período 3';

  @override
  String get teacherClassDescriptionLabel => 'Descripción (opcional)';

  @override
  String get teacherClassDescriptionHint => 'Descripción breve de esta clase';

  @override
  String get teacherClassSaveAction => 'Guardar';

  @override
  String get teacherClassCreateAction => 'Crear clase';

  @override
  String get teacherClassArchiveAction => 'Archivar clase';

  @override
  String get teacherClassArchiveConfirmTitle => '¿Archivar clase?';

  @override
  String get teacherClassArchiveConfirmMessage =>
      'Los estudiantes ya no verán las asignaciones de esta clase.';

  @override
  String get teacherClassArchiveConfirmAction => 'Archivar';

  @override
  String get teacherClassMembersTab => 'Miembros';

  @override
  String get teacherClassAssignmentsTab => 'Asignaciones';

  @override
  String get teacherClassAnalyticsTab => 'Analítica';

  @override
  String get teacherClassActiveMembersLabel => 'miembros activos';

  @override
  String get teacherClassPendingMembersLabel => 'pendientes de aprobación';

  @override
  String get teacherClassAddMemberTitle => 'Agregar estudiante';

  @override
  String get teacherClassAddMemberEmailLabel => 'Correo del estudiante';

  @override
  String get teacherClassAddMemberEmailHint => 'estudiante@correo.com';

  @override
  String get teacherClassAddMemberAction => 'Agregar';

  @override
  String get teacherClassInvalidEmailError =>
      'Ingresa un correo electrónico válido.';

  @override
  String get teacherClassMemberNotFoundError =>
      'No hay ningún estudiante registrado con ese correo.';

  @override
  String get teacherClassMemberAlreadyExistsError =>
      'Ese estudiante ya pertenece a esta clase.';

  @override
  String get teacherClassRemoveMemberAction => 'Eliminar';

  @override
  String get teacherClassRemoveMemberConfirmTitle => '¿Eliminar estudiante?';

  @override
  String get teacherClassRemoveMemberConfirmMessage =>
      'Este estudiante perderá acceso a todas las asignaciones de esta clase.';

  @override
  String get teacherClassApproveAction => 'Aprobar';

  @override
  String get teacherClassMembersEmpty =>
      'Aún no hay estudiantes en esta clase.';

  @override
  String get teacherClassPendingApprovalsTitle => 'Pendientes de aprobación';

  @override
  String get teacherAssignmentCreateTitle => 'Nueva asignación';

  @override
  String get teacherAssignmentTitleLabel => 'Título';

  @override
  String get teacherAssignmentTitleHint => 'Ej. Capítulo 5 — Quiz de práctica';

  @override
  String get teacherAssignmentInstructionsLabel => 'Instrucciones (opcional)';

  @override
  String get teacherAssignmentQuizLabel => 'Seleccionar quiz';

  @override
  String get teacherAssignmentStartsAtLabel => 'Se abre el';

  @override
  String get teacherAssignmentDueAtLabel => 'Fecha límite';

  @override
  String get teacherAssignmentMaxAttemptsLabel => 'Intentos máximos';

  @override
  String get teacherAssignmentMaxAttemptsHint =>
      'Dejar en blanco para ilimitados';

  @override
  String get teacherAssignmentShowAnswersLabel =>
      'Mostrar respuestas correctas';

  @override
  String get teacherAssignmentShowAnswersNever => 'Nunca';

  @override
  String get teacherAssignmentShowAnswersAfterAttempt => 'Tras cada intento';

  @override
  String get teacherAssignmentShowAnswersAfterDue => 'Tras la fecha límite';

  @override
  String get teacherAssignmentShowAnswersTeacherOnly => 'Solo el profesor';

  @override
  String get teacherAssignmentCreateAction => 'Crear asignación';

  @override
  String get teacherAssignmentEditTitle => 'Editar asignación';

  @override
  String get teacherAssignmentEditAction => 'Editar';

  @override
  String get teacherAssignmentSaveAction => 'Guardar cambios';

  @override
  String get teacherAssignmentTitleRequired => 'El título es obligatorio';

  @override
  String get teacherAssignmentQuizSelectHint => 'Seleccionar quiz';

  @override
  String get teacherAssignmentQuizRequiredError => 'Selecciona un quiz';

  @override
  String get teacherAssignmentQuizLockedHint =>
      'El quiz no se puede cambiar una vez creada la asignación.';

  @override
  String get teacherAssignmentMaxAttemptsInvalidError =>
      'Introduce un número válido de intentos';

  @override
  String get teacherAssignmentNotEditableError =>
      'Solo se pueden editar asignaciones activas.';

  @override
  String get teacherAssignmentMaxAttemptsBelowExistingError =>
      'Los intentos máximos no pueden ser menores a los que ya usaron los estudiantes.';

  @override
  String get teacherAssignmentInvalidDateRangeError =>
      'La fecha límite no puede ser anterior a la de inicio.';

  @override
  String get teacherAssignmentCloseAction => 'Cerrar asignación';

  @override
  String get teacherAssignmentArchiveAction => 'Archivar';

  @override
  String get teacherAssignmentCloseConfirmTitle => '¿Cerrar asignación?';

  @override
  String get teacherAssignmentCloseConfirmMessage =>
      'Los estudiantes ya no podrán enviar nuevos intentos.';

  @override
  String get teacherAssignmentCompletionTitle => 'Completación';

  @override
  String get teacherAssignmentAttemptsTitle => 'Intentos';

  @override
  String get teacherAssignmentCompletedLabel => 'completaron';

  @override
  String get teacherAssignmentPendingLabel => 'sin enviar';

  @override
  String get teacherAssignmentBestScoreLabel => 'Mejor';

  @override
  String get teacherAssignmentAttemptsLabel => 'intentos';

  @override
  String get teacherAssignmentDueLabel => 'Cierra';

  @override
  String get teacherAssignmentNoDueDate => 'Sin fecha límite';

  @override
  String get teacherAssignmentEmpty => 'Sin asignaciones aún.';

  @override
  String get teacherAssignmentFormSubtitle =>
      'Configura fechas, intentos y visibilidad de respuestas.';

  @override
  String get teacherAssignmentSectionDetails => 'Detalles';

  @override
  String get teacherAssignmentSectionQuiz => 'Cuestionario';

  @override
  String get teacherAssignmentSectionSchedule => 'Calendario';

  @override
  String get teacherAssignmentSectionRules => 'Reglas';

  @override
  String get teacherAssignmentCreateQuizCtaSubtitle =>
      'Créalo aquí y selecciónalo al instante';

  @override
  String get teacherAssignmentSelectQuizAction => 'Elegir de mis cuestionarios';

  @override
  String get teacherAssignmentChangeQuizAction => 'Cambiar';

  @override
  String get teacherAssignmentQuizDraftWarning =>
      'Este cuestionario está en borrador. Publícalo para que los estudiantes puedan ver la asignación.';

  @override
  String get teacherAssignmentNoQuizzesHint =>
      'Aún no tienes cuestionarios. Crea uno para continuar.';

  @override
  String get teacherAssignmentPickDatePlaceholder => 'Sin definir';

  @override
  String get teacherAssignmentDraftContinued =>
      'Continúa configurando tu asignación. El cuestionario nuevo ya está seleccionado.';

  @override
  String get teacherAnalyticsAvgScoreLabel => 'Prom. puntaje';

  @override
  String get teacherAnalyticsTotalSessionsLabel => 'Sesiones totales';

  @override
  String get teacherAnalyticsCompletionRateLabel => 'Completación';

  @override
  String get teacherUpgradeHeroTitle => 'Convierte tus quizzes en un aula';

  @override
  String get teacherUpgradeHeroSubtitle =>
      'Todo lo que necesitas para enseñar, asignar y hacer seguimiento — en un solo lugar.';

  @override
  String get teacherUpgradePriceLabel => '/ mes';

  @override
  String get teacherUpgradePopularBadge => 'El más elegido por educadores';

  @override
  String get teacherUpgradePillar1Title => 'Clases organizadas';

  @override
  String get teacherUpgradePillar1Body =>
      'Crea grupos, invita estudiantes por correo y gestiona el acceso.';

  @override
  String get teacherUpgradePillar2Title => 'Asignaciones inteligentes';

  @override
  String get teacherUpgradePillar2Body =>
      'Define fechas límite, limita intentos y controla cuándo se revelan las respuestas.';

  @override
  String get teacherUpgradePillar3Title => 'Activity Pulse';

  @override
  String get teacherUpgradePillar3Body =>
      'Feed en vivo de actividad estudiantil, insights automáticos y analítica por clase.';

  @override
  String get teacherUpgradeCta => 'Hazte Profesor';

  @override
  String get teacherUpgradeCancelHint =>
      'Cancela cuando quieras · Acceso inmediato al pagar';

  @override
  String get teacherUpgradeSeeAllPlans => 'Ver todos los planes';

  @override
  String get teacherUpgradeAlreadyActive =>
      'Ya tienes un plan Profesor activo.';

  @override
  String get teacherUpgradeCancelTitle => '¿Cancelar suscripción?';

  @override
  String get teacherUpgradeCancelMessage =>
      'Perderás el acceso al módulo Profesor y tus clases serán archivadas. Puedes volver a suscribirte en cualquier momento.';

  @override
  String get teacherUpgradeCancelConfirm => 'Cancelar plan';

  @override
  String get teacherUpgradeCancelSuccess =>
      'Suscripción cancelada. ¡Hasta pronto!';

  @override
  String get teacherUpgradeExpiryWarning =>
      'Tu plan Profesor vence en menos de 7 días. Renuévalo para mantener el acceso.';

  @override
  String get homeTeacherBannerTitle => '¿Eres docente?';

  @override
  String get homeTeacherBannerBody =>
      'Clases, asignaciones y analítica en tiempo real.';

  @override
  String get homeTeacherBannerAction => 'Ver plan Profesor';

  @override
  String get homeTeacherBannerDismissTooltip => 'No mostrar más';

  @override
  String get studentAssignmentsTitle => 'Mis asignaciones';

  @override
  String get studentAssignmentsAction => 'Asignaciones de clase';

  @override
  String get studentAssignmentsEmpty =>
      'No tienes asignaciones de tus profesores aún.';

  @override
  String get studentAssignmentStartAction => 'Empezar';

  @override
  String get studentAssignmentClosedLabel => 'Cerrada';

  @override
  String get studentAssignmentUnavailableLabel => 'No disponible';

  @override
  String get studentAssignmentNotYetOpenLabel => 'Próximamente';

  @override
  String get studentAssignmentNotYetOpenError =>
      'Esta asignación aún no está disponible. Revisa la fecha de inicio.';

  @override
  String get studentAssignmentPastDueLabel => 'Vencida';

  @override
  String get studentAssignmentMaxAttemptsLabel => 'Sin intentos';

  @override
  String get studentAssignmentAvailableNowLabel => 'Disponible ahora';

  @override
  String studentAssignmentAttemptsSummary(int used, int max) {
    return '$used de $max intentos';
  }

  @override
  String get studentAssignmentMyAttemptsAction => 'Mis intentos';

  @override
  String get studentAssignmentMyAttemptsTitle => 'Mis intentos';

  @override
  String get studentAssignmentMyAttemptsEmpty =>
      'Aún no has completado ningún intento en esta asignación.';

  @override
  String get studentAssignmentAttemptScoreOnlyHint =>
      'Solo puntuación — las respuestas correctas no están disponibles según la configuración del profesor.';

  @override
  String studentAssignmentAttemptsHeaderSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos registrados',
      one: '1 intento registrado',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentAttemptBestScore(String percent) {
    return 'Mejor resultado: $percent%';
  }

  @override
  String get studentAssignmentAttemptStatusFinished => 'Completado';

  @override
  String get studentAssignmentAttemptScoreOnlyBadge => 'Solo puntuación';

  @override
  String get studentAssignmentAttemptReviewAvailable => 'Ver respuestas';

  @override
  String studentAssignmentAttemptMeta(
    String score,
    String duration,
    String status,
  ) {
    return '$score · $duration · $status';
  }

  @override
  String get studentAssignmentsFilterAll => 'Todas';

  @override
  String get studentAssignmentsFilterPending => 'Pendientes';

  @override
  String get studentAssignmentsSearchHint => 'Buscar asignación o clase';

  @override
  String studentAssignmentsSummaryTodoOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count por hacer',
      one: '1 por hacer',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentsSummaryDueTodayOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vencen hoy',
      one: '1 vence hoy',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentsSummaryCombined(String todo, String dueToday) {
    return '$todo · $dueToday';
  }

  @override
  String get studentAssignmentsSummaryAllDone =>
      'No tienes asignaciones pendientes por ahora.';

  @override
  String studentAssignmentsClassGroupSubtitle(String teacher, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count asignaciones',
      one: '1 asignación',
    );
    return '$teacher · $_temp0';
  }

  @override
  String get studentAssignmentsEmptyFiltered =>
      'Ninguna asignación coincide con este filtro.';

  @override
  String studentAssignmentRowSubtitleDue(String date, String attemptsSuffix) {
    return 'Vence $date$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleDueToday(String attemptsSuffix) {
    return 'Vence hoy$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleAvailable(String attemptsSuffix) {
    return 'Disponible$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleNoDue(String attemptsSuffix) {
    return 'Sin fecha límite$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleNotYetOpen(String date) {
    return 'Se abre $date';
  }

  @override
  String studentAssignmentRowSubtitleStatus(
    String status,
    String attemptsSuffix,
  ) {
    return '$status$attemptsSuffix';
  }

  @override
  String studentAssignmentAttemptsSuffix(String summary) {
    return ' · $summary';
  }

  @override
  String get studentAssignmentStatusBadgeAvailable => 'Disponible';

  @override
  String get studentAssignmentDetailTitle => 'Detalle de asignación';

  @override
  String get profileTeacherPlanSectionTitle => 'Plan Profesor';

  @override
  String get profileTeacherPlanManageTitle => 'Gestionar plan Profesor';

  @override
  String get profileTeacherPlanActiveSubtitle =>
      'Plan activo · toca para gestionar';

  @override
  String get profileTeacherPlanInactiveSubtitle =>
      'Clases, asignaciones y analítica · Suscripción mensual';

  @override
  String get teacherUpgradeKeepPlan => 'No, mantener';

  @override
  String get teacherOnboardingWelcomeTitle => '¡Bienvenido, Profesor!';

  @override
  String teacherOnboardingStepProgress(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get teacherOnboardingStep1Title => 'Crea tu primera clase';

  @override
  String get teacherOnboardingStep1Body =>
      'Las clases te permiten organizar a tus estudiantes y asignarles quizzes con seguimiento personalizado.';

  @override
  String get teacherOnboardingClassNameLabel => 'Nombre de la clase';

  @override
  String get teacherOnboardingClassNameHint => 'Ej. Matemáticas — Grupo A';

  @override
  String get teacherOnboardingCreateClassAction => 'Crear clase y continuar';

  @override
  String get teacherOnboardingStep2Title => 'Invita tu primer estudiante';

  @override
  String get teacherOnboardingStep2Body =>
      'Escribe el correo de un estudiante registrado para añadirlo a tu clase. También puedes hacerlo más tarde.';

  @override
  String get teacherOnboardingStudentEmailLabel => 'Correo del estudiante';

  @override
  String get teacherOnboardingStudentEmailHint => 'estudiante@correo.com';

  @override
  String get teacherOnboardingInviteAction => 'Invitar y continuar';

  @override
  String get teacherOnboardingSkipAction => 'Omitir por ahora';

  @override
  String get teacherOnboardingStep3Title => '¡Todo listo!';

  @override
  String get teacherOnboardingStep3Body =>
      'Tu aula está configurada. Ahora puedes crear asignaciones, ver el progreso de tus estudiantes y analizar resultados en el Activity Pulse.';

  @override
  String get teacherOnboardingGoToDashboardAction => 'Ir al Panel de Profesor';
}
