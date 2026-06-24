// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'CraftQuestAI';

  @override
  String get homeWelcome => 'Bem-vindo ao CraftQuest';

  @override
  String homeWelcomeUser(String name) {
    return 'Ola, $name';
  }

  @override
  String homeRoleLabel(String role) {
    return 'Papel: $role';
  }

  @override
  String get roleUnknown => 'sem papel';

  @override
  String get roleTeacherLabel => 'Professor';

  @override
  String get roleStudentLabel => 'Estudante';

  @override
  String get roleInstitutionAdminLabel => 'Admin instituição';

  @override
  String get roleContentAdminLabel => 'Admin conteúdo';

  @override
  String get roleSuperAdminLabel => 'Superadmin';

  @override
  String get apiStatusLabel => 'Status da API';

  @override
  String get apiStatusLoading => 'Conectando...';

  @override
  String get apiStatusError => 'Nao foi possivel conectar a API';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get noInternetBannerTitle => 'Sem conexao com a internet';

  @override
  String get noInternetBannerMessage =>
      'Voce pode continuar navegando, mas os dados so atualizam quando a rede voltar.';

  @override
  String get noInternetSnackBarMessage =>
      'Sem conexao. Verifique a internet e tente novamente.';

  @override
  String get errorDevApiUnreachable =>
      'Nao foi possivel ligar a API no telemovel. Com USB ligado execute: adb reverse tcp:7080 tcp:7080 e reinicie a app.';

  @override
  String get genericRequestErrorMessage =>
      'Nao foi possivel concluir a solicitacao. Tente novamente em instantes.';

  @override
  String get errorHttpMethodNotAllowed =>
      'O servidor nao permite esta operacao. Reinicie a API e tente novamente.';

  @override
  String errorQuestionLimitReached(int max, String plan) {
    return 'Voce atingiu o limite de $max perguntas por questionario no plano $plan.';
  }

  @override
  String errorQuizLimitReached(int max, String plan) {
    return 'Voce atingiu o limite de $max questionarios no plano $plan.';
  }

  @override
  String errorQuizOverPlanLimit(int max, int current, String plan) {
    return 'Seu plano $plan permite $max questionarios e voce tem $current. Exclua questionarios ou faca upgrade para edita-los.';
  }

  @override
  String quizOverPlanLimitBanner(int current, int max) {
    return 'Modo somente leitura: voce tem $current questionarios, mas seu plano permite $max. Ainda pode praticar; exclua alguns ou faca upgrade para editar.';
  }

  @override
  String get billingPlanFreeName => 'Gratuito';

  @override
  String get billingPlanProName => 'Pro';

  @override
  String get billingPlanPremiumName => 'Premium';

  @override
  String get billingPlanTeacherName => 'Professor';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginSubtitle =>
      'Acesse gratuitamente sua conta CraftQuestAI — entre ou cadastre-se em segundos';

  @override
  String get parentalConsentTitle => 'Aprovação dos pais necessária';

  @override
  String get parentalConsentBodyDefault =>
      'Sua conta é supervisionada ou você é menor em uma região com regras de idade (ex.: Texas). Um responsável deve autorizar o CraftQuestAI no Google Play antes de continuar.';

  @override
  String get parentalConsentBodyPending =>
      'Há alterações pendentes de aprovação do responsável no Google Play. Peça para revisar no Family Link ou na Play Store e verifique novamente.';

  @override
  String get parentalConsentBodyDenied =>
      'O responsável não aprovou o acesso ao CraftQuestAI. Abra o Google Play para revisar a conta supervisionada ou fale com quem administra sua conta.';

  @override
  String get parentalConsentBodyUnknown =>
      'O Google Play não pôde confirmar sua idade. Abra a Play Store, entre com a mesma conta e conclua a verificação de idade; depois toque em Verificar novamente.';

  @override
  String get parentalConsentOpenPlayStore => 'Abrir Google Play';

  @override
  String get parentalConsentRecheckAction => 'Verificar novamente';

  @override
  String get loginAction => 'Entrar';

  @override
  String get loginRememberCredentials => 'Lembrar e-mail';

  @override
  String get loginInvalidCredentials =>
      'Email ou palavra-passe incorretos. Verifique os dados e tente novamente.';

  @override
  String get registerTitle => 'Criar conta';

  @override
  String get registerAction => 'Registrar';

  @override
  String get goToRegister => 'Nao tem conta? Registre-se';

  @override
  String get forgotPasswordLink => 'Esqueceu sua senha?';

  @override
  String get forgotPasswordTitle => 'Recuperar senha';

  @override
  String get forgotPasswordSubtitle =>
      'Enviaremos um link se existir uma conta com esse e-mail.';

  @override
  String get forgotPasswordAction => 'Enviar link';

  @override
  String get forgotPasswordSuccess =>
      'Se o e-mail estiver registrado, voce recebera instrucoes em breve.';

  @override
  String get resetPasswordTitle => 'Nova senha';

  @override
  String get resetPasswordSubtitle =>
      'Informe o codigo do e-mail e escolha uma nova senha.';

  @override
  String get resetPasswordTokenLabel => 'Codigo de recuperacao';

  @override
  String get resetPasswordAction => 'Salvar senha';

  @override
  String get resetPasswordSuccess => 'Senha atualizada. Ja pode entrar.';

  @override
  String get backToLogin => 'Voltar ao login';

  @override
  String get resetPasswordHaveCode => 'Ja tenho o codigo de recuperacao';

  @override
  String get oauthDividerLabel => 'ou continue com';

  @override
  String get oauthSignInWithGoogle => 'Entrar com Google';

  @override
  String get oauthSignInWithApple => 'Entrar com Apple';

  @override
  String get oauthSignInGoogleShort => 'Google';

  @override
  String get oauthSignInAppleShort => 'Apple';

  @override
  String get oauthSignInFailed => 'Não foi possível concluir o login social.';

  @override
  String get oauthGoogleWebOriginHint =>
      ' No Google Cloud (cliente Web), adicione origens JavaScript autorizadas: https://app.craftquestai.com, http://localhost:7357 e http://127.0.0.1:7357.';

  @override
  String get oauthGooglePeopleApiHint =>
      ' Ative a People API no Google Cloud (mesmo projeto do Client ID): https://console.cloud.google.com/apis/library/people.googleapis.com';

  @override
  String get oauthGoogleNotConfigured =>
      'O login com Google não está configurado. Defina ExternalAuth:Google:WebClientId na API ou GOOGLE_SERVER_CLIENT_ID ao executar o app.';

  @override
  String get oauthAppleNotConfigured =>
      'O login com Apple não está configurado no servidor (ExternalAuth:Apple:BundleId).';

  @override
  String get oauthAppleNotAvailable =>
      'Entrar com Apple não está disponível neste dispositivo.';

  @override
  String get oauthAppleWebNotConfigured =>
      'Apple na web exige Services ID e WebRedirectUri na API (ExternalAuth:Apple). Registe-os na Apple Developer.';

  @override
  String get billingCycleMonthly => 'Mensal';

  @override
  String get billingCycleAnnual => 'Anual';

  @override
  String get billingCycleAnnualPriceSuffix => '/ ano';

  @override
  String get billingAnnualNotAvailable => 'Plano anual nao disponivel';

  @override
  String get billingPlanInstitutionName => 'Instituicao';

  @override
  String get upgradeInstitutionHighlight =>
      'Licencas para centros, campi e docentes';

  @override
  String get institutionPlanContactHint =>
      'Contacte vendas para um orcamento personalizado.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get displayNameLabel => 'Nome de exibicao';

  @override
  String get fieldRequired => 'Este campo e obrigatorio';

  @override
  String get passwordMinLength => 'Minimo de 8 caracteres';

  @override
  String get logoutAction => 'Sair';

  @override
  String get navHomeLabel => 'Inicio';

  @override
  String get navPrepPlusLabel => 'Preparação+';

  @override
  String get navProfileLabel => 'Perfil';

  @override
  String get prepPlusScreenTitle => 'Preparação+';

  @override
  String get prepPlusScreenSubtitle =>
      'Questionários curados para o seu exame. Compre acesso por tempo.';

  @override
  String get homePrepPlusCardTitle => 'Preparação+';

  @override
  String get homePrepPlusCardSubtitle =>
      'Explore por país ou tema e compre só o que precisa.';

  @override
  String get prepPlusByCountrySection => 'Por país';

  @override
  String get prepPlusInternationalSection => 'Internacional';

  @override
  String prepPlusInternationalSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questionários disponíveis',
      one: '1 questionário disponível',
      zero: 'Nenhum questionário disponível',
    );
    return '$_temp0';
  }

  @override
  String prepPlusCategoryItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questionários',
      one: '1 questionário',
      zero: 'Sem questionários',
    );
    return '$_temp0';
  }

  @override
  String get prepPlusMyAccessesTitle => 'Meus acessos';

  @override
  String prepPlusMyAccessesActiveCount(int count) {
    return '$count ativos';
  }

  @override
  String get prepPlusTabActive => 'Ativos';

  @override
  String get prepPlusTabExpired => 'Expirados';

  @override
  String get prepPlusMyAccessesActiveEmpty => 'Você não tem acessos ativos.';

  @override
  String get prepPlusMyAccessesExpiredEmpty =>
      'Você não tem acessos expirados.';

  @override
  String get prepPlusSearchHint => 'Buscar questionário…';

  @override
  String get prepPlusCategoryEmpty => 'Não há questionários nesta categoria.';

  @override
  String get prepPlusFiltersAction => 'Filtros';

  @override
  String get prepPlusFiltersTitle => 'Filtros';

  @override
  String get prepPlusFiltersApply => 'Aplicar';

  @override
  String get prepPlusFilterPriceLabel => 'Preço';

  @override
  String get prepPlusFilterAccessLabel => 'Seu acesso';

  @override
  String get prepPlusFilterAll => 'Todos';

  @override
  String get prepPlusFilterFree => 'Grátis';

  @override
  String get prepPlusFilterPaid => 'Pagos';

  @override
  String get prepPlusFilterInstitutionLabel => 'Instituição ou exame';

  @override
  String get prepPlusAccessNone => 'Sem compra';

  @override
  String get prepPlusAccessActive => 'Ativo';

  @override
  String get prepPlusAccessExpired => 'Expirado';

  @override
  String prepPlusQuestionCount(int count) {
    return '$count perguntas';
  }

  @override
  String get prepPlusHasFreeOffer => 'Inclui opção grátis';

  @override
  String prepPlusFromPrice(double price, String currency) {
    final intl.NumberFormat priceNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return 'A partir de $priceString $currency';
  }

  @override
  String get prepPlusItemDetailTitle => 'Detalhe';

  @override
  String get prepPlusPreviewAction => 'Testar simulação (3 perguntas)';

  @override
  String get prepPlusPreviewSimulationCtaTitle => 'Simulação interativa';

  @override
  String get prepPlusPreviewSimulationCtaSubtitle =>
      'Responda como na prática real — sem salvar resultados.';

  @override
  String get prepPlusPreviewTitle => 'Pré-visualização';

  @override
  String prepPlusPreviewSubtitle(String title) {
    return 'Amostra de «$title»';
  }

  @override
  String get prepPlusPreviewSimulationTitle => 'Simulação';

  @override
  String get prepPlusPreviewSimulationBanner => 'Modo demonstração';

  @override
  String prepPlusPreviewSimulationSubtitle(String title) {
    return '«$title» — mesma experiência da prática';
  }

  @override
  String get prepPlusPreviewTryInteraction =>
      'Toque uma resposta para ver como a ferramenta funciona.';

  @override
  String get prepPlusPreviewPrevious => 'Anterior';

  @override
  String get prepPlusPreviewNext => 'Próxima';

  @override
  String get prepPlusPreviewFinishCta => 'Fechar simulação';

  @override
  String prepPlusPreviewQuestionLabel(int number) {
    return 'Pergunta $number';
  }

  @override
  String get prepPlusAccessCombosTitle => 'Escolha seu combo de acesso';

  @override
  String get prepPlusAccessCombosSubtitle =>
      'Inclui o questionário completo no período selecionado.';

  @override
  String get prepPlusBestValueBadge => 'MELHOR VALOR';

  @override
  String prepPlusPricePerDay(String price) {
    return '$price / dia';
  }

  @override
  String get prepPlusComboIncludesAccess =>
      'Acesso total ao banco de perguntas';

  @override
  String get prepPlusSelectDuration => 'Duração do acesso';

  @override
  String get prepPlusDuration30 => '30 dias';

  @override
  String get prepPlusDuration60 => '60 dias';

  @override
  String get prepPlusDuration90 => '90 dias';

  @override
  String get prepPlusDuration6Months => '6 meses';

  @override
  String prepPlusDurationDays(int days) {
    return '$days dias';
  }

  @override
  String prepPlusOfferPrice(double price, String currency) {
    final intl.NumberFormat priceNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String priceString = priceNumberFormat.format(price);

    return '$priceString $currency';
  }

  @override
  String get prepPlusPracticeAction => 'Praticar';

  @override
  String get prepPlusBuyAction => 'Comprar acesso';

  @override
  String get prepPlusGetFreeAccessAction => 'Obter acesso grátis';

  @override
  String get prepPlusRenewAction => 'Renovar acesso';

  @override
  String prepPlusAccessUntil(String date) {
    return 'Vence em $date';
  }

  @override
  String prepPlusExpiresOn(String date) {
    return 'Vence em $date';
  }

  @override
  String prepPlusExpiredOn(String date) {
    return 'Expirou em $date';
  }

  @override
  String get prepPlusNotAvailableForPurchase =>
      'Indisponível para compra no momento.';

  @override
  String get prepPlusViewHistory => 'Ver meu histórico';

  @override
  String get prepPlusAccessGranted => 'Acesso concedido. Já pode praticar!';

  @override
  String get prepPlusConfirmPayPalPayment => 'Confirmar pagamento PayPal';

  @override
  String get prepPlusStoreProductMissing =>
      'Pagamento na loja não configurado para esta oferta. Use a versão web com PayPal.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get selectAvatarTitle => 'Seu avatar';

  @override
  String get profileChangeAvatarAction => 'Alterar avatar';

  @override
  String get profileEditNameAction => 'Editar nome';

  @override
  String get profileNameUpdatedMessage => 'Nome atualizado';

  @override
  String get profileNameInvalidMessage =>
      'Digite um nome entre 1 e 160 caracteres.';

  @override
  String get profileSaveAction => 'Salvar';

  @override
  String get profileAvatarPickerHint =>
      'Toque um ícone para atualizar seu perfil';

  @override
  String get avatarUpdatedMessage => 'Avatar atualizado';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageEnglish => 'Ingles';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languagePortuguese => 'Portugues';

  @override
  String get languageUpdatedMessage => 'Idioma atualizado';

  @override
  String get securitySectionTitle => 'Seguranca';

  @override
  String get changePasswordTitle => 'Alterar senha';

  @override
  String get changePasswordAction => 'Salvar senha';

  @override
  String get currentPasswordLabel => 'Senha atual';

  @override
  String get newPasswordLabel => 'Nova senha';

  @override
  String get confirmPasswordLabel => 'Confirmar senha';

  @override
  String get passwordsDoNotMatch => 'As senhas nao coincidem';

  @override
  String get passwordChangedMessage => 'Senha atualizada';

  @override
  String get currentPasswordIncorrectError => 'A senha atual nao esta correta.';

  @override
  String get passwordChangeUnavailableError =>
      'Esta conta nao tem senha local. Use o login com Google ou Apple.';

  @override
  String get myQuizzesAction => 'Meus questionarios';

  @override
  String get quizzesTitle => 'Questionarios';

  @override
  String get quizzesEmpty => 'Voce ainda nao tem questionarios';

  @override
  String get quizzesLoadError => 'Nao foi possivel carregar os questionarios';

  @override
  String get createQuizAction => 'Criar questionario';

  @override
  String get quizFolderNewFolderAction => 'Nova pasta';

  @override
  String get quizFolderCreateTitle => 'Nova pasta';

  @override
  String get quizFolderCreateSubfolderTitle => 'Nova subpasta';

  @override
  String get quizFolderRenameTitle => 'Renomear pasta';

  @override
  String get quizFolderRenameAction => 'Renomear';

  @override
  String get quizFolderDeleteAction => 'Excluir pasta';

  @override
  String get quizFolderCreateSubfolderAction => 'Criar subpasta';

  @override
  String get quizFolderMoveQuizAction => 'Mover para pasta';

  @override
  String get quizFolderMoveQuizTitle => 'Mover questionario';

  @override
  String get quizFolderUncategorized => 'Sem pasta';

  @override
  String get quizFolderNameHint => 'Nome da pasta';

  @override
  String get quizFolderDeleteConfirmTitle => 'Excluir pasta?';

  @override
  String quizFolderDeleteConfirmMessage(String folderName) {
    return 'A pasta \"$folderName\" sera excluida. Os questionarios nao serao excluidos.';
  }

  @override
  String quizFolderDeleteConfirmWithQuizzes(String folderName, int quizCount) {
    return 'A pasta \"$folderName\" e suas subpastas serao excluidas. $quizCount questionarios ficarao sem pasta.';
  }

  @override
  String get quizSearchHint => 'Buscar questionarios';

  @override
  String get quizSearchNoResults => 'Sem resultados';

  @override
  String get quizFolderDropToRoot => 'Mover para a raiz';

  @override
  String get quizFolderMoveInvalid => 'Nao e possivel mover para la';

  @override
  String get createQuizTitle => 'Novo questionario';

  @override
  String get createQuizNextStepTitle => 'Adicione perguntas ao seu quiz';

  @override
  String get createQuizNextStepSubtitle =>
      'Comece criando uma pergunta, importe de um arquivo ou gere com IA.';

  @override
  String get createQuizAddQuestionsManually => 'Criar perguntas manualmente';

  @override
  String get createQuizImportQuestions => 'Importar perguntas';

  @override
  String get createQuizSkipQuestionsSetup => 'Fazer depois';

  @override
  String get quizTitleLabel => 'Titulo';

  @override
  String get quizTitleTapToEdit => 'Toque no titulo para editar';

  @override
  String get quizDescriptionLabel => 'Descricao (opcional)';

  @override
  String quizListSubtitle(String status, int count) {
    return '$status · $count perguntas';
  }

  @override
  String get quizStatusDraft => 'Rascunho';

  @override
  String get quizStatusPublished => 'Publicado';

  @override
  String get quizDetailTitle => 'Detalhe do questionario';

  @override
  String get quizDetailImportAiDraftAction =>
      'Importar perguntas geradas por IA';

  @override
  String quizDetailImportAiDraftBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perguntas geradas por IA prontas para importar',
      one: '1 pergunta gerada por IA pronta para importar',
    );
    return '$_temp0';
  }

  @override
  String get quizListPendingAiDraft => 'Rascunho de IA pronto para importar';

  @override
  String get addQuestionAction => 'Adicionar pergunta';

  @override
  String get viewQuizQuestionsAction => 'Ver perguntas';

  @override
  String get exportQuizPdfAction => 'Exportar PDF';

  @override
  String get exportQuizPdfReady => 'PDF pronto';

  @override
  String get exportQuizPdfFailed => 'Nao foi possivel gerar o PDF';

  @override
  String get exportQuizPdfEmpty => 'Adicione perguntas antes de exportar';

  @override
  String get publishQuizAction => 'Publicar';

  @override
  String get quizPublishedMessage => 'Questionario publicado';

  @override
  String get deleteQuizAction => 'Excluir questionario';

  @override
  String get deleteQuizConfirmTitle => 'Excluir questionario?';

  @override
  String deleteQuizConfirmMessage(String title) {
    return '\"$title\" e todas as perguntas serao removidos. Esta acao nao pode ser desfeita.';
  }

  @override
  String get quizDeletedMessage => 'Questionario excluido';

  @override
  String get questionsEmpty => 'Sem perguntas ainda';

  @override
  String get quizDetailQuestionsSection => 'Perguntas do questionario';

  @override
  String quizQuestionsCount(int count) {
    return '$count perguntas';
  }

  @override
  String quizDetailOptionCount(int count) {
    return '$count opcoes';
  }

  @override
  String quizDetailCorrectKeys(String keys) {
    return 'Resposta correta: $keys';
  }

  @override
  String quizDetailCorrectKeysPlural(String keys) {
    return 'Respostas corretas: $keys';
  }

  @override
  String get questionTypeLabelSingleChoice => 'Escolha unica';

  @override
  String get questionTypeLabelMultipleChoice => 'Multipla escolha';

  @override
  String get questionTypeLabelTrueFalse => 'Verdadeiro / Falso';

  @override
  String get questionTypeLabelImageChoice => 'Opcoes com imagem';

  @override
  String get questionTypeLabelImageBased => 'Baseada em imagem';

  @override
  String questionListIndexLabel(int index) {
    return 'P$index';
  }

  @override
  String get editQuestionAction => 'Editar';

  @override
  String get deleteQuestionAction => 'Excluir';

  @override
  String get editQuestionTitle => 'Editar pergunta';

  @override
  String get deleteQuestionConfirmTitle => 'Excluir pergunta?';

  @override
  String get deleteQuestionConfirmMessage =>
      'A pergunta sera removida do questionario. Esta acao nao pode ser desfeita.';

  @override
  String get questionDeletedMessage => 'Pergunta excluida';

  @override
  String get questionSavedMessage => 'Pergunta salva';

  @override
  String get addQuestionTitle => 'Nova pergunta';

  @override
  String get questionTypeLabel => 'Tipo de pergunta';

  @override
  String get questionTextLabel => 'Enunciado';

  @override
  String get questionJustificationLabel => 'Justificação (resposta correta)';

  @override
  String get questionJustificationHint =>
      'Explique em um único texto por que a(s) resposta(s) correta(s) está(ão) correta(s).';

  @override
  String get questionJustificationReviewHint =>
      'Visível ao rever as tentativas do questionário (não durante a prática).';

  @override
  String get explanationVisibilityAfterQuiz => 'Ao terminar o questionário';

  @override
  String get explanationVisibilityAfterAnswer => 'Após cada resposta';

  @override
  String get explanationVisibilityNever => 'Não mostrar na prática';

  @override
  String get practiceReviewJustificationTitle => 'Justificação';

  @override
  String get practiceReviewJustificationTapToExpand =>
      'Toque para ver a explicação';

  @override
  String practiceReviewSourcePage(int page) {
    return 'Página $page';
  }

  @override
  String get aiGenerationIncludeExplanationsLabel => 'Incluir justificações';

  @override
  String get aiGenerationIncludeExplanationsHint =>
      'A IA gerará texto explicativo e número da página do material quando aplicável.';

  @override
  String get questionPointsLabel => 'Pontos';

  @override
  String get questionPointsHint =>
      'Pontuacao ao acertar (somente esta pergunta)';

  @override
  String questionPointsValue(String points) {
    return '$points pts';
  }

  @override
  String get questionInvalidPoints => 'Os pontos devem ser maiores que 0';

  @override
  String answerOptionLabel(String key) {
    return 'Opcao $key';
  }

  @override
  String get correctAnswerKeyLabel => 'Resposta correta (key)';

  @override
  String get saveQuestionAction => 'Salvar pergunta';

  @override
  String get trueLabel => 'Verdadeiro';

  @override
  String get falseLabel => 'Falso';

  @override
  String get minTwoOptions => 'Informe pelo menos duas opcoes';

  @override
  String get questionImageLabel => 'Imagem do enunciado';

  @override
  String get correctAnswersLabel => 'Respostas corretas';

  @override
  String get selectCorrectAnswersHint =>
      'Selecione uma ou mais opcoes corretas';

  @override
  String get imageChoiceHint =>
      'Anexe uma imagem em pelo menos uma opcao de resposta';

  @override
  String get imageBasedQuestionHint =>
      'Envie a imagem ou diagrama desta pergunta';

  @override
  String get requireQuestionImage =>
      'Perguntas baseadas em imagem exigem uma imagem';

  @override
  String get requireOptionImage => 'Adicione pelo menos uma imagem nas opcoes';

  @override
  String get selectAtLeastOneCorrect =>
      'Marque pelo menos uma resposta correta';

  @override
  String correctIdsLabel(int count) {
    return '$count resposta(s) correta(s) por ID';
  }

  @override
  String get practiceOptionsTitle => 'Parametros de pratica';

  @override
  String get practiceRandomizeQuestionsLabel => 'Ordem aleatoria das perguntas';

  @override
  String get practiceRandomizeQuestionsHint =>
      'As perguntas aparecem em ordem diferente a cada pratica';

  @override
  String get quizRandomizeQuestionsHint =>
      'Aplica-se as tarefas dos seus alunos e quando praticam este questionario';

  @override
  String get practiceShowTimerLabel => 'Mostrar tempo decorrido';

  @override
  String get practiceShowTimerHint =>
      'Exibe um relogio enquanto voce responde o questionario';

  @override
  String get practiceSoundEffectsLabel => 'Efeitos sonoros';

  @override
  String get practiceSoundEffectsHint =>
      'Sons ao iniciar, navegar entre perguntas e finalizar';

  @override
  String practiceElapsedLabel(String elapsed) {
    return 'Tempo: $elapsed';
  }

  @override
  String get practiceDurationLabel => 'Tempo gasto';

  @override
  String get practiceQuizAction => 'Praticar';

  @override
  String get practiceSessionTitle => 'Sessao de pratica';

  @override
  String practiceProgressLabel(int answered, int total) {
    return '$answered de $total respondidas';
  }

  @override
  String practiceProgressCompletedLabel(int done, int total) {
    return '$done de $total concluidas';
  }

  @override
  String get practiceNavigateQuestionsLabel => 'Perguntas';

  @override
  String get practiceOpenQuestionMapAction => 'Mapa';

  @override
  String get practiceMapTitle => 'Mapa de perguntas';

  @override
  String get practiceMapFilterAll => 'Todas';

  @override
  String get practiceMapFilterPending => 'Pendentes';

  @override
  String get practiceMapFilterCompleted => 'Feitas';

  @override
  String get practiceMapEmptyFilter => 'Nenhuma pergunta com este filtro';

  @override
  String get practiceNavLegendAnswered => 'Respondida';

  @override
  String get practiceNavLegendPending => 'Pendente';

  @override
  String get practiceNavLegendCurrent => 'Atual';

  @override
  String practiceQuestionNavTooltip(int number) {
    return 'Pergunta $number';
  }

  @override
  String get practicePreviousQuestionAction => 'Anterior';

  @override
  String get practiceQuestionAnsweredLabel => 'Ja respondida';

  @override
  String get practiceUpdateAnswerAction => 'Atualizar resposta';

  @override
  String get practiceAnswerEditHint =>
      'Voce pode alterar sua resposta e tocar em Atualizar resposta';

  @override
  String get practiceSavingAnswerHint => 'Salvando sua resposta…';

  @override
  String practiceQuestionCounter(int current, int total) {
    return 'Pergunta $current de $total';
  }

  @override
  String get practiceSelectAnswer => 'Selecione pelo menos uma resposta';

  @override
  String get practiceSubmitAnswerAction => 'Confirmar resposta';

  @override
  String get practiceNextQuestionAction => 'Proxima pergunta';

  @override
  String get practiceFinishAction => 'Finalizar pratica';

  @override
  String get practiceResumeTitle => 'Pratica em andamento';

  @override
  String practiceResumeMessage(int answered, int total) {
    return 'Voce tem uma pratica salva com $answered de $total perguntas respondidas. O que deseja fazer?';
  }

  @override
  String get practiceContinueAction => 'Continuar';

  @override
  String get practiceStartNewAction => 'Comecar de novo';

  @override
  String get practiceSaveAndExitAction => 'Salvar e sair';

  @override
  String get practicePreparingSession => 'Preparando sua tentativa…';

  @override
  String get practiceInProgressChip => 'Pratica em andamento';

  @override
  String practiceInProgressSubtitle(int answered, int total) {
    return '$answered/$total respondidas';
  }

  @override
  String get practiceFinishEarlyAction => 'Finalizar agora';

  @override
  String get practiceNoQuestions => 'Este questionario nao tem perguntas';

  @override
  String get practiceResultTitle => 'Resultado';

  @override
  String practicePercentageLabel(double percentage) {
    return '$percentage%';
  }

  @override
  String practiceScoreLabel(double obtained, double possible) {
    return 'Pontuacao: $obtained / $possible';
  }

  @override
  String practiceCorrectLabel(int count) {
    return 'Corretas: $count';
  }

  @override
  String practiceIncorrectLabel(int count) {
    return 'Incorretas: $count';
  }

  @override
  String get practiceViewResultsAction => 'Ver resultados';

  @override
  String get practiceReviewHiddenByAssignment =>
      'Seu professor configurou esta tarefa para não mostrar as respostas corretas. Você só pode ver sua pontuação geral.';

  @override
  String practiceReviewHiddenUntilDue(String date) {
    return 'As respostas corretas estarão disponíveis após a data limite ($date). Por enquanto você só pode ver sua pontuação geral.';
  }

  @override
  String get practiceReviewHiddenUntilDueNoDate =>
      'As respostas corretas estarão disponíveis após a data limite. Por enquanto você só pode ver sua pontuação geral.';

  @override
  String get practiceReviewHiddenTeacherOnly =>
      'Somente seu professor pode ver as respostas corretas. Você pode consultar sua pontuação geral.';

  @override
  String get practiceBackHomeAction => 'Voltar ao inicio';

  @override
  String get importQuestionsAction => 'Importar perguntas';

  @override
  String get importQuestionsTitle => 'Importar perguntas';

  @override
  String get importExcelAction => 'Importar do Excel';

  @override
  String get excelImportTitle => 'Importar Excel';

  @override
  String get excelImportSubtitle =>
      'Envie um arquivo .xlsx com suas perguntas. Voce revisara uma previa antes de confirmar.';

  @override
  String get excelImportColumnsHint =>
      'Colunas: Pergunta, Tipo (inclui image_choice e image_based_question sem arquivos de imagem), Opcao A–E, Resposta correta (ex.: B ou A|C), Pontos e Secao (opcionais). Imagens depois no app.';

  @override
  String get excelImportDownloadTemplate => 'Baixar modelo Excel';

  @override
  String get excelImportTemplateReady =>
      'Modelo pronto para salvar ou compartilhar';

  @override
  String get excelImportTemplateFailed => 'Nao foi possivel baixar o modelo';

  @override
  String get excelImportDropHint => 'Arraste seu arquivo .xlsx aqui';

  @override
  String get excelImportDropSubhint => 'Ou escolha um arquivo no dispositivo';

  @override
  String get excelImportPickFile => 'Escolher arquivo';

  @override
  String get excelImportUploadAction => 'Enviar e revisar';

  @override
  String get excelImportOnlyXlsx => 'Apenas arquivos .xlsx sao aceitos';

  @override
  String get excelImportFileTooLarge => 'O arquivo excede o limite de 5 MB';

  @override
  String get excelImportReadFailed =>
      'Nao foi possivel ler o arquivo selecionado';

  @override
  String get excelImportSelectFileFirst =>
      'Selecione um arquivo Excel primeiro';

  @override
  String get excelImportColumnsTitle => 'Formato das colunas';

  @override
  String get excelImportTemplateSection => 'Passo 1 · Modelo';

  @override
  String get excelImportUploadSection => 'Passo 2 · Seu arquivo';

  @override
  String get excelImportFileReady => 'Arquivo pronto para importar';

  @override
  String get excelImportChangeFile => 'Trocar arquivo';

  @override
  String get importImageMediaPending =>
      'As imagens nao sao importadas do arquivo. Voce pode adiciona-las depois no app ao editar a pergunta.';

  @override
  String get importImagePendingBadge => 'Imagem pendente no app';

  @override
  String get importFormatLabel => 'Formato';

  @override
  String get importFormatJson => 'CQIF JSON';

  @override
  String get importFormatTxt => 'TXT CraftQuest';

  @override
  String get importContentLabel => 'Conteudo';

  @override
  String get importContentHint =>
      'Cole aqui o JSON CQIF v2 ou o TXT CraftQuest';

  @override
  String get importContentRequired => 'Cole o conteudo para importar';

  @override
  String get importProcessAction => 'Processar importacao';

  @override
  String get importNoValidQuestions => 'Nao ha perguntas validas para importar';

  @override
  String get importPreviewTitle => 'Pre-visualizacao';

  @override
  String importSummaryLabel(int valid, int total, int errors) {
    return '$valid validas de $total ($errors com erro)';
  }

  @override
  String get importSummaryLoading => 'A carregar perguntas…';

  @override
  String importSummaryReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perguntas prontas para rever',
      one: '1 pergunta pronta para rever',
    );
    return '$_temp0';
  }

  @override
  String importSummaryWithErrors(int valid, int total, int errors) {
    return '$valid validas de $total · $errors com erro';
  }

  @override
  String get importSummaryEmpty =>
      'Nao foram detetadas perguntas nesta importacao';

  @override
  String importErrorLine(int row, String message) {
    return 'Linha $row: $message';
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
    return '$count perguntas importadas';
  }

  @override
  String importPlanLimitPreviewNotice(
    String plan,
    int max,
    int current,
    int importable,
    int total,
  ) {
    return 'O plano $plan permite ate $max perguntas por questionario ($current ja neste questionario). Apenas $importable de $total do arquivo serao importadas.';
  }

  @override
  String importConfirmDisabledQuizFull(int current, int max) {
    return 'Nao e possivel importar mais: este questionario ja tem $current e o limite do plano e $max por questionario.';
  }

  @override
  String importPlanLimitConfirmNotice(
    int imported,
    String plan,
    int max,
    int skipped,
  ) {
    return '$imported perguntas importadas. No plano $plan o limite e $max por questionario; $skipped perguntas do arquivo nao foram adicionadas.';
  }

  @override
  String get teacherAttemptsAction => 'Ver tentativas';

  @override
  String get teacherAttemptsTitle => 'Tentativas de pratica';

  @override
  String get teacherAttemptsEmpty => 'Ainda nao ha tentativas finalizadas';

  @override
  String get teacherAttemptsFilterLabel => 'Estudante';

  @override
  String get teacherAttemptsFilterAll => 'Todos os estudantes';

  @override
  String get teacherAttemptsFilterEmpty =>
      'Nao ha tentativas para este estudante';

  @override
  String teacherAttemptsStudentsSummary(int students, int attempts) {
    return '$students estudantes · $attempts tentativas';
  }

  @override
  String get teacherAttemptsAttemptCountOne => '1 tentativa';

  @override
  String teacherAttemptsAttemptCountMany(int count) {
    return '$count tentativas';
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
  String get teacherReviewTitle => 'Revisao da tentativa';

  @override
  String teacherReviewStudentLabel(String name) {
    return 'Estudante: $name';
  }

  @override
  String teacherReviewScoreLabel(double obtained, double possible) {
    return 'Pontuacao: $obtained / $possible';
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
    return 'Plano: $plan';
  }

  @override
  String get billingPlanChipLabel => 'Plano';

  @override
  String billingUsageLabel(int quizzes, String maxQuizzes) {
    return 'Questionarios: $quizzes/$maxQuizzes';
  }

  @override
  String get billingQuizzesUnlimited => 'Questionarios: Ilimitados';

  @override
  String billingCreditsLabel(int credits) {
    return 'Creditos IA deste mes: $credits';
  }

  @override
  String get redeemCodeAction => 'Resgatar codigo';

  @override
  String get redeemCodeTitle => 'Resgatar codigo de acesso';

  @override
  String get redeemCodeSubtitle =>
      'Digite o codigo compartilhado pelo professor ou colega';

  @override
  String get redeemCodeLabel => 'Codigo';

  @override
  String get redeemCodeRequired => 'Digite um codigo';

  @override
  String redeemCodeSuccess(String title) {
    return 'Acesso concedido a \"$title\"';
  }

  @override
  String redeemCodeAlreadyInShared(String title) {
    return 'Voce ja tem \"$title\" em Compartilhados.';
  }

  @override
  String get accessibleQuizzesAction => 'Questionarios compartilhados';

  @override
  String get accessibleQuizzesTitle => 'Questionarios compartilhados';

  @override
  String get accessibleQuizzesEmpty =>
      'Nenhum questionario compartilhado. Resgate um codigo.';

  @override
  String accessibleQuizzesSharedBy(String name) {
    return 'Compartilhado por $name';
  }

  @override
  String accessibleQuizzesGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questionarios',
      one: '1 questionario',
    );
    return '$_temp0';
  }

  @override
  String get accessibleQuizzesRemoveAction => 'Remover de compartilhados';

  @override
  String get accessibleQuizzesRemoveConfirmTitle =>
      'Remover de compartilhados?';

  @override
  String accessibleQuizzesRemoveConfirmMessage(String title) {
    return '\"$title\" sera removido da sua lista. O questionario nao e excluido; voce pode resgata-lo novamente com o codigo, se precisar.';
  }

  @override
  String get accessibleQuizzesRemovedMessage =>
      'Questionario removido dos compartilhados';

  @override
  String accessibleQuizzesSlotBanner(int current, int max) {
    return 'Questionarios compartilhados: $current/$max';
  }

  @override
  String get accessibleQuizzesSlotFull =>
      'Cupo do plano Free completo. Remova um para resgatar outro codigo.';

  @override
  String errorSharedQuizSlotLimit(int max) {
    return 'Seu plano Free permite $max questionarios compartilhados. Remova um em Compartilhados para resgatar outro.';
  }

  @override
  String get errorCannotRedeemOwnQuiz =>
      'Voce nao pode resgatar o codigo de um questionario que voce criou. Abra-o em Meus questionarios.';

  @override
  String get shareCodeViewAction => 'Ver codigo';

  @override
  String get shareCodeExistingHint =>
      'Este e o codigo permanente deste questionario.';

  @override
  String get myQuizAnalyticsAction => 'Minha analitica';

  @override
  String get myQuizAnalyticsTitle => 'Minha analitica de pratica';

  @override
  String get myPracticeAttemptsAction => 'Minhas tentativas';

  @override
  String get myPracticeAttemptsTitle => 'Minhas tentativas de pratica';

  @override
  String get myPracticeAttemptsEmpty =>
      'Voce ainda nao concluiu nenhuma tentativa neste questionario.';

  @override
  String get myPracticeReviewTitle => 'Revisao da minha tentativa';

  @override
  String myQuizAnalyticsAttemptsLabel(int count) {
    return '$count tentativas concluidas';
  }

  @override
  String myQuizAnalyticsAverageLabel(double percentage) {
    return 'Media: $percentage%';
  }

  @override
  String myQuizAnalyticsBestLabel(double percentage) {
    return 'Melhor: $percentage%';
  }

  @override
  String get createShareCodeAction => 'Gerar codigo';

  @override
  String get shareCodeTitle => 'Codigo de acesso';

  @override
  String get shareCodeCreateTitle => 'Compartilhar questionario';

  @override
  String get shareCodeCreateTeacherSubtitle =>
      'Escolha se qualquer pessoa pode praticar ou apenas sua turma.';

  @override
  String get shareCodeCreateStudentSubtitle =>
      'Sera gerado um codigo para muitas pessoas praticarem (sem ver tentativas de outros).';

  @override
  String get shareCodeAudienceAnyone => 'Qualquer pessoa';

  @override
  String get shareCodeAudienceAnyoneHint =>
      'Com ou sem conta. Mesmo codigo para todos.';

  @override
  String get shareCodeAudienceGroup => 'Apenas minha turma';

  @override
  String get shareCodeAudienceGroupHint =>
      'Apenas alunos da turma escolhida (conta obrigatoria).';

  @override
  String get shareCodeSelectClassLabel => 'Turma';

  @override
  String shareCodeClassOption(String name, int count) {
    return '$name ($count alunos)';
  }

  @override
  String get shareCodeNoClasses =>
      'Voce ainda nao tem turmas. Crie uma turma para compartir apenas com seu grupo.';

  @override
  String get shareCodeGroupRequired =>
      'Selecione uma turma para compartilhar com o grupo.';

  @override
  String get shareCodeResultOpenHint =>
      'Valido para muitas pessoas. Tambem funciona em Praticar com codigo sem conta.';

  @override
  String get shareCodeResultGroupHint =>
      'Apenas membros da turma selecionada, com conta.';

  @override
  String get shareCodeCopyAction => 'Copiar';

  @override
  String get shareCodeCopied => 'Codigo copiado';

  @override
  String get shareCodeCopyLinkAction => 'Copiar link';

  @override
  String get shareCodeLinkCopied => 'Link copiado';

  @override
  String get shareCodeShareLinkAction => 'Compartilhar link';

  @override
  String shareCodeShareLinkMessage(String title, String url, String code) {
    return 'Entre em "$title" no CraftQuestAI:\n$url\n\nOu use o codigo: $code';
  }

  @override
  String get shareCodeCloseAction => 'Fechar';

  @override
  String get quizInviteTitle => 'Convidar pessoas';

  @override
  String get quizInviteSubtitle =>
      'A pessoa precisa ter conta no CraftQuest. O questionario aparece em Compartilhados (sem codigo).';

  @override
  String get quizInviteEmailsLabel => 'E-mails';

  @override
  String get quizInviteEmailsHint => 'um@email.com, outro@email.com';

  @override
  String get quizInviteAction => 'Convidar';

  @override
  String get quizInviteEmailsRequired => 'Digite pelo menos um e-mail valido.';

  @override
  String quizInviteSuccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas convidadas',
      one: '1 pessoa convidada',
    );
    return '$_temp0';
  }

  @override
  String quizInviteOutcomeInvited(String name) {
    return '$name: convidado/a';
  }

  @override
  String quizInviteOutcomeAlreadyHadAccess(String name) {
    return '$name: ja tinha acesso';
  }

  @override
  String quizInviteOutcomeNotFound(String email) {
    return '$email: nenhuma conta com este e-mail';
  }

  @override
  String quizInviteOutcomeInvalidEmail(String email) {
    return '$email: e-mail invalido';
  }

  @override
  String quizInviteOutcomeSlotLimit(String name) {
    return '$name: sem vaga no plano Free';
  }

  @override
  String get quizInviteOutcomeSelf => 'Voce nao pode convidar a si mesmo/a';

  @override
  String get errorDirectInviteNotAllowed =>
      'Convites diretos exigem plano Pro ou Professor.';

  @override
  String get errorActivePracticeSession =>
      'Voce tem uma pratica em andamento. Continue ou comece de novo.';

  @override
  String get aiNormalizeAction => 'Normalizar com IA';

  @override
  String get aiImproveImportAction => 'Melhorar com IA';

  @override
  String get aiNormalizeSuccess => 'Normalizacao IA concluida';

  @override
  String get quizAnalyticsAction => 'Analitica';

  @override
  String get quizAnalyticsTitle => 'Analitica do questionario';

  @override
  String quizAnalyticsSessionsLabel(int count) {
    return 'Tentativas finalizadas: $count';
  }

  @override
  String quizAnalyticsQuestionStats(int attempts, int correct, int incorrect) {
    return '$attempts tentativas · $correct corretas · $incorrect incorretas';
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
  String get attachImageAction => 'Anexar imagem';

  @override
  String get imagePickPermissionDenied =>
      'Permita o acesso a fotos em Ajustes para anexar imagens.';

  @override
  String get imagePickFailed =>
      'Nao foi possivel abrir a galeria. Tente novamente.';

  @override
  String get imageTooLargeForUpload =>
      'A imagem e muito grande (max. 5 MB). Escolha outra ou uma foto menor.';

  @override
  String get imageAttachedSuccess => 'Imagem anexada com sucesso.';

  @override
  String get imageUploadInvalidResponse =>
      'O servidor respondeu de forma inesperada. Reinicie a API e tente novamente.';

  @override
  String get imageUploadInvalidMultipart =>
      'Nao foi possivel enviar a imagem ao servidor. Reinicie a app e a API e tente novamente.';

  @override
  String get imageUploadFileRequired =>
      'Nenhum ficheiro de imagem foi recebido. Selecione a foto novamente.';

  @override
  String get imageUploadUnsupportedType =>
      'Formato de imagem nao suportado. Use JPG, PNG, WebP ou GIF.';

  @override
  String get imagePreviewLoadFailed =>
      'A imagem foi guardada, mas a pre-visualizacao nao carregou. Verifique a ligacao ao servidor.';

  @override
  String get removeImageAction => 'Remover imagem';

  @override
  String get viewFullImageAction => 'Ver imagem completa';

  @override
  String get closeAction => 'Fechar';

  @override
  String get imageLoadError => 'Nao foi possivel carregar a imagem';

  @override
  String get upgradePlanAction => 'Melhorar plano';

  @override
  String get upgradePlanTitle => 'Melhorar plano';

  @override
  String get upgradePlanSubtitle =>
      'Compare os planos e escolha o que mais combina com voce.';

  @override
  String get upgradePlanAlreadyHighest =>
      'Voce ja tem o plano mais alto disponivel. Nao ha mais upgrades por agora.';

  @override
  String upgradeProHighlightQuizzesLimit(int max) {
    return 'Questionarios ilimitados (seu plano atual: max. $max)';
  }

  @override
  String upgradeProHighlightQuestionsLimit(int max) {
    return 'Sem limite de perguntas por questionario (seu plano atual: $max)';
  }

  @override
  String get upgradeProHighlightAiCredits =>
      '150 creditos IA por mes (seu plano atual: 20)';

  @override
  String upgradePlanHighlightAiCredits(int credits, int currentCredits) {
    return '$credits creditos IA por mes (seu plano atual: $currentCredits)';
  }

  @override
  String get upgradeProHighlightShared =>
      'Compartilhados ilimitados ao resgatar ou convidar';

  @override
  String get upgradeProHighlightDirectInvite =>
      'Convide pessoas especificas por e-mail';

  @override
  String get upgradeTeacherHighlightIncludesPro => 'Tudo do plano Pro';

  @override
  String get upgradeTeacherHighlightAiCredits =>
      '360 creditos IA por mes para mais geracoes';

  @override
  String get upgradeTeacherHighlightClasses => 'Turmas e grupos de estudantes';

  @override
  String get upgradeTeacherHighlightAssignments =>
      'Tarefas com prazos, tentativas e revisao';

  @override
  String get upgradeTeacherHighlightGroupShare =>
      'Compartilhe codigos so com sua turma';

  @override
  String get upgradeTeacherHighlightTracking =>
      'Acompanhe tentativas e resultados por aluno';

  @override
  String get buyWithStoreAction => 'Comprar na loja';

  @override
  String get buyWithPayPalAction => 'Pagar com PayPal';

  @override
  String get paypalWebHint =>
      'Na web, PayPal e o metodo de pagamento recomendado.';

  @override
  String get paypalAwaitingCapture =>
      'Conclua o pagamento no PayPal e confirme a captura.';

  @override
  String get paypalAwaitingSubscriptionActivation =>
      'Aprove a assinatura no PayPal e volte ao app para ativá-la.';

  @override
  String get subscriptionAutoRenewDisclaimer =>
      'Renovação automática a cada período até você cancelar. Você pode desativar a qualquer momento.';

  @override
  String upgradeSuccess(String plan) {
    return 'Plano ativado: $plan';
  }

  @override
  String get storeProductNotConfigured => 'Produto da loja nao configurado';

  @override
  String storeProductNotFound(String id) {
    return 'Produto nao encontrado: $id';
  }

  @override
  String get purchaseFailed => 'A compra nao foi concluida';

  @override
  String get purchaseVerificationFailed =>
      'Não foi possível verificar sua compra. Tente novamente em instantes.';

  @override
  String get contactSales => 'Contactar vendas';

  @override
  String get aiGenerationHubTitle => 'Gerar com IA';

  @override
  String get aiGenerationHubSubtitle =>
      'Envie PDF ou Word com texto selecionavel e obtenha um questionario revisavel em minutos.';

  @override
  String get aiGenerationHubAction => 'Criar a partir de material';

  @override
  String get aiGenerationLibraryTitle => 'Biblioteca de materiais';

  @override
  String aiGenerationLibraryRetentionHint(int days) {
    return 'Os materiais sao removidos automaticamente ao fim de $days dias. Pode apaga-los antes com o icone do caixote do lixo.';
  }

  @override
  String aiGenerationLibraryExpiresOn(String date) {
    return 'Eliminacao automatica: $date';
  }

  @override
  String aiGenerationLibraryMaterialCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count materiais',
      one: '1 material',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerationLibraryStatusReady => 'Pronto';

  @override
  String get aiGenerationLibraryStatusProcessing => 'A processar';

  @override
  String get aiGenerationLibraryStatusFailed => 'Erro';

  @override
  String get aiGenerationLibraryStatusPending => 'Pendente';

  @override
  String aiGenerationLibraryUploaded(String date) {
    return 'Enviado em $date';
  }

  @override
  String aiGenerationLibraryExpiresInDays(int days) {
    return 'Elimina-se em $days dias';
  }

  @override
  String get aiGenerationLibraryNeedsReview => 'Rever texto';

  @override
  String get aiGenerationLibraryEmpty => 'Ainda nao tem materiais guardados.';

  @override
  String get aiGenerationLibraryEmptySubtitle =>
      'Os PDF e Word que enviar para gerar com IA aparecerao aqui.';

  @override
  String get aiGenerationLibraryAction => 'Ver biblioteca';

  @override
  String get deleteStudyMaterialConfirmTitle => 'Eliminar material';

  @override
  String deleteStudyMaterialConfirmMessage(String title) {
    return 'Sera eliminado \"$title\" e o texto extraido. O questionario gerado sera mantido. Esta acao nao pode ser anulada.';
  }

  @override
  String get deleteStudyMaterialAction => 'Eliminar';

  @override
  String get studyMaterialDeletedMessage => 'Material eliminado';

  @override
  String get aiGenerationUploadTitle => 'Enviar material';

  @override
  String get aiGenerationUploadSubtitle =>
      'Envie um PDF ou Word com texto copiavel. Revisara o alcance de paginas antes de gerar o questionario.';

  @override
  String get aiGenerationUploadHeroDrop => 'Arraste o seu PDF ou Word aqui';

  @override
  String get aiGenerationUploadHeroPick =>
      'ou escolha um ficheiro no seu dispositivo';

  @override
  String get aiGenerationUploadFormatGuideTitle => 'Dicas e limites de formato';

  @override
  String get aiGenerationUploadHint =>
      'PDF ou DOCX com texto selecionavel, nao digitalizados (max. 25 MB)';

  @override
  String aiGenerationUploadLimitsHint(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'Ate $maxPagesPerFile paginas por ficheiro · ate $maxPagesPerGeneration paginas por geracao';
  }

  @override
  String aiGenerationUploadLimitsSteps(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'Se o documento for maior, divida-o em varios ficheiros (cada um com $maxPagesPerFile paginas ou menos) ou exporte apenas o capitulo necessario. Depois pode gerar questionarios em blocos de ate $maxPagesPerGeneration paginas.';
  }

  @override
  String errorMaterialPageLimitGuidance(
    int maxPagesPerFile,
    int maxPagesPerGeneration,
  ) {
    return 'O que pode fazer: divida o PDF ou Word em partes de $maxPagesPerFile paginas ou menos (por capitulos ou blocos) e envie-as separadamente. Em cada material, gere o questionario escolhendo ate $maxPagesPerGeneration paginas de cada vez.';
  }

  @override
  String get aiGenerationUploadAnotherFileAction => 'Enviar outro ficheiro';

  @override
  String get aiGenerationDropHint => 'Tambem pode arrastar ficheiros aqui';

  @override
  String get aiGenerationUploadAction => 'Enviar e analisar';

  @override
  String get aiGenerationUploadFileReady => 'Ficheiro pronto para enviar';

  @override
  String get aiGenerationUploadChangeFile => 'Alterar ficheiro';

  @override
  String get aiGenerationUploadRemoveFile => 'Remover';

  @override
  String get aiGenerationProcessing => 'A analisar documento…';

  @override
  String get aiGenerationNeedsOcr =>
      'Pouco texto detetado. Use PDF ou Word com texto selecionavel, ou revise e cole o conteudo.';

  @override
  String get aiGenerationReviewTextTitle => 'Rever texto';

  @override
  String get aiGenerationReviewTextHint =>
      'O documento tem pouco texto extraivel. Corrija o detetado ou cole conteudo com texto selecionavel.';

  @override
  String get aiGenerationReviewTextSave => 'Guardar e continuar';

  @override
  String get aiGenerationReviewTextAction => 'Rever texto';

  @override
  String get aiGenerationOutlineTitle => 'Alcance do material';

  @override
  String aiGenerationPageRange(int from, int to) {
    return 'Paginas $from–$to';
  }

  @override
  String aiGenerationPageRangeOfTotal(int from, int to, int total) {
    return 'Paginas $from–$to de $total';
  }

  @override
  String get aiGenerationPageRangeHelp =>
      'Escolha quais paginas do documento serao usadas para gerar o questionario. Arraste cada extremo do controle para limitar o trecho.';

  @override
  String aiGenerationPageRangeSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paginas neste trecho',
      one: '1 pagina neste trecho',
    );
    return '$_temp0';
  }

  @override
  String aiGenerationPageRangeOverLimit(int max) {
    return 'Maximo de $max paginas por geracao. Reduza o trecho selecionado.';
  }

  @override
  String aiGenerationWordsInScopePurpose(int words) {
    return 'A IA gerara perguntas a partir de aproximadamente $words palavras nesse trecho.';
  }

  @override
  String get aiGenerationTopicHint => 'Foco opcional (tema ou seccao)';

  @override
  String aiGenerationWordsInScope(int words) {
    return '$words palavras no alcance';
  }

  @override
  String get aiGenerationParamsTitle => 'Parametros de geracao';

  @override
  String aiGenerationMaterialLanguageNotice(String language) {
    return 'As perguntas serao geradas em $language conforme o idioma do material.';
  }

  @override
  String get aiGenerationPresetQuick => 'Revisao rapida';

  @override
  String get aiGenerationPresetStandard => 'Exame padrao';

  @override
  String get aiGenerationPresetDeep => 'Pratica profunda';

  @override
  String get aiGenerationQuestionCount => 'Numero de perguntas';

  @override
  String aiGenerationQuestionCountOfMax(int count, int max) {
    return '$count de $max';
  }

  @override
  String get aiGenerationQuestionTypes => 'Tipos de pergunta';

  @override
  String get aiGenerationTypeSingleChoice => 'Escolha unica';

  @override
  String get aiGenerationTypeMultipleChoice => 'Escolha multipla';

  @override
  String get aiGenerationTypeTrueFalse => 'Verdadeiro / falso';

  @override
  String get aiGenerationDifficulty => 'Dificuldade';

  @override
  String get aiGenerationDifficultyEasy => 'Facil';

  @override
  String get aiGenerationDifficultyMedium => 'Media';

  @override
  String get aiGenerationDifficultyHard => 'Dificil';

  @override
  String get aiGenerationDifficultyMixed => 'Mista';

  @override
  String aiGenerationCreditsCost(int credits, int available) {
    return 'Consumira $credits creditos IA ($available disponiveis)';
  }

  @override
  String get aiGenerationStartAction => 'Gerar questionario';

  @override
  String get aiGenerationProgressTitle => 'A gerar questionario';

  @override
  String get aiGenerationProgressSubtitle =>
      'A IA esta a criar perguntas a partir do seu material…';

  @override
  String get aiGenerationProgressDeferredRetry =>
      'O servico de IA esta sobrecarregado. Tentaremos novamente em breve.';

  @override
  String aiGenerationProgressDeferredRetryMinutes(int minutes) {
    return 'Nova tentativa automatica em cerca de $minutes min. Pode manter esta tela aberta.';
  }

  @override
  String aiGenerationProgressAutoRetry(int attempt) {
    return 'Tentativa automatica $attempt em andamento…';
  }

  @override
  String get aiGenerationCreditsNotConsumed =>
      'Nenhum credito de IA foi descontado.';

  @override
  String get aiGenerationRetryAction => 'Tentar gerar novamente';

  @override
  String get aiGenerationProgressTakingLong =>
      'Ainda em processamento (pode demorar varios minutos). Se a API foi reiniciada, tente gerar novamente.';

  @override
  String get aiGenerationProgressStuck =>
      'A geracao parece bloqueada no servidor.';

  @override
  String get aiGenerationProgressStuckDetail =>
      'Este trabalho esta em processamento ha demasiado tempo. Volte atras e gere novamente; os creditos nao foram consumidos se nao terminou.';

  @override
  String get aiGenerationStuckGoBackAction => 'Voltar e tentar de novo';

  @override
  String get errorSessionExpired =>
      'A sua sessao expirou. Inicie sessao novamente e tente outra vez.';

  @override
  String get aiGenerationFailed => 'Nao foi possivel gerar o questionario';

  @override
  String get errorGenerationJobNotRetryable =>
      'Este trabalho de geracao nao pode ser repetido agora.';

  @override
  String get errorGuestNotAllowed =>
      'Este codigo requer uma conta registrada. Crie uma conta gratuita para continuar.';

  @override
  String errorGroupAccessDenied(String className) {
    return 'Este codigo e apenas para membros da turma \"$className\".';
  }

  @override
  String get errorGroupAccessDeniedGeneric =>
      'Este codigo e apenas para membros da turma do professor.';

  @override
  String get errorAiGenerationInvalidOutput =>
      'A IA devolveu um formato invalido. Toque em Tentar gerar novamente; nenhum credito foi descontado.';

  @override
  String get aiGenerationFromQuizAction => 'Gerar com IA a partir de material';

  @override
  String get importAiGeneratedBadge => 'Gerada por IA';

  @override
  String get errorAiCreditsInsufficient =>
      'Creditos IA insuficientes para esta geracao.';

  @override
  String get errorAiCreditPacksNotAvailable =>
      'Pacotes de creditos IA estao disponiveis nos planos Pro e Teacher.';

  @override
  String get aiCreditPacksTitle => 'Comprar creditos IA';

  @override
  String get aiCreditPacksSubtitle =>
      'Recarregue creditos para continuar gerando com IA. Pacotes comprados nao expiram; a cota mensal do plano reinicia a cada mes.';

  @override
  String aiCreditPacksCurrentBalance(int credits) {
    return 'Saldo atual: $credits creditos';
  }

  @override
  String aiCreditPacksCreditsLabel(int credits) {
    return '$credits creditos IA';
  }

  @override
  String aiCreditPacksBuyForPrice(String price) {
    return 'Comprar · $price';
  }

  @override
  String get aiCreditPacksEmpty =>
      'Nenhum pacote disponivel. Reinicie a API ou contacte o suporte se o problema continuar.';

  @override
  String get aiCreditPacksBuyAction => 'Comprar creditos';

  @override
  String aiCreditPacksPurchaseSuccess(int credits) {
    return '$credits creditos IA adicionados a sua conta.';
  }

  @override
  String get aiCreditsInsufficientDialogMessage =>
      'Voce pode comprar um pacote de creditos para continuar gerando com IA.';

  @override
  String get aiCreditsInsufficientFreePlanMessage =>
      'Faca upgrade para Pro ou Teacher para comprar pacotes de creditos IA.';

  @override
  String get homeBuyAiCreditsAction => 'Comprar creditos IA';

  @override
  String get errorMaterialNeedsOcr =>
      'Pouco texto extraivel. Use PDF ou Word com texto selecionavel, ou revise e cole o conteudo.';

  @override
  String get errorMaterialNotSelectableText =>
      'Este ficheiro parece digitalizado ou sem texto selecionavel.';

  @override
  String get errorMaterialNotSelectableTextGuidance =>
      'Recomendacoes:\n• Abra o ficheiro e confirme que pode selecionar e copiar paragrafos (nao apenas ampliar).\n• Se for digitalizado: no Word, Ficheiro → Abrir o PDF e deixe reconhecer o texto; reveja e guarde como DOCX.\n• Alternativa: OCR externo (Adobe, Google Drive), cole o texto no Word e envie como DOCX.\n• Exporte a partir do Word ou Google Docs; evite PDFs feitos so com fotos ou «imprimir para imagem».\n• Volte a enviar DOCX ou PDF exportado do Word com texto selecionavel.';

  @override
  String get errorMaterialNeedsOcrGuidance =>
      'Recomendacoes:\n• Use PDF ou DOCX em que possa selecionar e copiar texto.\n• Se a origem for digitalizada, converta para Word com texto (passos de OCR acima) e envie DOCX.\n• Tambem pode colar o conteudo no Word, guardar como DOCX e enviar esse ficheiro.';

  @override
  String get errorMaterialTooLargeGuidance =>
      'Recomendacoes:\n• O limite e 25 MB por ficheiro.\n• Comprima imagens no Word ou exporte apenas o capitulo necessario.\n• Divida o documento em ficheiros mais pequenos se ainda for demasiado grande.';

  @override
  String get aiGenerationUploadRecommendationsTitle => 'Recomendacoes';

  @override
  String get aiGenerationUploadSelectableTextHint =>
      'O PDF ou Word deve permitir selecionar e copiar texto. Documentos digitalizados nao sao suportados.';

  @override
  String get errorMaterialTooLarge =>
      'O ficheiro excede o tamanho maximo permitido.';

  @override
  String errorMaterialPageLimitExceeded(int maxPages) {
    return 'O documento excede o maximo de $maxPages paginas por ficheiro.';
  }

  @override
  String errorGenerationPageRangeExceeded(int maxPages) {
    return 'So pode gerar a partir de no maximo $maxPages paginas de cada vez.';
  }

  @override
  String get errorGenerationScopeEmpty =>
      'Sem texto no intervalo de paginas selecionado.';

  @override
  String get errorGenerationAlreadyInProgress =>
      'Ja existe uma geracao em curso para este material.';

  @override
  String get errorAiNotConfigured =>
      'A geracao com IA nao esta configurada no servidor.';

  @override
  String get errorAiGeminiQuotaExhausted =>
      'Os creditos do Gemini esgotaram. Adicione saldo no Google AI Studio (ai.google.dev) e tente novamente.';

  @override
  String get errorAiGeminiModelUnavailable =>
      'O modelo Gemini configurado nao esta mais disponivel. Defina Ai:GeminiModel como gemini-2.5-flash e reinicie a API.';

  @override
  String get errorAiGeminiOverloaded =>
      'O Gemini esta com alta demanda no momento. Aguarde alguns minutos e tente gerar novamente.';

  @override
  String get errorAiGeminiApiKeyInvalid =>
      'A chave da API do Gemini e invalida (expirada, revogada ou vazada). Crie uma nova chave no Google AI Studio, atualize appsettings.Development.local.json e reinicie a API.';

  @override
  String get aiActivityTitle => 'Atividade IA';

  @override
  String get aiActivityAction => 'Atividade IA';

  @override
  String get aiActivityEmpty =>
      'Sem geracoes recentes. Ao gerar um questionario, os trabalhos aparecem aqui mesmo que feche a app.';

  @override
  String get aiActivityStatusDraftReady => 'Rascunho pronto';

  @override
  String get aiActivityStatusFailed => 'Erro';

  @override
  String get aiActivityStatusCompleted => 'Concluida';

  @override
  String get aiActivityReviewDraft => 'Toque para rever e importar o rascunho';

  @override
  String get aiActivityViewProgress => 'Toque para ver o progresso';

  @override
  String get aiActivityTapForDetails => 'Toque para ver detalhes';

  @override
  String get aiActivityUnknownMaterial => 'Material';

  @override
  String aiActivityPagesRange(int from, int to) {
    return 'Paginas $from–$to';
  }

  @override
  String get aiLibraryStatusDraftReady => 'Rascunho pronto';

  @override
  String get aiGenerationBackgroundSnack =>
      'Geracao em segundo plano. Pode sair; retome em Atividade IA ou na biblioteca.';

  @override
  String get aiGenerationResumedSnack =>
      'Ja havia uma geracao em curso para este material. A mostrar o progresso.';

  @override
  String aiGenerationProgressPercent(int percent) {
    return '$percent% concluido';
  }

  @override
  String get aiJobStageQueued => 'Em fila';

  @override
  String get aiJobStagePreparing => 'A preparar material';

  @override
  String get aiJobStageOutlining => 'A planear temas';

  @override
  String get aiJobStageGenerating => 'A gerar perguntas';

  @override
  String get aiJobStageMerging => 'A combinar resultados';

  @override
  String get aiJobStageValidating => 'A validar perguntas';

  @override
  String get aiJobStageImporting => 'A preparar rascunho';

  @override
  String get aiJobStageCompleted => 'Concluida';

  @override
  String get aiJobStageFailed => 'Erro';

  @override
  String get aiActivityClearHistoryAction => 'Limpar historico';

  @override
  String get aiActivityClearHistoryTitle => 'Limpar historico?';

  @override
  String get aiActivityClearHistoryMessage =>
      'Serao removidas geracoes concluidas e erros antigos. Mantem-se as em curso e os rascunhos por rever.';

  @override
  String aiActivityClearHistoryDone(int count) {
    return 'Foram removidas $count entradas do historico.';
  }

  @override
  String get aiActivityClearHistoryNothing => 'Nao havia entradas para limpar.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get practiceStatusInProgress => 'Em andamento';

  @override
  String get guestCodeTitle => 'Praticar com codigo';

  @override
  String get guestCodeSubtitle =>
      'Insira o codigo compartilhado pelo seu professor para praticar sem criar conta.';

  @override
  String get guestCodeAction => 'Comecar';

  @override
  String get guestCodeLabel => 'Codigo';

  @override
  String get guestCodeRequired => 'Insira um codigo';

  @override
  String get guestCodePasteTooltip => 'Colar';

  @override
  String get guestEphemeralNotice =>
      'Esta e uma sessao temporaria. Tudo sera apagado ao sair.';

  @override
  String get guestAnonymousLimitTitle => 'Bom trabalho praticando!';

  @override
  String get guestAnonymousLimitMessage =>
      'Voce atingiu o limite de praticas anonimas. Crie uma conta gratuita em 10 segundos para continuar jogando, salvar seu progresso e criar seus proprios questionarios.';

  @override
  String get guestAnonymousLimitLater => 'Mais tarde';

  @override
  String get guestAnonymousLimitSignUp => 'Criar conta';

  @override
  String get guestPracticeWithCodeAction => 'Praticar com codigo';

  @override
  String get guestShellFreeBadge => 'Gratis';

  @override
  String get guestShellHeroHint =>
      'Pratique agora. Registre-se gratis para salvar o progresso e desbloquear mais.';

  @override
  String get guestShellSessionBadge => 'Sem conta';

  @override
  String get guestPracticeOptions => 'Opcoes de pratica';

  @override
  String get guestStartPracticeAction => 'Praticar';

  @override
  String get guestAttemptsTitle => 'Nesta visita';

  @override
  String get guestAttemptsEmpty =>
      'Voce ainda nao praticou nesta visita. Comece agora!';

  @override
  String get guestLeaveAction => 'Sair';

  @override
  String get guestLeaveConfirmTitle => 'Sair desta visita?';

  @override
  String get guestLeaveConfirmMessage =>
      'Todas as tentativas desta visita serao apagadas. Esta acao nao pode ser desfeita.';

  @override
  String get guestRegisterAction => 'Criar conta gratuita';

  @override
  String get guestTryAgainAction => 'Tentar novamente';

  @override
  String get guestResultStatCorrect => 'Corretas';

  @override
  String get guestResultStatIncorrect => 'Incorretas';

  @override
  String get guestViewResultsAction => 'Ver resultados';

  @override
  String get guestTimerRegisteredOnlyHint =>
      'Apenas para usuarios registrados. Criar conta e gratis.';

  @override
  String get guestRegisterCtaTitle => 'Quer salvar seus resultados?';

  @override
  String get guestRegisterBenefit1 =>
      'Historico permanente de todas as suas tentativas';

  @override
  String get guestRegisterBenefit2 => 'Crie seus proprios questionarios com IA';

  @override
  String get guestRegisterBenefit3 =>
      'Plano Free: 2 questionarios e 20 creditos de IA, gratis';

  @override
  String get guestRegisterBenefit4 => 'Experiencia sem anuncios';

  @override
  String get guestRegisterBenefit5 =>
      'Compartilhe questionarios com codigos ou convites';

  @override
  String get guestRegisterBenefit6 =>
      'Analitica de pratica: veja onde voce mais erra';

  @override
  String get guestRegisterPromoSubtitle =>
      'Crie uma conta gratuita em segundos e desbloqueie tudo isso.';

  @override
  String get guestRegisterPromoBenefitsTitle => 'Com sua conta registrada';

  @override
  String guestRegisterPromoCountdown(int seconds) {
    return 'Ver resultados em $seconds s';
  }

  @override
  String get guestRegisterPromoSkipTooltip => 'Ver resultados agora';

  @override
  String get guestExitPracticeTitle => 'Sair da pratica?';

  @override
  String get guestExitPracticeMessage =>
      'Seu progresso foi salvo e voce pode retomar quando voltar.';

  @override
  String get guestExitPracticeConfirm => 'Sair';

  @override
  String get teacherTabLabel => 'Professor';

  @override
  String get teacherDashboardTitle => 'Painel';

  @override
  String get teacherDashboardTotalStudents => 'Alunos';

  @override
  String get teacherDashboardActiveClasses => 'Turmas';

  @override
  String get teacherDashboardPublishedQuizzes => 'Quizzes';

  @override
  String get teacherDashboardSessionsThisWeek => 'Esta semana';

  @override
  String get teacherDashboardActivityFeedTitle => 'Atividade recente';

  @override
  String get teacherDashboardInsightsTitle => 'Insights';

  @override
  String get teacherDashboardEmptyFeed =>
      'Sem atividade ainda. Compartilhe um quiz com seus alunos!';

  @override
  String get teacherDashboardEmptyInsights =>
      'Sem insights ainda. Volte quando seus alunos começarem a praticar.';

  @override
  String get teacherDashboardInventoryStudents => 'Alunos';

  @override
  String get teacherDashboardInventoryClasses => 'Turmas';

  @override
  String get teacherDashboardInventoryQuizzes => 'Atribuídos';

  @override
  String get teacherDashboardUrgentTitle => 'Requer atenção';

  @override
  String get teacherDashboardUrgentEmpty =>
      'Nenhuma tarefa urgente no momento.';

  @override
  String teacherDashboardUrgentDueLabel(String date) {
    return 'Vence $date';
  }

  @override
  String teacherDashboardUrgentPendingLabel(int pending, int total) {
    return '$pending de $total sem entregar';
  }

  @override
  String teacherDashboardActiveStudentsWeek(int count) {
    return 'Alunos ativos esta semana: $count';
  }

  @override
  String teacherInsightHighError(String errorRate, String questionText) {
    return 'Uma pergunta tem $errorRate% de erros: $questionText';
  }

  @override
  String teacherInsightMostActive(
    int sessionCount,
    int studentCount,
    String quizTitle,
  ) {
    return '$sessionCount práticas esta semana ($studentCount alunos) · $quizTitle';
  }

  @override
  String get teacherAssignmentAnalyticsTitle => 'Análise da tarefa';

  @override
  String get teacherAssignmentAnalyticsAction => 'Ver análise';

  @override
  String get teacherAssignmentAnalyticsRosterTitle => 'Alunos';

  @override
  String get teacherAssignmentAnalyticsHardQuestionsTitle =>
      'Perguntas difíceis';

  @override
  String get teacherAssignmentAnalyticsDistractorTitle =>
      'Seleção por opção (esta tarefa)';

  @override
  String get teacherAssignmentAnalyticsDistributionTitle =>
      'Distribuição de notas';

  @override
  String get teacherAssignmentAnalyticsNoAttempt => 'Sem tentativa';

  @override
  String teacherAssignmentAnalyticsCompletionLabel(int completed, int total) {
    return 'Entregaram $completed de $total';
  }

  @override
  String teacherAssignmentAnalyticsBestLabel(String score) {
    return 'Melhor: $score%';
  }

  @override
  String teacherAssignmentAnalyticsLastLabel(String score) {
    return 'Último: $score%';
  }

  @override
  String teacherAssignmentAnalyticsErrorRateLabel(String rate, int attempts) {
    return '$rate% erro · $attempts tentativas';
  }

  @override
  String get teacherClassAnalyticsActiveStudentsLabel => 'Alunos com prática';

  @override
  String get teacherClassAnalyticsAverageLabel => 'Média';

  @override
  String get teacherClassAnalyticsAssignmentsTitle => 'Tarefas';

  @override
  String get studentAssignmentProgressTitle => 'Meu progresso';

  @override
  String get studentAssignmentProgressAction => 'Meu progresso';

  @override
  String get studentAssignmentProgressMyStats => 'Meus resultados';

  @override
  String get studentAssignmentProgressEvolutionTitle => 'Minha evolução';

  @override
  String get studentAssignmentProgressHardQuestionsTitle =>
      'Perguntas para revisar';

  @override
  String studentAssignmentProgressTrendUp(String points) {
    return 'Você melhorou $points pts desde a primeira tentativa';
  }

  @override
  String studentAssignmentProgressAttemptLabel(int number, String percent) {
    return 'Tentativa $number: $percent%';
  }

  @override
  String get practiceResultRepracticeTitle => 'Perguntas para revisar';

  @override
  String practiceResultTrendUp(String points) {
    return '$points pts a mais que na tentativa anterior';
  }

  @override
  String practiceResultTrendDown(String points) {
    return '$points pts a menos que na tentativa anterior';
  }

  @override
  String get practiceResultReviewQuestionAction => 'Ver na revisão';

  @override
  String get analyticsPersonalOnlyLabel => 'Somente suas tentativas';

  @override
  String get analyticsOnlyDifficultFilter => 'Só difíceis';

  @override
  String analyticsPersonalAccuracyLabel(String percent) {
    return '$percent% de acerto nas suas tentativas';
  }

  @override
  String scoreDistributionRange(int min, int max) {
    return '$min–$max%';
  }

  @override
  String get teacherClassesTitle => 'Minhas turmas';

  @override
  String get teacherClassesEmpty => 'Você ainda não criou nenhuma turma.';

  @override
  String get teacherClassCreateTitle => 'Nova turma';

  @override
  String get teacherClassNameLabel => 'Nome da turma';

  @override
  String get teacherClassNameHint => 'Ex. Álgebra II — Período 3';

  @override
  String get teacherClassDescriptionLabel => 'Descrição (opcional)';

  @override
  String get teacherClassDescriptionHint => 'Breve descrição desta turma';

  @override
  String get teacherClassSaveAction => 'Salvar';

  @override
  String get teacherClassCreateAction => 'Criar turma';

  @override
  String get teacherClassArchiveAction => 'Arquivar turma';

  @override
  String get teacherClassArchiveConfirmTitle => 'Arquivar turma?';

  @override
  String get teacherClassArchiveConfirmMessage =>
      'Os alunos não verão mais as tarefas desta turma.';

  @override
  String get teacherClassArchiveConfirmAction => 'Arquivar';

  @override
  String get teacherClassesArchivedSectionTitle => 'Turmas arquivadas';

  @override
  String get teacherClassRestoreAction => 'Restaurar turma';

  @override
  String get teacherClassRestoreConfirmTitle => 'Restaurar turma?';

  @override
  String get teacherClassRestoreConfirmMessage =>
      'A turma voltará a ficar ativa e os estudantes verão novamente as tarefas abertas.';

  @override
  String get teacherClassRestoreConfirmAction => 'Restaurar';

  @override
  String get teacherClassArchivedBanner =>
      'Esta turma está arquivada. Restaure-a para editar ou criar tarefas.';

  @override
  String get teacherClassRestoredMessage => 'Turma restaurada';

  @override
  String get teacherClassDeletePermanentAction => 'Excluir';

  @override
  String get teacherClassDeletePermanentTitle => 'Excluir turma arquivada?';

  @override
  String teacherClassDeletePermanentMessage(String name) {
    return '«$name» deixara de aparecer na sua lista. Membros, tarefas e historico de pratica permanecem no sistema. Aplica-se apenas a turmas ja arquivadas.';
  }

  @override
  String get teacherClassDeletePermanentConfirm => 'Excluir';

  @override
  String get teacherClassDeletedMessage => 'Turma removida da sua lista';

  @override
  String get teacherClassDeleteRequiresArchiveError =>
      'Arquive a turma antes de exclui-la.';

  @override
  String get teacherClassNotArchivedError => 'Esta turma nao esta arquivada.';

  @override
  String get teacherClassMembersTab => 'Membros';

  @override
  String get teacherClassAssignmentsTab => 'Tarefas';

  @override
  String get teacherClassAnalyticsTab => 'Análises';

  @override
  String get teacherClassActiveMembersLabel => 'membros ativos';

  @override
  String get teacherClassPendingMembersLabel => 'aguardando aprovação';

  @override
  String get teacherClassAddMemberTitle => 'Adicionar aluno';

  @override
  String get teacherClassAddMemberEmailLabel => 'E-mail do aluno';

  @override
  String get teacherClassAddMemberEmailHint => 'aluno@email.com';

  @override
  String get teacherClassAddMemberAction => 'Adicionar';

  @override
  String get teacherClassInvalidEmailError =>
      'Digite um endereço de e-mail válido.';

  @override
  String get teacherClassMemberNotFoundError =>
      'Nenhum aluno registrado foi encontrado com esse e-mail.';

  @override
  String get teacherClassMemberAlreadyExistsError =>
      'Esse aluno já pertence a esta turma.';

  @override
  String get teacherClassRemoveMemberAction => 'Remover';

  @override
  String get teacherClassRemoveMemberConfirmTitle => 'Remover aluno?';

  @override
  String get teacherClassRemoveMemberConfirmMessage =>
      'Este aluno perderá acesso a todas as tarefas desta turma.';

  @override
  String get teacherClassApproveAction => 'Aprovar';

  @override
  String get teacherClassMembersEmpty => 'Nenhum aluno nesta turma ainda.';

  @override
  String get teacherClassPendingApprovalsTitle => 'Aguardando aprovação';

  @override
  String get teacherAssignmentCreateTitle => 'Nova tarefa';

  @override
  String get teacherAssignmentTitleLabel => 'Título';

  @override
  String get teacherAssignmentTitleHint => 'Ex. Capítulo 5 — Quiz de prática';

  @override
  String get teacherAssignmentInstructionsLabel => 'Instruções (opcional)';

  @override
  String get teacherAssignmentQuizLabel => 'Selecionar quiz';

  @override
  String get teacherAssignmentStartsAtLabel => 'Abre em';

  @override
  String get teacherAssignmentDueAtLabel => 'Data limite';

  @override
  String get teacherAssignmentMaxAttemptsLabel => 'Tentativas máximas';

  @override
  String get teacherAssignmentMaxAttemptsHint =>
      'Deixe em branco para ilimitadas';

  @override
  String get teacherAssignmentShowAnswersLabel => 'Mostrar respostas corretas';

  @override
  String get teacherAssignmentShowAnswersNever => 'Nunca';

  @override
  String get teacherAssignmentShowAnswersAfterAttempt => 'Após cada tentativa';

  @override
  String get teacherAssignmentShowAnswersAfterDue => 'Após a data limite';

  @override
  String get teacherAssignmentShowAnswersTeacherOnly => 'Somente o professor';

  @override
  String get teacherAssignmentRandomizeQuestionsLabel =>
      'Ordem aleatoria das perguntas';

  @override
  String get teacherAssignmentRandomizeQuestionsHint =>
      'Como as perguntas aparecem nesta tarefa da turma.';

  @override
  String get teacherAssignmentAllowStudentRandomizeLabel =>
      'O aluno pode alterar a ordem';

  @override
  String get teacherAssignmentAllowStudentRandomizeHint =>
      'Se desativado, todos usam a opcao acima.';

  @override
  String get teacherAssignmentForfeitExitLabel =>
      'Sair sem terminar consome uma tentativa';

  @override
  String get teacherAssignmentForfeitExitHint =>
      'So se aplica com limite maximo de tentativas. O aluno nao podera pausar e retomar.';

  @override
  String get teacherAssignmentForfeitRequiresMaxAttempts =>
      'Defina pelo menos 1 tentativa maxima para ativar esta regra.';

  @override
  String get practiceForfeitExitDialogTitle => 'Sair da pratica?';

  @override
  String get practiceForfeitExitDialogMessage =>
      'Se sair agora, contara como uma tentativa usada mesmo sem finalizar o questionario.';

  @override
  String get practiceForfeitExitConfirm => 'Sair e usar tentativa';

  @override
  String get practiceForfeitExitCancel => 'Continuar praticando';

  @override
  String get studentAssignmentAttemptStatusForfeited => 'Saida antecipada';

  @override
  String get studentAssignmentRandomizeLockedShuffled =>
      'Ordem aleatoria definida pelo professor';

  @override
  String get studentAssignmentRandomizeLockedOrdered =>
      'Ordem do questionario definida pelo professor';

  @override
  String get studentAssignmentPracticeOptionsTitle => 'Opcoes de pratica';

  @override
  String get teacherAssignmentCreateAction => 'Criar tarefa';

  @override
  String get teacherAssignmentEditTitle => 'Editar tarefa';

  @override
  String get teacherAssignmentEditAction => 'Editar';

  @override
  String get teacherAssignmentSaveAction => 'Salvar alterações';

  @override
  String get teacherAssignmentTitleRequired => 'O título é obrigatório';

  @override
  String get teacherAssignmentQuizSelectHint => 'Selecionar quiz';

  @override
  String get teacherAssignmentQuizRequiredError => 'Selecione um quiz';

  @override
  String get teacherAssignmentQuizLockedHint =>
      'O quiz não pode ser alterado após a tarefa ser criada.';

  @override
  String get teacherAssignmentMaxAttemptsInvalidError =>
      'Digite um número válido de tentativas';

  @override
  String get teacherAssignmentNotEditableError =>
      'Somente tarefas ativas podem ser editadas.';

  @override
  String get teacherAssignmentMaxAttemptsBelowExistingError =>
      'O máximo de tentativas não pode ser menor que as tentativas já usadas pelos alunos.';

  @override
  String get teacherAssignmentInvalidDateRangeError =>
      'O prazo não pode ser anterior à data de abertura.';

  @override
  String get teacherAssignmentCloseAction => 'Fechar tarefa';

  @override
  String get teacherAssignmentArchiveAction => 'Arquivar';

  @override
  String get teacherAssignmentCloseConfirmTitle => 'Fechar tarefa?';

  @override
  String get teacherAssignmentCloseConfirmMessage =>
      'Os alunos não poderão enviar novas tentativas.';

  @override
  String get teacherAssignmentCompletionTitle => 'Conclusão';

  @override
  String get teacherAssignmentAttemptsTitle => 'Tentativas';

  @override
  String get teacherAssignmentCompletedLabel => 'concluíram';

  @override
  String get teacherAssignmentPendingLabel => 'não enviado';

  @override
  String get teacherAssignmentBestScoreLabel => 'Melhor';

  @override
  String get teacherAssignmentAttemptsLabel => 'tentativas';

  @override
  String get teacherAssignmentDueLabel => 'Encerra';

  @override
  String get teacherAssignmentNoDueDate => 'Sem data limite';

  @override
  String get teacherAssignmentEmpty => 'Sem tarefas ainda.';

  @override
  String get teacherAssignmentFormSubtitle =>
      'Configure datas, tentativas e quando as respostas são reveladas.';

  @override
  String get teacherAssignmentSectionDetails => 'Detalhes';

  @override
  String get teacherAssignmentSectionQuiz => 'Questionário';

  @override
  String get teacherAssignmentSectionSchedule => 'Calendário';

  @override
  String get teacherAssignmentSectionRules => 'Regras';

  @override
  String get teacherAssignmentCreateQuizCtaSubtitle =>
      'Crie aqui e selecione na hora';

  @override
  String get teacherAssignmentSelectQuizAction => 'Escolher dos meus quizzes';

  @override
  String get teacherAssignmentChangeQuizAction => 'Alterar';

  @override
  String get teacherAssignmentQuizDraftWarning =>
      'Este quiz está em rascunho. Publique-o para que os alunos vejam a tarefa.';

  @override
  String get teacherAssignmentNoQuizzesHint =>
      'Você ainda não tem quizzes. Crie um para continuar.';

  @override
  String get teacherAssignmentPickDatePlaceholder => 'Não definido';

  @override
  String get teacherAssignmentDraftContinued =>
      'Continue configurando sua tarefa. O novo quiz já está selecionado.';

  @override
  String get teacherAnalyticsAvgScoreLabel => 'Média de pontos';

  @override
  String get teacherAnalyticsTotalSessionsLabel => 'Sessões totais';

  @override
  String get teacherAnalyticsCompletionRateLabel => 'Conclusão';

  @override
  String get teacherUpgradeHeroTitle =>
      'Transforme seus quizzes em sala de aula';

  @override
  String get teacherUpgradeHeroSubtitle =>
      'Tudo o que você precisa para ensinar, atribuir e acompanhar — em um só lugar.';

  @override
  String get teacherUpgradePriceLabel => '/ mês';

  @override
  String get teacherUpgradePopularBadge => 'O mais escolhido por educadores';

  @override
  String get teacherUpgradePillar1Title => 'Turmas organizadas';

  @override
  String get teacherUpgradePillar1Body =>
      'Crie grupos, convide alunos por e-mail e gerencie o acesso.';

  @override
  String get teacherUpgradePillar2Title => 'Tarefas inteligentes';

  @override
  String get teacherUpgradePillar2Body =>
      'Defina prazos, limite tentativas e controle quando as respostas são reveladas.';

  @override
  String get teacherUpgradePillar3Title => 'Activity Pulse';

  @override
  String get teacherUpgradePillar3Body =>
      'Feed ao vivo de atividade dos alunos, insights automáticos e análises por turma.';

  @override
  String get teacherUpgradeCta => 'Torne-se Professor';

  @override
  String get teacherUpgradeCancelHint =>
      'Cancele quando quiser · Acesso imediato após o pagamento';

  @override
  String get teacherUpgradeSeeAllPlans => 'Ver todos os planos';

  @override
  String get teacherUpgradeAlreadyActive =>
      'Você já tem um plano Professor ativo.';

  @override
  String teacherUpgradeNextRenewal(String date) {
    return 'Próxima renovação: $date';
  }

  @override
  String teacherUpgradeAccessUntil(String date) {
    return 'Acesso até $date (sem renovação automática)';
  }

  @override
  String get teacherUpgradeCancelTitle => 'Cancelar assinatura?';

  @override
  String get teacherUpgradeCancelMessage =>
      'A renovação automática será desativada. Você mantém o plano Professor até o fim do período pago; depois passa para Free.';

  @override
  String get teacherUpgradeCancelConfirm => 'Desativar renovação';

  @override
  String get teacherUpgradeCancelSuccess => 'Assinatura cancelada. Até logo!';

  @override
  String teacherUpgradeCancelSuccessUntil(String date) {
    return 'Renovação automática desativada. Acesso ao plano Professor até $date.';
  }

  @override
  String get billingCancelStoreTitle => 'Gerir assinatura na loja';

  @override
  String get billingCancelStoreMessageGoogle =>
      'As cobranças recorrentes do CraftQuest são geridas no Google Play. Abra as suas assinaturas na Play Store, cancele o CraftQuest e manterá o acesso até ao fim do período pago.';

  @override
  String get billingCancelStoreMessageApple =>
      'As cobranças recorrentes do CraftQuest são geridas na App Store. Abra as suas assinaturas nos Ajustes da Apple, cancele o CraftQuest e manterá o acesso até ao fim do período pago.';

  @override
  String get billingCancelStoreOpenGooglePlay => 'Abrir Google Play';

  @override
  String get billingCancelStoreOpenAppStore => 'Abrir App Store';

  @override
  String get billingCancelStoreSyncTitle => 'Atualizar estado no CraftQuest?';

  @override
  String get billingCancelStoreSyncMessage =>
      'Se já cancelou na loja, pode desativar a renovação no CraftQuest para refletir o fim do período na app. A cobrança só para na loja.';

  @override
  String get billingCancelStoreSyncConfirm => 'Desativar renovação na app';

  @override
  String get billingResumeAutoRenewTitle => 'Reativar renovação automática?';

  @override
  String get billingResumeAutoRenewMessage =>
      'Voltará a ser cobrado no fim do período atual. Mantém o acesso até lá.';

  @override
  String get billingResumeAutoRenewConfirm => 'Reativar renovação';

  @override
  String get billingResumeAutoRenewSuccess => 'Renovação automática reativada.';

  @override
  String billingResumeAutoRenewSuccessUntil(String date) {
    return 'Próxima renovação em $date.';
  }

  @override
  String get billingResumeStoreTitle => 'Reativar assinatura na loja';

  @override
  String get billingResumeStoreMessageGoogle =>
      'Para voltar a cobrar de forma recorrente, reative o CraftQuest no Google Play (Assinaturas). Depois pode sincronizar o estado na app.';

  @override
  String get billingResumeStoreMessageApple =>
      'Para voltar a cobrar de forma recorrente, reative o CraftQuest na App Store (Assinaturas). Depois pode sincronizar o estado na app.';

  @override
  String get billingResumeStoreSyncTitle => 'Atualizar estado no CraftQuest?';

  @override
  String get billingResumeStoreSyncMessage =>
      'Se já reativou a assinatura na loja, confirme aqui para mostrar a próxima renovação na app.';

  @override
  String get billingResumeStoreSyncConfirm => 'Reativar renovação na app';

  @override
  String get billingResumeRequiresResubscribeTitle =>
      'Assinar novamente com PayPal';

  @override
  String get billingResumeRequiresResubscribeMessage =>
      'A renovação no PayPal já foi cancelada. Para manter cobrança automática, crie uma nova assinatura.';

  @override
  String get billingResumeRequiresResubscribeConfirm => 'Assinar novamente';

  @override
  String get teacherUpgradeExpiryWarning =>
      'Seu plano Professor vence em menos de 7 dias. Renove para manter o acesso.';

  @override
  String get homeTeacherBannerTitle => 'Você é professor?';

  @override
  String get homeTeacherBannerBody =>
      'Turmas, tarefas e análises em tempo real.';

  @override
  String get homeTeacherBannerAction => 'Ver plano Professor';

  @override
  String get homeTeacherBannerDismissTooltipWeekly => 'Ocultar nesta semana';

  @override
  String get homeTeacherBannerDismissTooltipMonthly => 'Ocultar neste mês';

  @override
  String get studentAssignmentsTitle => 'Minhas atribuições';

  @override
  String get studentAssignmentsAction => 'Atribuições da turma';

  @override
  String get studentAssignmentsEmpty =>
      'Você ainda não tem atribuições dos seus professores.';

  @override
  String get studentAssignmentStartAction => 'Começar';

  @override
  String get studentAssignmentClosedLabel => 'Encerrada';

  @override
  String get studentAssignmentUnavailableLabel => 'Indisponível';

  @override
  String get studentAssignmentNotYetOpenLabel => 'Em breve';

  @override
  String get studentAssignmentNotYetOpenError =>
      'Esta atribuição ainda não está disponível. Verifique a data de abertura.';

  @override
  String get studentAssignmentPastDueLabel => 'Prazo encerrado';

  @override
  String get studentAssignmentMaxAttemptsLabel => 'Sem tentativas';

  @override
  String get studentAssignmentAvailableNowLabel => 'Disponível agora';

  @override
  String studentAssignmentAttemptsSummary(int used, int max) {
    return '$used de $max tentativas';
  }

  @override
  String get studentAssignmentMyAttemptsAction => 'Minhas tentativas';

  @override
  String get studentAssignmentMyAttemptsTitle => 'Minhas tentativas';

  @override
  String get studentAssignmentMyAttemptsEmpty =>
      'Você ainda não completou nenhuma tentativa nesta tarefa.';

  @override
  String get studentAssignmentAttemptScoreOnlyHint =>
      'Somente pontuação — as respostas corretas não estão disponíveis conforme a configuração do professor.';

  @override
  String studentAssignmentAttemptsHeaderSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentativas registradas',
      one: '1 tentativa registrada',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentAttemptBestScore(String percent) {
    return 'Melhor resultado: $percent%';
  }

  @override
  String get studentAssignmentAttemptStatusFinished => 'Concluída';

  @override
  String get studentAssignmentAttemptScoreOnlyBadge => 'Somente pontuação';

  @override
  String get studentAssignmentAttemptReviewAvailable => 'Ver respostas';

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
  String get studentAssignmentsFilterPending => 'Pendentes';

  @override
  String get studentAssignmentsSearchHint => 'Buscar tarefa ou turma';

  @override
  String studentAssignmentsSummaryTodoOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pendentes',
      one: '1 pendente',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentsSummaryDueTodayOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vencem hoje',
      one: '1 vence hoje',
    );
    return '$_temp0';
  }

  @override
  String studentAssignmentsSummaryCombined(String todo, String dueToday) {
    return '$todo · $dueToday';
  }

  @override
  String get studentAssignmentsSummaryAllDone =>
      'Você não tem tarefas pendentes no momento.';

  @override
  String studentAssignmentsClassGroupSubtitle(String teacher, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarefas',
      one: '1 tarefa',
    );
    return '$teacher · $_temp0';
  }

  @override
  String get studentAssignmentsEmptyFiltered =>
      'Nenhuma tarefa corresponde a este filtro.';

  @override
  String studentAssignmentRowSubtitleDue(String date, String attemptsSuffix) {
    return 'Vence $date$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleDueToday(String attemptsSuffix) {
    return 'Vence hoje$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleAvailable(String attemptsSuffix) {
    return 'Disponível$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleNoDue(String attemptsSuffix) {
    return 'Sem data limite$attemptsSuffix';
  }

  @override
  String studentAssignmentRowSubtitleNotYetOpen(String date) {
    return 'Abre $date';
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
  String get studentAssignmentStatusBadgeAvailable => 'Disponível';

  @override
  String get studentAssignmentDetailTitle => 'Detalhes da tarefa';

  @override
  String subscriptionPlanActive(String planName) {
    return 'Plano $planName ativo.';
  }

  @override
  String get profileProPlanSectionTitle => 'Plano Pro';

  @override
  String get profileProPlanManageTitle => 'Gerenciar plano Pro';

  @override
  String get profileProPlanActiveSubtitle =>
      'Plano ativo · toque para gerenciar';

  @override
  String get profileProPlanInactiveSubtitle =>
      'Quizzes ilimitados e mais · Assinatura mensal ou anual';

  @override
  String get profileTeacherPlanSectionTitle => 'Plano Professor';

  @override
  String get profileTeacherPlanManageTitle => 'Gerenciar plano Professor';

  @override
  String get profileTeacherPlanActiveSubtitle =>
      'Plano ativo · toque para gerenciar';

  @override
  String get profileTeacherPlanInactiveSubtitle =>
      'Turmas, tarefas e análises · Assinatura mensal';

  @override
  String get profilePaymentHistorySectionTitle => 'Pagamentos';

  @override
  String get profilePaymentHistoryAction => 'Historico de transacoes';

  @override
  String get profilePaymentHistorySubtitle =>
      'Assinaturas, Preparacao+ e outros pagamentos';

  @override
  String get paymentHistoryTitle => 'Historico de pagamentos';

  @override
  String get paymentHistoryEmpty =>
      'Ainda nao ha transacoes registadas na sua conta.';

  @override
  String paymentHistoryAmount(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get paymentPurchaseStatusValidated => 'Concluido';

  @override
  String get paymentPurchaseStatusPending => 'Pendente';

  @override
  String get paymentPurchaseStatusRejected => 'Rejeitado';

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
  String get paymentProviderOther => 'Outro';

  @override
  String get paymentProductTypeSubscription => 'Assinatura';

  @override
  String get paymentProductTypePrepAccess => 'Preparacao+';

  @override
  String get paymentProductTypeAiCredits => 'Creditos IA';

  @override
  String get paymentProductTypeShareCodes => 'Codigos partilhados';

  @override
  String get paymentProductTypeCuratedPackage => 'Pacote';

  @override
  String get paymentProductTypeTeacherSeats => 'Lugares professor';

  @override
  String get paymentProductTypeOther => 'Outro';

  @override
  String get teacherUpgradeKeepPlan => 'Não, manter';

  @override
  String get teacherOnboardingWelcomeTitle => 'Bem-vindo, Professor!';

  @override
  String teacherOnboardingStepProgress(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get teacherOnboardingStep1Title => 'Crie sua primeira turma';

  @override
  String get teacherOnboardingStep1Body =>
      'As turmas permitem organizar alunos e atribuir quizzes com acompanhamento personalizado.';

  @override
  String get teacherOnboardingClassNameLabel => 'Nome da turma';

  @override
  String get teacherOnboardingClassNameHint => 'Ex. Matemática — Grupo A';

  @override
  String get teacherOnboardingCreateClassAction => 'Criar turma e continuar';

  @override
  String get teacherOnboardingStep2Title => 'Convide seu primeiro aluno';

  @override
  String get teacherOnboardingStep2Body =>
      'Digite o e-mail de um aluno registrado para adicioná-lo à turma. Você também pode fazer isso depois.';

  @override
  String get teacherOnboardingStudentEmailLabel => 'E-mail do aluno';

  @override
  String get teacherOnboardingStudentEmailHint => 'aluno@email.com';

  @override
  String get teacherOnboardingInviteAction => 'Convidar e continuar';

  @override
  String get teacherOnboardingSkipAction => 'Pular por agora';

  @override
  String get teacherOnboardingStep3Title => 'Tudo pronto!';

  @override
  String get teacherOnboardingStep3Body =>
      'Sua sala de aula está configurada. Agora você pode criar tarefas, acompanhar o progresso dos alunos e analisar resultados no Activity Pulse.';

  @override
  String get teacherOnboardingGoToDashboardAction =>
      'Ir ao Painel do Professor';

  @override
  String get prepAdminProfileSectionTitle => 'Administração';

  @override
  String get prepAdminProfileAction => 'Preparação+ (catálogo)';

  @override
  String get prepAdminProfileSubtitle =>
      'Categorias, itens, preços e publicação';

  @override
  String get prepAdminHubTitle => 'Admin Preparação+';

  @override
  String get prepAdminHubSubtitle =>
      'Gerencie o catálogo B2C curado da plataforma.';

  @override
  String get prepAdminCategoriesAction => 'Categorias';

  @override
  String get prepAdminCategoriesSubtitle => 'Países, regiões e Internacional';

  @override
  String get prepAdminCatalogAction => 'Itens do catálogo';

  @override
  String get prepAdminCatalogSubtitle => 'Questionários, ofertas e amostras';

  @override
  String get prepAdminCategoriesTitle => 'Categorias Prep+';

  @override
  String get prepAdminAddRootCategory => 'Categoria raiz';

  @override
  String get prepAdminAddSubcategory => 'Subcategoria';

  @override
  String get prepAdminEditCategoryTitle => 'Editar categoria';

  @override
  String get prepAdminDeleteCategoryTitle => 'Excluir categoria?';

  @override
  String prepAdminDeleteCategoryMessage(String name) {
    return '«$name» e suas subcategorias serão removidas se não tiverem itens.';
  }

  @override
  String get prepAdminCategoryDeleted => 'Categoria excluída';

  @override
  String get prepAdminCategorySaved => 'Categoria salva';

  @override
  String get prepAdminActive => 'Ativa';

  @override
  String get prepAdminInactive => 'Inativa';

  @override
  String get prepAdminCategoryTypeLabel => 'Tipo';

  @override
  String get prepAdminCategoryTypeGeographic => 'Geográfica (país)';

  @override
  String get prepAdminCategoryTypeThematic => 'Temática (Internacional)';

  @override
  String get prepAdminNameLabel => 'Nome';

  @override
  String get prepAdminSlugLabel => 'Slug (URL)';

  @override
  String get prepAdminRequiredField => 'Campo obrigatório';

  @override
  String get prepAdminDescriptionLabel => 'Descrição';

  @override
  String get prepAdminCountryCodeLabel => 'Código do país (ISO)';

  @override
  String get prepAdminIconKeyLabel => 'Ícone (chave)';

  @override
  String get prepAdminSortOrderLabel => 'Ordem';

  @override
  String get prepAdminCatalogTitle => 'Catálogo Prep+';

  @override
  String get prepAdminNewCatalogItem => 'Novo item';

  @override
  String get prepAdminPublishedFilter => 'Publicados';

  @override
  String get prepAdminDraftFilter => 'Rascunhos';

  @override
  String get prepAdminCatalogEmpty => 'Não há itens no catálogo.';

  @override
  String prepAdminItemSummarySubtitle(
    String category,
    int questions,
    int offers,
    int samples,
    String status,
  ) {
    return '$category · $questions perg. · $offers ofertas · $samples amostras · $status';
  }

  @override
  String get prepAdminEditItemTitle => 'Editar item';

  @override
  String get prepAdminMetadataSection => 'Metadados';

  @override
  String get prepAdminOffersSection => 'Matriz de preços';

  @override
  String get prepAdminSamplesSection => 'Perguntas amostra';

  @override
  String get prepAdminPublishSection => 'Publicação';

  @override
  String get prepAdminQuizIdLabel => 'ID do questionário';

  @override
  String get prepAdminQuizIdHint => 'GUID do quiz existente na plataforma';

  @override
  String get prepAdminQuizIdRequired => 'Informe o ID do questionário';

  @override
  String get prepAdminQuizSearchLabel => 'Buscar questionário';

  @override
  String get prepAdminSelectQuizLabel => 'Questionário';

  @override
  String get prepAdminSelectQuizHint =>
      'Apenas questionários criados por administradores de conteúdo, ainda não no catálogo.';

  @override
  String get prepAdminSelectQuizError => 'Selecione um questionário.';

  @override
  String get prepAdminLinkableQuizzesEmpty =>
      'Não há questionários disponíveis. Crie um com conta admin ou remova os que já estão no catálogo.';

  @override
  String prepAdminLinkableQuizOption(String title, int count, String author) {
    return '$title · $count perg. · $author';
  }

  @override
  String get prepAdminSubcategoryLabel => 'Subcategoria';

  @override
  String get prepAdminSelectCategoryError => 'Selecione uma subcategoria';

  @override
  String get prepAdminTitleOverrideLabel => 'Título no catálogo (opcional)';

  @override
  String get prepAdminTagsLabel => 'Etiquetas';

  @override
  String get prepAdminTagsHint => 'Separadas por vírgulas';

  @override
  String get prepAdminListingStartLabel => 'Início da venda';

  @override
  String get prepAdminListingEndLabel => 'Fim da venda';

  @override
  String get prepAdminOptionalDate => 'Não definido';

  @override
  String get prepAdminCreateItemAction => 'Criar item';

  @override
  String get prepAdminSaveMetadataAction => 'Salvar metadados';

  @override
  String get prepAdminSaveOffersAction => 'Salvar preços';

  @override
  String get prepAdminPickSamplesAction => 'Escolher 3 perguntas';

  @override
  String get prepAdminSamplesEmpty => 'Ainda não há perguntas amostra.';

  @override
  String get prepAdminPublishAction => 'Publicar no catálogo';

  @override
  String get prepAdminUnpublishAction => 'Despublicar';

  @override
  String get prepAdminDeleteItemAction => 'Excluir item';

  @override
  String get prepAdminDeleteItemTitle => 'Excluir item do catálogo?';

  @override
  String get prepAdminDeleteItemMessage =>
      'O item deixará de aparecer. Os acessos já comprados permanecem no histórico.';

  @override
  String get prepAdminItemCreated => 'Item criado';

  @override
  String get prepAdminMetadataSaved => 'Metadados salvos';

  @override
  String get prepAdminOffersRequired => 'Ative pelo menos uma oferta de acesso';

  @override
  String get prepAdminOffersSaved => 'Preços salvos';

  @override
  String get prepAdminSamplesSaved => 'Amostras salvas';

  @override
  String get prepAdminPublished => 'Publicado no catálogo';

  @override
  String get prepAdminUnpublished => 'Despublicado';

  @override
  String get prepAdminItemDeleted => 'Item excluído';

  @override
  String prepAdminLinkedQuiz(String title) {
    return 'Questionário: $title';
  }

  @override
  String prepAdminOffersChip(int count) {
    return '$count ofertas ativas';
  }

  @override
  String prepAdminSamplesChip(int count) {
    return '$count/3 amostras';
  }

  @override
  String get prepAdminOfferFreeLabel => 'Acesso grátis';

  @override
  String get prepAdminOfferPriceLabel => 'Preço';

  @override
  String get prepAdminOfferCurrencyLabel => 'Moeda';

  @override
  String get prepAdminStoreProductIdLabel => 'ID produto loja (IAP)';

  @override
  String get prepAdminSamplesLoadError =>
      'Não foi possível carregar as perguntas';

  @override
  String get prepAdminSamplesCountError => 'Selecione exatamente 3 perguntas';

  @override
  String get prepAdminSamplesPickerTitle => 'Perguntas amostra';

  @override
  String prepAdminSamplesPickerSubtitle(int selected, int required) {
    return '$selected de $required selecionadas';
  }

  @override
  String get errorPrepCategoryNotFound => 'Categoria não encontrada.';

  @override
  String get errorPrepCategoryHasSubcategories =>
      'Não é possível excluir: há subcategorias ativas.';

  @override
  String get errorPrepCategoryHasItems =>
      'Não é possível excluir: há itens no catálogo.';

  @override
  String get errorPrepQuizNotFound => 'Questionário não encontrado.';

  @override
  String get errorPrepQuizNotEligible =>
      'Só podem ser adicionados questionários criados por um administrador de conteúdo.';

  @override
  String get errorPrepQuizAlreadyInCatalog =>
      'Este questionário já está na Preparação+.';

  @override
  String get errorPrepCatalogItemNotFound => 'Item do catálogo não encontrado.';

  @override
  String errorPrepSampleCountRequired(int count) {
    return 'São necessárias exatamente $count perguntas amostra.';
  }

  @override
  String get errorPrepSampleQuestionsNotInQuiz =>
      'As perguntas amostra devem pertencer ao questionário vinculado.';

  @override
  String get errorPrepInvalidCategoryType => 'Tipo de categoria inválido.';

  @override
  String get errorPrepNameSlugRequired => 'Nome e slug são obrigatórios.';

  @override
  String get errorPrepParentCategoryNotFound => 'Categoria pai não encontrada.';

  @override
  String get errorPrepSubcategoryTypeMismatch =>
      'O tipo da subcategoria deve coincidir com o pai.';

  @override
  String get errorPrepCategorySelfParent =>
      'Uma categoria não pode ser seu próprio pai.';

  @override
  String get errorPrepSlugDuplicate => 'Esse slug já existe neste nível.';

  @override
  String get errorPrepCategoryInactive =>
      'Categoria não encontrada ou inativa.';

  @override
  String get errorPrepItemRequiresSubcategory =>
      'O item deve ser atribuído a uma subcategoria, não a uma raiz.';

  @override
  String get errorPrepInstitutionTagGeographicOnly =>
      'A etiqueta de instituição só se aplica a categorias geográficas.';

  @override
  String get errorPrepCategoryHierarchyBroken =>
      'A hierarquia de categorias está incompleta.';

  @override
  String get errorPrepOffersRequired =>
      'É necessária pelo menos uma oferta de acesso.';

  @override
  String get errorPrepInvalidDuration =>
      'Duração inválida. Permitidas: 30, 60, 90 e 183 dias.';

  @override
  String get errorPrepPriceNegative => 'O preço não pode ser negativo.';

  @override
  String get errorPrepOfferDurationDuplicate =>
      'Há durações duplicadas nas ofertas.';

  @override
  String get errorPrepActiveOfferRequiredPublish =>
      'Ative pelo menos uma oferta antes de publicar.';

  @override
  String errorPrepSamplesRequiredPublish(int count) {
    return 'Configure exatamente $count perguntas amostra antes de publicar.';
  }

  @override
  String get errorPrepQuizNoQuestions =>
      'O questionário vinculado deve ter pelo menos uma pergunta.';

  @override
  String get errorPrepListingEndBeforeStart =>
      'A data de fim da venda deve ser posterior ao início.';

  @override
  String get errorPrepPreviewNotAvailable =>
      'A pré-visualização não está disponível para este item.';

  @override
  String get errorPrepItemNotAvailable =>
      'Este item não está disponível para compra no momento.';

  @override
  String get errorPrepOfferNotFound => 'Oferta não encontrada.';

  @override
  String get errorPrepOfferIsFree =>
      'Esta oferta é grátis. Use o checkout sem pagamento.';

  @override
  String get errorPrepPayPalPurchaseNotFound =>
      'Compra PayPal da Preparação+ não encontrada.';

  @override
  String get errorPrepMobilePlatformInvalid =>
      'A plataforma deve ser google_play ou app_store.';

  @override
  String get errorPrepStoreProductMismatch =>
      'O produto da loja não coincide com esta oferta.';

  @override
  String get errorPrepOfferNoLongerExists => 'A oferta já não existe.';

  @override
  String get errorPrepInvalidProductCode =>
      'Código de produto de compra inválido.';

  @override
  String get errorPrepGooglePlayNotConfigured =>
      'Google Play não está configurado no servidor.';

  @override
  String get errorPrepAppStoreNotConfigured =>
      'App Store não está configurado. Use pagamentos mock em desenvolvimento.';
}
