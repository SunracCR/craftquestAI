import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'CraftQuest'**
  String get appTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a CraftQuest'**
  String get homeWelcome;

  /// No description provided for @homeWelcomeUser.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String homeWelcomeUser(String name);

  /// No description provided for @homeRoleLabel.
  ///
  /// In es, this message translates to:
  /// **'Rol: {role}'**
  String homeRoleLabel(String role);

  /// No description provided for @roleUnknown.
  ///
  /// In es, this message translates to:
  /// **'sin rol'**
  String get roleUnknown;

  /// No description provided for @roleTeacherLabel.
  ///
  /// In es, this message translates to:
  /// **'Profesor'**
  String get roleTeacherLabel;

  /// No description provided for @roleStudentLabel.
  ///
  /// In es, this message translates to:
  /// **'Estudiante'**
  String get roleStudentLabel;

  /// No description provided for @roleInstitutionAdminLabel.
  ///
  /// In es, this message translates to:
  /// **'Admin institución'**
  String get roleInstitutionAdminLabel;

  /// No description provided for @roleContentAdminLabel.
  ///
  /// In es, this message translates to:
  /// **'Admin contenido'**
  String get roleContentAdminLabel;

  /// No description provided for @roleSuperAdminLabel.
  ///
  /// In es, this message translates to:
  /// **'Superadmin'**
  String get roleSuperAdminLabel;

  /// No description provided for @apiStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado del API'**
  String get apiStatusLabel;

  /// No description provided for @apiStatusLoading.
  ///
  /// In es, this message translates to:
  /// **'Conectando...'**
  String get apiStatusLoading;

  /// No description provided for @apiStatusError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar al API'**
  String get apiStatusError;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @noInternetBannerTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet'**
  String get noInternetBannerTitle;

  /// No description provided for @noInternetBannerMessage.
  ///
  /// In es, this message translates to:
  /// **'Puedes seguir navegando, pero los datos no se actualizarán hasta que vuelva la red.'**
  String get noInternetBannerMessage;

  /// No description provided for @noInternetSnackBarMessage.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet e inténtalo de nuevo.'**
  String get noInternetSnackBarMessage;

  /// No description provided for @genericRequestErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la solicitud. Inténtalo de nuevo en unos momentos.'**
  String get genericRequestErrorMessage;

  /// No description provided for @errorHttpMethodNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'El servidor no admite esta operación. Reinicia la API e inténtalo de nuevo.'**
  String get errorHttpMethodNotAllowed;

  /// No description provided for @errorQuestionLimitReached.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite de {max} preguntas por cuestionario en tu plan {plan}.'**
  String errorQuestionLimitReached(int max, String plan);

  /// No description provided for @errorQuizLimitReached.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite de {max} cuestionarios en tu plan {plan}.'**
  String errorQuizLimitReached(int max, String plan);

  /// No description provided for @billingPlanFreeName.
  ///
  /// In es, this message translates to:
  /// **'Gratis'**
  String get billingPlanFreeName;

  /// No description provided for @billingPlanProName.
  ///
  /// In es, this message translates to:
  /// **'Pro'**
  String get billingPlanProName;

  /// No description provided for @billingPlanPremiumName.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get billingPlanPremiumName;

  /// No description provided for @billingPlanTeacherName.
  ///
  /// In es, this message translates to:
  /// **'Profesor'**
  String get billingPlanTeacherName;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Accede gratis a tu cuenta CraftQuest — entra o regístrate en segundos'**
  String get loginSubtitle;

  /// No description provided for @loginAction.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get loginAction;

  /// No description provided for @loginRememberCredentials.
  ///
  /// In es, this message translates to:
  /// **'Recordar usuario y contraseña'**
  String get loginRememberCredentials;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerTitle;

  /// No description provided for @registerAction.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get registerAction;

  /// No description provided for @goToRegister.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get goToRegister;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre para mostrar'**
  String get displayNameLabel;

  /// No description provided for @fieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get fieldRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get passwordMinLength;

  /// No description provided for @logoutAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutAction;

  /// No description provided for @navHomeLabel.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHomeLabel;

  /// No description provided for @navProfileLabel.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfileLabel;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @selectAvatarTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu avatar'**
  String get selectAvatarTitle;

  /// No description provided for @profileChangeAvatarAction.
  ///
  /// In es, this message translates to:
  /// **'Cambiar avatar'**
  String get profileChangeAvatarAction;

  /// No description provided for @profileEditNameAction.
  ///
  /// In es, this message translates to:
  /// **'Editar nombre'**
  String get profileEditNameAction;

  /// No description provided for @profileNameUpdatedMessage.
  ///
  /// In es, this message translates to:
  /// **'Nombre actualizado'**
  String get profileNameUpdatedMessage;

  /// No description provided for @profileNameInvalidMessage.
  ///
  /// In es, this message translates to:
  /// **'Introduce un nombre entre 1 y 160 caracteres.'**
  String get profileNameInvalidMessage;

  /// No description provided for @profileSaveAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get profileSaveAction;

  /// No description provided for @profileAvatarPickerHint.
  ///
  /// In es, this message translates to:
  /// **'Toca un icono para actualizar tu perfil'**
  String get profileAvatarPickerHint;

  /// No description provided for @avatarUpdatedMessage.
  ///
  /// In es, this message translates to:
  /// **'Avatar actualizado'**
  String get avatarUpdatedMessage;

  /// No description provided for @languageSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageSectionTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languagePortuguese.
  ///
  /// In es, this message translates to:
  /// **'Portugués'**
  String get languagePortuguese;

  /// No description provided for @languageUpdatedMessage.
  ///
  /// In es, this message translates to:
  /// **'Idioma actualizado'**
  String get languageUpdatedMessage;

  /// No description provided for @securitySectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get securitySectionTitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar contraseña'**
  String get changePasswordAction;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChangedMessage.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get passwordChangedMessage;

  /// No description provided for @myQuizzesAction.
  ///
  /// In es, this message translates to:
  /// **'Mis cuestionarios'**
  String get myQuizzesAction;

  /// No description provided for @quizzesTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuestionarios'**
  String get quizzesTitle;

  /// No description provided for @quizzesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes cuestionarios'**
  String get quizzesEmpty;

  /// No description provided for @quizzesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los cuestionarios'**
  String get quizzesLoadError;

  /// No description provided for @createQuizAction.
  ///
  /// In es, this message translates to:
  /// **'Crear cuestionario'**
  String get createQuizAction;

  /// No description provided for @createQuizTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo cuestionario'**
  String get createQuizTitle;

  /// No description provided for @createQuizNextStepTitle.
  ///
  /// In es, this message translates to:
  /// **'Añade preguntas a tu cuestionario'**
  String get createQuizNextStepTitle;

  /// No description provided for @createQuizNextStepSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza creando una pregunta, importa desde un archivo o genera con IA.'**
  String get createQuizNextStepSubtitle;

  /// No description provided for @createQuizAddQuestionsManually.
  ///
  /// In es, this message translates to:
  /// **'Crear preguntas manualmente'**
  String get createQuizAddQuestionsManually;

  /// No description provided for @createQuizImportQuestions.
  ///
  /// In es, this message translates to:
  /// **'Importar preguntas'**
  String get createQuizImportQuestions;

  /// No description provided for @createQuizSkipQuestionsSetup.
  ///
  /// In es, this message translates to:
  /// **'Hacerlo después'**
  String get createQuizSkipQuestionsSetup;

  /// No description provided for @quizTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get quizTitleLabel;

  /// No description provided for @quizTitleTapToEdit.
  ///
  /// In es, this message translates to:
  /// **'Toca el título para editarlo'**
  String get quizTitleTapToEdit;

  /// No description provided for @quizDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get quizDescriptionLabel;

  /// No description provided for @quizListSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{status} · {count} preguntas'**
  String quizListSubtitle(String status, int count);

  /// No description provided for @quizStatusDraft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get quizStatusDraft;

  /// No description provided for @quizStatusPublished.
  ///
  /// In es, this message translates to:
  /// **'Publicado'**
  String get quizStatusPublished;

  /// No description provided for @quizDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del cuestionario'**
  String get quizDetailTitle;

  /// No description provided for @quizDetailImportAiDraftAction.
  ///
  /// In es, this message translates to:
  /// **'Importar preguntas generadas por IA'**
  String get quizDetailImportAiDraftAction;

  /// No description provided for @quizDetailImportAiDraftBanner.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 pregunta generada por IA lista para importar} other{{count} preguntas generadas por IA listas para importar}}'**
  String quizDetailImportAiDraftBanner(int count);

  /// No description provided for @quizListPendingAiDraft.
  ///
  /// In es, this message translates to:
  /// **'Borrador IA listo para importar'**
  String get quizListPendingAiDraft;

  /// No description provided for @addQuestionAction.
  ///
  /// In es, this message translates to:
  /// **'Añadir pregunta'**
  String get addQuestionAction;

  /// No description provided for @viewQuizQuestionsAction.
  ///
  /// In es, this message translates to:
  /// **'Ver preguntas'**
  String get viewQuizQuestionsAction;

  /// No description provided for @publishQuizAction.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get publishQuizAction;

  /// No description provided for @quizPublishedMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuestionario publicado'**
  String get quizPublishedMessage;

  /// No description provided for @deleteQuizAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuestionario'**
  String get deleteQuizAction;

  /// No description provided for @deleteQuizConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar cuestionario?'**
  String get deleteQuizConfirmTitle;

  /// No description provided for @deleteQuizConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{title}\" y todas sus preguntas. Esta acción no se puede deshacer.'**
  String deleteQuizConfirmMessage(String title);

  /// No description provided for @quizDeletedMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuestionario eliminado'**
  String get quizDeletedMessage;

  /// No description provided for @questionsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin preguntas todavía'**
  String get questionsEmpty;

  /// No description provided for @quizDetailQuestionsSection.
  ///
  /// In es, this message translates to:
  /// **'Preguntas del cuestionario'**
  String get quizDetailQuestionsSection;

  /// No description provided for @quizQuestionsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} preguntas'**
  String quizQuestionsCount(int count);

  /// No description provided for @quizDetailOptionCount.
  ///
  /// In es, this message translates to:
  /// **'{count} opciones'**
  String quizDetailOptionCount(int count);

  /// No description provided for @quizDetailCorrectKeys.
  ///
  /// In es, this message translates to:
  /// **'Respuesta correcta: {keys}'**
  String quizDetailCorrectKeys(String keys);

  /// No description provided for @quizDetailCorrectKeysPlural.
  ///
  /// In es, this message translates to:
  /// **'Respuestas correctas: {keys}'**
  String quizDetailCorrectKeysPlural(String keys);

  /// No description provided for @questionTypeLabelSingleChoice.
  ///
  /// In es, this message translates to:
  /// **'Selección única'**
  String get questionTypeLabelSingleChoice;

  /// No description provided for @questionTypeLabelMultipleChoice.
  ///
  /// In es, this message translates to:
  /// **'Selección múltiple'**
  String get questionTypeLabelMultipleChoice;

  /// No description provided for @questionTypeLabelTrueFalse.
  ///
  /// In es, this message translates to:
  /// **'Falso / Verdadero'**
  String get questionTypeLabelTrueFalse;

  /// No description provided for @questionTypeLabelImageChoice.
  ///
  /// In es, this message translates to:
  /// **'Opciones con imagen'**
  String get questionTypeLabelImageChoice;

  /// No description provided for @questionTypeLabelImageBased.
  ///
  /// In es, this message translates to:
  /// **'Basada en imagen'**
  String get questionTypeLabelImageBased;

  /// No description provided for @questionListIndexLabel.
  ///
  /// In es, this message translates to:
  /// **'P{index}'**
  String questionListIndexLabel(int index);

  /// No description provided for @editQuestionAction.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get editQuestionAction;

  /// No description provided for @deleteQuestionAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteQuestionAction;

  /// No description provided for @editQuestionTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar pregunta'**
  String get editQuestionTitle;

  /// No description provided for @deleteQuestionConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar pregunta?'**
  String get deleteQuestionConfirmTitle;

  /// No description provided for @deleteQuestionConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'La pregunta se quitará del cuestionario. Esta acción no se puede deshacer.'**
  String get deleteQuestionConfirmMessage;

  /// No description provided for @questionDeletedMessage.
  ///
  /// In es, this message translates to:
  /// **'Pregunta eliminada'**
  String get questionDeletedMessage;

  /// No description provided for @questionSavedMessage.
  ///
  /// In es, this message translates to:
  /// **'Pregunta guardada'**
  String get questionSavedMessage;

  /// No description provided for @addQuestionTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva pregunta'**
  String get addQuestionTitle;

  /// No description provided for @questionTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de pregunta'**
  String get questionTypeLabel;

  /// No description provided for @questionTextLabel.
  ///
  /// In es, this message translates to:
  /// **'Enunciado'**
  String get questionTextLabel;

  /// No description provided for @questionPointsLabel.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get questionPointsLabel;

  /// No description provided for @questionPointsHint.
  ///
  /// In es, this message translates to:
  /// **'Puntaje si se responde bien (solo esta pregunta)'**
  String get questionPointsHint;

  /// No description provided for @questionPointsValue.
  ///
  /// In es, this message translates to:
  /// **'{points} pts'**
  String questionPointsValue(String points);

  /// No description provided for @questionInvalidPoints.
  ///
  /// In es, this message translates to:
  /// **'Los puntos deben ser mayores que 0'**
  String get questionInvalidPoints;

  /// No description provided for @answerOptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Opción {key}'**
  String answerOptionLabel(String key);

  /// No description provided for @correctAnswerKeyLabel.
  ///
  /// In es, this message translates to:
  /// **'Respuesta correcta (key)'**
  String get correctAnswerKeyLabel;

  /// No description provided for @saveQuestionAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar pregunta'**
  String get saveQuestionAction;

  /// No description provided for @trueLabel.
  ///
  /// In es, this message translates to:
  /// **'Verdadero'**
  String get trueLabel;

  /// No description provided for @falseLabel.
  ///
  /// In es, this message translates to:
  /// **'Falso'**
  String get falseLabel;

  /// No description provided for @minTwoOptions.
  ///
  /// In es, this message translates to:
  /// **'Indica al menos dos opciones'**
  String get minTwoOptions;

  /// No description provided for @questionImageLabel.
  ///
  /// In es, this message translates to:
  /// **'Imagen del enunciado'**
  String get questionImageLabel;

  /// No description provided for @correctAnswersLabel.
  ///
  /// In es, this message translates to:
  /// **'Respuestas correctas'**
  String get correctAnswersLabel;

  /// No description provided for @selectCorrectAnswersHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una o más opciones correctas'**
  String get selectCorrectAnswersHint;

  /// No description provided for @imageChoiceHint.
  ///
  /// In es, this message translates to:
  /// **'Adjunta una imagen en al menos una opción de respuesta'**
  String get imageChoiceHint;

  /// No description provided for @imageBasedQuestionHint.
  ///
  /// In es, this message translates to:
  /// **'Sube la imagen o diagrama que acompaña el enunciado'**
  String get imageBasedQuestionHint;

  /// No description provided for @requireQuestionImage.
  ///
  /// In es, this message translates to:
  /// **'La pregunta basada en imagen requiere una imagen'**
  String get requireQuestionImage;

  /// No description provided for @requireOptionImage.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos una imagen en las opciones'**
  String get requireOptionImage;

  /// No description provided for @selectAtLeastOneCorrect.
  ///
  /// In es, this message translates to:
  /// **'Marca al menos una respuesta correcta'**
  String get selectAtLeastOneCorrect;

  /// No description provided for @correctIdsLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} respuesta(s) correcta(s) por ID'**
  String correctIdsLabel(int count);

  /// No description provided for @practiceOptionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Parámetros de práctica'**
  String get practiceOptionsTitle;

  /// No description provided for @practiceRandomizeQuestionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Orden aleatorio de preguntas'**
  String get practiceRandomizeQuestionsLabel;

  /// No description provided for @practiceRandomizeQuestionsHint.
  ///
  /// In es, this message translates to:
  /// **'Las preguntas se muestran en un orden distinto en cada práctica'**
  String get practiceRandomizeQuestionsHint;

  /// No description provided for @practiceShowTimerLabel.
  ///
  /// In es, this message translates to:
  /// **'Mostrar tiempo transcurrido'**
  String get practiceShowTimerLabel;

  /// No description provided for @practiceShowTimerHint.
  ///
  /// In es, this message translates to:
  /// **'Muestra un reloj mientras respondes el cuestionario'**
  String get practiceShowTimerHint;

  /// No description provided for @practiceElapsedLabel.
  ///
  /// In es, this message translates to:
  /// **'Tiempo: {elapsed}'**
  String practiceElapsedLabel(String elapsed);

  /// No description provided for @practiceDurationLabel.
  ///
  /// In es, this message translates to:
  /// **'Tiempo empleado'**
  String get practiceDurationLabel;

  /// No description provided for @practiceQuizAction.
  ///
  /// In es, this message translates to:
  /// **'Practicar'**
  String get practiceQuizAction;

  /// No description provided for @practiceSessionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sesión de práctica'**
  String get practiceSessionTitle;

  /// No description provided for @practiceProgressLabel.
  ///
  /// In es, this message translates to:
  /// **'{answered} de {total} respondidas'**
  String practiceProgressLabel(int answered, int total);

  /// No description provided for @practiceProgressCompletedLabel.
  ///
  /// In es, this message translates to:
  /// **'{done} de {total} completadas'**
  String practiceProgressCompletedLabel(int done, int total);

  /// No description provided for @practiceNavigateQuestionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Preguntas'**
  String get practiceNavigateQuestionsLabel;

  /// No description provided for @practiceOpenQuestionMapAction.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get practiceOpenQuestionMapAction;

  /// No description provided for @practiceMapTitle.
  ///
  /// In es, this message translates to:
  /// **'Mapa de preguntas'**
  String get practiceMapTitle;

  /// No description provided for @practiceMapFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get practiceMapFilterAll;

  /// No description provided for @practiceMapFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get practiceMapFilterPending;

  /// No description provided for @practiceMapFilterCompleted.
  ///
  /// In es, this message translates to:
  /// **'Hechas'**
  String get practiceMapFilterCompleted;

  /// No description provided for @practiceMapEmptyFilter.
  ///
  /// In es, this message translates to:
  /// **'No hay preguntas con este filtro'**
  String get practiceMapEmptyFilter;

  /// No description provided for @practiceNavLegendAnswered.
  ///
  /// In es, this message translates to:
  /// **'Respondida'**
  String get practiceNavLegendAnswered;

  /// No description provided for @practiceNavLegendPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get practiceNavLegendPending;

  /// No description provided for @practiceNavLegendCurrent.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get practiceNavLegendCurrent;

  /// No description provided for @practiceQuestionNavTooltip.
  ///
  /// In es, this message translates to:
  /// **'Pregunta {number}'**
  String practiceQuestionNavTooltip(int number);

  /// No description provided for @practicePreviousQuestionAction.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get practicePreviousQuestionAction;

  /// No description provided for @practiceQuestionAnsweredLabel.
  ///
  /// In es, this message translates to:
  /// **'Ya respondida'**
  String get practiceQuestionAnsweredLabel;

  /// No description provided for @practiceUpdateAnswerAction.
  ///
  /// In es, this message translates to:
  /// **'Actualizar respuesta'**
  String get practiceUpdateAnswerAction;

  /// No description provided for @practiceAnswerEditHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes cambiar tu respuesta y pulsar Actualizar respuesta'**
  String get practiceAnswerEditHint;

  /// No description provided for @practiceSavingAnswerHint.
  ///
  /// In es, this message translates to:
  /// **'Guardando tu respuesta…'**
  String get practiceSavingAnswerHint;

  /// No description provided for @practiceQuestionCounter.
  ///
  /// In es, this message translates to:
  /// **'Pregunta {current} de {total}'**
  String practiceQuestionCounter(int current, int total);

  /// No description provided for @practiceSelectAnswer.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos una respuesta'**
  String get practiceSelectAnswer;

  /// No description provided for @practiceSubmitAnswerAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar respuesta'**
  String get practiceSubmitAnswerAction;

  /// No description provided for @practiceNextQuestionAction.
  ///
  /// In es, this message translates to:
  /// **'Siguiente pregunta'**
  String get practiceNextQuestionAction;

  /// No description provided for @practiceFinishAction.
  ///
  /// In es, this message translates to:
  /// **'Finalizar práctica'**
  String get practiceFinishAction;

  /// No description provided for @practiceResumeTitle.
  ///
  /// In es, this message translates to:
  /// **'Práctica en curso'**
  String get practiceResumeTitle;

  /// No description provided for @practiceResumeMessage.
  ///
  /// In es, this message translates to:
  /// **'Tienes una práctica guardada con {answered} de {total} preguntas respondidas. ¿Qué deseas hacer?'**
  String practiceResumeMessage(int answered, int total);

  /// No description provided for @practiceContinueAction.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get practiceContinueAction;

  /// No description provided for @practiceStartNewAction.
  ///
  /// In es, this message translates to:
  /// **'Empezar de nuevo'**
  String get practiceStartNewAction;

  /// No description provided for @practiceSaveAndExitAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar y salir'**
  String get practiceSaveAndExitAction;

  /// No description provided for @practiceInProgressChip.
  ///
  /// In es, this message translates to:
  /// **'Práctica en curso'**
  String get practiceInProgressChip;

  /// No description provided for @practiceInProgressSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{answered}/{total} respondidas'**
  String practiceInProgressSubtitle(int answered, int total);

  /// No description provided for @practiceFinishEarlyAction.
  ///
  /// In es, this message translates to:
  /// **'Finalizar ahora'**
  String get practiceFinishEarlyAction;

  /// No description provided for @practiceNoQuestions.
  ///
  /// In es, this message translates to:
  /// **'Este cuestionario no tiene preguntas'**
  String get practiceNoQuestions;

  /// No description provided for @practiceResultTitle.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get practiceResultTitle;

  /// No description provided for @practicePercentageLabel.
  ///
  /// In es, this message translates to:
  /// **'{percentage}%'**
  String practicePercentageLabel(double percentage);

  /// No description provided for @practiceScoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Puntuación: {obtained} / {possible}'**
  String practiceScoreLabel(double obtained, double possible);

  /// No description provided for @practiceCorrectLabel.
  ///
  /// In es, this message translates to:
  /// **'Correctas: {count}'**
  String practiceCorrectLabel(int count);

  /// No description provided for @practiceIncorrectLabel.
  ///
  /// In es, this message translates to:
  /// **'Incorrectas: {count}'**
  String practiceIncorrectLabel(int count);

  /// No description provided for @practiceViewResultsAction.
  ///
  /// In es, this message translates to:
  /// **'Ver resultados'**
  String get practiceViewResultsAction;

  /// No description provided for @practiceReviewHiddenByAssignment.
  ///
  /// In es, this message translates to:
  /// **'Tu profesor configuró esta asignación para no mostrar las respuestas correctas. Solo puedes ver tu puntuación general.'**
  String get practiceReviewHiddenByAssignment;

  /// No description provided for @practiceReviewHiddenUntilDue.
  ///
  /// In es, this message translates to:
  /// **'Las respuestas correctas estarán disponibles después de la fecha límite ({date}). Por ahora solo puedes ver tu puntuación general.'**
  String practiceReviewHiddenUntilDue(String date);

  /// No description provided for @practiceReviewHiddenUntilDueNoDate.
  ///
  /// In es, this message translates to:
  /// **'Las respuestas correctas estarán disponibles después de la fecha límite. Por ahora solo puedes ver tu puntuación general.'**
  String get practiceReviewHiddenUntilDueNoDate;

  /// No description provided for @practiceReviewHiddenTeacherOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo tu profesor puede ver las respuestas correctas. Puedes consultar tu puntuación general.'**
  String get practiceReviewHiddenTeacherOnly;

  /// No description provided for @practiceBackHomeAction.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get practiceBackHomeAction;

  /// No description provided for @importQuestionsAction.
  ///
  /// In es, this message translates to:
  /// **'Importar preguntas'**
  String get importQuestionsAction;

  /// No description provided for @importQuestionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar preguntas'**
  String get importQuestionsTitle;

  /// No description provided for @importExcelAction.
  ///
  /// In es, this message translates to:
  /// **'Importar desde Excel'**
  String get importExcelAction;

  /// No description provided for @excelImportTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar Excel'**
  String get excelImportTitle;

  /// No description provided for @excelImportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sube un archivo .xlsx con tus preguntas. Revisarás una vista previa antes de confirmar.'**
  String get excelImportSubtitle;

  /// No description provided for @excelImportColumnsHint.
  ///
  /// In es, this message translates to:
  /// **'Columnas: Pregunta, Tipo (incluye image_choice e image_based_question sin archivos de imagen), Opción A–E, Respuesta correcta (ej. B o A|C), Puntos y Sección (opcionales). Las imágenes se añaden después en la app.'**
  String get excelImportColumnsHint;

  /// No description provided for @excelImportDownloadTemplate.
  ///
  /// In es, this message translates to:
  /// **'Descargar plantilla Excel'**
  String get excelImportDownloadTemplate;

  /// No description provided for @excelImportTemplateReady.
  ///
  /// In es, this message translates to:
  /// **'Plantilla lista para guardar o compartir'**
  String get excelImportTemplateReady;

  /// No description provided for @excelImportTemplateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar la plantilla'**
  String get excelImportTemplateFailed;

  /// No description provided for @excelImportDropHint.
  ///
  /// In es, this message translates to:
  /// **'Arrastra tu archivo .xlsx aquí'**
  String get excelImportDropHint;

  /// No description provided for @excelImportDropSubhint.
  ///
  /// In es, this message translates to:
  /// **'O elige un archivo desde tu dispositivo'**
  String get excelImportDropSubhint;

  /// No description provided for @excelImportPickFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get excelImportPickFile;

  /// No description provided for @excelImportUploadAction.
  ///
  /// In es, this message translates to:
  /// **'Subir y revisar'**
  String get excelImportUploadAction;

  /// No description provided for @excelImportOnlyXlsx.
  ///
  /// In es, this message translates to:
  /// **'Solo se admiten archivos .xlsx'**
  String get excelImportOnlyXlsx;

  /// No description provided for @excelImportFileTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El archivo supera el límite de 5 MB'**
  String get excelImportFileTooLarge;

  /// No description provided for @excelImportReadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el archivo seleccionado'**
  String get excelImportReadFailed;

  /// No description provided for @excelImportSelectFileFirst.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un archivo Excel primero'**
  String get excelImportSelectFileFirst;

  /// No description provided for @excelImportColumnsTitle.
  ///
  /// In es, this message translates to:
  /// **'Formato de columnas'**
  String get excelImportColumnsTitle;

  /// No description provided for @excelImportTemplateSection.
  ///
  /// In es, this message translates to:
  /// **'Paso 1 · Plantilla'**
  String get excelImportTemplateSection;

  /// No description provided for @excelImportUploadSection.
  ///
  /// In es, this message translates to:
  /// **'Paso 2 · Tu archivo'**
  String get excelImportUploadSection;

  /// No description provided for @excelImportFileReady.
  ///
  /// In es, this message translates to:
  /// **'Archivo listo para importar'**
  String get excelImportFileReady;

  /// No description provided for @excelImportChangeFile.
  ///
  /// In es, this message translates to:
  /// **'Cambiar archivo'**
  String get excelImportChangeFile;

  /// No description provided for @importImageMediaPending.
  ///
  /// In es, this message translates to:
  /// **'Las imágenes no se importan desde el archivo. Podrás añadirlas después en la app al editar la pregunta.'**
  String get importImageMediaPending;

  /// No description provided for @importImagePendingBadge.
  ///
  /// In es, this message translates to:
  /// **'Imagen pendiente en la app'**
  String get importImagePendingBadge;

  /// No description provided for @importFormatLabel.
  ///
  /// In es, this message translates to:
  /// **'Formato'**
  String get importFormatLabel;

  /// No description provided for @importFormatJson.
  ///
  /// In es, this message translates to:
  /// **'CQIF JSON'**
  String get importFormatJson;

  /// No description provided for @importFormatTxt.
  ///
  /// In es, this message translates to:
  /// **'TXT CraftQuest'**
  String get importFormatTxt;

  /// No description provided for @importContentLabel.
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get importContentLabel;

  /// No description provided for @importContentHint.
  ///
  /// In es, this message translates to:
  /// **'Pega aquí el JSON CQIF v2 o el archivo TXT'**
  String get importContentHint;

  /// No description provided for @importContentRequired.
  ///
  /// In es, this message translates to:
  /// **'Pega el contenido a importar'**
  String get importContentRequired;

  /// No description provided for @importProcessAction.
  ///
  /// In es, this message translates to:
  /// **'Procesar importación'**
  String get importProcessAction;

  /// No description provided for @importNoValidQuestions.
  ///
  /// In es, this message translates to:
  /// **'No hay preguntas válidas para importar'**
  String get importNoValidQuestions;

  /// No description provided for @importPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get importPreviewTitle;

  /// No description provided for @importSummaryLabel.
  ///
  /// In es, this message translates to:
  /// **'{valid} válidas de {total} ({errors} con error)'**
  String importSummaryLabel(int valid, int total, int errors);

  /// No description provided for @importErrorLine.
  ///
  /// In es, this message translates to:
  /// **'Fila {row}: {message}'**
  String importErrorLine(int row, String message);

  /// No description provided for @importQuestionTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo: {type}'**
  String importQuestionTypeLabel(String type);

  /// No description provided for @importAnswerLine.
  ///
  /// In es, this message translates to:
  /// **'{key}: {text}{correct}'**
  String importAnswerLine(String key, String text, String correct);

  /// No description provided for @importConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar e importar'**
  String get importConfirmAction;

  /// No description provided for @importConfirmSuccess.
  ///
  /// In es, this message translates to:
  /// **'{count} preguntas importadas'**
  String importConfirmSuccess(int count);

  /// No description provided for @importPlanLimitPreviewNotice.
  ///
  /// In es, this message translates to:
  /// **'Tu plan {plan} permite hasta {max} preguntas por cuestionario (ya tienes {current}). Solo se importarán {importable} de {total} del archivo.'**
  String importPlanLimitPreviewNotice(
    String plan,
    int max,
    int current,
    int importable,
    int total,
  );

  /// No description provided for @importConfirmDisabledQuizFull.
  ///
  /// In es, this message translates to:
  /// **'No puedes importar más preguntas: este cuestionario ya tiene {current} y el límite del plan es {max} por cuestionario.'**
  String importConfirmDisabledQuizFull(int current, int max);

  /// No description provided for @importPlanLimitConfirmNotice.
  ///
  /// In es, this message translates to:
  /// **'Se importaron {imported} preguntas. En el plan {plan} el máximo es {max} por cuestionario; {skipped} preguntas del archivo no se añadieron.'**
  String importPlanLimitConfirmNotice(
    int imported,
    String plan,
    int max,
    int skipped,
  );

  /// No description provided for @teacherAttemptsAction.
  ///
  /// In es, this message translates to:
  /// **'Ver intentos'**
  String get teacherAttemptsAction;

  /// No description provided for @teacherAttemptsTitle.
  ///
  /// In es, this message translates to:
  /// **'Intentos de práctica'**
  String get teacherAttemptsTitle;

  /// No description provided for @teacherAttemptsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay intentos finalizados'**
  String get teacherAttemptsEmpty;

  /// No description provided for @teacherAttemptsFilterLabel.
  ///
  /// In es, this message translates to:
  /// **'Estudiante'**
  String get teacherAttemptsFilterLabel;

  /// No description provided for @teacherAttemptsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos los estudiantes'**
  String get teacherAttemptsFilterAll;

  /// No description provided for @teacherAttemptsFilterEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay intentos para este estudiante'**
  String get teacherAttemptsFilterEmpty;

  /// No description provided for @teacherAttemptsStudentsSummary.
  ///
  /// In es, this message translates to:
  /// **'{students} estudiantes · {attempts} intentos'**
  String teacherAttemptsStudentsSummary(int students, int attempts);

  /// No description provided for @teacherAttemptsAttemptCountOne.
  ///
  /// In es, this message translates to:
  /// **'1 intento'**
  String get teacherAttemptsAttemptCountOne;

  /// No description provided for @teacherAttemptsAttemptCountMany.
  ///
  /// In es, this message translates to:
  /// **'{count} intentos'**
  String teacherAttemptsAttemptCountMany(int count);

  /// No description provided for @teacherAttemptRowTitle.
  ///
  /// In es, this message translates to:
  /// **'{date}'**
  String teacherAttemptRowTitle(String date);

  /// No description provided for @teacherAttemptTitle.
  ///
  /// In es, this message translates to:
  /// **'{name} · {date}'**
  String teacherAttemptTitle(String name, String date);

  /// No description provided for @teacherAttemptSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{obtained}/{possible} ({percent}%) · {status}'**
  String teacherAttemptSubtitle(
    double obtained,
    double possible,
    String percent,
    String status,
  );

  /// No description provided for @teacherAttemptSubtitleWithDuration.
  ///
  /// In es, this message translates to:
  /// **'{stats} · {duration}'**
  String teacherAttemptSubtitleWithDuration(String stats, String duration);

  /// No description provided for @teacherReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisión del intento'**
  String get teacherReviewTitle;

  /// No description provided for @teacherReviewStudentLabel.
  ///
  /// In es, this message translates to:
  /// **'Estudiante: {name}'**
  String teacherReviewStudentLabel(String name);

  /// No description provided for @teacherReviewScoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Puntuación: {obtained} / {possible}'**
  String teacherReviewScoreLabel(double obtained, double possible);

  /// No description provided for @teacherReviewQuestionLabel.
  ///
  /// In es, this message translates to:
  /// **'{order}. {text}'**
  String teacherReviewQuestionLabel(int order, String text);

  /// No description provided for @teacherReviewAnswerStatus.
  ///
  /// In es, this message translates to:
  /// **'{status} · {awarded}/{possible} pts'**
  String teacherReviewAnswerStatus(
    String status,
    double awarded,
    double possible,
  );

  /// No description provided for @billingPlanLabel.
  ///
  /// In es, this message translates to:
  /// **'Plan: {plan}'**
  String billingPlanLabel(String plan);

  /// No description provided for @billingPlanChipLabel.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get billingPlanChipLabel;

  /// No description provided for @billingUsageLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuestionarios: {quizzes}/{maxQuizzes}'**
  String billingUsageLabel(int quizzes, String maxQuizzes);

  /// No description provided for @billingQuizzesUnlimited.
  ///
  /// In es, this message translates to:
  /// **'Cuestionarios: Ilimitados'**
  String get billingQuizzesUnlimited;

  /// No description provided for @billingCreditsLabel.
  ///
  /// In es, this message translates to:
  /// **'Créditos IA este mes: {credits}'**
  String billingCreditsLabel(int credits);

  /// No description provided for @redeemCodeAction.
  ///
  /// In es, this message translates to:
  /// **'Canjear código'**
  String get redeemCodeAction;

  /// No description provided for @redeemCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Canjear código de acceso'**
  String get redeemCodeTitle;

  /// No description provided for @redeemCodeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce el código compartido por tu profesor o compañero'**
  String get redeemCodeSubtitle;

  /// No description provided for @redeemCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get redeemCodeLabel;

  /// No description provided for @redeemCodeRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce un código'**
  String get redeemCodeRequired;

  /// No description provided for @redeemCodeSuccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso concedido a \"{title}\"'**
  String redeemCodeSuccess(String title);

  /// No description provided for @redeemCodeAlreadyInShared.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes «{title}» en Mis compartidos.'**
  String redeemCodeAlreadyInShared(String title);

  /// No description provided for @accessibleQuizzesAction.
  ///
  /// In es, this message translates to:
  /// **'Cuestionarios compartidos'**
  String get accessibleQuizzesAction;

  /// No description provided for @accessibleQuizzesTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuestionarios compartidos'**
  String get accessibleQuizzesTitle;

  /// No description provided for @accessibleQuizzesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes cuestionarios compartidos. Canjea un código.'**
  String get accessibleQuizzesEmpty;

  /// No description provided for @accessibleQuizzesSharedBy.
  ///
  /// In es, this message translates to:
  /// **'Compartido por {name}'**
  String accessibleQuizzesSharedBy(String name);

  /// No description provided for @accessibleQuizzesGroupCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cuestionario} other{{count} cuestionarios}}'**
  String accessibleQuizzesGroupCount(int count);

  /// No description provided for @accessibleQuizzesRemoveAction.
  ///
  /// In es, this message translates to:
  /// **'Quitar de compartidos'**
  String get accessibleQuizzesRemoveAction;

  /// No description provided for @accessibleQuizzesRemoveConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar de compartidos?'**
  String get accessibleQuizzesRemoveConfirmTitle;

  /// No description provided for @accessibleQuizzesRemoveConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se quitará «{title}» de tu lista. El cuestionario no se borra; puedes volver a canjearlo con el código si lo necesitas.'**
  String accessibleQuizzesRemoveConfirmMessage(String title);

  /// No description provided for @accessibleQuizzesRemovedMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuestionario quitado de compartidos'**
  String get accessibleQuizzesRemovedMessage;

  /// No description provided for @accessibleQuizzesSlotBanner.
  ///
  /// In es, this message translates to:
  /// **'Cuestionarios compartidos: {current}/{max}'**
  String accessibleQuizzesSlotBanner(int current, int max);

  /// No description provided for @accessibleQuizzesSlotFull.
  ///
  /// In es, this message translates to:
  /// **'Cupo completo en plan Free. Quita uno para canjear otro código.'**
  String get accessibleQuizzesSlotFull;

  /// No description provided for @errorSharedQuizSlotLimit.
  ///
  /// In es, this message translates to:
  /// **'Tu plan Free permite {max} cuestionarios compartidos. Quita uno de Mis compartidos para canjear otro.'**
  String errorSharedQuizSlotLimit(int max);

  /// No description provided for @errorCannotRedeemOwnQuiz.
  ///
  /// In es, this message translates to:
  /// **'No puedes canjear el código de un cuestionario que tú creaste. Ábrelo desde Mis cuestionarios.'**
  String get errorCannotRedeemOwnQuiz;

  /// No description provided for @shareCodeViewAction.
  ///
  /// In es, this message translates to:
  /// **'Ver código'**
  String get shareCodeViewAction;

  /// No description provided for @shareCodeExistingHint.
  ///
  /// In es, this message translates to:
  /// **'Este es el código permanente de este cuestionario.'**
  String get shareCodeExistingHint;

  /// No description provided for @myQuizAnalyticsAction.
  ///
  /// In es, this message translates to:
  /// **'Mi analítica'**
  String get myQuizAnalyticsAction;

  /// No description provided for @myQuizAnalyticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi analítica de práctica'**
  String get myQuizAnalyticsTitle;

  /// No description provided for @myPracticeAttemptsAction.
  ///
  /// In es, this message translates to:
  /// **'Mis intentos'**
  String get myPracticeAttemptsAction;

  /// No description provided for @myPracticeAttemptsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis intentos de práctica'**
  String get myPracticeAttemptsTitle;

  /// No description provided for @myPracticeAttemptsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has completado ningún intento en este cuestionario.'**
  String get myPracticeAttemptsEmpty;

  /// No description provided for @myPracticeReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisión de mi intento'**
  String get myPracticeReviewTitle;

  /// No description provided for @myQuizAnalyticsAttemptsLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} intentos completados'**
  String myQuizAnalyticsAttemptsLabel(int count);

  /// No description provided for @myQuizAnalyticsAverageLabel.
  ///
  /// In es, this message translates to:
  /// **'Promedio: {percentage}%'**
  String myQuizAnalyticsAverageLabel(double percentage);

  /// No description provided for @myQuizAnalyticsBestLabel.
  ///
  /// In es, this message translates to:
  /// **'Mejor: {percentage}%'**
  String myQuizAnalyticsBestLabel(double percentage);

  /// No description provided for @createShareCodeAction.
  ///
  /// In es, this message translates to:
  /// **'Generar código'**
  String get createShareCodeAction;

  /// No description provided for @shareCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Código de acceso'**
  String get shareCodeTitle;

  /// No description provided for @shareCodeCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir cuestionario'**
  String get shareCodeCreateTitle;

  /// No description provided for @shareCodeCreateTeacherSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige si cualquiera puede practicar o solo tu grupo.'**
  String get shareCodeCreateTeacherSubtitle;

  /// No description provided for @shareCodeCreateStudentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se generará un código para que muchas personas practiquen (sin ver intentos ajenos).'**
  String get shareCodeCreateStudentSubtitle;

  /// No description provided for @shareCodeAudienceAnyone.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera'**
  String get shareCodeAudienceAnyone;

  /// No description provided for @shareCodeAudienceAnyoneHint.
  ///
  /// In es, this message translates to:
  /// **'Con o sin cuenta. Mismo código para todos.'**
  String get shareCodeAudienceAnyoneHint;

  /// No description provided for @shareCodeAudienceGroup.
  ///
  /// In es, this message translates to:
  /// **'Solo mi grupo'**
  String get shareCodeAudienceGroup;

  /// No description provided for @shareCodeAudienceGroupHint.
  ///
  /// In es, this message translates to:
  /// **'Solo estudiantes de la clase que elijas (requieren cuenta).'**
  String get shareCodeAudienceGroupHint;

  /// No description provided for @shareCodeSelectClassLabel.
  ///
  /// In es, this message translates to:
  /// **'Clase'**
  String get shareCodeSelectClassLabel;

  /// No description provided for @shareCodeClassOption.
  ///
  /// In es, this message translates to:
  /// **'{name} ({count} estudiantes)'**
  String shareCodeClassOption(String name, int count);

  /// No description provided for @shareCodeNoClasses.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes clases. Crea una clase para compartir solo con tu grupo.'**
  String get shareCodeNoClasses;

  /// No description provided for @shareCodeGroupRequired.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una clase para compartir con el grupo.'**
  String get shareCodeGroupRequired;

  /// No description provided for @shareCodeResultOpenHint.
  ///
  /// In es, this message translates to:
  /// **'Válido para muchas personas. También sirve en «Practicar con código» sin cuenta.'**
  String get shareCodeResultOpenHint;

  /// No description provided for @shareCodeResultGroupHint.
  ///
  /// In es, this message translates to:
  /// **'Solo miembros de la clase seleccionada, con cuenta.'**
  String get shareCodeResultGroupHint;

  /// No description provided for @shareCodeCopyAction.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get shareCodeCopyAction;

  /// No description provided for @shareCodeCopied.
  ///
  /// In es, this message translates to:
  /// **'Código copiado'**
  String get shareCodeCopied;

  /// No description provided for @shareCodeCloseAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get shareCodeCloseAction;

  /// No description provided for @quizInviteTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitar personas'**
  String get quizInviteTitle;

  /// No description provided for @quizInviteSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La persona debe tener cuenta en CraftQuest. Aparecerá el cuestionario en Mis compartidos (sin código).'**
  String get quizInviteSubtitle;

  /// No description provided for @quizInviteEmailsLabel.
  ///
  /// In es, this message translates to:
  /// **'Correos'**
  String get quizInviteEmailsLabel;

  /// No description provided for @quizInviteEmailsHint.
  ///
  /// In es, this message translates to:
  /// **'uno@correo.com, otro@correo.com'**
  String get quizInviteEmailsHint;

  /// No description provided for @quizInviteAction.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get quizInviteAction;

  /// No description provided for @quizInviteEmailsRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce al menos un correo válido.'**
  String get quizInviteEmailsRequired;

  /// No description provided for @quizInviteSuccessCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 persona invitada} other{{count} personas invitadas}}'**
  String quizInviteSuccessCount(int count);

  /// No description provided for @quizInviteOutcomeInvited.
  ///
  /// In es, this message translates to:
  /// **'{name}: invitado/a'**
  String quizInviteOutcomeInvited(String name);

  /// No description provided for @quizInviteOutcomeAlreadyHadAccess.
  ///
  /// In es, this message translates to:
  /// **'{name}: ya tenía acceso'**
  String quizInviteOutcomeAlreadyHadAccess(String name);

  /// No description provided for @quizInviteOutcomeNotFound.
  ///
  /// In es, this message translates to:
  /// **'{email}: no hay cuenta con ese correo'**
  String quizInviteOutcomeNotFound(String email);

  /// No description provided for @quizInviteOutcomeInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'{email}: correo no válido'**
  String quizInviteOutcomeInvalidEmail(String email);

  /// No description provided for @quizInviteOutcomeSlotLimit.
  ///
  /// In es, this message translates to:
  /// **'{name}: sin cupo en plan Free'**
  String quizInviteOutcomeSlotLimit(String name);

  /// No description provided for @quizInviteOutcomeSelf.
  ///
  /// In es, this message translates to:
  /// **'No puedes invitarte a ti mismo/a'**
  String get quizInviteOutcomeSelf;

  /// No description provided for @errorDirectInviteNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'Las invitaciones directas requieren plan Pro o Profesor.'**
  String get errorDirectInviteNotAllowed;

  /// No description provided for @errorActivePracticeSession.
  ///
  /// In es, this message translates to:
  /// **'Tienes una práctica en curso. Continúa o empieza de nuevo.'**
  String get errorActivePracticeSession;

  /// No description provided for @aiNormalizeAction.
  ///
  /// In es, this message translates to:
  /// **'Normalizar con IA'**
  String get aiNormalizeAction;

  /// No description provided for @aiImproveImportAction.
  ///
  /// In es, this message translates to:
  /// **'Mejorar con IA'**
  String get aiImproveImportAction;

  /// No description provided for @aiNormalizeSuccess.
  ///
  /// In es, this message translates to:
  /// **'Normalización IA completada'**
  String get aiNormalizeSuccess;

  /// No description provided for @quizAnalyticsAction.
  ///
  /// In es, this message translates to:
  /// **'Analítica'**
  String get quizAnalyticsAction;

  /// No description provided for @quizAnalyticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Analítica del cuestionario'**
  String get quizAnalyticsTitle;

  /// No description provided for @quizAnalyticsSessionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Intentos finalizados: {count}'**
  String quizAnalyticsSessionsLabel(int count);

  /// No description provided for @quizAnalyticsQuestionStats.
  ///
  /// In es, this message translates to:
  /// **'{attempts} intentos · {correct} correctas · {incorrect} incorrectas'**
  String quizAnalyticsQuestionStats(int attempts, int correct, int incorrect);

  /// No description provided for @quizAnalyticsOptionLabel.
  ///
  /// In es, this message translates to:
  /// **'{key}: {text} — {count} ({rate}%){correct}'**
  String quizAnalyticsOptionLabel(
    String key,
    String text,
    int count,
    double rate,
    String correct,
  );

  /// No description provided for @attachImageAction.
  ///
  /// In es, this message translates to:
  /// **'Adjuntar imagen'**
  String get attachImageAction;

  /// No description provided for @removeImageAction.
  ///
  /// In es, this message translates to:
  /// **'Quitar imagen'**
  String get removeImageAction;

  /// No description provided for @viewFullImageAction.
  ///
  /// In es, this message translates to:
  /// **'Ver imagen completa'**
  String get viewFullImageAction;

  /// No description provided for @closeAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get closeAction;

  /// No description provided for @imageLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la imagen'**
  String get imageLoadError;

  /// No description provided for @upgradePlanAction.
  ///
  /// In es, this message translates to:
  /// **'Mejorar plan'**
  String get upgradePlanAction;

  /// No description provided for @upgradePlanTitle.
  ///
  /// In es, this message translates to:
  /// **'Mejorar plan'**
  String get upgradePlanTitle;

  /// No description provided for @upgradePlanSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Compara los planes y elige el que más te conviene.'**
  String get upgradePlanSubtitle;

  /// No description provided for @upgradePlanAlreadyHighest.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes el plan más alto disponible. No hay más mejoras por ahora.'**
  String get upgradePlanAlreadyHighest;

  /// No description provided for @upgradeProHighlightQuizzes.
  ///
  /// In es, this message translates to:
  /// **'Cuestionarios ilimitados (tu plan actual: máx. 5)'**
  String get upgradeProHighlightQuizzes;

  /// No description provided for @upgradeProHighlightQuestions.
  ///
  /// In es, this message translates to:
  /// **'Sin límite de preguntas por cuestionario (tu plan actual: 65)'**
  String get upgradeProHighlightQuestions;

  /// No description provided for @upgradeProHighlightAiCredits.
  ///
  /// In es, this message translates to:
  /// **'150 créditos IA al mes (tu plan actual: 20)'**
  String get upgradeProHighlightAiCredits;

  /// No description provided for @upgradeProHighlightShared.
  ///
  /// In es, this message translates to:
  /// **'Compartidos ilimitados al canjear o invitar'**
  String get upgradeProHighlightShared;

  /// No description provided for @upgradeProHighlightDirectInvite.
  ///
  /// In es, this message translates to:
  /// **'Invita a personas concretas por correo'**
  String get upgradeProHighlightDirectInvite;

  /// No description provided for @upgradeTeacherHighlightIncludesPro.
  ///
  /// In es, this message translates to:
  /// **'Todo lo incluido en Pro'**
  String get upgradeTeacherHighlightIncludesPro;

  /// No description provided for @upgradeTeacherHighlightAiCredits.
  ///
  /// In es, this message translates to:
  /// **'360 créditos IA al mes para más generaciones'**
  String get upgradeTeacherHighlightAiCredits;

  /// No description provided for @upgradeTeacherHighlightClasses.
  ///
  /// In es, this message translates to:
  /// **'Clases y grupos de estudiantes'**
  String get upgradeTeacherHighlightClasses;

  /// No description provided for @upgradeTeacherHighlightAssignments.
  ///
  /// In es, this message translates to:
  /// **'Asignaciones con fechas, intentos y revisión'**
  String get upgradeTeacherHighlightAssignments;

  /// No description provided for @upgradeTeacherHighlightGroupShare.
  ///
  /// In es, this message translates to:
  /// **'Comparte códigos solo con tu clase'**
  String get upgradeTeacherHighlightGroupShare;

  /// No description provided for @upgradeTeacherHighlightTracking.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de intentos y resultados por alumno'**
  String get upgradeTeacherHighlightTracking;

  /// No description provided for @buyWithStoreAction.
  ///
  /// In es, this message translates to:
  /// **'Comprar en la tienda'**
  String get buyWithStoreAction;

  /// No description provided for @buyWithPayPalAction.
  ///
  /// In es, this message translates to:
  /// **'Pagar con PayPal'**
  String get buyWithPayPalAction;

  /// No description provided for @paypalWebHint.
  ///
  /// In es, this message translates to:
  /// **'En la web, PayPal es el método de pago recomendado.'**
  String get paypalWebHint;

  /// No description provided for @paypalAwaitingCapture.
  ///
  /// In es, this message translates to:
  /// **'Completa el pago en PayPal y confirma la captura.'**
  String get paypalAwaitingCapture;

  /// No description provided for @upgradeSuccess.
  ///
  /// In es, this message translates to:
  /// **'Plan activado: {plan}'**
  String upgradeSuccess(String plan);

  /// No description provided for @storeProductNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'Producto de tienda no configurado'**
  String get storeProductNotConfigured;

  /// No description provided for @storeProductNotFound.
  ///
  /// In es, this message translates to:
  /// **'Producto no encontrado: {id}'**
  String storeProductNotFound(String id);

  /// No description provided for @purchaseFailed.
  ///
  /// In es, this message translates to:
  /// **'La compra no se completó'**
  String get purchaseFailed;

  /// No description provided for @purchaseVerificationFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos verificar tu compra. Inténtalo de nuevo en unos momentos.'**
  String get purchaseVerificationFailed;

  /// No description provided for @contactSales.
  ///
  /// In es, this message translates to:
  /// **'Contactar ventas'**
  String get contactSales;

  /// No description provided for @aiGenerationHubTitle.
  ///
  /// In es, this message translates to:
  /// **'Generar con IA'**
  String get aiGenerationHubTitle;

  /// No description provided for @aiGenerationHubSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sube PDF o Word con texto seleccionable y crea un cuestionario revisable en minutos.'**
  String get aiGenerationHubSubtitle;

  /// No description provided for @aiGenerationHubAction.
  ///
  /// In es, this message translates to:
  /// **'Crear desde material'**
  String get aiGenerationHubAction;

  /// No description provided for @aiGenerationLibraryTitle.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca de materiales'**
  String get aiGenerationLibraryTitle;

  /// No description provided for @aiGenerationLibraryRetentionHint.
  ///
  /// In es, this message translates to:
  /// **'Los materiales se eliminan solos a los {days} días. Puedes borrarlos antes con el icono de papelera.'**
  String aiGenerationLibraryRetentionHint(int days);

  /// No description provided for @aiGenerationLibraryExpiresOn.
  ///
  /// In es, this message translates to:
  /// **'Eliminación automática: {date}'**
  String aiGenerationLibraryExpiresOn(String date);

  /// No description provided for @aiGenerationLibraryMaterialCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 material} other{{count} materiales}}'**
  String aiGenerationLibraryMaterialCount(int count);

  /// No description provided for @aiGenerationLibraryStatusReady.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get aiGenerationLibraryStatusReady;

  /// No description provided for @aiGenerationLibraryStatusProcessing.
  ///
  /// In es, this message translates to:
  /// **'Procesando'**
  String get aiGenerationLibraryStatusProcessing;

  /// No description provided for @aiGenerationLibraryStatusFailed.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get aiGenerationLibraryStatusFailed;

  /// No description provided for @aiGenerationLibraryStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get aiGenerationLibraryStatusPending;

  /// No description provided for @aiGenerationLibraryUploaded.
  ///
  /// In es, this message translates to:
  /// **'Subido el {date}'**
  String aiGenerationLibraryUploaded(String date);

  /// No description provided for @aiGenerationLibraryExpiresInDays.
  ///
  /// In es, this message translates to:
  /// **'Se elimina en {days} días'**
  String aiGenerationLibraryExpiresInDays(int days);

  /// No description provided for @aiGenerationLibraryNeedsReview.
  ///
  /// In es, this message translates to:
  /// **'Revisar texto'**
  String get aiGenerationLibraryNeedsReview;

  /// No description provided for @aiGenerationLibraryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes materiales guardados.'**
  String get aiGenerationLibraryEmpty;

  /// No description provided for @aiGenerationLibraryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los PDF y Word que subas para generar con IA aparecerán aquí.'**
  String get aiGenerationLibraryEmptySubtitle;

  /// No description provided for @aiGenerationLibraryAction.
  ///
  /// In es, this message translates to:
  /// **'Ver biblioteca'**
  String get aiGenerationLibraryAction;

  /// No description provided for @deleteStudyMaterialConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar material'**
  String get deleteStudyMaterialConfirmTitle;

  /// No description provided for @deleteStudyMaterialConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{title}\" y su texto extraído. El cuestionario generado se conservará. Esta acción no se puede deshacer.'**
  String deleteStudyMaterialConfirmMessage(String title);

  /// No description provided for @deleteStudyMaterialAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteStudyMaterialAction;

  /// No description provided for @studyMaterialDeletedMessage.
  ///
  /// In es, this message translates to:
  /// **'Material eliminado'**
  String get studyMaterialDeletedMessage;

  /// No description provided for @aiGenerationUploadTitle.
  ///
  /// In es, this message translates to:
  /// **'Subir material'**
  String get aiGenerationUploadTitle;

  /// No description provided for @aiGenerationUploadSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sube un PDF o Word con texto copiable. Revisarás el alcance de páginas antes de generar el cuestionario.'**
  String get aiGenerationUploadSubtitle;

  /// No description provided for @aiGenerationUploadHeroDrop.
  ///
  /// In es, this message translates to:
  /// **'Arrastra tu PDF o Word aquí'**
  String get aiGenerationUploadHeroDrop;

  /// No description provided for @aiGenerationUploadHeroPick.
  ///
  /// In es, this message translates to:
  /// **'o elige un archivo desde tu dispositivo'**
  String get aiGenerationUploadHeroPick;

  /// No description provided for @aiGenerationUploadFormatGuideTitle.
  ///
  /// In es, this message translates to:
  /// **'Consejos y límites de formato'**
  String get aiGenerationUploadFormatGuideTitle;

  /// No description provided for @aiGenerationUploadHint.
  ///
  /// In es, this message translates to:
  /// **'PDF o DOCX con texto seleccionable, no escaneados (máx. 25 MB)'**
  String get aiGenerationUploadHint;

  /// No description provided for @aiGenerationUploadLimitsHint.
  ///
  /// In es, this message translates to:
  /// **'Hasta {maxPagesPerFile} páginas por archivo · hasta {maxPagesPerGeneration} páginas por generación'**
  String aiGenerationUploadLimitsHint(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  );

  /// No description provided for @aiGenerationUploadLimitsSteps.
  ///
  /// In es, this message translates to:
  /// **'Si el documento es más largo, divídelo en varios archivos (cada uno con {maxPagesPerFile} páginas o menos) o exporta solo el capítulo que necesitas. Después podrás generar el cuestionario por tramos de hasta {maxPagesPerGeneration} páginas.'**
  String aiGenerationUploadLimitsSteps(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  );

  /// No description provided for @errorMaterialPageLimitGuidance.
  ///
  /// In es, this message translates to:
  /// **'Qué puedes hacer: divide el PDF o Word en partes de {maxPagesPerFile} páginas o menos (por capítulos o bloques) y súbelas por separado. En cada material, genera el quiz eligiendo hasta {maxPagesPerGeneration} páginas a la vez.'**
  String errorMaterialPageLimitGuidance(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  );

  /// No description provided for @aiGenerationUploadAnotherFileAction.
  ///
  /// In es, this message translates to:
  /// **'Subir otro archivo'**
  String get aiGenerationUploadAnotherFileAction;

  /// No description provided for @aiGenerationDropHint.
  ///
  /// In es, this message translates to:
  /// **'También puedes arrastrar archivos aquí'**
  String get aiGenerationDropHint;

  /// No description provided for @aiGenerationUploadAction.
  ///
  /// In es, this message translates to:
  /// **'Subir y analizar'**
  String get aiGenerationUploadAction;

  /// No description provided for @aiGenerationUploadFileReady.
  ///
  /// In es, this message translates to:
  /// **'Archivo listo para subir'**
  String get aiGenerationUploadFileReady;

  /// No description provided for @aiGenerationUploadChangeFile.
  ///
  /// In es, this message translates to:
  /// **'Cambiar archivo'**
  String get aiGenerationUploadChangeFile;

  /// No description provided for @aiGenerationUploadRemoveFile.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get aiGenerationUploadRemoveFile;

  /// No description provided for @aiGenerationProcessing.
  ///
  /// In es, this message translates to:
  /// **'Analizando documento…'**
  String get aiGenerationProcessing;

  /// No description provided for @aiGenerationNeedsOcr.
  ///
  /// In es, this message translates to:
  /// **'Poco texto detectado. Usa un PDF o Word con texto seleccionable, o revisa y pega el contenido.'**
  String get aiGenerationNeedsOcr;

  /// No description provided for @aiGenerationReviewTextTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar texto'**
  String get aiGenerationReviewTextTitle;

  /// No description provided for @aiGenerationReviewTextHint.
  ///
  /// In es, this message translates to:
  /// **'El documento tiene poco texto extraíble. Corrige lo detectado o pega el contenido con texto seleccionable.'**
  String get aiGenerationReviewTextHint;

  /// No description provided for @aiGenerationReviewTextSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar y continuar'**
  String get aiGenerationReviewTextSave;

  /// No description provided for @aiGenerationReviewTextAction.
  ///
  /// In es, this message translates to:
  /// **'Revisar texto'**
  String get aiGenerationReviewTextAction;

  /// No description provided for @aiGenerationOutlineTitle.
  ///
  /// In es, this message translates to:
  /// **'Alcance del material'**
  String get aiGenerationOutlineTitle;

  /// No description provided for @aiGenerationPageRange.
  ///
  /// In es, this message translates to:
  /// **'Páginas {from}–{to}'**
  String aiGenerationPageRange(int from, int to);

  /// No description provided for @aiGenerationPageRangeOfTotal.
  ///
  /// In es, this message translates to:
  /// **'Páginas {from}–{to} de {total}'**
  String aiGenerationPageRangeOfTotal(int from, int to, int total);

  /// No description provided for @aiGenerationPageRangeHelp.
  ///
  /// In es, this message translates to:
  /// **'Elige qué páginas del documento usarán para generar el cuestionario. Arrastra cada extremo del control para acotar el tramo.'**
  String get aiGenerationPageRangeHelp;

  /// No description provided for @aiGenerationPageRangeSelectedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 página en este tramo} other{{count} páginas en este tramo}}'**
  String aiGenerationPageRangeSelectedCount(int count);

  /// No description provided for @aiGenerationPageRangeOverLimit.
  ///
  /// In es, this message translates to:
  /// **'Máximo {max} páginas por generación. Reduce el tramo seleccionado.'**
  String aiGenerationPageRangeOverLimit(int max);

  /// No description provided for @aiGenerationWordsInScopePurpose.
  ///
  /// In es, this message translates to:
  /// **'La IA generará preguntas a partir de aproximadamente {words} palabras en ese tramo.'**
  String aiGenerationWordsInScopePurpose(int words);

  /// No description provided for @aiGenerationTopicHint.
  ///
  /// In es, this message translates to:
  /// **'Enfoque opcional (tema o apartado)'**
  String get aiGenerationTopicHint;

  /// No description provided for @aiGenerationWordsInScope.
  ///
  /// In es, this message translates to:
  /// **'{words} palabras en el alcance'**
  String aiGenerationWordsInScope(int words);

  /// No description provided for @aiGenerationParamsTitle.
  ///
  /// In es, this message translates to:
  /// **'Parámetros de generación'**
  String get aiGenerationParamsTitle;

  /// No description provided for @aiGenerationMaterialLanguageNotice.
  ///
  /// In es, this message translates to:
  /// **'Las preguntas se generarán en {language} según el idioma del material.'**
  String aiGenerationMaterialLanguageNotice(String language);

  /// No description provided for @aiGenerationPresetQuick.
  ///
  /// In es, this message translates to:
  /// **'Repaso rápido'**
  String get aiGenerationPresetQuick;

  /// No description provided for @aiGenerationPresetStandard.
  ///
  /// In es, this message translates to:
  /// **'Examen estándar'**
  String get aiGenerationPresetStandard;

  /// No description provided for @aiGenerationPresetDeep.
  ///
  /// In es, this message translates to:
  /// **'Práctica profunda'**
  String get aiGenerationPresetDeep;

  /// No description provided for @aiGenerationQuestionCount.
  ///
  /// In es, this message translates to:
  /// **'Número de preguntas'**
  String get aiGenerationQuestionCount;

  /// No description provided for @aiGenerationQuestionCountOfMax.
  ///
  /// In es, this message translates to:
  /// **'{count} de {max}'**
  String aiGenerationQuestionCountOfMax(int count, int max);

  /// No description provided for @aiGenerationQuestionTypes.
  ///
  /// In es, this message translates to:
  /// **'Tipos de pregunta'**
  String get aiGenerationQuestionTypes;

  /// No description provided for @aiGenerationTypeSingleChoice.
  ///
  /// In es, this message translates to:
  /// **'Opción única'**
  String get aiGenerationTypeSingleChoice;

  /// No description provided for @aiGenerationTypeMultipleChoice.
  ///
  /// In es, this message translates to:
  /// **'Opción múltiple'**
  String get aiGenerationTypeMultipleChoice;

  /// No description provided for @aiGenerationTypeTrueFalse.
  ///
  /// In es, this message translates to:
  /// **'Verdadero / falso'**
  String get aiGenerationTypeTrueFalse;

  /// No description provided for @aiGenerationDifficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get aiGenerationDifficulty;

  /// No description provided for @aiGenerationDifficultyEasy.
  ///
  /// In es, this message translates to:
  /// **'Fácil'**
  String get aiGenerationDifficultyEasy;

  /// No description provided for @aiGenerationDifficultyMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get aiGenerationDifficultyMedium;

  /// No description provided for @aiGenerationDifficultyHard.
  ///
  /// In es, this message translates to:
  /// **'Difícil'**
  String get aiGenerationDifficultyHard;

  /// No description provided for @aiGenerationDifficultyMixed.
  ///
  /// In es, this message translates to:
  /// **'Mixta'**
  String get aiGenerationDifficultyMixed;

  /// No description provided for @aiGenerationCreditsCost.
  ///
  /// In es, this message translates to:
  /// **'Consumirá {credits} créditos IA ({available} disponibles)'**
  String aiGenerationCreditsCost(int credits, int available);

  /// No description provided for @aiGenerationStartAction.
  ///
  /// In es, this message translates to:
  /// **'Generar cuestionario'**
  String get aiGenerationStartAction;

  /// No description provided for @aiGenerationProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Generando cuestionario'**
  String get aiGenerationProgressTitle;

  /// No description provided for @aiGenerationProgressSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La IA está creando preguntas a partir de tu material…'**
  String get aiGenerationProgressSubtitle;

  /// No description provided for @aiGenerationProgressDeferredRetry.
  ///
  /// In es, this message translates to:
  /// **'El servicio de IA está saturado. Reintentaremos automáticamente en breve.'**
  String get aiGenerationProgressDeferredRetry;

  /// No description provided for @aiGenerationProgressDeferredRetryMinutes.
  ///
  /// In es, this message translates to:
  /// **'Reintento automático en unos {minutes} min. Puedes dejar esta pantalla abierta.'**
  String aiGenerationProgressDeferredRetryMinutes(int minutes);

  /// No description provided for @aiGenerationProgressAutoRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintento automático {attempt} en curso…'**
  String aiGenerationProgressAutoRetry(int attempt);

  /// No description provided for @aiGenerationCreditsNotConsumed.
  ///
  /// In es, this message translates to:
  /// **'No se han descontado créditos de IA.'**
  String get aiGenerationCreditsNotConsumed;

  /// No description provided for @aiGenerationRetryAction.
  ///
  /// In es, this message translates to:
  /// **'Reintentar generación'**
  String get aiGenerationRetryAction;

  /// No description provided for @aiGenerationProgressTakingLong.
  ///
  /// In es, this message translates to:
  /// **'Sigue en curso (puede tardar varios minutos). Si se interrumpió la API, reiníciala o pulsa Reintentar.'**
  String get aiGenerationProgressTakingLong;

  /// No description provided for @aiGenerationProgressStuck.
  ///
  /// In es, this message translates to:
  /// **'La generación parece bloqueada en el servidor.'**
  String get aiGenerationProgressStuck;

  /// No description provided for @aiGenerationProgressStuckDetail.
  ///
  /// In es, this message translates to:
  /// **'El trabajo lleva demasiado tiempo en «procesando» sin avanzar. Vuelve atrás y genera de nuevo; no se han descontado créditos si no terminó.'**
  String get aiGenerationProgressStuckDetail;

  /// No description provided for @aiGenerationStuckGoBackAction.
  ///
  /// In es, this message translates to:
  /// **'Volver y generar de nuevo'**
  String get aiGenerationStuckGoBackAction;

  /// No description provided for @errorSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Vuelve a iniciar sesión e inténtalo de nuevo.'**
  String get errorSessionExpired;

  /// No description provided for @aiGenerationFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar el cuestionario'**
  String get aiGenerationFailed;

  /// No description provided for @errorGenerationJobNotRetryable.
  ///
  /// In es, this message translates to:
  /// **'Este trabajo de generación no se puede reintentar ahora.'**
  String get errorGenerationJobNotRetryable;

  /// No description provided for @errorGuestNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'Este código requiere una cuenta registrada. Crea una cuenta gratuita para continuar.'**
  String get errorGuestNotAllowed;

  /// No description provided for @errorGroupAccessDenied.
  ///
  /// In es, this message translates to:
  /// **'Este código es solo para miembros de la clase «{className}».'**
  String errorGroupAccessDenied(String className);

  /// No description provided for @errorGroupAccessDeniedGeneric.
  ///
  /// In es, this message translates to:
  /// **'Este código es solo para miembros de la clase del profesor.'**
  String get errorGroupAccessDeniedGeneric;

  /// No description provided for @errorAiGenerationInvalidOutput.
  ///
  /// In es, this message translates to:
  /// **'La IA devolvió un formato inválido. Pulsa «Reintentar generación»; no se han descontado créditos.'**
  String get errorAiGenerationInvalidOutput;

  /// No description provided for @aiGenerationFromQuizAction.
  ///
  /// In es, this message translates to:
  /// **'Generar con IA desde material'**
  String get aiGenerationFromQuizAction;

  /// No description provided for @importAiGeneratedBadge.
  ///
  /// In es, this message translates to:
  /// **'Generada por IA'**
  String get importAiGeneratedBadge;

  /// No description provided for @errorAiCreditsInsufficient.
  ///
  /// In es, this message translates to:
  /// **'No tienes créditos IA suficientes para esta generación.'**
  String get errorAiCreditsInsufficient;

  /// No description provided for @errorMaterialNeedsOcr.
  ///
  /// In es, this message translates to:
  /// **'Hay poco texto extraíble. Usa PDF o Word con texto seleccionable, o revisa y pega el contenido.'**
  String get errorMaterialNeedsOcr;

  /// No description provided for @errorMaterialNotSelectableText.
  ///
  /// In es, this message translates to:
  /// **'Este archivo parece escaneado o sin texto seleccionable.'**
  String get errorMaterialNotSelectableText;

  /// No description provided for @errorMaterialNotSelectableTextGuidance.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones:\n• Abre el archivo y comprueba que puedes seleccionar y copiar párrafos (no solo hacer zoom).\n• Si es un escaneo: en Word, Archivo → Abrir el PDF y deja que reconozca el texto; revisa y guarda como DOCX.\n• Alternativa: OCR externo (Adobe, Google Drive), pega el texto en Word y súbelo como DOCX.\n• Exporta desde Word o Google Docs; evita PDFs hechos solo con fotos o «imprimir a imagen».\n• Vuelve a subir DOCX o PDF exportado desde Word con texto seleccionable.'**
  String get errorMaterialNotSelectableTextGuidance;

  /// No description provided for @errorMaterialNeedsOcrGuidance.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones:\n• Usa un PDF o DOCX donde puedas seleccionar y copiar el texto.\n• Si el original es escaneado, conviértelo a Word con texto (ver pasos de OCR arriba) y súbelo como DOCX.\n• También puedes pegar el contenido en Word, guardar como DOCX y subir ese archivo.'**
  String get errorMaterialNeedsOcrGuidance;

  /// No description provided for @errorMaterialTooLargeGuidance.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones:\n• El límite es 25 MB por archivo.\n• Comprime imágenes embebidas en Word o exporta solo el capítulo que necesitas.\n• Divide el documento en varios archivos más pequeños si sigue siendo pesado.'**
  String get errorMaterialTooLargeGuidance;

  /// No description provided for @aiGenerationUploadRecommendationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones'**
  String get aiGenerationUploadRecommendationsTitle;

  /// No description provided for @aiGenerationUploadSelectableTextHint.
  ///
  /// In es, this message translates to:
  /// **'El PDF o Word debe permitir seleccionar y copiar texto. Los documentos escaneados no son válidos.'**
  String get aiGenerationUploadSelectableTextHint;

  /// No description provided for @errorMaterialTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El archivo supera el tamaño máximo permitido.'**
  String get errorMaterialTooLarge;

  /// No description provided for @errorMaterialPageLimitExceeded.
  ///
  /// In es, this message translates to:
  /// **'El documento supera el máximo de {maxPages} páginas por archivo.'**
  String errorMaterialPageLimitExceeded(int maxPages);

  /// No description provided for @errorGenerationPageRangeExceeded.
  ///
  /// In es, this message translates to:
  /// **'Solo puedes generar desde un máximo de {maxPages} páginas por vez.'**
  String errorGenerationPageRangeExceeded(int maxPages);

  /// No description provided for @errorGenerationScopeEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay texto en el rango de páginas seleccionado.'**
  String get errorGenerationScopeEmpty;

  /// No description provided for @errorGenerationAlreadyInProgress.
  ///
  /// In es, this message translates to:
  /// **'Ya hay una generación en curso para este material.'**
  String get errorGenerationAlreadyInProgress;

  /// No description provided for @errorAiNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'La generación con IA no está configurada en el servidor.'**
  String get errorAiNotConfigured;

  /// No description provided for @errorAiGeminiQuotaExhausted.
  ///
  /// In es, this message translates to:
  /// **'Se agotaron los créditos de Gemini. Añade saldo en Google AI Studio (ai.google.dev) y vuelve a intentarlo.'**
  String get errorAiGeminiQuotaExhausted;

  /// No description provided for @errorAiGeminiModelUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El modelo de Gemini configurado ya no está disponible. Actualiza Ai:GeminiModel a gemini-2.5-flash y reinicia la API.'**
  String get errorAiGeminiModelUnavailable;

  /// No description provided for @errorAiGeminiOverloaded.
  ///
  /// In es, this message translates to:
  /// **'Gemini tiene mucha demanda ahora mismo. Espera unos minutos y vuelve a intentar la generación.'**
  String get errorAiGeminiOverloaded;

  /// No description provided for @aiActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad IA'**
  String get aiActivityTitle;

  /// No description provided for @aiActivityAction.
  ///
  /// In es, this message translates to:
  /// **'Actividad IA'**
  String get aiActivityAction;

  /// No description provided for @aiActivityEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay generaciones recientes. Al generar un cuestionario aparecerán aquí, aunque cierres la app.'**
  String get aiActivityEmpty;

  /// No description provided for @aiActivityStatusDraftReady.
  ///
  /// In es, this message translates to:
  /// **'Borrador listo'**
  String get aiActivityStatusDraftReady;

  /// No description provided for @aiActivityStatusFailed.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get aiActivityStatusFailed;

  /// No description provided for @aiActivityStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get aiActivityStatusCompleted;

  /// No description provided for @aiActivityReviewDraft.
  ///
  /// In es, this message translates to:
  /// **'Toca para revisar e importar el borrador'**
  String get aiActivityReviewDraft;

  /// No description provided for @aiActivityViewProgress.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver el progreso'**
  String get aiActivityViewProgress;

  /// No description provided for @aiActivityTapForDetails.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver el detalle'**
  String get aiActivityTapForDetails;

  /// No description provided for @aiActivityUnknownMaterial.
  ///
  /// In es, this message translates to:
  /// **'Material'**
  String get aiActivityUnknownMaterial;

  /// No description provided for @aiActivityPagesRange.
  ///
  /// In es, this message translates to:
  /// **'Páginas {from}–{to}'**
  String aiActivityPagesRange(int from, int to);

  /// No description provided for @aiLibraryStatusDraftReady.
  ///
  /// In es, this message translates to:
  /// **'Borrador listo'**
  String get aiLibraryStatusDraftReady;

  /// No description provided for @aiGenerationBackgroundSnack.
  ///
  /// In es, this message translates to:
  /// **'Generación en segundo plano. Puedes salir; retómala en Actividad IA o en la biblioteca.'**
  String get aiGenerationBackgroundSnack;

  /// No description provided for @aiGenerationResumedSnack.
  ///
  /// In es, this message translates to:
  /// **'Ya había una generación en curso para este material. Mostrando su progreso.'**
  String get aiGenerationResumedSnack;

  /// No description provided for @aiGenerationProgressPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent} % completado'**
  String aiGenerationProgressPercent(int percent);

  /// No description provided for @aiJobStageQueued.
  ///
  /// In es, this message translates to:
  /// **'En cola'**
  String get aiJobStageQueued;

  /// No description provided for @aiJobStagePreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando material'**
  String get aiJobStagePreparing;

  /// No description provided for @aiJobStageOutlining.
  ///
  /// In es, this message translates to:
  /// **'Planificando temas'**
  String get aiJobStageOutlining;

  /// No description provided for @aiJobStageGenerating.
  ///
  /// In es, this message translates to:
  /// **'Generando preguntas'**
  String get aiJobStageGenerating;

  /// No description provided for @aiJobStageMerging.
  ///
  /// In es, this message translates to:
  /// **'Combinando resultados'**
  String get aiJobStageMerging;

  /// No description provided for @aiJobStageValidating.
  ///
  /// In es, this message translates to:
  /// **'Validando preguntas'**
  String get aiJobStageValidating;

  /// No description provided for @aiJobStageImporting.
  ///
  /// In es, this message translates to:
  /// **'Preparando borrador'**
  String get aiJobStageImporting;

  /// No description provided for @aiJobStageCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get aiJobStageCompleted;

  /// No description provided for @aiJobStageFailed.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get aiJobStageFailed;

  /// No description provided for @aiActivityClearHistoryAction.
  ///
  /// In es, this message translates to:
  /// **'Limpiar historial'**
  String get aiActivityClearHistoryAction;

  /// No description provided for @aiActivityClearHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Limpiar historial?'**
  String get aiActivityClearHistoryTitle;

  /// No description provided for @aiActivityClearHistoryMessage.
  ///
  /// In es, this message translates to:
  /// **'Se quitarán las generaciones completadas y los errores antiguos. Se conservan las que están en curso y los borradores pendientes de revisar.'**
  String get aiActivityClearHistoryMessage;

  /// No description provided for @aiActivityClearHistoryDone.
  ///
  /// In es, this message translates to:
  /// **'Se eliminaron {count} entradas del historial.'**
  String aiActivityClearHistoryDone(int count);

  /// No description provided for @aiActivityClearHistoryNothing.
  ///
  /// In es, this message translates to:
  /// **'No había entradas que limpiar.'**
  String get aiActivityClearHistoryNothing;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @practiceStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get practiceStatusInProgress;

  /// No description provided for @guestCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Practicar con código'**
  String get guestCodeTitle;

  /// No description provided for @guestCodeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce el código que te compartió tu profesor para practicar sin crear cuenta.'**
  String get guestCodeSubtitle;

  /// No description provided for @guestCodeAction.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get guestCodeAction;

  /// No description provided for @guestCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get guestCodeLabel;

  /// No description provided for @guestCodeRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce un código'**
  String get guestCodeRequired;

  /// No description provided for @guestCodePasteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Pegar'**
  String get guestCodePasteTooltip;

  /// No description provided for @guestEphemeralNotice.
  ///
  /// In es, this message translates to:
  /// **'Esta sesión es temporal. Al salir se borra todo.'**
  String get guestEphemeralNotice;

  /// No description provided for @guestPracticeWithCodeAction.
  ///
  /// In es, this message translates to:
  /// **'Practicar con código'**
  String get guestPracticeWithCodeAction;

  /// No description provided for @guestShellFreeBadge.
  ///
  /// In es, this message translates to:
  /// **'Gratis'**
  String get guestShellFreeBadge;

  /// No description provided for @guestShellHeroHint.
  ///
  /// In es, this message translates to:
  /// **'Practica ahora. Regístrate gratis para guardar tu progreso y desbloquear más.'**
  String get guestShellHeroHint;

  /// No description provided for @guestShellSessionBadge.
  ///
  /// In es, this message translates to:
  /// **'Sin cuenta'**
  String get guestShellSessionBadge;

  /// No description provided for @guestPracticeOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones de práctica'**
  String get guestPracticeOptions;

  /// No description provided for @guestStartPracticeAction.
  ///
  /// In es, this message translates to:
  /// **'Practicar'**
  String get guestStartPracticeAction;

  /// No description provided for @guestAttemptsTitle.
  ///
  /// In es, this message translates to:
  /// **'En esta visita'**
  String get guestAttemptsTitle;

  /// No description provided for @guestAttemptsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no has practicado en esta visita. ¡Empieza ahora!'**
  String get guestAttemptsEmpty;

  /// No description provided for @guestLeaveAction.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get guestLeaveAction;

  /// No description provided for @guestLeaveConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir de la visita?'**
  String get guestLeaveConfirmTitle;

  /// No description provided for @guestLeaveConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán todos los intentos de esta visita. Esta acción no se puede deshacer.'**
  String get guestLeaveConfirmMessage;

  /// No description provided for @guestRegisterAction.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta gratis'**
  String get guestRegisterAction;

  /// No description provided for @guestTryAgainAction.
  ///
  /// In es, this message translates to:
  /// **'Volver a practicar'**
  String get guestTryAgainAction;

  /// No description provided for @guestResultStatCorrect.
  ///
  /// In es, this message translates to:
  /// **'Correctas'**
  String get guestResultStatCorrect;

  /// No description provided for @guestResultStatIncorrect.
  ///
  /// In es, this message translates to:
  /// **'Incorrectas'**
  String get guestResultStatIncorrect;

  /// No description provided for @guestViewResultsAction.
  ///
  /// In es, this message translates to:
  /// **'Ver resultados'**
  String get guestViewResultsAction;

  /// No description provided for @guestTimerRegisteredOnlyHint.
  ///
  /// In es, this message translates to:
  /// **'Solo para usuarios registrados. Crear cuenta es gratis.'**
  String get guestTimerRegisteredOnlyHint;

  /// No description provided for @guestRegisterCtaTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres guardar tus resultados?'**
  String get guestRegisterCtaTitle;

  /// No description provided for @guestRegisterBenefit1.
  ///
  /// In es, this message translates to:
  /// **'Historial permanente de todos tus intentos'**
  String get guestRegisterBenefit1;

  /// No description provided for @guestRegisterBenefit2.
  ///
  /// In es, this message translates to:
  /// **'Crea tus propios cuestionarios con IA'**
  String get guestRegisterBenefit2;

  /// No description provided for @guestRegisterBenefit3.
  ///
  /// In es, this message translates to:
  /// **'Plan Free: 5 cuestionarios y 20 créditos IA, gratis'**
  String get guestRegisterBenefit3;

  /// No description provided for @guestExitPracticeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir de la práctica?'**
  String get guestExitPracticeTitle;

  /// No description provided for @guestExitPracticeMessage.
  ///
  /// In es, this message translates to:
  /// **'El progreso de esta sesión no se perderá: podrás reanudarla al volver.'**
  String get guestExitPracticeMessage;

  /// No description provided for @guestExitPracticeConfirm.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get guestExitPracticeConfirm;

  /// No description provided for @teacherTabLabel.
  ///
  /// In es, this message translates to:
  /// **'Profesor'**
  String get teacherTabLabel;

  /// No description provided for @teacherDashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get teacherDashboardTitle;

  /// No description provided for @teacherDashboardTotalStudents.
  ///
  /// In es, this message translates to:
  /// **'Estudiantes'**
  String get teacherDashboardTotalStudents;

  /// No description provided for @teacherDashboardActiveClasses.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get teacherDashboardActiveClasses;

  /// No description provided for @teacherDashboardPublishedQuizzes.
  ///
  /// In es, this message translates to:
  /// **'Quizzes'**
  String get teacherDashboardPublishedQuizzes;

  /// No description provided for @teacherDashboardSessionsThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get teacherDashboardSessionsThisWeek;

  /// No description provided for @teacherDashboardActivityFeedTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get teacherDashboardActivityFeedTitle;

  /// No description provided for @teacherDashboardInsightsTitle.
  ///
  /// In es, this message translates to:
  /// **'Análisis'**
  String get teacherDashboardInsightsTitle;

  /// No description provided for @teacherDashboardEmptyFeed.
  ///
  /// In es, this message translates to:
  /// **'Aún sin actividad. ¡Comparte un quiz con tus estudiantes!'**
  String get teacherDashboardEmptyFeed;

  /// No description provided for @teacherDashboardEmptyInsights.
  ///
  /// In es, this message translates to:
  /// **'Sin análisis aún. Vuelve cuando tus estudiantes empiecen a practicar.'**
  String get teacherDashboardEmptyInsights;

  /// No description provided for @teacherDashboardInventoryStudents.
  ///
  /// In es, this message translates to:
  /// **'Estudiantes'**
  String get teacherDashboardInventoryStudents;

  /// No description provided for @teacherDashboardInventoryClasses.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get teacherDashboardInventoryClasses;

  /// No description provided for @teacherDashboardInventoryQuizzes.
  ///
  /// In es, this message translates to:
  /// **'Quizzes'**
  String get teacherDashboardInventoryQuizzes;

  /// No description provided for @teacherDashboardUrgentTitle.
  ///
  /// In es, this message translates to:
  /// **'Requiere atención'**
  String get teacherDashboardUrgentTitle;

  /// No description provided for @teacherDashboardUrgentEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay tareas urgentes por ahora.'**
  String get teacherDashboardUrgentEmpty;

  /// No description provided for @teacherDashboardUrgentDueLabel.
  ///
  /// In es, this message translates to:
  /// **'Vence {date}'**
  String teacherDashboardUrgentDueLabel(String date);

  /// No description provided for @teacherDashboardUrgentPendingLabel.
  ///
  /// In es, this message translates to:
  /// **'{pending} de {total} sin entregar'**
  String teacherDashboardUrgentPendingLabel(int pending, int total);

  /// No description provided for @teacherDashboardActiveStudentsWeek.
  ///
  /// In es, this message translates to:
  /// **'Alumnos activos esta semana: {count}'**
  String teacherDashboardActiveStudentsWeek(int count);

  /// No description provided for @teacherInsightHighError.
  ///
  /// In es, this message translates to:
  /// **'Una pregunta tiene {errorRate}% de errores: {questionText}'**
  String teacherInsightHighError(String errorRate, String questionText);

  /// No description provided for @teacherInsightMostActive.
  ///
  /// In es, this message translates to:
  /// **'{sessionCount} prácticas esta semana ({studentCount} alumnos) · {quizTitle}'**
  String teacherInsightMostActive(
    int sessionCount,
    int studentCount,
    String quizTitle,
  );

  /// No description provided for @teacherAssignmentAnalyticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Analítica de la tarea'**
  String get teacherAssignmentAnalyticsTitle;

  /// No description provided for @teacherAssignmentAnalyticsAction.
  ///
  /// In es, this message translates to:
  /// **'Ver analítica'**
  String get teacherAssignmentAnalyticsAction;

  /// No description provided for @teacherAssignmentAnalyticsRosterTitle.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get teacherAssignmentAnalyticsRosterTitle;

  /// No description provided for @teacherAssignmentAnalyticsHardQuestionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas difíciles'**
  String get teacherAssignmentAnalyticsHardQuestionsTitle;

  /// No description provided for @teacherAssignmentAnalyticsDistributionTitle.
  ///
  /// In es, this message translates to:
  /// **'Distribución de notas'**
  String get teacherAssignmentAnalyticsDistributionTitle;

  /// No description provided for @teacherAssignmentAnalyticsNoAttempt.
  ///
  /// In es, this message translates to:
  /// **'Sin intento'**
  String get teacherAssignmentAnalyticsNoAttempt;

  /// No description provided for @teacherAssignmentAnalyticsCompletionLabel.
  ///
  /// In es, this message translates to:
  /// **'Entregaron {completed} de {total}'**
  String teacherAssignmentAnalyticsCompletionLabel(int completed, int total);

  /// No description provided for @teacherAssignmentAnalyticsBestLabel.
  ///
  /// In es, this message translates to:
  /// **'Mejor: {score}%'**
  String teacherAssignmentAnalyticsBestLabel(String score);

  /// No description provided for @teacherAssignmentAnalyticsLastLabel.
  ///
  /// In es, this message translates to:
  /// **'Último: {score}%'**
  String teacherAssignmentAnalyticsLastLabel(String score);

  /// No description provided for @teacherAssignmentAnalyticsErrorRateLabel.
  ///
  /// In es, this message translates to:
  /// **'{rate}% error · {attempts} intentos'**
  String teacherAssignmentAnalyticsErrorRateLabel(String rate, int attempts);

  /// No description provided for @teacherClassAnalyticsActiveStudentsLabel.
  ///
  /// In es, this message translates to:
  /// **'Alumnos con práctica'**
  String get teacherClassAnalyticsActiveStudentsLabel;

  /// No description provided for @teacherClassAnalyticsAverageLabel.
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get teacherClassAnalyticsAverageLabel;

  /// No description provided for @teacherClassAnalyticsAssignmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Asignaciones'**
  String get teacherClassAnalyticsAssignmentsTitle;

  /// No description provided for @studentAssignmentProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi progreso'**
  String get studentAssignmentProgressTitle;

  /// No description provided for @studentAssignmentProgressAction.
  ///
  /// In es, this message translates to:
  /// **'Mi progreso'**
  String get studentAssignmentProgressAction;

  /// No description provided for @studentAssignmentProgressMyStats.
  ///
  /// In es, this message translates to:
  /// **'Mis resultados'**
  String get studentAssignmentProgressMyStats;

  /// No description provided for @studentAssignmentProgressEvolutionTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi evolución'**
  String get studentAssignmentProgressEvolutionTitle;

  /// No description provided for @studentAssignmentProgressHardQuestionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas a repasar'**
  String get studentAssignmentProgressHardQuestionsTitle;

  /// No description provided for @studentAssignmentProgressTrendUp.
  ///
  /// In es, this message translates to:
  /// **'Mejoraste {points} pts respecto a tu primer intento'**
  String studentAssignmentProgressTrendUp(String points);

  /// No description provided for @studentAssignmentProgressAttemptLabel.
  ///
  /// In es, this message translates to:
  /// **'Intento {number}: {percent}%'**
  String studentAssignmentProgressAttemptLabel(int number, String percent);

  /// No description provided for @practiceResultRepracticeTitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas a repasar'**
  String get practiceResultRepracticeTitle;

  /// No description provided for @practiceResultTrendUp.
  ///
  /// In es, this message translates to:
  /// **'+{points} pts vs intento anterior'**
  String practiceResultTrendUp(String points);

  /// No description provided for @practiceResultTrendDown.
  ///
  /// In es, this message translates to:
  /// **'{points} pts vs intento anterior'**
  String practiceResultTrendDown(String points);

  /// No description provided for @practiceResultReviewQuestionAction.
  ///
  /// In es, this message translates to:
  /// **'Ver en revisión'**
  String get practiceResultReviewQuestionAction;

  /// No description provided for @analyticsPersonalOnlyLabel.
  ///
  /// In es, this message translates to:
  /// **'Solo tus intentos'**
  String get analyticsPersonalOnlyLabel;

  /// No description provided for @analyticsOnlyDifficultFilter.
  ///
  /// In es, this message translates to:
  /// **'Solo difíciles'**
  String get analyticsOnlyDifficultFilter;

  /// No description provided for @analyticsPersonalAccuracyLabel.
  ///
  /// In es, this message translates to:
  /// **'{percent}% acierto en tus intentos'**
  String analyticsPersonalAccuracyLabel(String percent);

  /// No description provided for @scoreDistributionRange.
  ///
  /// In es, this message translates to:
  /// **'{min}–{max}%'**
  String scoreDistributionRange(int min, int max);

  /// No description provided for @teacherClassesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis clases'**
  String get teacherClassesTitle;

  /// No description provided for @teacherClassesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has creado ninguna clase.'**
  String get teacherClassesEmpty;

  /// No description provided for @teacherClassCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva clase'**
  String get teacherClassCreateTitle;

  /// No description provided for @teacherClassNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la clase'**
  String get teacherClassNameLabel;

  /// No description provided for @teacherClassNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Álgebra II — Período 3'**
  String get teacherClassNameHint;

  /// No description provided for @teacherClassDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get teacherClassDescriptionLabel;

  /// No description provided for @teacherClassDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Descripción breve de esta clase'**
  String get teacherClassDescriptionHint;

  /// No description provided for @teacherClassSaveAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get teacherClassSaveAction;

  /// No description provided for @teacherClassCreateAction.
  ///
  /// In es, this message translates to:
  /// **'Crear clase'**
  String get teacherClassCreateAction;

  /// No description provided for @teacherClassArchiveAction.
  ///
  /// In es, this message translates to:
  /// **'Archivar clase'**
  String get teacherClassArchiveAction;

  /// No description provided for @teacherClassArchiveConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Archivar clase?'**
  String get teacherClassArchiveConfirmTitle;

  /// No description provided for @teacherClassArchiveConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Los estudiantes ya no verán las asignaciones de esta clase.'**
  String get teacherClassArchiveConfirmMessage;

  /// No description provided for @teacherClassArchiveConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get teacherClassArchiveConfirmAction;

  /// No description provided for @teacherClassMembersTab.
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get teacherClassMembersTab;

  /// No description provided for @teacherClassAssignmentsTab.
  ///
  /// In es, this message translates to:
  /// **'Asignaciones'**
  String get teacherClassAssignmentsTab;

  /// No description provided for @teacherClassAnalyticsTab.
  ///
  /// In es, this message translates to:
  /// **'Analítica'**
  String get teacherClassAnalyticsTab;

  /// No description provided for @teacherClassActiveMembersLabel.
  ///
  /// In es, this message translates to:
  /// **'miembros activos'**
  String get teacherClassActiveMembersLabel;

  /// No description provided for @teacherClassPendingMembersLabel.
  ///
  /// In es, this message translates to:
  /// **'pendientes de aprobación'**
  String get teacherClassPendingMembersLabel;

  /// No description provided for @teacherClassAddMemberTitle.
  ///
  /// In es, this message translates to:
  /// **'Agregar estudiante'**
  String get teacherClassAddMemberTitle;

  /// No description provided for @teacherClassAddMemberEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo del estudiante'**
  String get teacherClassAddMemberEmailLabel;

  /// No description provided for @teacherClassAddMemberEmailHint.
  ///
  /// In es, this message translates to:
  /// **'estudiante@correo.com'**
  String get teacherClassAddMemberEmailHint;

  /// No description provided for @teacherClassAddMemberAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get teacherClassAddMemberAction;

  /// No description provided for @teacherClassInvalidEmailError.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido.'**
  String get teacherClassInvalidEmailError;

  /// No description provided for @teacherClassMemberNotFoundError.
  ///
  /// In es, this message translates to:
  /// **'No hay ningún estudiante registrado con ese correo.'**
  String get teacherClassMemberNotFoundError;

  /// No description provided for @teacherClassMemberAlreadyExistsError.
  ///
  /// In es, this message translates to:
  /// **'Ese estudiante ya pertenece a esta clase.'**
  String get teacherClassMemberAlreadyExistsError;

  /// No description provided for @teacherClassRemoveMemberAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get teacherClassRemoveMemberAction;

  /// No description provided for @teacherClassRemoveMemberConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar estudiante?'**
  String get teacherClassRemoveMemberConfirmTitle;

  /// No description provided for @teacherClassRemoveMemberConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Este estudiante perderá acceso a todas las asignaciones de esta clase.'**
  String get teacherClassRemoveMemberConfirmMessage;

  /// No description provided for @teacherClassApproveAction.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get teacherClassApproveAction;

  /// No description provided for @teacherClassMembersEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay estudiantes en esta clase.'**
  String get teacherClassMembersEmpty;

  /// No description provided for @teacherClassPendingApprovalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Pendientes de aprobación'**
  String get teacherClassPendingApprovalsTitle;

  /// No description provided for @teacherAssignmentCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva asignación'**
  String get teacherAssignmentCreateTitle;

  /// No description provided for @teacherAssignmentTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get teacherAssignmentTitleLabel;

  /// No description provided for @teacherAssignmentTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Capítulo 5 — Quiz de práctica'**
  String get teacherAssignmentTitleHint;

  /// No description provided for @teacherAssignmentInstructionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones (opcional)'**
  String get teacherAssignmentInstructionsLabel;

  /// No description provided for @teacherAssignmentQuizLabel.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar quiz'**
  String get teacherAssignmentQuizLabel;

  /// No description provided for @teacherAssignmentStartsAtLabel.
  ///
  /// In es, this message translates to:
  /// **'Se abre el'**
  String get teacherAssignmentStartsAtLabel;

  /// No description provided for @teacherAssignmentDueAtLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha límite'**
  String get teacherAssignmentDueAtLabel;

  /// No description provided for @teacherAssignmentMaxAttemptsLabel.
  ///
  /// In es, this message translates to:
  /// **'Intentos máximos'**
  String get teacherAssignmentMaxAttemptsLabel;

  /// No description provided for @teacherAssignmentMaxAttemptsHint.
  ///
  /// In es, this message translates to:
  /// **'Dejar en blanco para ilimitados'**
  String get teacherAssignmentMaxAttemptsHint;

  /// No description provided for @teacherAssignmentShowAnswersLabel.
  ///
  /// In es, this message translates to:
  /// **'Mostrar respuestas correctas'**
  String get teacherAssignmentShowAnswersLabel;

  /// No description provided for @teacherAssignmentShowAnswersNever.
  ///
  /// In es, this message translates to:
  /// **'Nunca'**
  String get teacherAssignmentShowAnswersNever;

  /// No description provided for @teacherAssignmentShowAnswersAfterAttempt.
  ///
  /// In es, this message translates to:
  /// **'Tras cada intento'**
  String get teacherAssignmentShowAnswersAfterAttempt;

  /// No description provided for @teacherAssignmentShowAnswersAfterDue.
  ///
  /// In es, this message translates to:
  /// **'Tras la fecha límite'**
  String get teacherAssignmentShowAnswersAfterDue;

  /// No description provided for @teacherAssignmentShowAnswersTeacherOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo el profesor'**
  String get teacherAssignmentShowAnswersTeacherOnly;

  /// No description provided for @teacherAssignmentCreateAction.
  ///
  /// In es, this message translates to:
  /// **'Crear asignación'**
  String get teacherAssignmentCreateAction;

  /// No description provided for @teacherAssignmentEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar asignación'**
  String get teacherAssignmentEditTitle;

  /// No description provided for @teacherAssignmentEditAction.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get teacherAssignmentEditAction;

  /// No description provided for @teacherAssignmentSaveAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get teacherAssignmentSaveAction;

  /// No description provided for @teacherAssignmentTitleRequired.
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio'**
  String get teacherAssignmentTitleRequired;

  /// No description provided for @teacherAssignmentQuizSelectHint.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar quiz'**
  String get teacherAssignmentQuizSelectHint;

  /// No description provided for @teacherAssignmentQuizRequiredError.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un quiz'**
  String get teacherAssignmentQuizRequiredError;

  /// No description provided for @teacherAssignmentQuizLockedHint.
  ///
  /// In es, this message translates to:
  /// **'El quiz no se puede cambiar una vez creada la asignación.'**
  String get teacherAssignmentQuizLockedHint;

  /// No description provided for @teacherAssignmentMaxAttemptsInvalidError.
  ///
  /// In es, this message translates to:
  /// **'Introduce un número válido de intentos'**
  String get teacherAssignmentMaxAttemptsInvalidError;

  /// No description provided for @teacherAssignmentNotEditableError.
  ///
  /// In es, this message translates to:
  /// **'Solo se pueden editar asignaciones activas.'**
  String get teacherAssignmentNotEditableError;

  /// No description provided for @teacherAssignmentMaxAttemptsBelowExistingError.
  ///
  /// In es, this message translates to:
  /// **'Los intentos máximos no pueden ser menores a los que ya usaron los estudiantes.'**
  String get teacherAssignmentMaxAttemptsBelowExistingError;

  /// No description provided for @teacherAssignmentInvalidDateRangeError.
  ///
  /// In es, this message translates to:
  /// **'La fecha límite no puede ser anterior a la de inicio.'**
  String get teacherAssignmentInvalidDateRangeError;

  /// No description provided for @teacherAssignmentCloseAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar asignación'**
  String get teacherAssignmentCloseAction;

  /// No description provided for @teacherAssignmentArchiveAction.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get teacherAssignmentArchiveAction;

  /// No description provided for @teacherAssignmentCloseConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar asignación?'**
  String get teacherAssignmentCloseConfirmTitle;

  /// No description provided for @teacherAssignmentCloseConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Los estudiantes ya no podrán enviar nuevos intentos.'**
  String get teacherAssignmentCloseConfirmMessage;

  /// No description provided for @teacherAssignmentCompletionTitle.
  ///
  /// In es, this message translates to:
  /// **'Completación'**
  String get teacherAssignmentCompletionTitle;

  /// No description provided for @teacherAssignmentAttemptsTitle.
  ///
  /// In es, this message translates to:
  /// **'Intentos'**
  String get teacherAssignmentAttemptsTitle;

  /// No description provided for @teacherAssignmentCompletedLabel.
  ///
  /// In es, this message translates to:
  /// **'completaron'**
  String get teacherAssignmentCompletedLabel;

  /// No description provided for @teacherAssignmentPendingLabel.
  ///
  /// In es, this message translates to:
  /// **'sin enviar'**
  String get teacherAssignmentPendingLabel;

  /// No description provided for @teacherAssignmentBestScoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Mejor'**
  String get teacherAssignmentBestScoreLabel;

  /// No description provided for @teacherAssignmentAttemptsLabel.
  ///
  /// In es, this message translates to:
  /// **'intentos'**
  String get teacherAssignmentAttemptsLabel;

  /// No description provided for @teacherAssignmentDueLabel.
  ///
  /// In es, this message translates to:
  /// **'Cierra'**
  String get teacherAssignmentDueLabel;

  /// No description provided for @teacherAssignmentNoDueDate.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha límite'**
  String get teacherAssignmentNoDueDate;

  /// No description provided for @teacherAssignmentEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin asignaciones aún.'**
  String get teacherAssignmentEmpty;

  /// No description provided for @teacherAssignmentFormSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configura fechas, intentos y visibilidad de respuestas.'**
  String get teacherAssignmentFormSubtitle;

  /// No description provided for @teacherAssignmentSectionDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get teacherAssignmentSectionDetails;

  /// No description provided for @teacherAssignmentSectionQuiz.
  ///
  /// In es, this message translates to:
  /// **'Cuestionario'**
  String get teacherAssignmentSectionQuiz;

  /// No description provided for @teacherAssignmentSectionSchedule.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get teacherAssignmentSectionSchedule;

  /// No description provided for @teacherAssignmentSectionRules.
  ///
  /// In es, this message translates to:
  /// **'Reglas'**
  String get teacherAssignmentSectionRules;

  /// No description provided for @teacherAssignmentCreateQuizCtaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Créalo aquí y selecciónalo al instante'**
  String get teacherAssignmentCreateQuizCtaSubtitle;

  /// No description provided for @teacherAssignmentSelectQuizAction.
  ///
  /// In es, this message translates to:
  /// **'Elegir de mis cuestionarios'**
  String get teacherAssignmentSelectQuizAction;

  /// No description provided for @teacherAssignmentChangeQuizAction.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get teacherAssignmentChangeQuizAction;

  /// No description provided for @teacherAssignmentQuizDraftWarning.
  ///
  /// In es, this message translates to:
  /// **'Este cuestionario está en borrador. Publícalo para que los estudiantes puedan ver la asignación.'**
  String get teacherAssignmentQuizDraftWarning;

  /// No description provided for @teacherAssignmentNoQuizzesHint.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes cuestionarios. Crea uno para continuar.'**
  String get teacherAssignmentNoQuizzesHint;

  /// No description provided for @teacherAssignmentPickDatePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Sin definir'**
  String get teacherAssignmentPickDatePlaceholder;

  /// No description provided for @teacherAssignmentDraftContinued.
  ///
  /// In es, this message translates to:
  /// **'Continúa configurando tu asignación. El cuestionario nuevo ya está seleccionado.'**
  String get teacherAssignmentDraftContinued;

  /// No description provided for @teacherAnalyticsAvgScoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Prom. puntaje'**
  String get teacherAnalyticsAvgScoreLabel;

  /// No description provided for @teacherAnalyticsTotalSessionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Sesiones totales'**
  String get teacherAnalyticsTotalSessionsLabel;

  /// No description provided for @teacherAnalyticsCompletionRateLabel.
  ///
  /// In es, this message translates to:
  /// **'Completación'**
  String get teacherAnalyticsCompletionRateLabel;

  /// No description provided for @teacherUpgradeHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Convierte tus quizzes en un aula'**
  String get teacherUpgradeHeroTitle;

  /// No description provided for @teacherUpgradeHeroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todo lo que necesitas para enseñar, asignar y hacer seguimiento — en un solo lugar.'**
  String get teacherUpgradeHeroSubtitle;

  /// No description provided for @teacherUpgradePriceLabel.
  ///
  /// In es, this message translates to:
  /// **'/ mes'**
  String get teacherUpgradePriceLabel;

  /// No description provided for @teacherUpgradePopularBadge.
  ///
  /// In es, this message translates to:
  /// **'El más elegido por educadores'**
  String get teacherUpgradePopularBadge;

  /// No description provided for @teacherUpgradePillar1Title.
  ///
  /// In es, this message translates to:
  /// **'Clases organizadas'**
  String get teacherUpgradePillar1Title;

  /// No description provided for @teacherUpgradePillar1Body.
  ///
  /// In es, this message translates to:
  /// **'Crea grupos, invita estudiantes por correo y gestiona el acceso.'**
  String get teacherUpgradePillar1Body;

  /// No description provided for @teacherUpgradePillar2Title.
  ///
  /// In es, this message translates to:
  /// **'Asignaciones inteligentes'**
  String get teacherUpgradePillar2Title;

  /// No description provided for @teacherUpgradePillar2Body.
  ///
  /// In es, this message translates to:
  /// **'Define fechas límite, limita intentos y controla cuándo se revelan las respuestas.'**
  String get teacherUpgradePillar2Body;

  /// No description provided for @teacherUpgradePillar3Title.
  ///
  /// In es, this message translates to:
  /// **'Activity Pulse'**
  String get teacherUpgradePillar3Title;

  /// No description provided for @teacherUpgradePillar3Body.
  ///
  /// In es, this message translates to:
  /// **'Feed en vivo de actividad estudiantil, insights automáticos y analítica por clase.'**
  String get teacherUpgradePillar3Body;

  /// No description provided for @teacherUpgradeCta.
  ///
  /// In es, this message translates to:
  /// **'Hazte Profesor'**
  String get teacherUpgradeCta;

  /// No description provided for @teacherUpgradeCancelHint.
  ///
  /// In es, this message translates to:
  /// **'Cancela cuando quieras · Acceso inmediato al pagar'**
  String get teacherUpgradeCancelHint;

  /// No description provided for @teacherUpgradeSeeAllPlans.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los planes'**
  String get teacherUpgradeSeeAllPlans;

  /// No description provided for @teacherUpgradeAlreadyActive.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes un plan Profesor activo.'**
  String get teacherUpgradeAlreadyActive;

  /// No description provided for @teacherUpgradeCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar suscripción?'**
  String get teacherUpgradeCancelTitle;

  /// No description provided for @teacherUpgradeCancelMessage.
  ///
  /// In es, this message translates to:
  /// **'Perderás el acceso al módulo Profesor y tus clases serán archivadas. Puedes volver a suscribirte en cualquier momento.'**
  String get teacherUpgradeCancelMessage;

  /// No description provided for @teacherUpgradeCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'Cancelar plan'**
  String get teacherUpgradeCancelConfirm;

  /// No description provided for @teacherUpgradeCancelSuccess.
  ///
  /// In es, this message translates to:
  /// **'Suscripción cancelada. ¡Hasta pronto!'**
  String get teacherUpgradeCancelSuccess;

  /// No description provided for @teacherUpgradeExpiryWarning.
  ///
  /// In es, this message translates to:
  /// **'Tu plan Profesor vence en menos de 7 días. Renuévalo para mantener el acceso.'**
  String get teacherUpgradeExpiryWarning;

  /// No description provided for @homeTeacherBannerTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eres docente?'**
  String get homeTeacherBannerTitle;

  /// No description provided for @homeTeacherBannerBody.
  ///
  /// In es, this message translates to:
  /// **'Clases, asignaciones y analítica en tiempo real.'**
  String get homeTeacherBannerBody;

  /// No description provided for @homeTeacherBannerAction.
  ///
  /// In es, this message translates to:
  /// **'Ver plan Profesor'**
  String get homeTeacherBannerAction;

  /// No description provided for @homeTeacherBannerDismissTooltip.
  ///
  /// In es, this message translates to:
  /// **'No mostrar más'**
  String get homeTeacherBannerDismissTooltip;

  /// No description provided for @studentAssignmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis asignaciones'**
  String get studentAssignmentsTitle;

  /// No description provided for @studentAssignmentsAction.
  ///
  /// In es, this message translates to:
  /// **'Asignaciones de clase'**
  String get studentAssignmentsAction;

  /// No description provided for @studentAssignmentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes asignaciones de tus profesores aún.'**
  String get studentAssignmentsEmpty;

  /// No description provided for @studentAssignmentStartAction.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get studentAssignmentStartAction;

  /// No description provided for @studentAssignmentClosedLabel.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get studentAssignmentClosedLabel;

  /// No description provided for @studentAssignmentUnavailableLabel.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get studentAssignmentUnavailableLabel;

  /// No description provided for @studentAssignmentNotYetOpenLabel.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get studentAssignmentNotYetOpenLabel;

  /// No description provided for @studentAssignmentNotYetOpenError.
  ///
  /// In es, this message translates to:
  /// **'Esta asignación aún no está disponible. Revisa la fecha de inicio.'**
  String get studentAssignmentNotYetOpenError;

  /// No description provided for @studentAssignmentPastDueLabel.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get studentAssignmentPastDueLabel;

  /// No description provided for @studentAssignmentMaxAttemptsLabel.
  ///
  /// In es, this message translates to:
  /// **'Sin intentos'**
  String get studentAssignmentMaxAttemptsLabel;

  /// No description provided for @studentAssignmentAvailableNowLabel.
  ///
  /// In es, this message translates to:
  /// **'Disponible ahora'**
  String get studentAssignmentAvailableNowLabel;

  /// No description provided for @studentAssignmentAttemptsSummary.
  ///
  /// In es, this message translates to:
  /// **'{used} de {max} intentos'**
  String studentAssignmentAttemptsSummary(int used, int max);

  /// No description provided for @studentAssignmentMyAttemptsAction.
  ///
  /// In es, this message translates to:
  /// **'Mis intentos'**
  String get studentAssignmentMyAttemptsAction;

  /// No description provided for @studentAssignmentMyAttemptsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis intentos'**
  String get studentAssignmentMyAttemptsTitle;

  /// No description provided for @studentAssignmentMyAttemptsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has completado ningún intento en esta asignación.'**
  String get studentAssignmentMyAttemptsEmpty;

  /// No description provided for @studentAssignmentAttemptScoreOnlyHint.
  ///
  /// In es, this message translates to:
  /// **'Solo puntuación — las respuestas correctas no están disponibles según la configuración del profesor.'**
  String get studentAssignmentAttemptScoreOnlyHint;

  /// No description provided for @studentAssignmentAttemptsHeaderSummary.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 intento registrado} other{{count} intentos registrados}}'**
  String studentAssignmentAttemptsHeaderSummary(int count);

  /// No description provided for @studentAssignmentAttemptBestScore.
  ///
  /// In es, this message translates to:
  /// **'Mejor resultado: {percent}%'**
  String studentAssignmentAttemptBestScore(String percent);

  /// No description provided for @studentAssignmentAttemptStatusFinished.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get studentAssignmentAttemptStatusFinished;

  /// No description provided for @studentAssignmentAttemptScoreOnlyBadge.
  ///
  /// In es, this message translates to:
  /// **'Solo puntuación'**
  String get studentAssignmentAttemptScoreOnlyBadge;

  /// No description provided for @studentAssignmentAttemptReviewAvailable.
  ///
  /// In es, this message translates to:
  /// **'Ver respuestas'**
  String get studentAssignmentAttemptReviewAvailable;

  /// No description provided for @studentAssignmentAttemptMeta.
  ///
  /// In es, this message translates to:
  /// **'{score} · {duration} · {status}'**
  String studentAssignmentAttemptMeta(
    String score,
    String duration,
    String status,
  );

  /// No description provided for @studentAssignmentsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get studentAssignmentsFilterAll;

  /// No description provided for @studentAssignmentsFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get studentAssignmentsFilterPending;

  /// No description provided for @studentAssignmentsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar asignación o clase'**
  String get studentAssignmentsSearchHint;

  /// No description provided for @studentAssignmentsSummaryTodoOnly.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 por hacer} other{{count} por hacer}}'**
  String studentAssignmentsSummaryTodoOnly(int count);

  /// No description provided for @studentAssignmentsSummaryDueTodayOnly.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 vence hoy} other{{count} vencen hoy}}'**
  String studentAssignmentsSummaryDueTodayOnly(int count);

  /// No description provided for @studentAssignmentsSummaryCombined.
  ///
  /// In es, this message translates to:
  /// **'{todo} · {dueToday}'**
  String studentAssignmentsSummaryCombined(String todo, String dueToday);

  /// No description provided for @studentAssignmentsSummaryAllDone.
  ///
  /// In es, this message translates to:
  /// **'No tienes asignaciones pendientes por ahora.'**
  String get studentAssignmentsSummaryAllDone;

  /// No description provided for @studentAssignmentsClassGroupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{teacher} · {count, plural, =1{1 asignación} other{{count} asignaciones}}'**
  String studentAssignmentsClassGroupSubtitle(String teacher, int count);

  /// No description provided for @studentAssignmentsEmptyFiltered.
  ///
  /// In es, this message translates to:
  /// **'Ninguna asignación coincide con este filtro.'**
  String get studentAssignmentsEmptyFiltered;

  /// No description provided for @studentAssignmentRowSubtitleDue.
  ///
  /// In es, this message translates to:
  /// **'Vence {date}{attemptsSuffix}'**
  String studentAssignmentRowSubtitleDue(String date, String attemptsSuffix);

  /// No description provided for @studentAssignmentRowSubtitleDueToday.
  ///
  /// In es, this message translates to:
  /// **'Vence hoy{attemptsSuffix}'**
  String studentAssignmentRowSubtitleDueToday(String attemptsSuffix);

  /// No description provided for @studentAssignmentRowSubtitleAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible{attemptsSuffix}'**
  String studentAssignmentRowSubtitleAvailable(String attemptsSuffix);

  /// No description provided for @studentAssignmentRowSubtitleNoDue.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha límite{attemptsSuffix}'**
  String studentAssignmentRowSubtitleNoDue(String attemptsSuffix);

  /// No description provided for @studentAssignmentRowSubtitleNotYetOpen.
  ///
  /// In es, this message translates to:
  /// **'Se abre {date}'**
  String studentAssignmentRowSubtitleNotYetOpen(String date);

  /// No description provided for @studentAssignmentRowSubtitleStatus.
  ///
  /// In es, this message translates to:
  /// **'{status}{attemptsSuffix}'**
  String studentAssignmentRowSubtitleStatus(
    String status,
    String attemptsSuffix,
  );

  /// No description provided for @studentAssignmentAttemptsSuffix.
  ///
  /// In es, this message translates to:
  /// **' · {summary}'**
  String studentAssignmentAttemptsSuffix(String summary);

  /// No description provided for @studentAssignmentStatusBadgeAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get studentAssignmentStatusBadgeAvailable;

  /// No description provided for @studentAssignmentDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de asignación'**
  String get studentAssignmentDetailTitle;

  /// No description provided for @profileTeacherPlanSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Plan Profesor'**
  String get profileTeacherPlanSectionTitle;

  /// No description provided for @profileTeacherPlanManageTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar plan Profesor'**
  String get profileTeacherPlanManageTitle;

  /// No description provided for @profileTeacherPlanActiveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Plan activo · toca para gestionar'**
  String get profileTeacherPlanActiveSubtitle;

  /// No description provided for @profileTeacherPlanInactiveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Clases, asignaciones y analítica · Suscripción mensual'**
  String get profileTeacherPlanInactiveSubtitle;

  /// No description provided for @teacherUpgradeKeepPlan.
  ///
  /// In es, this message translates to:
  /// **'No, mantener'**
  String get teacherUpgradeKeepPlan;

  /// No description provided for @teacherOnboardingWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido, Profesor!'**
  String get teacherOnboardingWelcomeTitle;

  /// No description provided for @teacherOnboardingStepProgress.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String teacherOnboardingStepProgress(int current, int total);

  /// No description provided for @teacherOnboardingStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera clase'**
  String get teacherOnboardingStep1Title;

  /// No description provided for @teacherOnboardingStep1Body.
  ///
  /// In es, this message translates to:
  /// **'Las clases te permiten organizar a tus estudiantes y asignarles quizzes con seguimiento personalizado.'**
  String get teacherOnboardingStep1Body;

  /// No description provided for @teacherOnboardingClassNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la clase'**
  String get teacherOnboardingClassNameLabel;

  /// No description provided for @teacherOnboardingClassNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Matemáticas — Grupo A'**
  String get teacherOnboardingClassNameHint;

  /// No description provided for @teacherOnboardingCreateClassAction.
  ///
  /// In es, this message translates to:
  /// **'Crear clase y continuar'**
  String get teacherOnboardingCreateClassAction;

  /// No description provided for @teacherOnboardingStep2Title.
  ///
  /// In es, this message translates to:
  /// **'Invita tu primer estudiante'**
  String get teacherOnboardingStep2Title;

  /// No description provided for @teacherOnboardingStep2Body.
  ///
  /// In es, this message translates to:
  /// **'Escribe el correo de un estudiante registrado para añadirlo a tu clase. También puedes hacerlo más tarde.'**
  String get teacherOnboardingStep2Body;

  /// No description provided for @teacherOnboardingStudentEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo del estudiante'**
  String get teacherOnboardingStudentEmailLabel;

  /// No description provided for @teacherOnboardingStudentEmailHint.
  ///
  /// In es, this message translates to:
  /// **'estudiante@correo.com'**
  String get teacherOnboardingStudentEmailHint;

  /// No description provided for @teacherOnboardingInviteAction.
  ///
  /// In es, this message translates to:
  /// **'Invitar y continuar'**
  String get teacherOnboardingInviteAction;

  /// No description provided for @teacherOnboardingSkipAction.
  ///
  /// In es, this message translates to:
  /// **'Omitir por ahora'**
  String get teacherOnboardingSkipAction;

  /// No description provided for @teacherOnboardingStep3Title.
  ///
  /// In es, this message translates to:
  /// **'¡Todo listo!'**
  String get teacherOnboardingStep3Title;

  /// No description provided for @teacherOnboardingStep3Body.
  ///
  /// In es, this message translates to:
  /// **'Tu aula está configurada. Ahora puedes crear asignaciones, ver el progreso de tus estudiantes y analizar resultados en el Activity Pulse.'**
  String get teacherOnboardingStep3Body;

  /// No description provided for @teacherOnboardingGoToDashboardAction.
  ///
  /// In es, this message translates to:
  /// **'Ir al Panel de Profesor'**
  String get teacherOnboardingGoToDashboardAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
