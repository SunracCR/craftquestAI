// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CraftQuest';

  @override
  String get homeWelcome => 'Welcome to CraftQuest';

  @override
  String homeWelcomeUser(String name) {
    return 'Hello, $name';
  }

  @override
  String homeRoleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get roleUnknown => 'no role';

  @override
  String get roleTeacherLabel => 'Teacher';

  @override
  String get roleStudentLabel => 'Student';

  @override
  String get roleInstitutionAdminLabel => 'Institution admin';

  @override
  String get roleContentAdminLabel => 'Content admin';

  @override
  String get roleSuperAdminLabel => 'Super admin';

  @override
  String get apiStatusLabel => 'API status';

  @override
  String get apiStatusLoading => 'Connecting...';

  @override
  String get apiStatusError => 'Could not connect to the API';

  @override
  String get retry => 'Retry';

  @override
  String get noInternetBannerTitle => 'No internet connection';

  @override
  String get noInternetBannerMessage =>
      'You can keep browsing, but data will not update until you are back online.';

  @override
  String get noInternetSnackBarMessage =>
      'You are offline. Check your connection and try again.';

  @override
  String get genericRequestErrorMessage =>
      'The request could not be completed. Please try again shortly.';

  @override
  String get errorHttpMethodNotAllowed =>
      'The server does not support this operation. Restart the API and try again.';

  @override
  String errorQuestionLimitReached(int max, String plan) {
    return 'You reached the limit of $max questions per quiz on your $plan plan.';
  }

  @override
  String errorQuizLimitReached(int max, String plan) {
    return 'You reached the limit of $max quizzes on your $plan plan.';
  }

  @override
  String get billingPlanFreeName => 'Free';

  @override
  String get billingPlanProName => 'Pro';

  @override
  String get billingPlanPremiumName => 'Premium';

  @override
  String get billingPlanTeacherName => 'Teacher';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle =>
      'Access your CraftQuest account for free — sign in or create one in seconds';

  @override
  String get loginAction => 'Sign in';

  @override
  String get loginRememberCredentials => 'Remember email and password';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerAction => 'Sign up';

  @override
  String get goToRegister => 'Don\'t have an account? Sign up';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get passwordMinLength => 'Minimum 8 characters';

  @override
  String get logoutAction => 'Sign out';

  @override
  String get navHomeLabel => 'Home';

  @override
  String get navProfileLabel => 'Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get selectAvatarTitle => 'Your avatar';

  @override
  String get profileChangeAvatarAction => 'Change avatar';

  @override
  String get profileEditNameAction => 'Edit name';

  @override
  String get profileNameUpdatedMessage => 'Name updated';

  @override
  String get profileNameInvalidMessage =>
      'Enter a name between 1 and 160 characters.';

  @override
  String get profileSaveAction => 'Save';

  @override
  String get profileAvatarPickerHint => 'Tap an icon to update your profile';

  @override
  String get avatarUpdatedMessage => 'Avatar updated';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageUpdatedMessage => 'Language updated';

  @override
  String get securitySectionTitle => 'Security';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordAction => 'Save password';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordChangedMessage => 'Password updated';

  @override
  String get myQuizzesAction => 'My quizzes';

  @override
  String get quizzesTitle => 'Quizzes';

  @override
  String get quizzesEmpty => 'You have no quizzes yet';

  @override
  String get quizzesLoadError => 'Could not load quizzes';

  @override
  String get createQuizAction => 'Create quiz';

  @override
  String get createQuizTitle => 'New quiz';

  @override
  String get createQuizNextStepTitle => 'Add questions to your quiz';

  @override
  String get createQuizNextStepSubtitle =>
      'Start by creating a question, importing from a file, or generating with AI.';

  @override
  String get createQuizAddQuestionsManually => 'Create questions manually';

  @override
  String get createQuizImportQuestions => 'Import questions';

  @override
  String get createQuizSkipQuestionsSetup => 'Do it later';

  @override
  String get quizTitleLabel => 'Title';

  @override
  String get quizTitleTapToEdit => 'Tap the title to edit';

  @override
  String get quizDescriptionLabel => 'Description (optional)';

  @override
  String quizListSubtitle(String status, int count) {
    return '$status · $count questions';
  }

  @override
  String get quizStatusDraft => 'Draft';

  @override
  String get quizStatusPublished => 'Published';

  @override
  String get quizDetailTitle => 'Quiz detail';

  @override
  String get quizDetailImportAiDraftAction => 'Import AI-generated questions';

  @override
  String quizDetailImportAiDraftBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI-generated questions ready to import',
      one: '1 AI-generated question ready to import',
    );
    return '$_temp0';
  }

  @override
  String get quizListPendingAiDraft => 'AI draft ready to import';

  @override
  String get addQuestionAction => 'Add question';

  @override
  String get viewQuizQuestionsAction => 'View questions';

  @override
  String get publishQuizAction => 'Publish';

  @override
  String get quizPublishedMessage => 'Quiz published';

  @override
  String get deleteQuizAction => 'Delete quiz';

  @override
  String get deleteQuizConfirmTitle => 'Delete quiz?';

  @override
  String deleteQuizConfirmMessage(String title) {
    return '\"$title\" and all its questions will be removed. This action cannot be undone.';
  }

  @override
  String get quizDeletedMessage => 'Quiz deleted';

  @override
  String get questionsEmpty => 'No questions yet';

  @override
  String get quizDetailQuestionsSection => 'Quiz questions';

  @override
  String quizQuestionsCount(int count) {
    return '$count questions';
  }

  @override
  String quizDetailOptionCount(int count) {
    return '$count options';
  }

  @override
  String quizDetailCorrectKeys(String keys) {
    return 'Correct answer: $keys';
  }

  @override
  String quizDetailCorrectKeysPlural(String keys) {
    return 'Correct answers: $keys';
  }

  @override
  String get questionTypeLabelSingleChoice => 'Single choice';

  @override
  String get questionTypeLabelMultipleChoice => 'Multiple choice';

  @override
  String get questionTypeLabelTrueFalse => 'True / False';

  @override
  String get questionTypeLabelImageChoice => 'Image options';

  @override
  String get questionTypeLabelImageBased => 'Image-based';

  @override
  String questionListIndexLabel(int index) {
    return 'Q$index';
  }

  @override
  String get editQuestionAction => 'Edit';

  @override
  String get deleteQuestionAction => 'Delete';

  @override
  String get editQuestionTitle => 'Edit question';

  @override
  String get deleteQuestionConfirmTitle => 'Delete question?';

  @override
  String get deleteQuestionConfirmMessage =>
      'This question will be removed from the quiz. This action cannot be undone.';

  @override
  String get questionDeletedMessage => 'Question deleted';

  @override
  String get questionSavedMessage => 'Question saved';

  @override
  String get addQuestionTitle => 'New question';

  @override
  String get questionTypeLabel => 'Question type';

  @override
  String get questionTextLabel => 'Question text';

  @override
  String get questionPointsLabel => 'Points';

  @override
  String get questionPointsHint =>
      'Score when answered correctly (this question only)';

  @override
  String questionPointsValue(String points) {
    return '$points pts';
  }

  @override
  String get questionInvalidPoints => 'Points must be greater than 0';

  @override
  String answerOptionLabel(String key) {
    return 'Option $key';
  }

  @override
  String get correctAnswerKeyLabel => 'Correct answer (key)';

  @override
  String get saveQuestionAction => 'Save question';

  @override
  String get trueLabel => 'True';

  @override
  String get falseLabel => 'False';

  @override
  String get minTwoOptions => 'Enter at least two options';

  @override
  String get questionImageLabel => 'Question image';

  @override
  String get correctAnswersLabel => 'Correct answers';

  @override
  String get selectCorrectAnswersHint => 'Select one or more correct options';

  @override
  String get imageChoiceHint => 'Attach an image to at least one answer option';

  @override
  String get imageBasedQuestionHint =>
      'Upload the image or diagram for this question';

  @override
  String get requireQuestionImage => 'Image-based questions require an image';

  @override
  String get requireOptionImage =>
      'Add at least one image to the answer options';

  @override
  String get selectAtLeastOneCorrect => 'Mark at least one correct answer';

  @override
  String correctIdsLabel(int count) {
    return '$count correct answer(s) by ID';
  }

  @override
  String get practiceOptionsTitle => 'Practice settings';

  @override
  String get practiceRandomizeQuestionsLabel => 'Shuffle question order';

  @override
  String get practiceRandomizeQuestionsHint =>
      'Questions appear in a random order each time you practice';

  @override
  String get practiceShowTimerLabel => 'Show elapsed time';

  @override
  String get practiceShowTimerHint =>
      'Displays a running clock while you answer the quiz';

  @override
  String practiceElapsedLabel(String elapsed) {
    return 'Time: $elapsed';
  }

  @override
  String get practiceDurationLabel => 'Time spent';

  @override
  String get practiceQuizAction => 'Practice';

  @override
  String get practiceSessionTitle => 'Practice session';

  @override
  String practiceProgressLabel(int answered, int total) {
    return '$answered of $total answered';
  }

  @override
  String practiceProgressCompletedLabel(int done, int total) {
    return '$done of $total completed';
  }

  @override
  String get practiceNavigateQuestionsLabel => 'Questions';

  @override
  String get practiceOpenQuestionMapAction => 'Map';

  @override
  String get practiceMapTitle => 'Question map';

  @override
  String get practiceMapFilterAll => 'All';

  @override
  String get practiceMapFilterPending => 'Pending';

  @override
  String get practiceMapFilterCompleted => 'Done';

  @override
  String get practiceMapEmptyFilter => 'No questions match this filter';

  @override
  String get practiceNavLegendAnswered => 'Answered';

  @override
  String get practiceNavLegendPending => 'Pending';

  @override
  String get practiceNavLegendCurrent => 'Current';

  @override
  String practiceQuestionNavTooltip(int number) {
    return 'Question $number';
  }

  @override
  String get practicePreviousQuestionAction => 'Previous';

  @override
  String get practiceQuestionAnsweredLabel => 'Already answered';

  @override
  String get practiceUpdateAnswerAction => 'Update answer';

  @override
  String get practiceAnswerEditHint =>
      'You can change your answer and tap Update answer';

  @override
  String get practiceSavingAnswerHint => 'Saving your answer…';

  @override
  String practiceQuestionCounter(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get practiceSelectAnswer => 'Select at least one answer';

  @override
  String get practiceSubmitAnswerAction => 'Submit answer';

  @override
  String get practiceNextQuestionAction => 'Next question';

  @override
  String get practiceFinishAction => 'Finish practice';

  @override
  String get practiceResumeTitle => 'Practice in progress';

  @override
  String practiceResumeMessage(int answered, int total) {
    return 'You have a saved practice with $answered of $total questions answered. What would you like to do?';
  }

  @override
  String get practiceContinueAction => 'Continue';

  @override
  String get practiceStartNewAction => 'Start over';

  @override
  String get practiceSaveAndExitAction => 'Save and exit';

  @override
  String get practiceInProgressChip => 'Practice in progress';

  @override
  String practiceInProgressSubtitle(int answered, int total) {
    return '$answered/$total answered';
  }

  @override
  String get practiceFinishEarlyAction => 'Finish now';

  @override
  String get practiceNoQuestions => 'This quiz has no questions';

  @override
  String get practiceResultTitle => 'Results';

  @override
  String practicePercentageLabel(double percentage) {
    return '$percentage%';
  }

  @override
  String practiceScoreLabel(double obtained, double possible) {
    return 'Score: $obtained / $possible';
  }

  @override
  String practiceCorrectLabel(int count) {
    return 'Correct: $count';
  }

  @override
  String practiceIncorrectLabel(int count) {
    return 'Incorrect: $count';
  }

  @override
  String get practiceViewResultsAction => 'View results';

  @override
  String get practiceReviewHiddenByAssignment =>
      'Your teacher configured this assignment to hide correct answers. You can only see your overall score.';

  @override
  String practiceReviewHiddenUntilDue(String date) {
    return 'Correct answers will be available after the due date ($date). For now you can only see your overall score.';
  }

  @override
  String get practiceReviewHiddenUntilDueNoDate =>
      'Correct answers will be available after the due date. For now you can only see your overall score.';

  @override
  String get practiceReviewHiddenTeacherOnly =>
      'Only your teacher can see the correct answers. You can check your overall score.';

  @override
  String get practiceBackHomeAction => 'Back to home';

  @override
  String get importQuestionsAction => 'Import questions';

  @override
  String get importQuestionsTitle => 'Import questions';

  @override
  String get importExcelAction => 'Import from Excel';

  @override
  String get excelImportTitle => 'Excel import';

  @override
  String get excelImportSubtitle =>
      'Upload a .xlsx file with your questions. You will review a preview before confirming.';

  @override
  String get excelImportColumnsHint =>
      'Columns: Question, Type (includes image_choice and image_based_question without image files), Option A–E, Correct answer (e.g. B or A|C), Points and Section (optional). Add images later in the app.';

  @override
  String get excelImportDownloadTemplate => 'Download Excel template';

  @override
  String get excelImportTemplateReady => 'Template ready to save or share';

  @override
  String get excelImportTemplateFailed => 'Could not download the template';

  @override
  String get excelImportDropHint => 'Drag your .xlsx file here';

  @override
  String get excelImportDropSubhint => 'Or choose a file from your device';

  @override
  String get excelImportPickFile => 'Choose file';

  @override
  String get excelImportUploadAction => 'Upload and review';

  @override
  String get excelImportOnlyXlsx => 'Only .xlsx files are supported';

  @override
  String get excelImportFileTooLarge => 'File exceeds the 5 MB limit';

  @override
  String get excelImportReadFailed => 'Could not read the selected file';

  @override
  String get excelImportSelectFileFirst => 'Select an Excel file first';

  @override
  String get excelImportColumnsTitle => 'Column format';

  @override
  String get excelImportTemplateSection => 'Step 1 · Template';

  @override
  String get excelImportUploadSection => 'Step 2 · Your file';

  @override
  String get excelImportFileReady => 'File ready to import';

  @override
  String get excelImportChangeFile => 'Change file';

  @override
  String get importImageMediaPending =>
      'Images are not imported from the file. You can add them later in the app when editing the question.';

  @override
  String get importImagePendingBadge => 'Image pending in app';

  @override
  String get importFormatLabel => 'Format';

  @override
  String get importFormatJson => 'CQIF JSON';

  @override
  String get importFormatTxt => 'CraftQuest TXT';

  @override
  String get importContentLabel => 'Content';

  @override
  String get importContentHint => 'Paste CQIF v2 JSON or CraftQuest TXT here';

  @override
  String get importContentRequired => 'Paste content to import';

  @override
  String get importProcessAction => 'Process import';

  @override
  String get importNoValidQuestions => 'No valid questions to import';

  @override
  String get importPreviewTitle => 'Preview';

  @override
  String importSummaryLabel(int valid, int total, int errors) {
    return '$valid valid of $total ($errors with errors)';
  }

  @override
  String importErrorLine(int row, String message) {
    return 'Row $row: $message';
  }

  @override
  String importQuestionTypeLabel(String type) {
    return 'Type: $type';
  }

  @override
  String importAnswerLine(String key, String text, String correct) {
    return '$key: $text$correct';
  }

  @override
  String get importConfirmAction => 'Confirm and import';

  @override
  String importConfirmSuccess(int count) {
    return '$count questions imported';
  }

  @override
  String importPlanLimitPreviewNotice(
    String plan,
    int max,
    int current,
    int importable,
    int total,
  ) {
    return 'Your $plan plan allows up to $max questions per quiz ($current already in this quiz). Only $importable of $total from the file will be imported.';
  }

  @override
  String importConfirmDisabledQuizFull(int current, int max) {
    return 'You cannot import more questions: this quiz already has $current and your plan allows up to $max per quiz.';
  }

  @override
  String importPlanLimitConfirmNotice(
    int imported,
    String plan,
    int max,
    int skipped,
  ) {
    return '$imported questions were imported. On the $plan plan the limit is $max per quiz; $skipped questions from the file were not added.';
  }

  @override
  String get teacherAttemptsAction => 'View attempts';

  @override
  String get teacherAttemptsTitle => 'Practice attempts';

  @override
  String get teacherAttemptsEmpty => 'No finished attempts yet';

  @override
  String get teacherAttemptsFilterLabel => 'Student';

  @override
  String get teacherAttemptsFilterAll => 'All students';

  @override
  String get teacherAttemptsFilterEmpty => 'No attempts for this student';

  @override
  String teacherAttemptsStudentsSummary(int students, int attempts) {
    return '$students students · $attempts attempts';
  }

  @override
  String get teacherAttemptsAttemptCountOne => '1 attempt';

  @override
  String teacherAttemptsAttemptCountMany(int count) {
    return '$count attempts';
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
  String get teacherReviewTitle => 'Attempt review';

  @override
  String teacherReviewStudentLabel(String name) {
    return 'Student: $name';
  }

  @override
  String teacherReviewScoreLabel(double obtained, double possible) {
    return 'Score: $obtained / $possible';
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
    return 'Quizzes: $quizzes/$maxQuizzes';
  }

  @override
  String get billingQuizzesUnlimited => 'Quizzes: Unlimited';

  @override
  String billingCreditsLabel(int credits) {
    return 'AI credits this month: $credits';
  }

  @override
  String get redeemCodeAction => 'Redeem code';

  @override
  String get redeemCodeTitle => 'Redeem access code';

  @override
  String get redeemCodeSubtitle =>
      'Enter the code shared by your teacher or classmate';

  @override
  String get redeemCodeLabel => 'Code';

  @override
  String get redeemCodeRequired => 'Enter a code';

  @override
  String redeemCodeSuccess(String title) {
    return 'Access granted to \"$title\"';
  }

  @override
  String redeemCodeAlreadyInShared(String title) {
    return 'You already have \"$title\" in Shared quizzes.';
  }

  @override
  String get accessibleQuizzesAction => 'Shared quizzes';

  @override
  String get accessibleQuizzesTitle => 'Shared quizzes';

  @override
  String get accessibleQuizzesEmpty => 'No shared quizzes yet. Redeem a code.';

  @override
  String accessibleQuizzesSharedBy(String name) {
    return 'Shared by $name';
  }

  @override
  String accessibleQuizzesGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quizzes',
      one: '1 quiz',
    );
    return '$_temp0';
  }

  @override
  String get accessibleQuizzesRemoveAction => 'Remove from shared';

  @override
  String get accessibleQuizzesRemoveConfirmTitle => 'Remove from shared?';

  @override
  String accessibleQuizzesRemoveConfirmMessage(String title) {
    return '\"$title\" will be removed from your list. The quiz is not deleted; you can redeem it again with the code if needed.';
  }

  @override
  String get accessibleQuizzesRemovedMessage => 'Quiz removed from shared list';

  @override
  String accessibleQuizzesSlotBanner(int current, int max) {
    return 'Shared quizzes: $current/$max';
  }

  @override
  String get accessibleQuizzesSlotFull =>
      'Free plan slot full. Remove one to redeem another code.';

  @override
  String errorSharedQuizSlotLimit(int max) {
    return 'Your Free plan allows $max shared quizzes. Remove one from Shared quizzes to redeem another.';
  }

  @override
  String get errorCannotRedeemOwnQuiz =>
      'You cannot redeem a code for a quiz you created. Open it from My quizzes.';

  @override
  String get shareCodeViewAction => 'View code';

  @override
  String get shareCodeExistingHint =>
      'This is the permanent code for this quiz.';

  @override
  String get myQuizAnalyticsAction => 'My analytics';

  @override
  String get myQuizAnalyticsTitle => 'My practice analytics';

  @override
  String get myPracticeAttemptsAction => 'My attempts';

  @override
  String get myPracticeAttemptsTitle => 'My practice attempts';

  @override
  String get myPracticeAttemptsEmpty =>
      'You have not completed any attempts on this quiz yet.';

  @override
  String get myPracticeReviewTitle => 'My attempt review';

  @override
  String myQuizAnalyticsAttemptsLabel(int count) {
    return '$count completed attempts';
  }

  @override
  String myQuizAnalyticsAverageLabel(double percentage) {
    return 'Average: $percentage%';
  }

  @override
  String myQuizAnalyticsBestLabel(double percentage) {
    return 'Best: $percentage%';
  }

  @override
  String get createShareCodeAction => 'Generate code';

  @override
  String get shareCodeTitle => 'Access code';

  @override
  String get shareCodeCreateTitle => 'Share quiz';

  @override
  String get shareCodeCreateTeacherSubtitle =>
      'Choose whether anyone can practice or only your class.';

  @override
  String get shareCodeCreateStudentSubtitle =>
      'A multi-use code will be created so many people can practice (without seeing others\' attempts).';

  @override
  String get shareCodeAudienceAnyone => 'Anyone';

  @override
  String get shareCodeAudienceAnyoneHint =>
      'With or without an account. Same code for everyone.';

  @override
  String get shareCodeAudienceGroup => 'My class only';

  @override
  String get shareCodeAudienceGroupHint =>
      'Only students in the class you select (account required).';

  @override
  String get shareCodeSelectClassLabel => 'Class';

  @override
  String shareCodeClassOption(String name, int count) {
    return '$name ($count students)';
  }

  @override
  String get shareCodeNoClasses =>
      'You have no classes yet. Create a class to share with your group only.';

  @override
  String get shareCodeGroupRequired =>
      'Select a class to share with your group.';

  @override
  String get shareCodeResultOpenHint =>
      'Valid for many people. Also works in Practice with code without an account.';

  @override
  String get shareCodeResultGroupHint => 'Class members only, with an account.';

  @override
  String get shareCodeCopyAction => 'Copy';

  @override
  String get shareCodeCopied => 'Code copied';

  @override
  String get shareCodeCloseAction => 'Close';

  @override
  String get quizInviteTitle => 'Invite people';

  @override
  String get quizInviteSubtitle =>
      'They must have a CraftQuest account. The quiz appears in Shared quizzes (no code needed).';

  @override
  String get quizInviteEmailsLabel => 'Emails';

  @override
  String get quizInviteEmailsHint => 'one@email.com, another@email.com';

  @override
  String get quizInviteAction => 'Invite';

  @override
  String get quizInviteEmailsRequired => 'Enter at least one valid email.';

  @override
  String quizInviteSuccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people invited',
      one: '1 person invited',
    );
    return '$_temp0';
  }

  @override
  String quizInviteOutcomeInvited(String name) {
    return '$name: invited';
  }

  @override
  String quizInviteOutcomeAlreadyHadAccess(String name) {
    return '$name: already had access';
  }

  @override
  String quizInviteOutcomeNotFound(String email) {
    return '$email: no account with this email';
  }

  @override
  String quizInviteOutcomeInvalidEmail(String email) {
    return '$email: invalid email';
  }

  @override
  String quizInviteOutcomeSlotLimit(String name) {
    return '$name: Free plan shared slot limit';
  }

  @override
  String get quizInviteOutcomeSelf => 'You cannot invite yourself';

  @override
  String get errorDirectInviteNotAllowed =>
      'Direct invitations require a Pro or Teacher plan.';

  @override
  String get errorActivePracticeSession =>
      'You have a practice in progress. Continue or start over.';

  @override
  String get aiNormalizeAction => 'Normalize with AI';

  @override
  String get aiImproveImportAction => 'Improve with AI';

  @override
  String get aiNormalizeSuccess => 'AI normalization completed';

  @override
  String get quizAnalyticsAction => 'Analytics';

  @override
  String get quizAnalyticsTitle => 'Quiz analytics';

  @override
  String quizAnalyticsSessionsLabel(int count) {
    return 'Finished attempts: $count';
  }

  @override
  String quizAnalyticsQuestionStats(int attempts, int correct, int incorrect) {
    return '$attempts attempts · $correct correct · $incorrect incorrect';
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
  String get attachImageAction => 'Attach image';

  @override
  String get removeImageAction => 'Remove image';

  @override
  String get viewFullImageAction => 'View full image';

  @override
  String get closeAction => 'Close';

  @override
  String get imageLoadError => 'Could not load image';

  @override
  String get upgradePlanAction => 'Upgrade plan';

  @override
  String get upgradePlanTitle => 'Upgrade plan';

  @override
  String get upgradePlanSubtitle =>
      'Compare plans and pick the one that fits you best.';

  @override
  String get upgradePlanAlreadyHighest =>
      'You already have the highest available plan. No further upgrades right now.';

  @override
  String get upgradeProHighlightQuizzes =>
      'Unlimited quizzes (your current plan: max. 5)';

  @override
  String get upgradeProHighlightQuestions =>
      'No question limit per quiz (your current plan: 65)';

  @override
  String get upgradeProHighlightAiCredits =>
      '150 AI credits per month (your current plan: 20)';

  @override
  String get upgradeProHighlightShared =>
      'Unlimited shared quizzes when redeeming or inviting';

  @override
  String get upgradeProHighlightDirectInvite =>
      'Invite specific people by email';

  @override
  String get upgradeTeacherHighlightIncludesPro => 'Everything in Pro';

  @override
  String get upgradeTeacherHighlightAiCredits =>
      '360 AI credits per month for more generations';

  @override
  String get upgradeTeacherHighlightClasses => 'Classes and student groups';

  @override
  String get upgradeTeacherHighlightAssignments =>
      'Assignments with due dates, attempts, and review';

  @override
  String get upgradeTeacherHighlightGroupShare =>
      'Share codes for your class only';

  @override
  String get upgradeTeacherHighlightTracking =>
      'Track attempts and results per student';

  @override
  String get buyWithStoreAction => 'Buy in store';

  @override
  String get buyWithPayPalAction => 'Pay with PayPal';

  @override
  String get paypalWebHint =>
      'On the web, PayPal is the recommended payment method.';

  @override
  String get paypalAwaitingCapture =>
      'Complete payment in PayPal, then capture the order.';

  @override
  String upgradeSuccess(String plan) {
    return 'Plan activated: $plan';
  }

  @override
  String get storeProductNotConfigured => 'Store product is not configured';

  @override
  String storeProductNotFound(String id) {
    return 'Product not found: $id';
  }

  @override
  String get purchaseFailed => 'Purchase was not completed';

  @override
  String get purchaseVerificationFailed =>
      'We couldn\'t verify your purchase. Please try again in a moment.';

  @override
  String get contactSales => 'Contact sales';

  @override
  String get aiGenerationHubTitle => 'Generate with AI';

  @override
  String get aiGenerationHubSubtitle =>
      'Upload PDF or Word with selectable text and get a reviewable quiz in minutes.';

  @override
  String get aiGenerationHubAction => 'Create from material';

  @override
  String get aiGenerationLibraryTitle => 'Materials library';

  @override
  String aiGenerationLibraryRetentionHint(int days) {
    return 'Materials are removed automatically after $days days. You can delete them sooner using the trash icon.';
  }

  @override
  String aiGenerationLibraryExpiresOn(String date) {
    return 'Auto-delete: $date';
  }

  @override
  String aiGenerationLibraryMaterialCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count materials',
      one: '1 material',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerationLibraryStatusReady => 'Ready';

  @override
  String get aiGenerationLibraryStatusProcessing => 'Processing';

  @override
  String get aiGenerationLibraryStatusFailed => 'Failed';

  @override
  String get aiGenerationLibraryStatusPending => 'Pending';

  @override
  String aiGenerationLibraryUploaded(String date) {
    return 'Uploaded $date';
  }

  @override
  String aiGenerationLibraryExpiresInDays(int days) {
    return 'Auto-deletes in $days days';
  }

  @override
  String get aiGenerationLibraryNeedsReview => 'Review text';

  @override
  String get aiGenerationLibraryEmpty => 'You have no saved materials yet.';

  @override
  String get aiGenerationLibraryEmptySubtitle =>
      'PDF and Word files you upload for AI generation will appear here.';

  @override
  String get aiGenerationLibraryAction => 'View library';

  @override
  String get deleteStudyMaterialConfirmTitle => 'Delete material';

  @override
  String deleteStudyMaterialConfirmMessage(String title) {
    return '\"$title\" and its extracted text will be deleted. The generated quiz will be kept. This cannot be undone.';
  }

  @override
  String get deleteStudyMaterialAction => 'Delete';

  @override
  String get studyMaterialDeletedMessage => 'Material deleted';

  @override
  String get aiGenerationUploadTitle => 'Upload material';

  @override
  String get aiGenerationUploadSubtitle =>
      'Upload a PDF or Word file with copyable text. You will choose the page scope before generating the quiz.';

  @override
  String get aiGenerationUploadHeroDrop => 'Drag your PDF or Word file here';

  @override
  String get aiGenerationUploadHeroPick => 'or choose a file from your device';

  @override
  String get aiGenerationUploadFormatGuideTitle => 'Format tips and limits';

  @override
  String get aiGenerationUploadHint =>
      'PDF or DOCX with selectable text, not scanned images (max 25 MB)';

  @override
  String aiGenerationUploadLimitsHint(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'Up to $maxPagesPerFile pages per file · up to $maxPagesPerGeneration pages per generation';
  }

  @override
  String aiGenerationUploadLimitsSteps(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'If your document is longer, split it into several files (each with $maxPagesPerFile pages or fewer) or export only the chapter you need. You can then generate quizzes in chunks of up to $maxPagesPerGeneration pages.';
  }

  @override
  String errorMaterialPageLimitGuidance(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'What you can do: split the PDF or Word into parts of $maxPagesPerFile pages or fewer (by chapter or section) and upload them separately. For each file, generate the quiz using up to $maxPagesPerGeneration pages at a time.';
  }

  @override
  String get aiGenerationUploadAnotherFileAction => 'Upload another file';

  @override
  String get aiGenerationDropHint => 'You can also drag files here';

  @override
  String get aiGenerationUploadAction => 'Upload and analyze';

  @override
  String get aiGenerationUploadFileReady => 'File ready to upload';

  @override
  String get aiGenerationUploadChangeFile => 'Change file';

  @override
  String get aiGenerationUploadRemoveFile => 'Remove';

  @override
  String get aiGenerationProcessing => 'Analyzing document…';

  @override
  String get aiGenerationNeedsOcr =>
      'Little text detected. Use a PDF or Word with selectable text, or review and paste the content.';

  @override
  String get aiGenerationReviewTextTitle => 'Review text';

  @override
  String get aiGenerationReviewTextHint =>
      'This document has little extractable text. Fix what was detected or paste content with selectable text.';

  @override
  String get aiGenerationReviewTextSave => 'Save and continue';

  @override
  String get aiGenerationReviewTextAction => 'Review text';

  @override
  String get aiGenerationOutlineTitle => 'Material scope';

  @override
  String aiGenerationPageRange(int from, int to) {
    return 'Pages $from–$to';
  }

  @override
  String aiGenerationPageRangeOfTotal(int from, int to, int total) {
    return 'Pages $from–$to of $total';
  }

  @override
  String get aiGenerationPageRangeHelp =>
      'Choose which pages from the document will be used to generate the quiz. Drag each end of the slider to narrow the range.';

  @override
  String aiGenerationPageRangeSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages in this range',
      one: '1 page in this range',
    );
    return '$_temp0';
  }

  @override
  String aiGenerationPageRangeOverLimit(int max) {
    return 'Maximum $max pages per generation. Narrow the selected range.';
  }

  @override
  String aiGenerationWordsInScopePurpose(int words) {
    return 'The AI will generate questions from approximately $words words in that range.';
  }

  @override
  String get aiGenerationTopicHint => 'Optional focus (topic or section)';

  @override
  String aiGenerationWordsInScope(int words) {
    return '$words words in scope';
  }

  @override
  String get aiGenerationParamsTitle => 'Generation settings';

  @override
  String aiGenerationMaterialLanguageNotice(String language) {
    return 'Questions will be generated in $language based on the material\'s language.';
  }

  @override
  String get aiGenerationPresetQuick => 'Quick review';

  @override
  String get aiGenerationPresetStandard => 'Standard exam';

  @override
  String get aiGenerationPresetDeep => 'Deep practice';

  @override
  String get aiGenerationQuestionCount => 'Number of questions';

  @override
  String aiGenerationQuestionCountOfMax(int count, int max) {
    return '$count of $max';
  }

  @override
  String get aiGenerationQuestionTypes => 'Question types';

  @override
  String get aiGenerationTypeSingleChoice => 'Single choice';

  @override
  String get aiGenerationTypeMultipleChoice => 'Multiple choice';

  @override
  String get aiGenerationTypeTrueFalse => 'True / false';

  @override
  String get aiGenerationDifficulty => 'Difficulty';

  @override
  String get aiGenerationDifficultyEasy => 'Easy';

  @override
  String get aiGenerationDifficultyMedium => 'Medium';

  @override
  String get aiGenerationDifficultyHard => 'Hard';

  @override
  String get aiGenerationDifficultyMixed => 'Mixed';

  @override
  String aiGenerationCreditsCost(int credits, int available) {
    return 'Uses $credits AI credits ($available available)';
  }

  @override
  String get aiGenerationStartAction => 'Generate quiz';

  @override
  String get aiGenerationProgressTitle => 'Generating quiz';

  @override
  String get aiGenerationProgressSubtitle =>
      'AI is building questions from your material…';

  @override
  String get aiGenerationProgressDeferredRetry =>
      'The AI service is busy. We will retry automatically shortly.';

  @override
  String aiGenerationProgressDeferredRetryMinutes(int minutes) {
    return 'Automatic retry in about $minutes min. You can keep this screen open.';
  }

  @override
  String aiGenerationProgressAutoRetry(int attempt) {
    return 'Automatic retry $attempt in progress…';
  }

  @override
  String get aiGenerationCreditsNotConsumed => 'No AI credits were deducted.';

  @override
  String get aiGenerationRetryAction => 'Retry generation';

  @override
  String get aiGenerationProgressTakingLong =>
      'Still running (this can take several minutes). If the API was restarted, retry generation.';

  @override
  String get aiGenerationProgressStuck =>
      'Generation appears stuck on the server.';

  @override
  String get aiGenerationProgressStuckDetail =>
      'This job has been processing too long without finishing. Go back and start again; credits were not consumed if it did not complete.';

  @override
  String get aiGenerationStuckGoBackAction => 'Go back and try again';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Sign in again and try once more.';

  @override
  String get aiGenerationFailed => 'Could not generate the quiz';

  @override
  String get errorGenerationJobNotRetryable =>
      'This generation job cannot be retried right now.';

  @override
  String get errorGuestNotAllowed =>
      'This code requires a registered account. Create a free account to continue.';

  @override
  String errorGroupAccessDenied(String className) {
    return 'This code is only for members of the class \"$className\".';
  }

  @override
  String get errorGroupAccessDeniedGeneric =>
      'This code is only for members of the teacher\'s class.';

  @override
  String get errorAiGenerationInvalidOutput =>
      'The AI returned an invalid quiz format. Tap Retry generation; no credits were deducted.';

  @override
  String get aiGenerationFromQuizAction => 'Generate with AI from material';

  @override
  String get importAiGeneratedBadge => 'AI generated';

  @override
  String get errorAiCreditsInsufficient =>
      'Not enough AI credits for this generation.';

  @override
  String get errorMaterialNeedsOcr =>
      'Not enough extractable text. Use PDF or Word with selectable text, or review and paste the content.';

  @override
  String get errorMaterialNotSelectableText =>
      'This file looks scanned or has no selectable text.';

  @override
  String get errorMaterialNotSelectableTextGuidance =>
      'Recommendations:\n• Open the file and check you can select and copy paragraphs (not just zoom).\n• If it is a scan: in Word, File → Open the PDF and let it recognize text; review and save as DOCX.\n• Alternative: external OCR (Adobe, Google Drive), paste text into Word, upload as DOCX.\n• Export from Word or Google Docs; avoid PDFs made only from photos or print-to-image.\n• Upload DOCX or a PDF exported from Word with selectable text.';

  @override
  String get errorMaterialNeedsOcrGuidance =>
      'Recommendations:\n• Use a PDF or DOCX where you can select and copy text.\n• If the source is scanned, convert it to Word with text (see OCR steps above) and upload DOCX.\n• You can also paste content into Word, save as DOCX, and upload that file.';

  @override
  String get errorMaterialTooLargeGuidance =>
      'Recommendations:\n• The limit is 25 MB per file.\n• Compress embedded images in Word or export only the chapter you need.\n• Split the document into smaller files if it is still too large.';

  @override
  String get aiGenerationUploadRecommendationsTitle => 'Recommendations';

  @override
  String get aiGenerationUploadSelectableTextHint =>
      'The PDF or Word must allow selecting and copying text. Scanned documents are not supported.';

  @override
  String get errorMaterialTooLarge =>
      'File exceeds the maximum allowed upload size.';

  @override
  String errorMaterialPageLimitExceeded(int maxPages) {
    return 'The document exceeds the maximum of $maxPages pages per file.';
  }

  @override
  String errorGenerationPageRangeExceeded(int maxPages) {
    return 'You can only generate from up to $maxPages pages at a time.';
  }

  @override
  String get errorGenerationScopeEmpty => 'No text in the selected page range.';

  @override
  String get errorGenerationAlreadyInProgress =>
      'A generation is already in progress for this material.';

  @override
  String get errorAiNotConfigured =>
      'AI generation is not configured on the server.';

  @override
  String get errorAiGeminiQuotaExhausted =>
      'Gemini credits are exhausted. Add billing credits in Google AI Studio (ai.google.dev) and try again.';

  @override
  String get errorAiGeminiModelUnavailable =>
      'The configured Gemini model is no longer available. Set Ai:GeminiModel to gemini-2.5-flash and restart the API.';

  @override
  String get errorAiGeminiOverloaded =>
      'Gemini is under heavy load right now. Wait a few minutes and try generating again.';

  @override
  String get aiActivityTitle => 'AI activity';

  @override
  String get aiActivityAction => 'AI activity';

  @override
  String get aiActivityEmpty =>
      'No recent generations. When you generate a quiz, jobs appear here even if you close the app.';

  @override
  String get aiActivityStatusDraftReady => 'Draft ready';

  @override
  String get aiActivityStatusFailed => 'Failed';

  @override
  String get aiActivityStatusCompleted => 'Completed';

  @override
  String get aiActivityReviewDraft => 'Tap to review and import the draft';

  @override
  String get aiActivityViewProgress => 'Tap to view progress';

  @override
  String get aiActivityTapForDetails => 'Tap for details';

  @override
  String get aiActivityUnknownMaterial => 'Material';

  @override
  String aiActivityPagesRange(int from, int to) {
    return 'Pages $from–$to';
  }

  @override
  String get aiLibraryStatusDraftReady => 'Draft ready';

  @override
  String get aiGenerationBackgroundSnack =>
      'Generation runs in the background. You can leave; resume it in AI activity or the library.';

  @override
  String get aiGenerationResumedSnack =>
      'A generation was already in progress for this material. Showing its progress.';

  @override
  String aiGenerationProgressPercent(int percent) {
    return '$percent% complete';
  }

  @override
  String get aiJobStageQueued => 'Queued';

  @override
  String get aiJobStagePreparing => 'Preparing material';

  @override
  String get aiJobStageOutlining => 'Planning topics';

  @override
  String get aiJobStageGenerating => 'Generating questions';

  @override
  String get aiJobStageMerging => 'Merging results';

  @override
  String get aiJobStageValidating => 'Validating questions';

  @override
  String get aiJobStageImporting => 'Preparing draft';

  @override
  String get aiJobStageCompleted => 'Completed';

  @override
  String get aiJobStageFailed => 'Failed';

  @override
  String get aiActivityClearHistoryAction => 'Clear history';

  @override
  String get aiActivityClearHistoryTitle => 'Clear history?';

  @override
  String get aiActivityClearHistoryMessage =>
      'Completed runs and old failures will be removed. Jobs in progress and drafts waiting for review are kept.';

  @override
  String aiActivityClearHistoryDone(int count) {
    return 'Removed $count items from history.';
  }

  @override
  String get aiActivityClearHistoryNothing => 'There was nothing to clear.';

  @override
  String get cancel => 'Cancel';

  @override
  String get practiceStatusInProgress => 'In progress';

  @override
  String get guestCodeTitle => 'Practice with code';

  @override
  String get guestCodeSubtitle =>
      'Enter the code shared by your teacher to practice without creating an account.';

  @override
  String get guestCodeAction => 'Start';

  @override
  String get guestCodeLabel => 'Code';

  @override
  String get guestCodeRequired => 'Enter a code';

  @override
  String get guestCodePasteTooltip => 'Paste';

  @override
  String get guestEphemeralNotice =>
      'This is a temporary session. Everything is deleted when you leave.';

  @override
  String get guestPracticeWithCodeAction => 'Practice with code';

  @override
  String get guestShellFreeBadge => 'Free';

  @override
  String get guestShellHeroHint =>
      'Practice now. Sign up free to save progress and unlock more.';

  @override
  String get guestShellSessionBadge => 'No account';

  @override
  String get guestPracticeOptions => 'Practice options';

  @override
  String get guestStartPracticeAction => 'Practice';

  @override
  String get guestAttemptsTitle => 'This visit';

  @override
  String get guestAttemptsEmpty =>
      'You haven\'t practiced yet in this visit. Start now!';

  @override
  String get guestLeaveAction => 'Leave';

  @override
  String get guestLeaveConfirmTitle => 'Leave this visit?';

  @override
  String get guestLeaveConfirmMessage =>
      'All attempts from this visit will be deleted. This cannot be undone.';

  @override
  String get guestRegisterAction => 'Create free account';

  @override
  String get guestTryAgainAction => 'Try again';

  @override
  String get guestResultStatCorrect => 'Correct';

  @override
  String get guestResultStatIncorrect => 'Wrong';

  @override
  String get guestViewResultsAction => 'View results';

  @override
  String get guestTimerRegisteredOnlyHint =>
      'Registered users only. Creating an account is free.';

  @override
  String get guestRegisterCtaTitle => 'Want to save your results?';

  @override
  String get guestRegisterBenefit1 => 'Permanent history of all your attempts';

  @override
  String get guestRegisterBenefit2 => 'Create your own quizzes with AI';

  @override
  String get guestRegisterBenefit3 =>
      'Free plan: 5 quizzes and 20 AI credits, no cost';

  @override
  String get guestExitPracticeTitle => 'Exit practice?';

  @override
  String get guestExitPracticeMessage =>
      'Your progress is saved and you can resume it when you come back.';

  @override
  String get guestExitPracticeConfirm => 'Exit';

  @override
  String get teacherTabLabel => 'Teacher';

  @override
  String get teacherDashboardTitle => 'Dashboard';

  @override
  String get teacherDashboardTotalStudents => 'Students';

  @override
  String get teacherDashboardActiveClasses => 'Classes';

  @override
  String get teacherDashboardPublishedQuizzes => 'Quizzes';

  @override
  String get teacherDashboardSessionsThisWeek => 'This week';

  @override
  String get teacherDashboardActivityFeedTitle => 'Recent Activity';

  @override
  String get teacherDashboardInsightsTitle => 'Insights';

  @override
  String get teacherDashboardEmptyFeed =>
      'No activity yet. Share a quiz with your students!';

  @override
  String get teacherDashboardEmptyInsights =>
      'No insights yet. Come back when your students start practicing.';

  @override
  String get teacherDashboardInventoryStudents => 'Students';

  @override
  String get teacherDashboardInventoryClasses => 'Classes';

  @override
  String get teacherDashboardInventoryQuizzes => 'Quizzes';

  @override
  String get teacherDashboardUrgentTitle => 'Needs attention';

  @override
  String get teacherDashboardUrgentEmpty => 'No urgent tasks right now.';

  @override
  String teacherDashboardUrgentDueLabel(String date) {
    return 'Due $date';
  }

  @override
  String teacherDashboardUrgentPendingLabel(int pending, int total) {
    return '$pending of $total not submitted';
  }

  @override
  String teacherDashboardActiveStudentsWeek(int count) {
    return 'Active students this week: $count';
  }

  @override
  String teacherInsightHighError(String errorRate, String questionText) {
    return 'A question has $errorRate% errors: $questionText';
  }

  @override
  String teacherInsightMostActive(
    int sessionCount,
    int studentCount,
    String quizTitle,
  ) {
    return '$sessionCount practices this week ($studentCount students) · $quizTitle';
  }

  @override
  String get teacherAssignmentAnalyticsTitle => 'Assignment analytics';

  @override
  String get teacherAssignmentAnalyticsAction => 'View analytics';

  @override
  String get teacherAssignmentAnalyticsRosterTitle => 'Students';

  @override
  String get teacherAssignmentAnalyticsHardQuestionsTitle => 'Hard questions';

  @override
  String get teacherAssignmentAnalyticsDistributionTitle =>
      'Score distribution';

  @override
  String get teacherAssignmentAnalyticsNoAttempt => 'No attempt';

  @override
  String teacherAssignmentAnalyticsCompletionLabel(int completed, int total) {
    return 'Submitted $completed of $total';
  }

  @override
  String teacherAssignmentAnalyticsBestLabel(String score) {
    return 'Best: $score%';
  }

  @override
  String teacherAssignmentAnalyticsLastLabel(String score) {
    return 'Last: $score%';
  }

  @override
  String teacherAssignmentAnalyticsErrorRateLabel(String rate, int attempts) {
    return '$rate% error · $attempts attempts';
  }

  @override
  String get teacherClassAnalyticsActiveStudentsLabel =>
      'Students who practiced';

  @override
  String get teacherClassAnalyticsAverageLabel => 'Average';

  @override
  String get teacherClassAnalyticsAssignmentsTitle => 'Assignments';

  @override
  String get studentAssignmentProgressTitle => 'My progress';

  @override
  String get studentAssignmentProgressAction => 'My progress';

  @override
  String get studentAssignmentProgressMyStats => 'My results';

  @override
  String get studentAssignmentProgressEvolutionTitle => 'My progress over time';

  @override
  String get studentAssignmentProgressHardQuestionsTitle =>
      'Questions to review';

  @override
  String studentAssignmentProgressTrendUp(String points) {
    return 'You improved $points pts since your first attempt';
  }

  @override
  String studentAssignmentProgressAttemptLabel(int number, String percent) {
    return 'Attempt $number: $percent%';
  }

  @override
  String get practiceResultRepracticeTitle => 'Questions to review';

  @override
  String practiceResultTrendUp(String points) {
    return '+$points pts vs previous attempt';
  }

  @override
  String practiceResultTrendDown(String points) {
    return '$points pts vs previous attempt';
  }

  @override
  String get practiceResultReviewQuestionAction => 'View in review';

  @override
  String get analyticsPersonalOnlyLabel => 'Your attempts only';

  @override
  String get analyticsOnlyDifficultFilter => 'Difficult only';

  @override
  String analyticsPersonalAccuracyLabel(String percent) {
    return '$percent% correct on your attempts';
  }

  @override
  String scoreDistributionRange(int min, int max) {
    return '$min–$max%';
  }

  @override
  String get teacherClassesTitle => 'My Classes';

  @override
  String get teacherClassesEmpty => 'You haven\'t created any class yet.';

  @override
  String get teacherClassCreateTitle => 'New Class';

  @override
  String get teacherClassNameLabel => 'Class name';

  @override
  String get teacherClassNameHint => 'e.g. Algebra II — Period 3';

  @override
  String get teacherClassDescriptionLabel => 'Description (optional)';

  @override
  String get teacherClassDescriptionHint => 'Short description of this class';

  @override
  String get teacherClassSaveAction => 'Save';

  @override
  String get teacherClassCreateAction => 'Create class';

  @override
  String get teacherClassArchiveAction => 'Archive class';

  @override
  String get teacherClassArchiveConfirmTitle => 'Archive class?';

  @override
  String get teacherClassArchiveConfirmMessage =>
      'Students will no longer be able to see assignments from this class.';

  @override
  String get teacherClassArchiveConfirmAction => 'Archive';

  @override
  String get teacherClassMembersTab => 'Members';

  @override
  String get teacherClassAssignmentsTab => 'Assignments';

  @override
  String get teacherClassAnalyticsTab => 'Analytics';

  @override
  String get teacherClassActiveMembersLabel => 'active members';

  @override
  String get teacherClassPendingMembersLabel => 'pending approval';

  @override
  String get teacherClassAddMemberTitle => 'Add student';

  @override
  String get teacherClassAddMemberEmailLabel => 'Student email';

  @override
  String get teacherClassAddMemberEmailHint => 'student@email.com';

  @override
  String get teacherClassAddMemberAction => 'Add';

  @override
  String get teacherClassInvalidEmailError => 'Enter a valid email address.';

  @override
  String get teacherClassMemberNotFoundError =>
      'No registered student was found with that email.';

  @override
  String get teacherClassMemberAlreadyExistsError =>
      'That student is already in this class.';

  @override
  String get teacherClassRemoveMemberAction => 'Remove';

  @override
  String get teacherClassRemoveMemberConfirmTitle => 'Remove student?';

  @override
  String get teacherClassRemoveMemberConfirmMessage =>
      'This student will lose access to all assignments in this class.';

  @override
  String get teacherClassApproveAction => 'Approve';

  @override
  String get teacherClassMembersEmpty => 'No students in this class yet.';

  @override
  String get teacherClassPendingApprovalsTitle => 'Pending approval';

  @override
  String get teacherAssignmentCreateTitle => 'New Assignment';

  @override
  String get teacherAssignmentTitleLabel => 'Title';

  @override
  String get teacherAssignmentTitleHint => 'e.g. Chapter 5 — Practice Quiz';

  @override
  String get teacherAssignmentInstructionsLabel => 'Instructions (optional)';

  @override
  String get teacherAssignmentQuizLabel => 'Select quiz';

  @override
  String get teacherAssignmentStartsAtLabel => 'Opens on';

  @override
  String get teacherAssignmentDueAtLabel => 'Due date';

  @override
  String get teacherAssignmentMaxAttemptsLabel => 'Max attempts';

  @override
  String get teacherAssignmentMaxAttemptsHint => 'Leave blank for unlimited';

  @override
  String get teacherAssignmentShowAnswersLabel => 'Show correct answers';

  @override
  String get teacherAssignmentShowAnswersNever => 'Never';

  @override
  String get teacherAssignmentShowAnswersAfterAttempt => 'After each attempt';

  @override
  String get teacherAssignmentShowAnswersAfterDue => 'After due date';

  @override
  String get teacherAssignmentShowAnswersTeacherOnly => 'Teacher only';

  @override
  String get teacherAssignmentCreateAction => 'Create assignment';

  @override
  String get teacherAssignmentEditTitle => 'Edit assignment';

  @override
  String get teacherAssignmentEditAction => 'Edit';

  @override
  String get teacherAssignmentSaveAction => 'Save changes';

  @override
  String get teacherAssignmentTitleRequired => 'Title is required';

  @override
  String get teacherAssignmentQuizSelectHint => 'Select quiz';

  @override
  String get teacherAssignmentQuizRequiredError => 'Select a quiz';

  @override
  String get teacherAssignmentQuizLockedHint =>
      'The quiz cannot be changed after the assignment is created.';

  @override
  String get teacherAssignmentMaxAttemptsInvalidError =>
      'Enter a valid number of attempts';

  @override
  String get teacherAssignmentNotEditableError =>
      'Only active assignments can be edited.';

  @override
  String get teacherAssignmentMaxAttemptsBelowExistingError =>
      'Max attempts cannot be lower than attempts students have already used.';

  @override
  String get teacherAssignmentInvalidDateRangeError =>
      'Due date cannot be before the start date.';

  @override
  String get teacherAssignmentCloseAction => 'Close assignment';

  @override
  String get teacherAssignmentArchiveAction => 'Archive';

  @override
  String get teacherAssignmentCloseConfirmTitle => 'Close assignment?';

  @override
  String get teacherAssignmentCloseConfirmMessage =>
      'Students will no longer be able to submit new attempts.';

  @override
  String get teacherAssignmentCompletionTitle => 'Completion';

  @override
  String get teacherAssignmentAttemptsTitle => 'Attempts';

  @override
  String get teacherAssignmentCompletedLabel => 'completed';

  @override
  String get teacherAssignmentPendingLabel => 'not submitted';

  @override
  String get teacherAssignmentBestScoreLabel => 'Best';

  @override
  String get teacherAssignmentAttemptsLabel => 'attempts';

  @override
  String get teacherAssignmentDueLabel => 'Due';

  @override
  String get teacherAssignmentNoDueDate => 'No due date';

  @override
  String get teacherAssignmentEmpty => 'No assignments yet.';

  @override
  String get teacherAssignmentFormSubtitle =>
      'Set dates, attempts, and when answers are revealed.';

  @override
  String get teacherAssignmentSectionDetails => 'Details';

  @override
  String get teacherAssignmentSectionQuiz => 'Quiz';

  @override
  String get teacherAssignmentSectionSchedule => 'Schedule';

  @override
  String get teacherAssignmentSectionRules => 'Rules';

  @override
  String get teacherAssignmentCreateQuizCtaSubtitle =>
      'Create it here and select it instantly';

  @override
  String get teacherAssignmentSelectQuizAction => 'Choose from my quizzes';

  @override
  String get teacherAssignmentChangeQuizAction => 'Change';

  @override
  String get teacherAssignmentQuizDraftWarning =>
      'This quiz is a draft. Publish it so students can see the assignment.';

  @override
  String get teacherAssignmentNoQuizzesHint =>
      'You don\'t have any quizzes yet. Create one to continue.';

  @override
  String get teacherAssignmentPickDatePlaceholder => 'Not set';

  @override
  String get teacherAssignmentDraftContinued =>
      'Continue setting up your assignment. The new quiz is already selected.';

  @override
  String get teacherAnalyticsAvgScoreLabel => 'Avg. score';

  @override
  String get teacherAnalyticsTotalSessionsLabel => 'Total sessions';

  @override
  String get teacherAnalyticsCompletionRateLabel => 'Completion';

  @override
  String get teacherUpgradeHeroTitle => 'Turn your quizzes into a classroom';

  @override
  String get teacherUpgradeHeroSubtitle =>
      'Everything you need to teach, assign, and track — all in one place.';

  @override
  String get teacherUpgradePriceLabel => '/ month';

  @override
  String get teacherUpgradePopularBadge => 'Most popular for educators';

  @override
  String get teacherUpgradePillar1Title => 'Organized classes';

  @override
  String get teacherUpgradePillar1Body =>
      'Create groups, invite students by email and manage who has access.';

  @override
  String get teacherUpgradePillar2Title => 'Smart assignments';

  @override
  String get teacherUpgradePillar2Body =>
      'Set deadlines, limit attempts and control when answers are revealed.';

  @override
  String get teacherUpgradePillar3Title => 'Activity Pulse';

  @override
  String get teacherUpgradePillar3Body =>
      'Live feed of student activity, auto-insights and per-class analytics.';

  @override
  String get teacherUpgradeCta => 'Become a Teacher';

  @override
  String get teacherUpgradeCancelHint =>
      'Cancel anytime · Instant access after payment';

  @override
  String get teacherUpgradeSeeAllPlans => 'See all plans';

  @override
  String get teacherUpgradeAlreadyActive =>
      'You already have an active Teacher plan.';

  @override
  String get teacherUpgradeCancelTitle => 'Cancel subscription?';

  @override
  String get teacherUpgradeCancelMessage =>
      'You will lose access to the Teacher module and all your classes will be archived. You can resubscribe at any time.';

  @override
  String get teacherUpgradeCancelConfirm => 'Cancel plan';

  @override
  String get teacherUpgradeCancelSuccess =>
      'Subscription cancelled. See you soon!';

  @override
  String get teacherUpgradeExpiryWarning =>
      'Your Teacher plan expires in less than 7 days. Renew to keep access.';

  @override
  String get homeTeacherBannerTitle => 'Are you a teacher?';

  @override
  String get homeTeacherBannerBody =>
      'Classes, assignments and real-time analytics.';

  @override
  String get homeTeacherBannerAction => 'View Teacher plan';

  @override
  String get homeTeacherBannerDismissTooltip => 'Don\'t show again';

  @override
  String get studentAssignmentsTitle => 'My assignments';

  @override
  String get studentAssignmentsAction => 'Class assignments';

  @override
  String get studentAssignmentsEmpty =>
      'You don\'t have any assignments from your teachers yet.';

  @override
  String get studentAssignmentStartAction => 'Start';

  @override
  String get studentAssignmentClosedLabel => 'Closed';

  @override
  String get studentAssignmentUnavailableLabel => 'Unavailable';

  @override
  String get studentAssignmentNotYetOpenLabel => 'Coming soon';

  @override
  String get studentAssignmentNotYetOpenError =>
      'This assignment is not available yet. Check the opening date.';

  @override
  String get studentAssignmentPastDueLabel => 'Past due';

  @override
  String get studentAssignmentMaxAttemptsLabel => 'No attempts left';

  @override
  String get studentAssignmentAvailableNowLabel => 'Available now';

  @override
  String studentAssignmentAttemptsSummary(int used, int max) {
    return '$used of $max attempts';
  }

  @override
  String get studentAssignmentMyAttemptsAction => 'My attempts';

  @override
  String get studentAssignmentMyAttemptsTitle => 'My attempts';

  @override
  String get studentAssignmentMyAttemptsEmpty =>
      'You have not completed any attempts for this assignment yet.';

  @override
  String get studentAssignmentAttemptScoreOnlyHint =>
      'Score only — correct answers are not available per your teacher\'s settings.';

  @override
  String studentAssignmentAttemptsHeaderSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts recorded',
      one: '1 attempt recorded',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentAttemptBestScore(String percent) {
    return 'Best score: $percent%';
  }

  @override
  String get studentAssignmentAttemptStatusFinished => 'Completed';

  @override
  String get studentAssignmentAttemptScoreOnlyBadge => 'Score only';

  @override
  String get studentAssignmentAttemptReviewAvailable => 'View answers';

  @override
  String studentAssignmentAttemptMeta(
    String score,
    String duration,
    String status,
  ) {
    return '$score · $duration · $status';
  }

  @override
  String get studentAssignmentsFilterAll => 'All';

  @override
  String get studentAssignmentsFilterPending => 'Pending';

  @override
  String get studentAssignmentsSearchHint => 'Search assignment or class';

  @override
  String studentAssignmentsSummaryTodoOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to do',
      one: '1 to do',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentsSummaryDueTodayOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count due today',
      one: '1 due today',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentsSummaryCombined(String todo, String dueToday) {
    return '$todo · $dueToday';
  }

  @override
  String get studentAssignmentsSummaryAllDone =>
      'You have no pending assignments right now.';

  @override
  String studentAssignmentsClassGroupSubtitle(String teacher, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assignments',
      one: '1 assignment',
    );
    return '$teacher · $_temp0';
  }

  @override
  String get studentAssignmentsEmptyFiltered =>
      'No assignments match this filter.';

  @override
  String studentAssignmentRowSubtitleDue(String date, String attemptsSuffix) {
    return 'Due $date$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleDueToday(String attemptsSuffix) {
    return 'Due today$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleAvailable(String attemptsSuffix) {
    return 'Available$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleNoDue(String attemptsSuffix) {
    return 'No due date$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleNotYetOpen(String date) {
    return 'Opens $date';
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
  String get studentAssignmentStatusBadgeAvailable => 'Available';

  @override
  String get studentAssignmentDetailTitle => 'Assignment details';

  @override
  String get profileTeacherPlanSectionTitle => 'Teacher plan';

  @override
  String get profileTeacherPlanManageTitle => 'Manage Teacher plan';

  @override
  String get profileTeacherPlanActiveSubtitle => 'Active plan · tap to manage';

  @override
  String get profileTeacherPlanInactiveSubtitle =>
      'Classes, assignments and analytics · Monthly subscription';

  @override
  String get teacherUpgradeKeepPlan => 'No, keep it';

  @override
  String get teacherOnboardingWelcomeTitle => 'Welcome, Teacher!';

  @override
  String teacherOnboardingStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get teacherOnboardingStep1Title => 'Create your first class';

  @override
  String get teacherOnboardingStep1Body =>
      'Classes let you organize students and assign quizzes with personalized tracking.';

  @override
  String get teacherOnboardingClassNameLabel => 'Class name';

  @override
  String get teacherOnboardingClassNameHint => 'e.g. Mathematics — Group A';

  @override
  String get teacherOnboardingCreateClassAction => 'Create class and continue';

  @override
  String get teacherOnboardingStep2Title => 'Invite your first student';

  @override
  String get teacherOnboardingStep2Body =>
      'Enter a registered student\'s email to add them to your class. You can also do this later.';

  @override
  String get teacherOnboardingStudentEmailLabel => 'Student email';

  @override
  String get teacherOnboardingStudentEmailHint => 'student@email.com';

  @override
  String get teacherOnboardingInviteAction => 'Invite and continue';

  @override
  String get teacherOnboardingSkipAction => 'Skip for now';

  @override
  String get teacherOnboardingStep3Title => 'All set!';

  @override
  String get teacherOnboardingStep3Body =>
      'Your classroom is ready. You can now create assignments, track student progress, and analyze results in Activity Pulse.';

  @override
  String get teacherOnboardingGoToDashboardAction => 'Go to Teacher Dashboard';
}
