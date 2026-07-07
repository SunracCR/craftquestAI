// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'CraftQuestAI';

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
  String get errorDevApiUnreachable =>
      'No se pudo conectar con la API en el teléfono. Con el USB conectado ejecuta: adb reverse tcp:7080 tcp:7080 y reinicia la app.';

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
  String errorQuizOverPlanLimit(int max, int current, String plan) {
    return 'Tu plan $plan permite $max cuestionarios y tienes $current. Elimina cuestionarios o mejora tu plan para editarlos.';
  }

  @override
  String quizOverPlanLimitBanner(int current, int max) {
    return 'Modo solo lectura: tienes $current cuestionarios pero tu plan permite $max. Puedes practicarlos; elimina algunos o mejora tu plan para editarlos.';
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
      'Accede gratis a tu cuenta CraftQuestAI — entra o regístrate en segundos';

  @override
  String get parentalConsentTitle => 'Se requiere aprobación parental';

  @override
  String get parentalConsentBodyDefault =>
      'Tu cuenta está supervisada o eres menor en una región con normas de edad (p. ej. Texas). Un padre o tutor debe autorizar el uso de CraftQuestAI en Google Play antes de continuar.';

  @override
  String get parentalConsentBodyPending =>
      'Hay cambios pendientes de aprobación por tu padre o tutor en Google Play. Pídele que revise la solicitud en Family Link o en la Play Store y vuelve a comprobar el estado.';

  @override
  String get parentalConsentBodyDenied =>
      'Tu padre o tutor no aprobó el acceso a CraftQuestAI. Abre Google Play para revisar la configuración de la cuenta supervisada o contacta a quien administra tu cuenta.';

  @override
  String get parentalConsentBodyUnknown =>
      'Google Play no pudo confirmar tu edad. Abre la Play Store, inicia sesión con la misma cuenta y completa la verificación de edad; después pulsa «Comprobar de nuevo».';

  @override
  String get parentalConsentOpenPlayStore => 'Abrir Google Play';

  @override
  String get parentalConsentRecheckAction => 'Comprobar de nuevo';

  @override
  String get loginAction => 'Entrar';

  @override
  String get loginRememberCredentials => 'Recordar correo electrónico';

  @override
  String get loginInvalidCredentials =>
      'Correo o contraseña incorrectos. Comprueba los datos e inténtalo de nuevo.';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerAction => 'Registrarse';

  @override
  String get goToRegister => '¿No tienes cuenta? Regístrate';

  @override
  String get forgotPasswordLink => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordTitle => 'Recuperar contraseña';

  @override
  String get forgotPasswordSubtitle =>
      'Te enviaremos un enlace a tu correo si la cuenta existe.';

  @override
  String get forgotPasswordAction => 'Enviar enlace';

  @override
  String get forgotPasswordSuccess =>
      'Si el correo está registrado, recibirás instrucciones en breve.';

  @override
  String get resetPasswordTitle => 'Nueva contraseña';

  @override
  String get resetPasswordSubtitle =>
      'Introduce el código del correo y tu nueva contraseña.';

  @override
  String get resetPasswordTokenLabel => 'Código de recuperación';

  @override
  String get resetPasswordAction => 'Guardar contraseña';

  @override
  String get resetPasswordSuccess =>
      'Contraseña actualizada. Ya puedes iniciar sesión.';

  @override
  String get backToLogin => 'Volver al inicio de sesión';

  @override
  String get resetPasswordHaveCode => 'Ya tengo el código de recuperación';

  @override
  String get verifyEmailPendingTitle => 'Confirma tu correo';

  @override
  String verifyEmailPendingMessage(String email) {
    return 'Te enviamos un enlace de activación a $email. Revisa tu bandeja de entrada y la carpeta de spam.';
  }

  @override
  String get verifyEmailResendAction => 'Reenviar correo';

  @override
  String get verifyEmailResentMessage => 'Correo de activación reenviado.';

  @override
  String get verifyEmailTitle => 'Activar cuenta';

  @override
  String get verifyEmailInProgress => 'Estamos verificando tu correo…';

  @override
  String get verifyEmailSuccess => '¡Cuenta activada! Entrando…';

  @override
  String get verifyEmailRetryAction => 'Reintentar activación';

  @override
  String get errorEmailNotVerifiedTitle => 'Correo no verificado';

  @override
  String get errorEmailNotVerifiedMessage =>
      'Debes activar tu cuenta desde el enlace que te enviamos por correo antes de iniciar sesión.';

  @override
  String get errorEmailNotVerified =>
      'Tu correo aún no está verificado. Revisa tu bandeja o reenvía el enlace.';

  @override
  String get confirmPasswordChangeTitle => 'Confirmar cambio de contraseña';

  @override
  String get confirmPasswordChangeInProgress =>
      'Confirmando tu nueva contraseña…';

  @override
  String get confirmPasswordChangeSuccess =>
      'Contraseña actualizada correctamente.';

  @override
  String get confirmPasswordChangeRetryAction => 'Reintentar confirmación';

  @override
  String get passwordChangePendingMessage =>
      'Revisa tu correo para confirmar el cambio de contraseña.';

  @override
  String get errorInvalidVerificationToken =>
      'El enlace de activación no es válido o ha caducado.';

  @override
  String get errorInvalidPasswordChangeToken =>
      'El enlace de confirmación no es válido o ha caducado.';

  @override
  String get oauthDividerLabel => 'o continúa con';

  @override
  String get oauthSignInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get oauthSignInWithApple => 'Iniciar sesión con Apple';

  @override
  String get oauthSignInGoogleShort => 'Google';

  @override
  String get oauthSignInAppleShort => 'Apple';

  @override
  String get oauthSignInFailed =>
      'No se pudo completar el inicio de sesión social.';

  @override
  String get oauthGoogleWebOriginHint =>
      ' En Google Cloud (cliente Web), añade orígenes JavaScript autorizados: https://app.craftquestai.com, http://localhost:7357 y http://127.0.0.1:7357.';

  @override
  String get oauthGooglePeopleApiHint =>
      ' Habilita People API en Google Cloud (mismo proyecto que tu Client ID): https://console.cloud.google.com/apis/library/people.googleapis.com';

  @override
  String get oauthGoogleNotConfigured =>
      'Google no está configurado. Añade ExternalAuth:Google:WebClientId en la API o GOOGLE_SERVER_CLIENT_ID al ejecutar la app.';

  @override
  String get oauthAppleNotConfigured =>
      'Apple no está configurado en el servidor (ExternalAuth:Apple:BundleId).';

  @override
  String get oauthAppleNotAvailable =>
      'Iniciar sesión con Apple no está disponible en este dispositivo.';

  @override
  String get oauthAppleWebNotConfigured =>
      'Apple en web requiere Services ID y WebRedirectUri en la API (ExternalAuth:Apple). Regístralos en Apple Developer.';

  @override
  String get billingCycleMonthly => 'Mensual';

  @override
  String get billingCycleAnnual => 'Anual';

  @override
  String get billingCycleAnnualPriceSuffix => '/ año';

  @override
  String get billingAnnualNotAvailable => 'Anual no disponible para este plan';

  @override
  String get billingPlanInstitutionName => 'Institución';

  @override
  String get upgradeInstitutionHighlight =>
      'Licencias para centros educativos, sedes y docentes';

  @override
  String get institutionPlanContactHint =>
      'Contacta con ventas para un presupuesto a medida.';

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
  String get navPrepPlusLabel => 'Preparación+';

  @override
  String get navProfileLabel => 'Perfil';

  @override
  String get prepPlusScreenTitle => 'Preparación+';

  @override
  String get prepPlusScreenSubtitle =>
      'Cuestionarios curados para tu examen. Compra acceso por tiempo.';

  @override
  String get homePrepPlusCardTitle => 'Preparación+';

  @override
  String get homePrepPlusCardSubtitle =>
      'Explora por país o tema y compra solo lo que necesitas.';

  @override
  String get prepPlusByCountrySection => 'Por país';

  @override
  String get prepPlusInternationalSection => 'Internacional';

  @override
  String prepPlusInternationalSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuestionarios disponibles',
      one: '1 cuestionario disponible',
      zero: 'Sin cuestionarios disponibles',
    );
    return '$_temp0';
  }

  @override
  String prepPlusCategoryItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuestionarios',
      one: '1 cuestionario',
      zero: 'Sin cuestionarios',
    );
    return '$_temp0';
  }

  @override
  String get prepPlusMyAccessesTitle => 'Mis accesos';

  @override
  String prepPlusMyAccessesActiveCount(int count) {
    return '$count activos';
  }

  @override
  String get prepPlusTabActive => 'Activos';

  @override
  String get prepPlusTabExpired => 'Expirados';

  @override
  String get prepPlusMyAccessesActiveEmpty => 'No tienes accesos activos.';

  @override
  String get prepPlusMyAccessesExpiredEmpty => 'No tienes accesos expirados.';

  @override
  String get prepPlusSearchHint => 'Buscar cuestionario…';

  @override
  String get prepPlusCategoryEmpty => 'No hay cuestionarios en esta categoría.';

  @override
  String get prepPlusFiltersAction => 'Filtros';

  @override
  String get prepPlusFiltersTitle => 'Filtros';

  @override
  String get prepPlusFiltersApply => 'Aplicar';

  @override
  String get prepPlusFilterPriceLabel => 'Precio';

  @override
  String get prepPlusFilterAccessLabel => 'Tu acceso';

  @override
  String get prepPlusFilterAll => 'Todos';

  @override
  String get prepPlusFilterFree => 'Gratis';

  @override
  String get prepPlusFilterPaid => 'De pago';

  @override
  String get prepPlusFilterInstitutionLabel => 'Institución o examen';

  @override
  String get prepPlusAccessNone => 'Sin comprar';

  @override
  String get prepPlusAccessActive => 'Activo';

  @override
  String get prepPlusAccessExpired => 'Expirado';

  @override
  String prepPlusQuestionCount(int count) {
    return '$count preguntas';
  }

  @override
  String get prepPlusHasFreeOffer => 'Incluye opción gratis';

  @override
  String prepPlusFromPrice(double price, String currency) {
    final intl.NumberFormat priceNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return 'Desde $priceString $currency';
  }

  @override
  String get prepPlusItemDetailTitle => 'Detalle';

  @override
  String get prepPlusPreviewAction => 'Probar simulación (3 preguntas)';

  @override
  String get prepPlusPreviewSimulationCtaTitle => 'Simulación interactiva';

  @override
  String get prepPlusPreviewSimulationCtaSubtitle =>
      'Responde como en la práctica real — sin guardar resultados.';

  @override
  String get prepPlusPreviewTitle => 'Vista previa';

  @override
  String prepPlusPreviewSubtitle(String title) {
    return 'Muestra de «$title»';
  }

  @override
  String get prepPlusPreviewSimulationTitle => 'Simulación';

  @override
  String get prepPlusPreviewSimulationBanner => 'Modo demostración';

  @override
  String prepPlusPreviewSimulationSubtitle(String title) {
    return '«$title» — experiencia igual a practicar';
  }

  @override
  String get prepPlusPreviewTryInteraction =>
      'Toca una respuesta para ver cómo funciona la herramienta.';

  @override
  String get prepPlusPreviewPrevious => 'Anterior';

  @override
  String get prepPlusPreviewNext => 'Siguiente';

  @override
  String get prepPlusPreviewFinishCta => 'Finalizar simulación';

  @override
  String get prepPlusPreviewResultTitle => 'Resultado de simulación';

  @override
  String get prepPlusPreviewResultDemoNotice =>
      'Modo demostración — este resultado no se guarda en tu historial.';

  @override
  String get prepPlusPreviewTryAgainAction => 'Intentar de nuevo';

  @override
  String get prepPlusPreviewBackAction => 'Volver al detalle';

  @override
  String get prepPlusPreviewResultOmitted => 'Omitidas';

  @override
  String prepPlusPreviewQuestionLabel(int number) {
    return 'Pregunta $number';
  }

  @override
  String get prepPlusAccessCombosTitle => 'Elige tu combo de acceso';

  @override
  String get prepPlusAccessCombosSubtitle =>
      'Incluye el cuestionario completo durante el periodo seleccionado.';

  @override
  String get prepPlusBestValueBadge => 'MEJOR VALOR';

  @override
  String prepPlusPricePerDay(String price) {
    return '$price / día';
  }

  @override
  String get prepPlusComboIncludesAccess =>
      'Acceso total al banco de preguntas';

  @override
  String get prepPlusSelectDuration => 'Duración del acceso';

  @override
  String get prepPlusDuration30 => '30 días';

  @override
  String get prepPlusDuration60 => '60 días';

  @override
  String get prepPlusDuration90 => '90 días';

  @override
  String get prepPlusDuration6Months => '6 meses';

  @override
  String prepPlusDurationDays(int days) {
    return '$days días';
  }

  @override
  String prepPlusOfferPrice(double price, String currency) {
    final intl.NumberFormat priceNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '$priceString $currency';
  }

  @override
  String get prepPlusPracticeAction => 'Practicar';

  @override
  String get prepPlusBuyAction => 'Comprar acceso';

  @override
  String get prepPlusGetFreeAccessAction => 'Obtener acceso gratis';

  @override
  String get prepPlusRenewAction => 'Renovar acceso';

  @override
  String get prepPlusExtendAccessAction => 'Ampliar acceso';

  @override
  String get prepPlusExtendAccessCardSubtitle =>
      'Suma más días a tu acceso actual';

  @override
  String get prepPlusAccessCardNoAccessTitle =>
      'Aún no tienes acceso a este cuestionario';

  @override
  String prepPlusAccessFromPrice(String price) {
    return 'Desde $price';
  }

  @override
  String prepPlusAccessCountdownDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Vence en $days días',
      one: 'Vence en 1 día',
      zero: 'Vence hoy',
    );
    return '$_temp0';
  }

  @override
  String prepPlusAccessCountdownHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Vence en $hours horas',
      one: 'Vence en 1 hora',
    );
    return '$_temp0';
  }

  @override
  String prepPlusAccessCountdownTimer(String time) {
    return 'Vence en $time';
  }

  @override
  String get prepPlusShareAction => 'Compartir';

  @override
  String prepPlusShareLinkMessage(String title, String url) {
    return '🎯 ¡El repaso definitivo para el examen! Practica con el cuestionario de $title en CraftQuestAI y asegura esa nota. 🚀\n👇 Entra aquí:\n$url';
  }

  @override
  String get prepPlusPublicPreviewSignIn => 'Iniciar sesión para comprar';

  @override
  String prepPlusPublicPreviewQuestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas',
      one: '1 pregunta',
    );
    return '$_temp0';
  }

  @override
  String prepPlusAccessUntil(String date) {
    return 'Vence el $date';
  }

  @override
  String prepPlusExpiresOn(String date) {
    return 'Vence el $date';
  }

  @override
  String prepPlusExpiredOn(String date) {
    return 'Expiró el $date';
  }

  @override
  String get prepPlusNotAvailableForPurchase =>
      'No disponible para compra en este momento.';

  @override
  String get prepPlusViewHistory => 'Ver mi historial';

  @override
  String get prepPlusProgressSectionTitle => 'Mi progreso';

  @override
  String get prepPlusAccessGranted => 'Acceso concedido. ¡Ya puedes practicar!';

  @override
  String get prepPlusConfirmPayPalPayment => 'Confirmar pago PayPal';

  @override
  String get prepPlusStoreProductMissing =>
      'Pago en tienda no configurado para esta oferta. Usa la versión web con PayPal.';

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
  String get currentPasswordIncorrectError =>
      'La contraseña actual no es correcta.';

  @override
  String get passwordChangeUnavailableError =>
      'Esta cuenta no tiene contraseña local. Usa el inicio de sesión con Google o Apple.';

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
  String get quizFolderNewFolderAction => 'Nueva carpeta';

  @override
  String get quizFolderCreateTitle => 'Nueva carpeta';

  @override
  String get quizFolderCreateSubfolderTitle => 'Nueva subcarpeta';

  @override
  String get quizFolderRenameTitle => 'Renombrar carpeta';

  @override
  String get quizFolderRenameAction => 'Renombrar';

  @override
  String get quizFolderDeleteAction => 'Eliminar carpeta';

  @override
  String get quizFolderCreateSubfolderAction => 'Crear subcarpeta';

  @override
  String get quizFolderMoveQuizAction => 'Mover a carpeta';

  @override
  String get quizFolderMoveQuizTitle => 'Mover cuestionario';

  @override
  String get quizFolderUncategorized => 'Sin carpeta';

  @override
  String get quizFolderNameHint => 'Nombre de la carpeta';

  @override
  String get quizFolderDeleteConfirmTitle => '¿Eliminar carpeta?';

  @override
  String quizFolderDeleteConfirmMessage(String folderName) {
    return 'Se eliminará la carpeta \"$folderName\". Los cuestionarios no se borrarán.';
  }

  @override
  String quizFolderDeleteConfirmWithQuizzes(String folderName, int quizCount) {
    return 'Se eliminará la carpeta \"$folderName\" y sus subcarpetas. $quizCount cuestionarios quedarán sin carpeta.';
  }

  @override
  String get quizSearchHint => 'Buscar cuestionarios';

  @override
  String get quizSearchNoResults => 'Sin resultados';

  @override
  String get quizFolderDropToRoot => 'Mover a la raíz';

  @override
  String get quizFolderMoveInvalid => 'No se puede mover ahí';

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
  String get exportQuizPdfAction => 'Exportar PDF';

  @override
  String get exportQuizPdfGenerating => 'Generando PDF…';

  @override
  String get exportQuizPdfReady => 'PDF listo';

  @override
  String get exportQuizPdfDownloadHint =>
      'Si no ves el archivo, revisa la ventana de descarga de tu navegador';

  @override
  String get exportQuizPdfFailed => 'No se pudo generar el PDF';

  @override
  String get exportQuizPdfEmpty => 'Agrega preguntas antes de exportar';

  @override
  String get exportQuizPdfGeneratingHint =>
      'Preparando tu documento. Esto puede tardar unos segundos.';

  @override
  String get exportQuizPdfPlanRequired =>
      'La exportación a PDF está disponible en planes de pago.';

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
  String get questionJustificationLabel => 'Justificación (respuesta correcta)';

  @override
  String get questionJustificationHint =>
      'Explica en un solo texto por qué la(s) respuesta(s) correcta(s) lo son.';

  @override
  String get questionJustificationReviewHint =>
      'Visible al revisar los intentos del cuestionario (no durante la práctica).';

  @override
  String get explanationVisibilityAfterQuiz => 'Al terminar el cuestionario';

  @override
  String get explanationVisibilityAfterAnswer => 'Tras cada respuesta';

  @override
  String get explanationVisibilityNever => 'No mostrar en práctica';

  @override
  String get practiceReviewJustificationTitle => 'Justificación';

  @override
  String get practiceReviewJustificationTapToExpand =>
      'Toca para ver la explicación';

  @override
  String practiceReviewSourcePage(int page) {
    return 'Página $page';
  }

  @override
  String get aiGenerationIncludeExplanationsLabel => 'Incluir justificaciones';

  @override
  String get aiGenerationIncludeExplanationsHint =>
      'La IA generará texto explicativo y número de página del material cuando aplique.';

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
  String get quizRandomizeQuestionsHint =>
      'Aplica a las asignaciones de tus estudiantes y cuando practican este cuestionario';

  @override
  String get practiceShowTimerLabel => 'Mostrar tiempo transcurrido';

  @override
  String get practiceShowTimerHint =>
      'Muestra un reloj mientras respondes el cuestionario';

  @override
  String get practiceSoundEffectsLabel => 'Efectos de sonido';

  @override
  String get practiceSoundEffectsHint =>
      'Sonidos al iniciar, navegar entre preguntas y finalizar';

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
  String get practicePreparingSession => 'Preparando tu intento…';

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
  String get importFormatJsonHelp =>
      'Usa este formato si tienes un archivo .json exportado de CraftQuest, un borrador de la IA o datos de otra herramienta compatible con CQIF v2.';

  @override
  String get importFormatTxtHelp =>
      'Usa este formato si tienes un archivo de texto plano con la estructura CraftQuest ([QUIZ], [QUESTION], campos clave=valor). Es más cómodo para editar a mano.';

  @override
  String get importFormatUnsureHelp =>
      '¿No estás seguro? Pega el contenido, elige el formato más parecido y pulsa «Normalizar con IA» para convertirlo a JSON antes de importar.';

  @override
  String get importContentHintJson => 'Pega aquí el JSON CQIF v2 completo';

  @override
  String get importContentHintTxt =>
      'Pega aquí el archivo TXT CraftQuest ([QUIZ], [QUESTION]…)';

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
  String get importSummaryLoading => 'Cargando preguntas…';

  @override
  String importSummaryReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count preguntas listas para revisar',
      one: '1 pregunta lista para revisar',
    );
    return '$_temp0';
  }

  @override
  String importSummaryWithErrors(int valid, int total, int errors) {
    return '$valid válidas de $total · $errors con error';
  }

  @override
  String get importSummaryEmpty =>
      'No se detectaron preguntas en esta importación';

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
  String get teacherReviewLegend =>
      'Rojo = respuesta marcada incorrecta · Verde = respuesta marcada correcta · Bombilla = respuesta correcta no marcada';

  @override
  String get teacherReviewYourAnswerTag => 'Tu respuesta';

  @override
  String get teacherReviewCorrectAnswerTag => 'Respuesta correcta';

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
  String get redeemCodeOpeningQuiz => 'Abriendo cuestionario…';

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
  String get shareCodeCopyLinkAction => 'Copiar link';

  @override
  String get shareCodeLinkCopied => 'Link copiado';

  @override
  String get shareCodeShareLinkAction => 'Compartir link';

  @override
  String shareCodeShareLinkMessage(String title, String url, String code) {
    return 'Únete a \"$title\" en CraftQuestAI:\n$url\n\nO usa el código: $code';
  }

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
  String get imagePickPermissionDenied =>
      'Permite el acceso a fotos en Ajustes para adjuntar imágenes.';

  @override
  String get imagePickFailed =>
      'No se pudo abrir la galería. Inténtalo de nuevo.';

  @override
  String get imageTooLargeForUpload =>
      'La imagen es demasiado grande (máx. 5 MB). Elige otra o una foto más pequeña.';

  @override
  String get imageAttachedSuccess => 'Imagen adjuntada correctamente.';

  @override
  String get imageUploadInvalidResponse =>
      'El servidor respondió de forma inesperada. Reinicia la API y vuelve a intentarlo.';

  @override
  String get imageUploadInvalidMultipart =>
      'No se pudo enviar la imagen al servidor. Reinicia la app y la API e inténtalo de nuevo.';

  @override
  String get imageUploadFileRequired =>
      'No se recibió ningún archivo de imagen. Vuelve a seleccionar la foto.';

  @override
  String get imageUploadUnsupportedType =>
      'Formato de imagen no admitido. Usa JPG, PNG, WebP o GIF.';

  @override
  String get imagePreviewLoadFailed =>
      'Imagen guardada, pero no se pudo mostrar la vista previa. Comprueba la conexión con el servidor.';

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
  String upgradeProHighlightQuizzesLimit(int max) {
    return 'Cuestionarios ilimitados (tu plan actual: máx. $max)';
  }

  @override
  String upgradeProHighlightQuestionsLimit(int max) {
    return 'Sin límite de preguntas por cuestionario (tu plan actual: $max)';
  }

  @override
  String get upgradeProHighlightAiCredits =>
      '150 créditos IA al mes (tu plan actual: 20)';

  @override
  String upgradePlanHighlightAiCredits(int credits, int currentCredits) {
    return '$credits créditos IA al mes (tu plan actual: $currentCredits)';
  }

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
  String get paypalAwaitingSubscriptionActivation =>
      'Aprueba la suscripción en PayPal y vuelve a la app para activarla.';

  @override
  String get paypalReturnTitle => 'Pago con PayPal';

  @override
  String get paypalReturnProcessing => 'Procesando tu pago de PayPal…';

  @override
  String get paypalReturnSuccessSubscription =>
      'Suscripción activada correctamente.';

  @override
  String get paypalReturnSuccessPrep => 'Acceso Prep+ concedido correctamente.';

  @override
  String get paypalReturnSuccessCredits =>
      'Créditos de IA añadidos a tu cuenta.';

  @override
  String get paypalReturnSuccessOrder => 'Pago completado correctamente.';

  @override
  String get paypalReturnError =>
      'No pudimos completar el pago de PayPal. Inténtalo de nuevo.';

  @override
  String get paypalReturnCancelled => 'Cancelaste el pago en PayPal.';

  @override
  String get paypalReturnContinue => 'Continuar';

  @override
  String get subscriptionAutoRenewDisclaimer =>
      'Renovación automática cada periodo hasta que la canceles. Puedes desactivarla en cualquier momento.';

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
  String get errorAiCreditPacksNotAvailable =>
      'Los paquetes de créditos IA están disponibles en los planes Pro y Teacher.';

  @override
  String get aiCreditPacksTitle => 'Comprar créditos IA';

  @override
  String get aiCreditPacksSubtitle =>
      'Recarga créditos para seguir generando con IA. Los paquetes comprados no expiran; el cupo mensual del plan sí se reinicia cada mes.';

  @override
  String aiCreditPacksCurrentBalance(int credits) {
    return 'Saldo actual: $credits créditos';
  }

  @override
  String aiCreditPacksCreditsLabel(int credits) {
    return '$credits créditos IA';
  }

  @override
  String aiCreditPacksBuyForPrice(String price) {
    return 'Comprar · $price';
  }

  @override
  String get aiCreditPacksEmpty =>
      'No hay paquetes disponibles. Reinicia la API o contacta soporte si el problema continúa.';

  @override
  String get aiCreditPacksBuyAction => 'Comprar créditos';

  @override
  String aiCreditPacksPurchaseSuccess(int credits) {
    return 'Se añadieron $credits créditos IA a tu cuenta.';
  }

  @override
  String get aiCreditsInsufficientDialogMessage =>
      'Puedes comprar un paquete de créditos para seguir generando con IA.';

  @override
  String get aiCreditsInsufficientFreePlanMessage =>
      'Mejora a Pro o Teacher para comprar paquetes de créditos IA.';

  @override
  String get homeBuyAiCreditsAction => 'Comprar créditos IA';

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
  String get errorAiGeminiApiKeyInvalid =>
      'La API key de Gemini no es válida (expirada, revocada o filtrada). Crea una clave nueva en Google AI Studio, actualízala en appsettings.Development.local.json y reinicia la API.';

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
  String get guestAnonymousLimitTitle => '¡Buen trabajo practicando!';

  @override
  String get guestAnonymousLimitMessage =>
      'Has alcanzado el límite de prácticas anónimas. Crea una cuenta gratis en 10 segundos para seguir practicando, guardar tu progreso y crear tus propios cuestionarios.';

  @override
  String get guestAnonymousLimitLater => 'Más tarde';

  @override
  String get guestAnonymousLimitSignUp => 'Crear cuenta';

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
      'Plan Free: 2 cuestionarios y 20 créditos IA, gratis';

  @override
  String get guestRegisterBenefit4 => 'Experiencia sin anuncios';

  @override
  String get guestRegisterBenefit5 =>
      'Comparte cuestionarios con códigos o invitaciones';

  @override
  String get guestRegisterBenefit6 =>
      'Analítica de práctica: descubre dónde fallas más';

  @override
  String get guestRegisterPromoSubtitle =>
      'Crea una cuenta gratis en segundos y desbloquea todo esto.';

  @override
  String get guestRegisterPromoBenefitsTitle => 'Con tu cuenta registrada';

  @override
  String guestRegisterPromoCountdown(int seconds) {
    return 'Ver resultados en $seconds s';
  }

  @override
  String get guestRegisterPromoSkipTooltip => 'Ver resultados ahora';

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
  String get teacherDashboardInventoryQuizzes => 'Asignados';

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
  String get teacherAssignmentAnalyticsDistractorTitle =>
      'Selección por opción (esta tarea)';

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
    return '$points pts más que en tu intento anterior';
  }

  @override
  String practiceResultTrendDown(String points) {
    return '$points pts menos que en tu intento anterior';
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
  String get teacherClassesArchivedSectionTitle => 'Clases archivadas';

  @override
  String get teacherClassRestoreAction => 'Restaurar clase';

  @override
  String get teacherClassRestoreConfirmTitle => '¿Restaurar clase?';

  @override
  String get teacherClassRestoreConfirmMessage =>
      'La clase volverá a estar activa y los estudiantes verán de nuevo sus asignaciones abiertas.';

  @override
  String get teacherClassRestoreConfirmAction => 'Restaurar';

  @override
  String get teacherClassArchivedBanner =>
      'Esta clase está archivada. Restáurala para editarla o asignar tareas.';

  @override
  String get teacherClassRestoredMessage => 'Clase restaurada';

  @override
  String get teacherClassDeletePermanentAction => 'Eliminar';

  @override
  String get teacherClassDeletePermanentTitle => '¿Eliminar clase archivada?';

  @override
  String teacherClassDeletePermanentMessage(String name) {
    return '«$name» dejará de mostrarse en tu lista. Los datos (miembros, asignaciones e historial) se conservan en el sistema. Solo aplica a clases ya archivadas.';
  }

  @override
  String get teacherClassDeletePermanentConfirm => 'Eliminar';

  @override
  String get teacherClassDeletedMessage => 'Clase eliminada de tu lista';

  @override
  String get teacherClassDeleteRequiresArchiveError =>
      'Archiva la clase antes de eliminarla.';

  @override
  String get teacherClassNotArchivedError => 'Esta clase no está archivada.';

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
  String get teacherAssignmentRandomizeQuestionsLabel =>
      'Orden aleatorio de preguntas';

  @override
  String get teacherAssignmentRandomizeQuestionsHint =>
      'Define cómo se muestran las preguntas en esta tarea de clase.';

  @override
  String get teacherAssignmentAllowStudentRandomizeLabel =>
      'El alumno puede cambiar el orden';

  @override
  String get teacherAssignmentAllowStudentRandomizeHint =>
      'Si está desactivado, todos los alumnos usan la opción de arriba.';

  @override
  String get teacherAssignmentForfeitExitLabel =>
      'Salir sin terminar consume un intento';

  @override
  String get teacherAssignmentForfeitExitHint =>
      'Solo aplica cuando hay un máximo de intentos definido. El alumno no podrá pausar y reanudar.';

  @override
  String get teacherAssignmentForfeitRequiresMaxAttempts =>
      'Define al menos 1 intento máximo para activar esta regla.';

  @override
  String get practiceForfeitExitDialogTitle => '¿Salir de la práctica?';

  @override
  String get practiceForfeitExitDialogMessage =>
      'Si sales ahora, se contará como un intento usado aunque no hayas finalizado el cuestionario.';

  @override
  String get practiceForfeitExitConfirm => 'Salir y usar intento';

  @override
  String get practiceForfeitExitCancel => 'Seguir practicando';

  @override
  String get studentAssignmentAttemptStatusForfeited => 'Salida anticipada';

  @override
  String get studentAssignmentRandomizeLockedShuffled =>
      'Orden aleatorio fijado por el profesor';

  @override
  String get studentAssignmentRandomizeLockedOrdered =>
      'Orden del cuestionario fijado por el profesor';

  @override
  String get studentAssignmentPracticeOptionsTitle => 'Opciones de práctica';

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
  String teacherUpgradeNextRenewal(String date) {
    return 'Próxima renovación: $date';
  }

  @override
  String teacherUpgradeAccessUntil(String date) {
    return 'Acceso hasta el $date (sin renovación automática)';
  }

  @override
  String get teacherUpgradeCancelTitle => '¿Cancelar suscripción?';

  @override
  String get teacherUpgradeCancelMessage =>
      'Se desactivará la renovación automática. Mantendrás el plan Profesor hasta el final del periodo pagado; después pasarás a Free.';

  @override
  String get teacherUpgradeCancelConfirm => 'Desactivar renovación';

  @override
  String get teacherUpgradeCancelSuccess =>
      'Suscripción cancelada. ¡Hasta pronto!';

  @override
  String teacherUpgradeCancelSuccessUntil(String date) {
    return 'Renovación automática desactivada. Acceso al plan Profesor hasta el $date.';
  }

  @override
  String get billingCancelStoreTitle => 'Gestionar suscripción en la tienda';

  @override
  String get billingCancelStoreMessageGoogle =>
      'Los cobros recurrentes de CraftQuest se gestionan en Google Play. Abre tus suscripciones en Play Store, cancela CraftQuest y conservarás el acceso hasta el final del periodo pagado.';

  @override
  String get billingCancelStoreMessageApple =>
      'Los cobros recurrentes de CraftQuest se gestionan en el App Store. Abre tus suscripciones en Ajustes de Apple, cancela CraftQuest y conservarás el acceso hasta el final del periodo pagado.';

  @override
  String get billingCancelStoreOpenGooglePlay => 'Abrir Google Play';

  @override
  String get billingCancelStoreOpenAppStore => 'Abrir App Store';

  @override
  String get billingCancelStoreSyncTitle => '¿Actualizar estado en CraftQuest?';

  @override
  String get billingCancelStoreSyncMessage =>
      'Si ya cancelaste en la tienda, puedes desactivar la renovación en CraftQuest para reflejar el fin de periodo en la app. El cobro real solo se detiene en la tienda.';

  @override
  String get billingCancelStoreSyncConfirm => 'Desactivar renovación en la app';

  @override
  String get billingResumeAutoRenewTitle => '¿Reactivar renovación automática?';

  @override
  String get billingResumeAutoRenewMessage =>
      'Se volverá a cobrar al final del periodo actual. Mantendrás el acceso hasta entonces.';

  @override
  String get billingResumeAutoRenewConfirm => 'Reactivar renovación';

  @override
  String get billingResumeAutoRenewSuccess =>
      'Renovación automática reactivada.';

  @override
  String billingResumeAutoRenewSuccessUntil(String date) {
    return 'Próxima renovación el $date.';
  }

  @override
  String get billingResumeStoreTitle => 'Reactivar suscripción en la tienda';

  @override
  String get billingResumeStoreMessageGoogle =>
      'Para volver a cobrar de forma recurrente, reactiva CraftQuest en Google Play (Suscripciones). Después puedes sincronizar el estado en la app.';

  @override
  String get billingResumeStoreMessageApple =>
      'Para volver a cobrar de forma recurrente, reactiva CraftQuest en el App Store (Suscripciones). Después puedes sincronizar el estado en la app.';

  @override
  String get billingResumeStoreSyncTitle => '¿Actualizar estado en CraftQuest?';

  @override
  String get billingResumeStoreSyncMessage =>
      'Si ya reactivaste la suscripción en la tienda, confirma aquí para mostrar la próxima renovación en la app.';

  @override
  String get billingResumeStoreSyncConfirm => 'Reactivar renovación en la app';

  @override
  String get billingResumeRequiresResubscribeTitle =>
      'Volver a suscribirse con PayPal';

  @override
  String get billingResumeRequiresResubscribeMessage =>
      'La renovación en PayPal ya se canceló. Para seguir con cobros automáticos, crea una nueva suscripción.';

  @override
  String get billingResumeRequiresResubscribeConfirm => 'Suscribirse de nuevo';

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
  String get homeTeacherBannerDismissTooltipWeekly => 'Ocultar esta semana';

  @override
  String get homeTeacherBannerDismissTooltipMonthly => 'Ocultar este mes';

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
  String subscriptionPlanActive(String planName) {
    return 'Plan $planName activo.';
  }

  @override
  String get profileProPlanSectionTitle => 'Plan Pro';

  @override
  String get profileProPlanManageTitle => 'Gestionar plan Pro';

  @override
  String get profileProPlanActiveSubtitle =>
      'Plan activo · toca para gestionar';

  @override
  String get profileProPlanInactiveSubtitle =>
      'Quizzes ilimitados y más · Suscripción mensual o anual';

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
  String get profilePaymentHistorySectionTitle => 'Pagos';

  @override
  String get profilePaymentHistoryAction => 'Historial de transacciones';

  @override
  String get profilePaymentHistorySubtitle =>
      'Suscripciones, Preparación+ y otros pagos';

  @override
  String get paymentHistoryTitle => 'Historial de pagos';

  @override
  String get paymentHistoryEmpty =>
      'Aún no hay transacciones registradas en tu cuenta.';

  @override
  String paymentHistoryAmount(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get paymentPurchaseStatusValidated => 'Completado';

  @override
  String get paymentPurchaseStatusPending => 'Pendiente';

  @override
  String get paymentPurchaseStatusRejected => 'Rechazado';

  @override
  String get paymentPurchaseStatusRefunded => 'Reembolsado';

  @override
  String get paymentPurchaseStatusCancelled => 'Cancelado';

  @override
  String get paymentProviderPayPal => 'PayPal';

  @override
  String get paymentProviderGooglePlay => 'Google Play';

  @override
  String get paymentProviderAppStore => 'App Store';

  @override
  String get paymentProviderOther => 'Otro';

  @override
  String get paymentProductTypeSubscription => 'Suscripción';

  @override
  String get paymentProductTypePrepAccess => 'Preparación+';

  @override
  String get paymentProductTypeAiCredits => 'Créditos IA';

  @override
  String get paymentProductTypeShareCodes => 'Códigos compartidos';

  @override
  String get paymentProductTypeCuratedPackage => 'Paquete';

  @override
  String get paymentProductTypeTeacherSeats => 'Plazas profesor';

  @override
  String get paymentProductTypeOther => 'Otro';

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

  @override
  String get prepAdminProfileSectionTitle => 'Administración';

  @override
  String get prepAdminProfileAction => 'Preparación+ (catálogo)';

  @override
  String get prepAdminProfileSubtitle =>
      'Categorías, ítems, precios y publicación';

  @override
  String get prepAdminHubTitle => 'Admin Preparación+';

  @override
  String get prepAdminHubSubtitle =>
      'Gestiona el catálogo B2C curado de la plataforma.';

  @override
  String get prepAdminCategoriesAction => 'Categorías';

  @override
  String get prepAdminCategoriesSubtitle => 'Países, regiones e Internacional';

  @override
  String get prepAdminCatalogAction => 'Ítems del catálogo';

  @override
  String get prepAdminCatalogSubtitle => 'Cuestionarios, ofertas y muestras';

  @override
  String get prepAdminCategoriesTitle => 'Categorías Prep+';

  @override
  String get prepAdminAddRootCategory => 'Categoría raíz';

  @override
  String get prepAdminAddSubcategory => 'Subcategoría';

  @override
  String get prepAdminEditCategoryTitle => 'Editar categoría';

  @override
  String get prepAdminDeleteCategoryTitle => '¿Eliminar categoría?';

  @override
  String prepAdminDeleteCategoryMessage(String name) {
    return 'Se eliminará «$name» y sus subcategorías si no tienen ítems.';
  }

  @override
  String get prepAdminCategoryDeleted => 'Categoría eliminada';

  @override
  String get prepAdminCategorySaved => 'Categoría guardada';

  @override
  String get prepAdminActive => 'Activa';

  @override
  String get prepAdminInactive => 'Inactiva';

  @override
  String get prepAdminCategoryTypeLabel => 'Tipo';

  @override
  String get prepAdminCategoryTypeGeographic => 'Geográfica (país)';

  @override
  String get prepAdminCategoryTypeThematic => 'Temática (Internacional)';

  @override
  String get prepAdminNameLabel => 'Nombre';

  @override
  String get prepAdminSlugLabel => 'Slug (URL)';

  @override
  String get prepAdminRequiredField => 'Campo obligatorio';

  @override
  String get prepAdminDescriptionLabel => 'Descripción';

  @override
  String get prepAdminCountryCodeLabel => 'Código país (ISO)';

  @override
  String get prepAdminIconKeyLabel => 'Icono (clave)';

  @override
  String get prepAdminSortOrderLabel => 'Orden';

  @override
  String get prepAdminCatalogTitle => 'Catálogo Prep+';

  @override
  String get prepAdminNewCatalogItem => 'Nuevo ítem';

  @override
  String get prepAdminPublishedFilter => 'Publicados';

  @override
  String get prepAdminDraftFilter => 'Borradores';

  @override
  String get prepAdminCatalogEmpty => 'No hay ítems en el catálogo.';

  @override
  String prepAdminItemSummarySubtitle(
    String category,
    int questions,
    int offers,
    int samples,
    String status,
  ) {
    return '$category · $questions preg. · $offers ofertas · $samples muestras · $status';
  }

  @override
  String get prepAdminEditItemTitle => 'Editar ítem';

  @override
  String get prepAdminMetadataSection => 'Metadatos';

  @override
  String get prepAdminOffersSection => 'Matriz de precios';

  @override
  String get prepAdminSamplesSection => 'Preguntas muestra';

  @override
  String get prepAdminPublishSection => 'Publicación';

  @override
  String get prepAdminQuizIdLabel => 'ID del cuestionario';

  @override
  String get prepAdminQuizIdHint => 'GUID del quiz existente en la plataforma';

  @override
  String get prepAdminQuizIdRequired => 'Indica el ID del cuestionario';

  @override
  String get prepAdminQuizSearchLabel => 'Buscar cuestionario';

  @override
  String get prepAdminSelectQuizLabel => 'Cuestionario';

  @override
  String get prepAdminSelectQuizHint =>
      'Solo cuestionarios creados por administradores de contenido, aún no en el catálogo.';

  @override
  String get prepAdminSelectQuizError => 'Selecciona un cuestionario.';

  @override
  String get prepAdminLinkableQuizzesEmpty =>
      'No hay cuestionarios disponibles. Crea uno con una cuenta admin o quita los que ya están en el catálogo.';

  @override
  String prepAdminLinkableQuizOption(String title, int count, String author) {
    return '$title · $count preg. · $author';
  }

  @override
  String get prepAdminSubcategoryLabel => 'Subcategoría';

  @override
  String get prepAdminSelectCategoryError => 'Selecciona una subcategoría';

  @override
  String get prepAdminTitleOverrideLabel => 'Título en catálogo (opcional)';

  @override
  String get prepAdminTagsLabel => 'Etiquetas';

  @override
  String get prepAdminTagsHint => 'Separadas por comas';

  @override
  String get prepAdminCoverImageLabel => 'Portada (imagen)';

  @override
  String get prepAdminCoverImageHint =>
      'Se usa en la landing y al compartir en redes. Al subirla se guarda en el ítem automáticamente.';

  @override
  String get prepAdminCoverSaved => 'Portada guardada en el ítem.';

  @override
  String get prepAdminCoverRemoved => 'Portada eliminada del ítem.';

  @override
  String get prepAdminCoverSaving => 'Guardando portada…';

  @override
  String get prepAdminCoverSavedStatus => 'Portada guardada en el catálogo';

  @override
  String get prepAdminCoverNotSavedStatus =>
      'No se pudo confirmar el guardado. Pulsa «Guardar metadatos».';

  @override
  String get prepAdminCoverUploadedPendingCreate =>
      'Imagen subida. Se guardará al crear el ítem.';

  @override
  String get prepAdminCoverWillSaveOnCreate =>
      'Se guardará cuando pulses «Crear ítem».';

  @override
  String get prepAdminCoverSaveNeedsCategory =>
      'Selecciona una subcategoría antes de guardar la portada.';

  @override
  String get prepAdminShareLinkNoCover =>
      'Sube una portada para que aparezca la imagen al compartir en redes.';

  @override
  String get prepAdminShareLinkSection => 'Enlace para compartir';

  @override
  String get prepAdminShareLinkHint =>
      'Úsalo en redes sociales. Al abrirlo se muestra la landing con vista previa del ítem.';

  @override
  String get prepAdminShareLinkUnavailable =>
      'Publica el ítem para obtener el enlace de compartir.';

  @override
  String get prepAdminListingStartLabel => 'Inicio de venta';

  @override
  String get prepAdminListingEndLabel => 'Fin de venta';

  @override
  String get prepAdminOptionalDate => 'Sin definir';

  @override
  String get prepAdminCreateItemAction => 'Crear ítem';

  @override
  String get prepAdminSaveMetadataAction => 'Guardar metadatos';

  @override
  String get prepAdminSaveOffersAction => 'Guardar precios';

  @override
  String get prepAdminPickSamplesAction => 'Elegir 3 preguntas';

  @override
  String get prepAdminSamplesEmpty => 'Aún no hay preguntas muestra.';

  @override
  String get prepAdminPublishAction => 'Publicar en catálogo';

  @override
  String get prepAdminUnpublishAction => 'Despublicar';

  @override
  String get prepAdminDeleteItemAction => 'Eliminar ítem';

  @override
  String get prepAdminDeleteItemTitle => '¿Eliminar ítem del catálogo?';

  @override
  String get prepAdminDeleteItemMessage =>
      'El ítem dejará de mostrarse. Los accesos ya comprados se conservan en historial.';

  @override
  String get prepAdminItemCreated => 'Ítem creado';

  @override
  String get prepAdminMetadataSaved => 'Metadatos guardados';

  @override
  String get prepAdminOffersRequired => 'Activa al menos una oferta de acceso';

  @override
  String get prepAdminOffersSaved => 'Precios guardados';

  @override
  String get prepAdminSamplesSaved => 'Muestras guardadas';

  @override
  String get prepAdminPublished => 'Publicado en catálogo';

  @override
  String get prepAdminUnpublished => 'Despublicado';

  @override
  String get prepAdminItemDeleted => 'Ítem eliminado';

  @override
  String prepAdminLinkedQuiz(String title) {
    return 'Cuestionario: $title';
  }

  @override
  String prepAdminOffersChip(int count) {
    return '$count ofertas activas';
  }

  @override
  String prepAdminSamplesChip(int count) {
    return '$count/3 muestras';
  }

  @override
  String get prepAdminOfferFreeLabel => 'Acceso gratis';

  @override
  String get prepAdminOfferPriceLabel => 'Precio';

  @override
  String get prepAdminOfferCurrencyLabel => 'Moneda';

  @override
  String get prepAdminStoreProductIdLabel => 'ID producto tienda (IAP)';

  @override
  String get prepAdminSamplesLoadError => 'No se pudieron cargar las preguntas';

  @override
  String get prepAdminSamplesCountError => 'Selecciona exactamente 3 preguntas';

  @override
  String get prepAdminSamplesPickerTitle => 'Preguntas muestra';

  @override
  String prepAdminSamplesPickerSubtitle(int selected, int required) {
    return '$selected de $required seleccionadas';
  }

  @override
  String get errorPrepCategoryNotFound => 'Categoría no encontrada.';

  @override
  String get errorPrepCategoryHasSubcategories =>
      'No se puede eliminar: tiene subcategorías activas.';

  @override
  String get errorPrepCategoryHasItems =>
      'No se puede eliminar: tiene ítems en el catálogo.';

  @override
  String get errorPrepQuizNotFound => 'Cuestionario no encontrado.';

  @override
  String get errorPrepQuizNotEligible =>
      'Solo se pueden añadir cuestionarios creados por un administrador de contenido.';

  @override
  String get errorPrepQuizAlreadyInCatalog =>
      'Este cuestionario ya está en Preparación+.';

  @override
  String get errorPrepCatalogItemNotFound => 'Ítem de catálogo no encontrado.';

  @override
  String errorPrepSampleCountRequired(int count) {
    return 'Se requieren exactamente $count preguntas muestra.';
  }

  @override
  String get errorPrepSampleQuestionsNotInQuiz =>
      'Las preguntas muestra deben pertenecer al cuestionario vinculado.';

  @override
  String get errorPrepInvalidCategoryType => 'Tipo de categoría no válido.';

  @override
  String get errorPrepNameSlugRequired => 'Nombre y slug son obligatorios.';

  @override
  String get errorPrepParentCategoryNotFound =>
      'Categoría padre no encontrada.';

  @override
  String get errorPrepSubcategoryTypeMismatch =>
      'El tipo de subcategoría debe coincidir con el padre.';

  @override
  String get errorPrepCategorySelfParent =>
      'Una categoría no puede ser su propio padre.';

  @override
  String get errorPrepSlugDuplicate => 'Ese slug ya existe en este nivel.';

  @override
  String get errorPrepCategoryInactive => 'Categoría no encontrada o inactiva.';

  @override
  String get errorPrepItemRequiresSubcategory =>
      'El ítem debe asignarse a una subcategoría, no a una raíz.';

  @override
  String get errorPrepInstitutionTagGeographicOnly =>
      'La etiqueta de institución solo aplica en categorías geográficas.';

  @override
  String get errorPrepCategoryHierarchyBroken =>
      'La jerarquía de categorías está incompleta.';

  @override
  String get errorPrepOffersRequired =>
      'Se requiere al menos una oferta de acceso.';

  @override
  String get errorPrepInvalidDuration =>
      'Duración no válida. Permitidas: 30, 60, 90 y 183 días.';

  @override
  String get errorPrepPriceNegative => 'El precio no puede ser negativo.';

  @override
  String get errorPrepOfferDurationDuplicate =>
      'Hay duraciones duplicadas en las ofertas.';

  @override
  String get errorPrepActiveOfferRequiredPublish =>
      'Activa al menos una oferta antes de publicar.';

  @override
  String errorPrepSamplesRequiredPublish(int count) {
    return 'Configura exactamente $count preguntas muestra antes de publicar.';
  }

  @override
  String get errorPrepQuizNoQuestions =>
      'El cuestionario vinculado debe tener al menos una pregunta.';

  @override
  String get errorPrepListingEndBeforeStart =>
      'La fecha de fin de venta debe ser posterior al inicio.';

  @override
  String get errorPrepPreviewNotAvailable =>
      'La vista previa no está disponible para este ítem.';

  @override
  String get errorPrepItemNotAvailable =>
      'Este ítem no está disponible para compra en este momento.';

  @override
  String get errorPrepOfferNotFound => 'Oferta no encontrada.';

  @override
  String get errorPrepOfferIsFree =>
      'Esta oferta es gratis. Usa el checkout sin pago.';

  @override
  String get errorPrepPayPalPurchaseNotFound =>
      'Compra PayPal de Preparación+ no encontrada.';

  @override
  String get errorPrepMobilePlatformInvalid =>
      'La plataforma debe ser google_play o app_store.';

  @override
  String get errorPrepStoreProductMismatch =>
      'El producto de tienda no coincide con esta oferta.';

  @override
  String get errorPrepOfferNoLongerExists => 'La oferta ya no existe.';

  @override
  String get errorPrepInvalidProductCode =>
      'Código de producto de compra no válido.';

  @override
  String get errorPrepGooglePlayNotConfigured =>
      'Google Play no está configurado en el servidor.';

  @override
  String get errorPrepAppStoreNotConfigured =>
      'App Store no está configurado. Usa pagos mock en desarrollo.';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Aún no tienes notificaciones.';

  @override
  String get notificationsMarkAllRead => 'Marcar todo leído';

  @override
  String get notificationsUnreadBadge => 'No leída';

  @override
  String get notificationsPreferencesTitle => 'Ajustes de notificaciones';

  @override
  String get notificationsPreferencesSubtitle =>
      'Configura cómo quieres recibir cada tipo de aviso.';

  @override
  String get notificationsPreferencesSaved =>
      'Preferencias de notificaciones guardadas.';

  @override
  String get notificationsPreferencesSectionSharing => 'Compartidos y clases';

  @override
  String get notificationsPreferencesSectionAssignments => 'Tareas';

  @override
  String get notificationsPreferencesSectionMembership => 'Membresía';

  @override
  String get notificationsPreferencesSectionAi => 'Generación con IA';

  @override
  String get notificationsPreferencesDefaultsHint =>
      'Por defecto: avisos en la app y push activos. El correo solo viene activado en membresía por vencer y membresía vencida.';

  @override
  String get notificationsPreferencesResetDefaults =>
      'Restaurar valores por defecto';

  @override
  String get notificationsChannelInApp => 'En la app';

  @override
  String get notificationsChannelPush => 'Push';

  @override
  String get notificationsChannelEmail => 'Correo';

  @override
  String get notificationTypeQuizShared => 'Cuestionario compartido';

  @override
  String get notificationTypeClassJoined => 'Te unieron a una clase';

  @override
  String get notificationTypeAssignmentCreated => 'Nueva tarea';

  @override
  String get notificationTypeAssignmentDueSoon => 'Tarea por vencer';

  @override
  String get notificationTypeAiJobCompleted => 'Cuestionario IA listo';

  @override
  String get notificationTypeAiJobFailed => 'Error en cuestionario IA';

  @override
  String get notificationTypeMembershipExpiring => 'Membresía por vencer';

  @override
  String get notificationTypeMembershipExpired => 'Membresía vencida';

  @override
  String get legalSectionTitle => 'Legal';

  @override
  String get privacyPolicyLink => 'Política de privacidad';

  @override
  String get termsOfServiceLink => 'Términos de servicio';

  @override
  String get registerLegalDisclaimerPrefix => 'Al registrarte aceptas los ';

  @override
  String get registerLegalDisclaimerAnd => ' y la ';

  @override
  String get registerLegalDisclaimerSuffix => '.';

  @override
  String get deleteAccountTitle => 'Eliminar mi cuenta';

  @override
  String get deleteAccountSubtitle =>
      'Se eliminarán tus datos de forma permanente. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountConfirmHint => 'Escribe ELIMINAR para confirmar';

  @override
  String get deleteAccountConfirmWord => 'ELIMINAR';

  @override
  String get deleteAccountAction => 'Eliminar cuenta';

  @override
  String get deleteAccountSuccess => 'Tu cuenta ha sido eliminada.';

  @override
  String get deleteAccountCancel => 'Cancelar';

  @override
  String get parentalGateTitle => 'Verificación de adulto';

  @override
  String get parentalGateSubtitle => 'Para continuar, resuelve esta operación:';

  @override
  String get parentalGateAnswerLabel => 'Respuesta';

  @override
  String get parentalGateWrongAnswer =>
      'Respuesta incorrecta. Inténtalo de nuevo.';

  @override
  String get parentalGateConfirm => 'Confirmar';

  @override
  String get parentalGateCancel => 'Cancelar';

  @override
  String get ageScreenTitle => '¿Cuándo naciste?';

  @override
  String get ageScreenSubtitle =>
      'Usamos esta información para ofrecer una experiencia adecuada a tu edad.';

  @override
  String get ageScreenBirthDateLabel => 'Fecha de nacimiento';

  @override
  String get ageScreenContinue => 'Continuar';

  @override
  String get ageScreenMinorNotice =>
      'Como eres menor de edad, necesitarás el consentimiento de un padre, madre o tutor para crear una cuenta.';

  @override
  String get guardianEmailLabel => 'Correo del padre, madre o tutor';

  @override
  String get guardianEmailHint => 'tutor@ejemplo.com';

  @override
  String get parentalConsentPendingTitle => 'Esperando consentimiento parental';

  @override
  String parentalConsentPendingMessage(String email) {
    return 'Enviamos un correo a $email para que un adulto autorice tu cuenta.';
  }

  @override
  String get parentalConsentResend => 'Reenviar correo al tutor';

  @override
  String get correctBirthDateAction => 'Corregir fecha de nacimiento';

  @override
  String get correctBirthDateSubtitle => 'Si te equivocaste al indicar tu edad';

  @override
  String get correctBirthDateSuccess => 'Fecha de nacimiento actualizada';

  @override
  String get correctBirthDateLoginHint =>
      '¿Te equivocaste en tu fecha de nacimiento?';
}
