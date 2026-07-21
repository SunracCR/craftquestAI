
/*
CraftQuest MVP Completo v4 - Azure SQL DDL
Version: 4.0
Decision central: las respuestas reales son IDs estables (AnswerOptionId).
Las letras A/B/C/D son etiquetas visuales generadas por intento y guardadas en snapshots.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core') EXEC('CREATE SCHEMA core');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'billing') EXEC('CREATE SCHEMA billing');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'content') EXEC('CREATE SCHEMA content');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'quiz') EXEC('CREATE SCHEMA quiz');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'importing') EXEC('CREATE SCHEMA importing');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ai') EXEC('CREATE SCHEMA ai');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'teacher') EXEC('CREATE SCHEMA teacher');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sharing') EXEC('CREATE SCHEMA sharing');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'practice') EXEC('CREATE SCHEMA practice');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'analytics') EXEC('CREATE SCHEMA analytics');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit') EXEC('CREATE SCHEMA audit');
GO

/* =========================
   CORE
========================= */

IF OBJECT_ID('core.Users', 'U') IS NULL
CREATE TABLE core.Users (
    UserId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Users PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    ExternalSubject NVARCHAR(200) NULL,
    Email NVARCHAR(320) NOT NULL,
    EmailNormalized AS UPPER(Email) PERSISTED,
    PasswordHash VARBINARY(MAX) NULL,
    DisplayName NVARCHAR(160) NULL,
    PhotoUrl NVARCHAR(1000) NULL,
    CountryCode NVARCHAR(10) NULL,
    PhoneNumber NVARCHAR(40) NULL,
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Users_Status DEFAULT('active'),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    DeletedAt DATETIME2(7) NULL,
    CONSTRAINT UQ_Users_EmailNormalized UNIQUE (EmailNormalized),
    CONSTRAINT CK_Users_Status CHECK (Status IN ('active','suspended','deleted'))
);
GO

IF OBJECT_ID('core.Roles', 'U') IS NULL
CREATE TABLE core.Roles (
    RoleId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Roles_Code UNIQUE (Code)
);
GO

IF OBJECT_ID('core.UserRoles', 'U') IS NULL
CREATE TABLE core.UserRoles (
    UserId UNIQUEIDENTIFIER NOT NULL,
    RoleId INT NOT NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_UserRoles_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES core.Users(UserId),
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES core.Roles(RoleId)
);
GO

IF OBJECT_ID('core.AuthProviders', 'U') IS NULL
CREATE TABLE core.AuthProviders (
    AuthProviderId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AuthProviders PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    ProviderCode NVARCHAR(50) NOT NULL,
    ProviderSubject NVARCHAR(300) NOT NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_AuthProviders_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_AuthProviders_Users FOREIGN KEY (UserId) REFERENCES core.Users(UserId),
    CONSTRAINT UQ_AuthProviders_ProviderSubject UNIQUE (ProviderCode, ProviderSubject),
    CONSTRAINT CK_AuthProviders_ProviderCode CHECK (ProviderCode IN ('email','google','apple'))
);
GO

/* =========================
   BILLING, PLANS AND CREDITS
========================= */

IF OBJECT_ID('billing.Plans', 'U') IS NULL
CREATE TABLE billing.Plans (
    PlanId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Plans PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    MonthlyPrice DECIMAL(12,2) NULL,
    AnnualPrice DECIMAL(12,2) NULL,
    MaxQuizzes INT NULL,
    MaxQuestionsPerQuiz INT NULL,
    MaxQuestionsPerAiGeneration INT NULL,
    MonthlyAiCredits INT NOT NULL CONSTRAINT DF_Plans_MonthlyAiCredits DEFAULT(0),
    MonthlyShareCodes INT NOT NULL CONSTRAINT DF_Plans_MonthlyShareCodes DEFAULT(0),
    IsTeacherPlan BIT NOT NULL CONSTRAINT DF_Plans_IsTeacherPlan DEFAULT(0),
    IsInstitutionPlan BIT NOT NULL CONSTRAINT DF_Plans_IsInstitutionPlan DEFAULT(0),
    IsActive BIT NOT NULL CONSTRAINT DF_Plans_IsActive DEFAULT(1),
    CONSTRAINT UQ_Plans_Code UNIQUE (Code)
);
GO

IF OBJECT_ID('billing.UserSubscriptions', 'U') IS NULL
CREATE TABLE billing.UserSubscriptions (
    UserSubscriptionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_UserSubscriptions PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    PlanId INT NOT NULL,
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_UserSubscriptions_Status DEFAULT('active'),
    StartedAt DATETIME2(7) NOT NULL CONSTRAINT DF_UserSubscriptions_StartedAt DEFAULT SYSUTCDATETIME(),
    EndsAt DATETIME2(7) NULL,
    ProviderCode NVARCHAR(50) NULL,
    ProviderSubscriptionId NVARCHAR(300) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_UserSubscriptions_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_UserSubscriptions_Users FOREIGN KEY (UserId) REFERENCES core.Users(UserId),
    CONSTRAINT FK_UserSubscriptions_Plans FOREIGN KEY (PlanId) REFERENCES billing.Plans(PlanId),
    CONSTRAINT CK_UserSubscriptions_Status CHECK (Status IN ('active','expired','cancelled','past_due','trial'))
);
GO

IF OBJECT_ID('billing.Purchases', 'U') IS NULL
CREATE TABLE billing.Purchases (
    PurchaseId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Purchases PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    ProductCode NVARCHAR(100) NOT NULL,
    ProductType NVARCHAR(40) NOT NULL,
    ProviderCode NVARCHAR(50) NOT NULL,
    ProviderTransactionId NVARCHAR(300) NULL,
    Amount DECIMAL(12,2) NULL,
    CurrencyCode NVARCHAR(10) NULL,
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Purchases_Status DEFAULT('pending'),
    PurchasedAt DATETIME2(7) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Purchases_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Purchases_Users FOREIGN KEY (UserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_Purchases_ProductType CHECK (ProductType IN ('subscription','ai_credits','share_codes','curated_package','teacher_seats')),
    CONSTRAINT CK_Purchases_Status CHECK (Status IN ('pending','validated','rejected','refunded','cancelled'))
);
GO

IF OBJECT_ID('billing.CreditLedger', 'U') IS NULL
CREATE TABLE billing.CreditLedger (
    CreditLedgerId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_CreditLedger PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    CreditType NVARCHAR(40) NOT NULL,
    Delta INT NOT NULL,
    BalanceAfter INT NULL,
    Reason NVARCHAR(100) NOT NULL,
    ReferenceType NVARCHAR(80) NULL,
    ReferenceId UNIQUEIDENTIFIER NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_CreditLedger_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_CreditLedger_Users FOREIGN KEY (UserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_CreditLedger_CreditType CHECK (CreditType IN ('ai','ai_purchased','share_code','teacher_seat')),
    CONSTRAINT CK_CreditLedger_Reason CHECK (Reason IN ('grant_plan','purchase','consume','refund','admin_adjustment','monthly_reset'))
);
GO

/* =========================
   CONTENT AND FILES
========================= */

IF OBJECT_ID('content.MediaAssets', 'U') IS NULL
CREATE TABLE content.MediaAssets (
    MediaAssetId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_MediaAssets PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UploadedByUserId UNIQUEIDENTIFIER NOT NULL,
    StorageProvider NVARCHAR(40) NOT NULL CONSTRAINT DF_MediaAssets_StorageProvider DEFAULT('azure_blob'),
    ContainerName NVARCHAR(120) NOT NULL,
    BlobPath NVARCHAR(1000) NOT NULL,
    OriginalFileName NVARCHAR(260) NOT NULL,
    ContentType NVARCHAR(120) NULL,
    FileExtension NVARCHAR(20) NULL,
    FileSizeBytes BIGINT NULL,
    Sha256Hash NVARCHAR(128) NULL,
    AltText NVARCHAR(500) NULL,
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_MediaAssets_Status DEFAULT('active'),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_MediaAssets_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_MediaAssets_Users FOREIGN KEY (UploadedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_MediaAssets_Status CHECK (Status IN ('active','quarantined','deleted'))
);
GO

IF OBJECT_ID('content.StudyMaterials', 'U') IS NULL
CREATE TABLE content.StudyMaterials (
    StudyMaterialId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_StudyMaterials PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UploadedByUserId UNIQUEIDENTIFIER NOT NULL,
    MediaAssetId UNIQUEIDENTIFIER NULL,
    OriginalText NVARCHAR(MAX) NULL,
    FileType NVARCHAR(50) NOT NULL,
    ProcessingStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_StudyMaterials_Status DEFAULT('pending'),
    GeneratedQuizId UNIQUEIDENTIFIER NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_StudyMaterials_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_StudyMaterials_Users FOREIGN KEY (UploadedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT FK_StudyMaterials_MediaAssets FOREIGN KEY (MediaAssetId) REFERENCES content.MediaAssets(MediaAssetId),
    CONSTRAINT CK_StudyMaterials_FileType CHECK (FileType IN ('pdf','docx','txt','image','xlsx','csv','json','zip','raw_text')),
    CONSTRAINT CK_StudyMaterials_ProcessingStatus CHECK (ProcessingStatus IN ('pending','processing','completed','failed'))
);
GO

/* =========================
   QUIZZES, QUESTIONS AND ANSWERS
========================= */

IF OBJECT_ID('quiz.Quizzes', 'U') IS NULL
CREATE TABLE quiz.Quizzes (
    QuizId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Quizzes PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    CreatedByUserId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(220) NOT NULL,
    Description NVARCHAR(1000) NULL,
    Visibility NVARCHAR(40) NOT NULL CONSTRAINT DF_Quizzes_Visibility DEFAULT('private'),
    PublicationStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_Quizzes_PublicationStatus DEFAULT('draft'),
    DefaultQuestionPoints DECIMAL(10,2) NOT NULL CONSTRAINT DF_Quizzes_DefaultQuestionPoints DEFAULT(1),
    RandomizeQuestions BIT NOT NULL CONSTRAINT DF_Quizzes_RandomizeQuestions DEFAULT(0),
    DefaultRandomizeAnswerOptions BIT NOT NULL CONSTRAINT DF_Quizzes_DefaultRandomizeAnswers DEFAULT(1),
    IsCurated BIT NOT NULL CONSTRAINT DF_Quizzes_IsCurated DEFAULT(0),
    TargetCountryCode NVARCHAR(10) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Quizzes_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    DeletedAt DATETIME2(7) NULL,
    CONSTRAINT FK_Quizzes_Users FOREIGN KEY (CreatedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_Quizzes_Visibility CHECK (Visibility IN ('private','shared_by_code','class_only','public','curated')),
    CONSTRAINT CK_Quizzes_PublicationStatus CHECK (PublicationStatus IN ('draft','review','published','archived','deleted'))
);
GO

IF OBJECT_ID('quiz.QuizSections', 'U') IS NULL
CREATE TABLE quiz.QuizSections (
    QuizSectionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuizSections PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuizId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(160) NOT NULL,
    SortOrder INT NOT NULL CONSTRAINT DF_QuizSections_SortOrder DEFAULT(0),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuizSections_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_QuizSections_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT UQ_QuizSections_Name UNIQUE (QuizId, Name)
);
GO

IF OBJECT_ID('quiz.QuestionTypes', 'U') IS NULL
CREATE TABLE quiz.QuestionTypes (
    QuestionTypeId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_QuestionTypes PRIMARY KEY,
    Code NVARCHAR(60) NOT NULL,
    Name NVARCHAR(120) NOT NULL,
    Description NVARCHAR(500) NULL,
    SupportsMultipleCorrectAnswers BIT NOT NULL CONSTRAINT DF_QuestionTypes_SupportsMultiple DEFAULT(0),
    SupportsImages BIT NOT NULL CONSTRAINT DF_QuestionTypes_SupportsImages DEFAULT(0),
    RequiresOptions BIT NOT NULL CONSTRAINT DF_QuestionTypes_RequiresOptions DEFAULT(1),
    IsActive BIT NOT NULL CONSTRAINT DF_QuestionTypes_IsActive DEFAULT(1),
    CONSTRAINT UQ_QuestionTypes_Code UNIQUE (Code)
);
GO

IF OBJECT_ID('quiz.Questions', 'U') IS NULL
CREATE TABLE quiz.Questions (
    QuestionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Questions PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuizId UNIQUEIDENTIFIER NOT NULL,
    QuizSectionId UNIQUEIDENTIFIER NULL,
    QuestionTypeId INT NOT NULL,
    QuestionText NVARCHAR(MAX) NOT NULL,
    Points DECIMAL(10,2) NOT NULL CONSTRAINT DF_Questions_Points DEFAULT(1),
    SortOrder INT NOT NULL CONSTRAINT DF_Questions_SortOrder DEFAULT(0),
    Difficulty NVARCHAR(30) NULL,
    ExplanationVisibility NVARCHAR(40) NOT NULL CONSTRAINT DF_Questions_ExplanationVisibility DEFAULT('after_quiz'),
    RandomizeAnswerOptions BIT NOT NULL CONSTRAINT DF_Questions_RandomizeAnswerOptions DEFAULT(1),
    ScoringPolicy NVARCHAR(40) NOT NULL CONSTRAINT DF_Questions_ScoringPolicy DEFAULT('strict'),
    ReviewStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_Questions_ReviewStatus DEFAULT('approved'),
    IsGeneratedByAi BIT NOT NULL CONSTRAINT DF_Questions_IsGeneratedByAi DEFAULT(0),
    CreatedByUserId UNIQUEIDENTIFIER NOT NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Questions_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    DeletedAt DATETIME2(7) NULL,
    CONSTRAINT FK_Questions_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT FK_Questions_QuizSections FOREIGN KEY (QuizSectionId) REFERENCES quiz.QuizSections(QuizSectionId),
    CONSTRAINT FK_Questions_QuestionTypes FOREIGN KEY (QuestionTypeId) REFERENCES quiz.QuestionTypes(QuestionTypeId),
    CONSTRAINT FK_Questions_Users FOREIGN KEY (CreatedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_Questions_Difficulty CHECK (Difficulty IS NULL OR Difficulty IN ('easy','medium','hard')),
    CONSTRAINT CK_Questions_ExplanationVisibility CHECK (ExplanationVisibility IN ('never','after_answer','after_quiz','teacher_only')),
    CONSTRAINT CK_Questions_ScoringPolicy CHECK (ScoringPolicy IN ('strict','partial_future')),
    CONSTRAINT CK_Questions_ReviewStatus CHECK (ReviewStatus IN ('draft','needs_review','approved','rejected','archived'))
);
GO

/* 
QuestionAnswerOptions replaces any model where options contain IsCorrect.
Correct answers live in quiz.QuestionCorrectAnswerOptions.
StableKey is used for imports and CQIF; AnswerOptionId is the source of truth after creation.
*/
IF OBJECT_ID('quiz.QuestionAnswerOptions', 'U') IS NULL
CREATE TABLE quiz.QuestionAnswerOptions (
    AnswerOptionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuestionAnswerOptions PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    StableKey NVARCHAR(100) NOT NULL,
    AnswerText NVARCHAR(MAX) NULL,
    MediaAssetId UNIQUEIDENTIFIER NULL,
    DefaultSortOrder INT NOT NULL CONSTRAINT DF_QuestionAnswerOptions_DefaultSortOrder DEFAULT(0),
    IsActive BIT NOT NULL CONSTRAINT DF_QuestionAnswerOptions_IsActive DEFAULT(1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionAnswerOptions_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT FK_QuestionAnswerOptions_Questions FOREIGN KEY (QuestionId) REFERENCES quiz.Questions(QuestionId),
    CONSTRAINT FK_QuestionAnswerOptions_MediaAssets FOREIGN KEY (MediaAssetId) REFERENCES content.MediaAssets(MediaAssetId),
    CONSTRAINT UQ_QuestionAnswerOptions_StableKey UNIQUE (QuestionId, StableKey),
    CONSTRAINT UQ_QuestionAnswerOptions_QuestionAnswer UNIQUE (QuestionId, AnswerOptionId)
);
GO

IF OBJECT_ID('quiz.QuestionCorrectAnswerOptions', 'U') IS NULL
CREATE TABLE quiz.QuestionCorrectAnswerOptions (
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    AnswerOptionId UNIQUEIDENTIFIER NOT NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionCorrectAnswerOptions_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_QuestionCorrectAnswerOptions PRIMARY KEY (QuestionId, AnswerOptionId),
    CONSTRAINT FK_QuestionCorrectAnswerOptions_Questions FOREIGN KEY (QuestionId) REFERENCES quiz.Questions(QuestionId),
    CONSTRAINT FK_QuestionCorrectAnswerOptions_AnswerOptions FOREIGN KEY (QuestionId, AnswerOptionId)
        REFERENCES quiz.QuestionAnswerOptions(QuestionId, AnswerOptionId)
);
GO

IF OBJECT_ID('quiz.QuestionMedia', 'U') IS NULL
CREATE TABLE quiz.QuestionMedia (
    QuestionMediaId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuestionMedia PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    MediaAssetId UNIQUEIDENTIFIER NOT NULL,
    RoleCode NVARCHAR(40) NOT NULL,
    SortOrder INT NOT NULL CONSTRAINT DF_QuestionMedia_SortOrder DEFAULT(0),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionMedia_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_QuestionMedia_Questions FOREIGN KEY (QuestionId) REFERENCES quiz.Questions(QuestionId),
    CONSTRAINT FK_QuestionMedia_MediaAssets FOREIGN KEY (MediaAssetId) REFERENCES content.MediaAssets(MediaAssetId),
    CONSTRAINT CK_QuestionMedia_RoleCode CHECK (RoleCode IN ('question_image','explanation_image','source_image'))
);
GO

IF OBJECT_ID('quiz.QuestionJustifications', 'U') IS NULL
CREATE TABLE quiz.QuestionJustifications (
    QuestionJustificationId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuestionJustifications PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    JustificationText NVARCHAR(MAX) NULL,
    Status NVARCHAR(40) NOT NULL CONSTRAINT DF_QuestionJustifications_Status DEFAULT('missing'),
    GeneratedByAi BIT NOT NULL CONSTRAINT DF_QuestionJustifications_GeneratedByAi DEFAULT(0),
    ReviewedByUserId UNIQUEIDENTIFIER NULL,
    ReviewedAt DATETIME2(7) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionJustifications_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT FK_QuestionJustifications_Questions FOREIGN KEY (QuestionId) REFERENCES quiz.Questions(QuestionId),
    CONSTRAINT FK_QuestionJustifications_ReviewedBy FOREIGN KEY (ReviewedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_QuestionJustifications_Status CHECK (Status IN ('not_required','missing','ai_generated','needs_review','approved','rejected'))
);
GO

IF OBJECT_ID('quiz.QuestionJustificationSources', 'U') IS NULL
CREATE TABLE quiz.QuestionJustificationSources (
    JustificationSourceId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuestionJustificationSources PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuestionJustificationId UNIQUEIDENTIFIER NOT NULL,
    SourceTitle NVARCHAR(500) NULL,
    SourceUrl NVARCHAR(1500) NOT NULL,
    SourceProvider NVARCHAR(100) NULL,
    Snippet NVARCHAR(1000) NULL,
    RetrievedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionJustificationSources_RetrievedAt DEFAULT SYSUTCDATETIME(),
    IsPrimary BIT NOT NULL CONSTRAINT DF_QuestionJustificationSources_IsPrimary DEFAULT(0),
    CONSTRAINT FK_QuestionJustificationSources_Justifications FOREIGN KEY (QuestionJustificationId) REFERENCES quiz.QuestionJustifications(QuestionJustificationId)
);
GO

/* =========================
   TEACHER, CLASSES AND SHARING
========================= */

IF OBJECT_ID('teacher.Classes', 'U') IS NULL
CREATE TABLE teacher.Classes (
    ClassId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Classes PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    TeacherUserId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(180) NOT NULL,
    Description NVARCHAR(1000) NULL,
    InstitutionId UNIQUEIDENTIFIER NULL,
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Classes_Status DEFAULT('active'),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Classes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Classes_Teacher FOREIGN KEY (TeacherUserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_Classes_Status CHECK (Status IN ('active','archived','deleted'))
);
GO

IF OBJECT_ID('teacher.ClassMembers', 'U') IS NULL
CREATE TABLE teacher.ClassMembers (
    ClassMemberId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ClassMembers PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    ClassId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    MemberRole NVARCHAR(40) NOT NULL CONSTRAINT DF_ClassMembers_MemberRole DEFAULT('student'),
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_ClassMembers_Status DEFAULT('active'),
    JoinedAt DATETIME2(7) NOT NULL CONSTRAINT DF_ClassMembers_JoinedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ClassMembers_Classes FOREIGN KEY (ClassId) REFERENCES teacher.Classes(ClassId),
    CONSTRAINT FK_ClassMembers_Users FOREIGN KEY (UserId) REFERENCES core.Users(UserId),
    CONSTRAINT UQ_ClassMembers UNIQUE (ClassId, UserId),
    CONSTRAINT CK_ClassMembers_MemberRole CHECK (MemberRole IN ('student','teacher','assistant')),
    CONSTRAINT CK_ClassMembers_Status CHECK (Status IN ('active','removed','pending'))
);
GO

IF OBJECT_ID('teacher.Assignments', 'U') IS NULL
CREATE TABLE teacher.Assignments (
    AssignmentId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Assignments PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    ClassId UNIQUEIDENTIFIER NOT NULL,
    QuizId UNIQUEIDENTIFIER NOT NULL,
    CreatedByUserId UNIQUEIDENTIFIER NOT NULL,
    Title NVARCHAR(220) NOT NULL,
    Instructions NVARCHAR(1000) NULL,
    StartsAt DATETIME2(7) NULL,
    DueAt DATETIME2(7) NULL,
    MaxAttempts INT NULL,
    RandomizeQuestions BIT NOT NULL CONSTRAINT DF_Assignments_RandomizeQuestions DEFAULT(0),
    AllowStudentRandomizeQuestions BIT NOT NULL CONSTRAINT DF_Assignments_AllowStudentRandomizeQuestions DEFAULT(0),
    ForfeitExitCountsAsAttempt BIT NOT NULL CONSTRAINT DF_Assignments_ForfeitExitCountsAsAttempt DEFAULT(0),
    ShowCorrectAnswersMode NVARCHAR(40) NOT NULL CONSTRAINT DF_Assignments_ShowCorrectAnswersMode DEFAULT('after_due_date'),
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Assignments_Status DEFAULT('active'),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Assignments_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Assignments_Classes FOREIGN KEY (ClassId) REFERENCES teacher.Classes(ClassId),
    CONSTRAINT FK_Assignments_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT FK_Assignments_Users FOREIGN KEY (CreatedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_Assignments_ShowCorrectAnswersMode CHECK (ShowCorrectAnswersMode IN ('never','after_attempt','after_due_date','teacher_only')),
    CONSTRAINT CK_Assignments_Status CHECK (Status IN ('active','closed','archived'))
);
GO

IF OBJECT_ID('sharing.ShareCodes', 'U') IS NULL
CREATE TABLE sharing.ShareCodes (
    ShareCodeId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ShareCodes PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    Code NVARCHAR(80) NOT NULL,
    QuizId UNIQUEIDENTIFIER NULL,
    ClassId UNIQUEIDENTIFIER NULL,
    AssignmentId UNIQUEIDENTIFIER NULL,
    CreatedByUserId UNIQUEIDENTIFIER NOT NULL,
    CodeType NVARCHAR(40) NOT NULL,
    MaxRedemptions INT NOT NULL CONSTRAINT DF_ShareCodes_MaxRedemptions DEFAULT(1),
    RedemptionsCount INT NOT NULL CONSTRAINT DF_ShareCodes_RedemptionsCount DEFAULT(0),
    ExpiresAt DATETIME2(7) NULL,
    Status NVARCHAR(30) NOT NULL CONSTRAINT DF_ShareCodes_Status DEFAULT('active'),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_ShareCodes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_ShareCodes_Code UNIQUE (Code),
    CONSTRAINT FK_ShareCodes_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT FK_ShareCodes_Classes FOREIGN KEY (ClassId) REFERENCES teacher.Classes(ClassId),
    CONSTRAINT FK_ShareCodes_Assignments FOREIGN KEY (AssignmentId) REFERENCES teacher.Assignments(AssignmentId),
    CONSTRAINT FK_ShareCodes_Users FOREIGN KEY (CreatedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT CK_ShareCodes_CodeType CHECK (CodeType IN ('single_use','class_capacity','purchased_key')),
    CONSTRAINT CK_ShareCodes_Status CHECK (Status IN ('active','exhausted','expired','revoked'))
);
GO

IF OBJECT_ID('sharing.QuizAccesses', 'U') IS NULL
CREATE TABLE sharing.QuizAccesses (
    QuizAccessId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuizAccesses PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    QuizId UNIQUEIDENTIFIER NOT NULL,
    ClassId UNIQUEIDENTIFIER NULL,
    AssignmentId UNIQUEIDENTIFIER NULL,
    AccessType NVARCHAR(40) NOT NULL,
    GrantedByShareCodeId UNIQUEIDENTIFIER NULL,
    GrantedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuizAccesses_GrantedAt DEFAULT SYSUTCDATETIME(),
    LastPracticedAt DATETIME2(7) NULL,
    CONSTRAINT FK_QuizAccesses_Users FOREIGN KEY (UserId) REFERENCES core.Users(UserId),
    CONSTRAINT FK_QuizAccesses_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT FK_QuizAccesses_Classes FOREIGN KEY (ClassId) REFERENCES teacher.Classes(ClassId),
    CONSTRAINT FK_QuizAccesses_Assignments FOREIGN KEY (AssignmentId) REFERENCES teacher.Assignments(AssignmentId),
    CONSTRAINT FK_QuizAccesses_ShareCodes FOREIGN KEY (GrantedByShareCodeId) REFERENCES sharing.ShareCodes(ShareCodeId),
    CONSTRAINT UQ_QuizAccesses_UserQuizClassAssignment UNIQUE (UserId, QuizId, ClassId, AssignmentId),
    CONSTRAINT CK_QuizAccesses_AccessType CHECK (AccessType IN ('creator','redeemed','class_member','assignment','purchase','curated'))
);
GO

/* =========================
   IMPORTING AND CQIF V2
========================= */

IF OBJECT_ID('importing.QuestionImportBatches', 'U') IS NULL
CREATE TABLE importing.QuestionImportBatches (
    QuestionImportBatchId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuestionImportBatches PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuizId UNIQUEIDENTIFIER NULL,
    UploadedByUserId UNIQUEIDENTIFIER NOT NULL,
    SourceType NVARCHAR(40) NOT NULL,
    OriginalFileName NVARCHAR(260) NULL,
    MediaAssetId UNIQUEIDENTIFIER NULL,
    Status NVARCHAR(40) NOT NULL CONSTRAINT DF_QuestionImportBatches_Status DEFAULT('pending'),
    UseAiNormalization BIT NOT NULL CONSTRAINT DF_QuestionImportBatches_UseAiNormalization DEFAULT(0),
    TotalRows INT NOT NULL CONSTRAINT DF_QuestionImportBatches_TotalRows DEFAULT(0),
    ValidRows INT NOT NULL CONSTRAINT DF_QuestionImportBatches_ValidRows DEFAULT(0),
    ErrorRows INT NOT NULL CONSTRAINT DF_QuestionImportBatches_ErrorRows DEFAULT(0),
    CqifVersion NVARCHAR(20) NOT NULL CONSTRAINT DF_QuestionImportBatches_CqifVersion DEFAULT('2.0'),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionImportBatches_CreatedAt DEFAULT SYSUTCDATETIME(),
    CompletedAt DATETIME2(7) NULL,
    CONSTRAINT FK_QuestionImportBatches_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT FK_QuestionImportBatches_Users FOREIGN KEY (UploadedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT FK_QuestionImportBatches_MediaAssets FOREIGN KEY (MediaAssetId) REFERENCES content.MediaAssets(MediaAssetId),
    CONSTRAINT CK_QuestionImportBatches_SourceType CHECK (SourceType IN ('xlsx','txt','csv','json','zip','raw_text','ai')),
    CONSTRAINT CK_QuestionImportBatches_Status CHECK (Status IN ('pending','parsing','needs_ai_normalization','parsed','ready_for_review','confirmed','completed','completed_with_errors','failed','cancelled'))
);
GO

IF OBJECT_ID('importing.QuestionImportRows', 'U') IS NULL
CREATE TABLE importing.QuestionImportRows (
    QuestionImportRowId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuestionImportRows PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuestionImportBatchId UNIQUEIDENTIFIER NOT NULL,
    RowNumber INT NOT NULL,
    RawDataJson NVARCHAR(MAX) NULL,
    CqifQuestionJson NVARCHAR(MAX) NULL,
    Status NVARCHAR(40) NOT NULL CONSTRAINT DF_QuestionImportRows_Status DEFAULT('pending'),
    CreatedQuestionId UNIQUEIDENTIFIER NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionImportRows_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_QuestionImportRows_Batches FOREIGN KEY (QuestionImportBatchId) REFERENCES importing.QuestionImportBatches(QuestionImportBatchId),
    CONSTRAINT FK_QuestionImportRows_Questions FOREIGN KEY (CreatedQuestionId) REFERENCES quiz.Questions(QuestionId),
    CONSTRAINT CK_QuestionImportRows_Status CHECK (Status IN ('pending','valid','warning','error','created','skipped'))
);
GO

IF OBJECT_ID('importing.QuestionImportErrors', 'U') IS NULL
CREATE TABLE importing.QuestionImportErrors (
    QuestionImportErrorId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuestionImportErrors PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    QuestionImportRowId UNIQUEIDENTIFIER NULL,
    QuestionImportBatchId UNIQUEIDENTIFIER NOT NULL,
    FieldName NVARCHAR(160) NULL,
    ErrorCode NVARCHAR(80) NOT NULL,
    ErrorMessage NVARCHAR(1000) NOT NULL,
    Severity NVARCHAR(20) NOT NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionImportErrors_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_QuestionImportErrors_Rows FOREIGN KEY (QuestionImportRowId) REFERENCES importing.QuestionImportRows(QuestionImportRowId),
    CONSTRAINT FK_QuestionImportErrors_Batches FOREIGN KEY (QuestionImportBatchId) REFERENCES importing.QuestionImportBatches(QuestionImportBatchId),
    CONSTRAINT CK_QuestionImportErrors_Severity CHECK (Severity IN ('info','warning','error'))
);
GO

/* =========================
   AI
========================= */

IF OBJECT_ID('ai.AiJobs', 'U') IS NULL
CREATE TABLE ai.AiJobs (
    AiJobId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiJobs PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    RequestedByUserId UNIQUEIDENTIFIER NOT NULL,
    JobType NVARCHAR(80) NOT NULL,
    Status NVARCHAR(40) NOT NULL CONSTRAINT DF_AiJobs_Status DEFAULT('pending'),
    StudyMaterialId UNIQUEIDENTIFIER NULL,
    QuestionImportBatchId UNIQUEIDENTIFIER NULL,
    TargetQuizId UNIQUEIDENTIFIER NULL,
    ModelName NVARCHAR(120) NULL,
    PromptVersion NVARCHAR(80) NULL,
    InputTokens INT NULL,
    OutputTokens INT NULL,
    EstimatedCostUsd DECIMAL(12,6) NULL,
    CreditsConsumed INT NULL,
    ResultJson NVARCHAR(MAX) NULL,
    ErrorMessage NVARCHAR(2000) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_AiJobs_CreatedAt DEFAULT SYSUTCDATETIME(),
    CompletedAt DATETIME2(7) NULL,
    CONSTRAINT FK_AiJobs_Users FOREIGN KEY (RequestedByUserId) REFERENCES core.Users(UserId),
    CONSTRAINT FK_AiJobs_StudyMaterials FOREIGN KEY (StudyMaterialId) REFERENCES content.StudyMaterials(StudyMaterialId),
    CONSTRAINT FK_AiJobs_QuestionImportBatches FOREIGN KEY (QuestionImportBatchId) REFERENCES importing.QuestionImportBatches(QuestionImportBatchId),
    CONSTRAINT FK_AiJobs_Quizzes FOREIGN KEY (TargetQuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT CK_AiJobs_JobType CHECK (JobType IN ('generate_quiz','normalize_cqif','generate_justification','grounded_justification','validate_question','improve_distractors')),
    CONSTRAINT CK_AiJobs_Status CHECK (Status IN ('pending','processing','completed','failed','cancelled'))
);
GO

/* =========================
   PRACTICE ENGINE
========================= */

IF OBJECT_ID('practice.PracticeSessions', 'U') IS NULL
CREATE TABLE practice.PracticeSessions (
    PracticeSessionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PracticeSessions PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    StudentUserId UNIQUEIDENTIFIER NOT NULL,
    QuizId UNIQUEIDENTIFIER NOT NULL,
    ClassId UNIQUEIDENTIFIER NULL,
    AssignmentId UNIQUEIDENTIFIER NULL,
    StartedAt DATETIME2(7) NOT NULL CONSTRAINT DF_PracticeSessions_StartedAt DEFAULT SYSUTCDATETIME(),
    FinishedAt DATETIME2(7) NULL,
    DurationSeconds INT NULL,
    ScoreObtained DECIMAL(10,2) NOT NULL CONSTRAINT DF_PracticeSessions_ScoreObtained DEFAULT(0),
    ScorePossible DECIMAL(10,2) NOT NULL CONSTRAINT DF_PracticeSessions_ScorePossible DEFAULT(0),
    CorrectAnswers INT NOT NULL CONSTRAINT DF_PracticeSessions_CorrectAnswers DEFAULT(0),
    IncorrectAnswers INT NOT NULL CONSTRAINT DF_PracticeSessions_IncorrectAnswers DEFAULT(0),
    OmittedAnswers INT NOT NULL CONSTRAINT DF_PracticeSessions_OmittedAnswers DEFAULT(0),
    Status NVARCHAR(40) NOT NULL CONSTRAINT DF_PracticeSessions_Status DEFAULT('in_progress'),
    RandomizationStrategy NVARCHAR(40) NOT NULL CONSTRAINT DF_PracticeSessions_RandomizationStrategy DEFAULT('server_random'),
    ShowElapsedTimer BIT NOT NULL CONSTRAINT DF_PracticeSessions_ShowElapsedTimer DEFAULT(0),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_PracticeSessions_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_PracticeSessions_Users FOREIGN KEY (StudentUserId) REFERENCES core.Users(UserId),
    CONSTRAINT FK_PracticeSessions_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId),
    CONSTRAINT FK_PracticeSessions_Classes FOREIGN KEY (ClassId) REFERENCES teacher.Classes(ClassId),
    CONSTRAINT FK_PracticeSessions_Assignments FOREIGN KEY (AssignmentId) REFERENCES teacher.Assignments(AssignmentId),
    CONSTRAINT CK_PracticeSessions_Status CHECK (Status IN ('in_progress','finished','abandoned','expired','forfeited'))
);
GO

/* Per-user practice UI settings for each quiz (course). */
IF OBJECT_ID('practice.UserQuizPracticePreferences', 'U') IS NULL
CREATE TABLE practice.UserQuizPracticePreferences (
    UserId UNIQUEIDENTIFIER NOT NULL,
    QuizId UNIQUEIDENTIFIER NOT NULL,
    RandomizeQuestions BIT NOT NULL CONSTRAINT DF_UserQuizPracticePreferences_RandomizeQuestions DEFAULT(0),
    ShowElapsedTimer BIT NOT NULL CONSTRAINT DF_UserQuizPracticePreferences_ShowElapsedTimer DEFAULT(1),
    UpdatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_UserQuizPracticePreferences_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_UserQuizPracticePreferences PRIMARY KEY (UserId, QuizId),
    CONSTRAINT FK_UserQuizPracticePreferences_Users FOREIGN KEY (UserId) REFERENCES core.Users(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserQuizPracticePreferences_Quizzes FOREIGN KEY (QuizId) REFERENCES quiz.Quizzes(QuizId) ON DELETE CASCADE
);
GO

/* One row per question shown in a specific practice session. */
IF OBJECT_ID('practice.PracticeQuestionSnapshots', 'U') IS NULL
CREATE TABLE practice.PracticeQuestionSnapshots (
    PracticeQuestionSnapshotId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PracticeQuestionSnapshots PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    PracticeSessionId UNIQUEIDENTIFIER NOT NULL,
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    QuestionTypeCodeSnapshot NVARCHAR(60) NOT NULL,
    QuestionTextSnapshot NVARCHAR(MAX) NOT NULL,
    QuizSectionNameSnapshot NVARCHAR(160) NULL,
    PointsPossible DECIMAL(10,2) NOT NULL,
    PointsAwarded DECIMAL(10,2) NOT NULL CONSTRAINT DF_PracticeQuestionSnapshots_PointsAwarded DEFAULT(0),
    DisplayOrder INT NOT NULL,
    AnswerStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_PracticeQuestionSnapshots_AnswerStatus DEFAULT('unanswered'),
    IsCorrect BIT NULL,
    TimeSpentSeconds INT NULL,
    RandomizationSeed NVARCHAR(100) NULL,
    SubmittedAt DATETIME2(7) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_PracticeQuestionSnapshots_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_PracticeQuestionSnapshots_Sessions FOREIGN KEY (PracticeSessionId) REFERENCES practice.PracticeSessions(PracticeSessionId),
    CONSTRAINT FK_PracticeQuestionSnapshots_Questions FOREIGN KEY (QuestionId) REFERENCES quiz.Questions(QuestionId),
    CONSTRAINT UQ_PracticeQuestionSnapshots UNIQUE (PracticeSessionId, QuestionId),
    CONSTRAINT CK_PracticeQuestionSnapshots_AnswerStatus CHECK (AnswerStatus IN ('unanswered','answered','omitted','skipped'))
);
GO

/* 
All answer options as displayed to the student for that question snapshot.
DisplayLabel is A/B/C/D after randomization. AnswerOptionId is the real answer identity.
*/
IF OBJECT_ID('practice.PracticeAnswerOptionSnapshots', 'U') IS NULL
CREATE TABLE practice.PracticeAnswerOptionSnapshots (
    PracticeAnswerOptionSnapshotId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PracticeAnswerOptionSnapshots PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    PracticeQuestionSnapshotId UNIQUEIDENTIFIER NOT NULL,
    AnswerOptionId UNIQUEIDENTIFIER NOT NULL,
    StableKeySnapshot NVARCHAR(100) NULL,
    DisplayOrder INT NOT NULL,
    DisplayLabel NVARCHAR(10) NOT NULL,
    AnswerTextSnapshot NVARCHAR(MAX) NULL,
    MediaAssetIdSnapshot UNIQUEIDENTIFIER NULL,
    IsCorrectSnapshot BIT NOT NULL,
    WasSelected BIT NOT NULL CONSTRAINT DF_PracticeAnswerOptionSnapshots_WasSelected DEFAULT(0),
    SelectedAt DATETIME2(7) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_PracticeAnswerOptionSnapshots_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_PracticeAnswerOptionSnapshots_Questions FOREIGN KEY (PracticeQuestionSnapshotId) REFERENCES practice.PracticeQuestionSnapshots(PracticeQuestionSnapshotId),
    CONSTRAINT FK_PracticeAnswerOptionSnapshots_AnswerOptions FOREIGN KEY (AnswerOptionId) REFERENCES quiz.QuestionAnswerOptions(AnswerOptionId),
    CONSTRAINT FK_PracticeAnswerOptionSnapshots_MediaAssets FOREIGN KEY (MediaAssetIdSnapshot) REFERENCES content.MediaAssets(MediaAssetId),
    CONSTRAINT UQ_PracticeAnswerOptionSnapshots_Order UNIQUE (PracticeQuestionSnapshotId, DisplayOrder),
    CONSTRAINT UQ_PracticeAnswerOptionSnapshots_Label UNIQUE (PracticeQuestionSnapshotId, DisplayLabel),
    CONSTRAINT UQ_PracticeAnswerOptionSnapshots_Answer UNIQUE (PracticeQuestionSnapshotId, AnswerOptionId)
);
GO

/* =========================
   ANALYTICS AND AUDIT
========================= */

IF OBJECT_ID('analytics.QuestionStats', 'U') IS NULL
CREATE TABLE analytics.QuestionStats (
    QuestionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_QuestionStats PRIMARY KEY,
    AttemptsCount INT NOT NULL CONSTRAINT DF_QuestionStats_AttemptsCount DEFAULT(0),
    CorrectCount INT NOT NULL CONSTRAINT DF_QuestionStats_CorrectCount DEFAULT(0),
    IncorrectCount INT NOT NULL CONSTRAINT DF_QuestionStats_IncorrectCount DEFAULT(0),
    OmittedCount INT NOT NULL CONSTRAINT DF_QuestionStats_OmittedCount DEFAULT(0),
    AverageTimeSeconds DECIMAL(12,2) NULL,
    UpdatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_QuestionStats_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_QuestionStats_Questions FOREIGN KEY (QuestionId) REFERENCES quiz.Questions(QuestionId)
);
GO

IF OBJECT_ID('analytics.AnswerOptionStats', 'U') IS NULL
CREATE TABLE analytics.AnswerOptionStats (
    AnswerOptionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AnswerOptionStats PRIMARY KEY,
    QuestionId UNIQUEIDENTIFIER NOT NULL,
    SelectedCount INT NOT NULL CONSTRAINT DF_AnswerOptionStats_SelectedCount DEFAULT(0),
    LastSelectedAt DATETIME2(7) NULL,
    CONSTRAINT FK_AnswerOptionStats_AnswerOptions FOREIGN KEY (QuestionId, AnswerOptionId)
        REFERENCES quiz.QuestionAnswerOptions(QuestionId, AnswerOptionId)
);
GO

IF OBJECT_ID('audit.AuditEvents', 'U') IS NULL
CREATE TABLE audit.AuditEvents (
    AuditEventId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AuditEvents PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    ActorUserId UNIQUEIDENTIFIER NULL,
    EventType NVARCHAR(120) NOT NULL,
    EntityType NVARCHAR(120) NOT NULL,
    EntityId UNIQUEIDENTIFIER NULL,
    CorrelationId NVARCHAR(100) NULL,
    IpAddress NVARCHAR(80) NULL,
    UserAgent NVARCHAR(600) NULL,
    BeforeJson NVARCHAR(MAX) NULL,
    AfterJson NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_AuditEvents_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_AuditEvents_Users FOREIGN KEY (ActorUserId) REFERENCES core.Users(UserId)
);
GO

/* =========================
   INDEXES
========================= */

CREATE INDEX IX_Quizzes_CreatedBy ON quiz.Quizzes(CreatedByUserId, PublicationStatus) WHERE DeletedAt IS NULL;
CREATE INDEX IX_Quizzes_CreatedByUser_CreatedAt ON quiz.Quizzes(CreatedByUserId, CreatedAt DESC) WHERE DeletedAt IS NULL;
CREATE INDEX IX_Questions_Quiz ON quiz.Questions(QuizId, SortOrder) WHERE DeletedAt IS NULL;
CREATE INDEX IX_QuestionAnswerOptions_Question ON quiz.QuestionAnswerOptions(QuestionId, DefaultSortOrder) WHERE IsActive = 1;
CREATE INDEX IX_PracticeSessions_Student ON practice.PracticeSessions(StudentUserId, StartedAt DESC);
CREATE INDEX IX_PracticeSessions_Assignment ON practice.PracticeSessions(AssignmentId, StartedAt DESC) WHERE AssignmentId IS NOT NULL;
CREATE INDEX IX_PracticeQuestionSnapshots_SessionOrder ON practice.PracticeQuestionSnapshots(PracticeSessionId, DisplayOrder);
CREATE INDEX IX_PracticeAnswerOptionSnapshots_QuestionOrder ON practice.PracticeAnswerOptionSnapshots(PracticeQuestionSnapshotId, DisplayOrder);
CREATE INDEX IX_QuestionImportBatches_User ON importing.QuestionImportBatches(UploadedByUserId, CreatedAt DESC);
CREATE INDEX IX_AiJobs_PendingImportByQuiz ON ai.AiJobs(RequestedByUserId, JobType, Status, TargetQuizId) INCLUDE (CompletedAt, QuestionImportBatchId) WHERE TargetQuizId IS NOT NULL;
CREATE INDEX IX_AuditEvents_Entity ON audit.AuditEvents(EntityType, EntityId, CreatedAt DESC);
GO

/* =========================
   SEED DATA
========================= */

MERGE core.Roles AS target
USING (VALUES
    ('student', 'Student'),
    ('teacher', 'Teacher'),
    ('institution_admin', 'Institution Admin'),
    ('content_admin', 'Content Admin'),
    ('super_admin', 'Super Admin')
) AS source (Code, Name)
ON target.Code = source.Code
WHEN MATCHED THEN UPDATE SET Name = source.Name
WHEN NOT MATCHED THEN INSERT (Code, Name) VALUES (source.Code, source.Name);
GO

MERGE quiz.QuestionTypes AS target
USING (VALUES
    ('single_choice', 'Seleccion unica', 'El estudiante selecciona una respuesta correcta.', 0, 0, 1),
    ('multiple_choice', 'Seleccion multiple', 'El estudiante puede seleccionar varias respuestas.', 1, 0, 1),
    ('true_false', 'Falso/Verdadero', 'Pregunta con dos respuestas posibles TRUE/FALSE.', 0, 0, 1),
    ('image_choice', 'Respuesta con imagenes', 'Opciones de respuesta pueden contener imagenes.', 0, 1, 1),
    ('image_based_question', 'Pregunta basada en imagen', 'La pregunta depende de una imagen o diagrama.', 0, 1, 1)
) AS source (Code, Name, Description, SupportsMultipleCorrectAnswers, SupportsImages, RequiresOptions)
ON target.Code = source.Code
WHEN MATCHED THEN UPDATE SET
    Name = source.Name,
    Description = source.Description,
    SupportsMultipleCorrectAnswers = source.SupportsMultipleCorrectAnswers,
    SupportsImages = source.SupportsImages,
    RequiresOptions = source.RequiresOptions,
    IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (Code, Name, Description, SupportsMultipleCorrectAnswers, SupportsImages, RequiresOptions)
    VALUES (source.Code, source.Name, source.Description, source.SupportsMultipleCorrectAnswers, source.SupportsImages, source.RequiresOptions);
GO

MERGE billing.Plans AS target
USING (VALUES
    ('free', 'Free', NULL, NULL, 2, 50, 20, 2, 0, 0),
    ('pro', 'Pro', 4.99, 48.99, NULL, NULL, 90, 20, 0, 0),
    ('teacher', 'Teacher', 9.99, 99.99, NULL, NULL, 180, 200, 1, 0),
    ('institution', 'Institution', NULL, NULL, NULL, NULL, 5000, 1000, 1, 1)
) AS source (Code, Name, MonthlyPrice, AnnualPrice, MaxQuizzes, MaxQuestionsPerQuiz, MonthlyAiCredits, MonthlyShareCodes, IsTeacherPlan, IsInstitutionPlan)
ON target.Code = source.Code
WHEN MATCHED THEN UPDATE SET
    Name = source.Name,
    MonthlyPrice = source.MonthlyPrice,
    AnnualPrice = source.AnnualPrice,
    MaxQuizzes = source.MaxQuizzes,
    MaxQuestionsPerQuiz = source.MaxQuestionsPerQuiz,
    MonthlyAiCredits = source.MonthlyAiCredits,
    MonthlyShareCodes = source.MonthlyShareCodes,
    IsTeacherPlan = source.IsTeacherPlan,
    IsInstitutionPlan = source.IsInstitutionPlan
WHEN NOT MATCHED THEN
    INSERT (Code, Name, MonthlyPrice, AnnualPrice, MaxQuizzes, MaxQuestionsPerQuiz, MonthlyAiCredits, MonthlyShareCodes, IsTeacherPlan, IsInstitutionPlan)
    VALUES (source.Code, source.Name, source.MonthlyPrice, source.AnnualPrice, source.MaxQuizzes, source.MaxQuestionsPerQuiz, source.MonthlyAiCredits, source.MonthlyShareCodes, source.IsTeacherPlan, source.IsInstitutionPlan);
GO

/* =========================
   VIEWS
========================= */

CREATE OR ALTER VIEW practice.v_TeacherPracticeReview AS
SELECT
    ps.PracticeSessionId,
    ps.StudentUserId,
    ps.QuizId,
    ps.ClassId,
    ps.AssignmentId,
    pqs.PracticeQuestionSnapshotId,
    pqs.QuestionId,
    pqs.DisplayOrder AS QuestionDisplayOrder,
    pqs.QuestionTextSnapshot,
    pqs.QuestionTypeCodeSnapshot,
    pqs.PointsPossible,
    pqs.PointsAwarded,
    pqs.AnswerStatus,
    pqs.IsCorrect,
    paos.AnswerOptionId,
    paos.StableKeySnapshot,
    paos.DisplayOrder AS AnswerDisplayOrder,
    paos.DisplayLabel,
    paos.AnswerTextSnapshot,
    paos.MediaAssetIdSnapshot,
    paos.IsCorrectSnapshot,
    paos.WasSelected
FROM practice.PracticeSessions ps
JOIN practice.PracticeQuestionSnapshots pqs
    ON ps.PracticeSessionId = pqs.PracticeSessionId
JOIN practice.PracticeAnswerOptionSnapshots paos
    ON pqs.PracticeQuestionSnapshotId = paos.PracticeQuestionSnapshotId;
GO

/* =========================
   STORED PROCEDURE: SAFE SHARE CODE REDEMPTION
========================= */

CREATE OR ALTER PROCEDURE sharing.RedeemShareCode
    @Code NVARCHAR(80),
    @RedeemedByUserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ShareCodeId UNIQUEIDENTIFIER;
    DECLARE @QuizId UNIQUEIDENTIFIER;
    DECLARE @ClassId UNIQUEIDENTIFIER;
    DECLARE @AssignmentId UNIQUEIDENTIFIER;
    DECLARE @MaxRedemptions INT;
    DECLARE @RedemptionsCount INT;
    DECLARE @Status NVARCHAR(30);

    BEGIN TRANSACTION;

    SELECT
        @ShareCodeId = ShareCodeId,
        @QuizId = QuizId,
        @ClassId = ClassId,
        @AssignmentId = AssignmentId,
        @MaxRedemptions = MaxRedemptions,
        @RedemptionsCount = RedemptionsCount,
        @Status = Status
    FROM sharing.ShareCodes WITH (UPDLOCK, ROWLOCK)
    WHERE Code = @Code;

    IF @ShareCodeId IS NULL
        THROW 51000, 'Share code not found.', 1;

    IF @Status <> 'active'
        THROW 51001, 'Share code is not active.', 1;

    IF @RedemptionsCount >= @MaxRedemptions
        THROW 51002, 'Share code has no available redemptions.', 1;

    UPDATE sharing.ShareCodes
    SET RedemptionsCount = RedemptionsCount + 1,
        Status = CASE WHEN RedemptionsCount + 1 >= MaxRedemptions THEN 'exhausted' ELSE Status END
    WHERE ShareCodeId = @ShareCodeId;

    IF @QuizId IS NOT NULL
    BEGIN
        INSERT INTO sharing.QuizAccesses (UserId, QuizId, ClassId, AssignmentId, AccessType, GrantedByShareCodeId)
        SELECT @RedeemedByUserId, @QuizId, @ClassId, @AssignmentId,
               CASE WHEN @ClassId IS NULL THEN 'redeemed' ELSE 'class_member' END,
               @ShareCodeId
        WHERE NOT EXISTS (
            SELECT 1 FROM sharing.QuizAccesses
            WHERE UserId = @RedeemedByUserId
              AND QuizId = @QuizId
              AND ISNULL(ClassId, '00000000-0000-0000-0000-000000000000') = ISNULL(@ClassId, '00000000-0000-0000-0000-000000000000')
              AND ISNULL(AssignmentId, '00000000-0000-0000-0000-000000000000') = ISNULL(@AssignmentId, '00000000-0000-0000-0000-000000000000')
        );
    END

    COMMIT TRANSACTION;

    SELECT @ShareCodeId AS ShareCodeId, @QuizId AS QuizId, @ClassId AS ClassId, @AssignmentId AS AssignmentId;
END
GO
