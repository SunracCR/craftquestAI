using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Persistence;

public class CraftQuestDbContext(DbContextOptions<CraftQuestDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<AuthProvider> AuthProviders => Set<AuthProvider>();
    public DbSet<QuestionType> QuestionTypes => Set<QuestionType>();
    public DbSet<Plan> Plans => Set<Plan>();
    public DbSet<Quiz> Quizzes => Set<Quiz>();
    public DbSet<Question> Questions => Set<Question>();
    public DbSet<QuestionAnswerOption> QuestionAnswerOptions => Set<QuestionAnswerOption>();
    public DbSet<QuestionCorrectAnswerOption> QuestionCorrectAnswerOptions => Set<QuestionCorrectAnswerOption>();
    public DbSet<QuestionJustification> QuestionJustifications => Set<QuestionJustification>();
    public DbSet<UserQuizPracticePreference> UserQuizPracticePreferences =>
        Set<UserQuizPracticePreference>();
    public DbSet<PracticeSession> PracticeSessions => Set<PracticeSession>();
    public DbSet<PracticeQuestionSnapshot> PracticeQuestionSnapshots => Set<PracticeQuestionSnapshot>();
    public DbSet<PracticeAnswerOptionSnapshot> PracticeAnswerOptionSnapshots => Set<PracticeAnswerOptionSnapshot>();
    public DbSet<QuestionImportBatch> QuestionImportBatches => Set<QuestionImportBatch>();
    public DbSet<QuestionImportRow> QuestionImportRows => Set<QuestionImportRow>();
    public DbSet<QuestionImportError> QuestionImportErrors => Set<QuestionImportError>();
    public DbSet<UserSubscription> UserSubscriptions => Set<UserSubscription>();
    public DbSet<Purchase> Purchases => Set<Purchase>();
    public DbSet<CreditLedgerEntry> CreditLedgerEntries => Set<CreditLedgerEntry>();
    public DbSet<ShareCode> ShareCodes => Set<ShareCode>();
    public DbSet<QuizAccess> QuizAccesses => Set<QuizAccess>();
    public DbSet<AiJob> AiJobs => Set<AiJob>();
    public DbSet<MediaAsset> MediaAssets => Set<MediaAsset>();
    public DbSet<StudyMaterial> StudyMaterials => Set<StudyMaterial>();
    public DbSet<StudyMaterialPage> StudyMaterialPages => Set<StudyMaterialPage>();
    public DbSet<StudyMaterialSection> StudyMaterialSections => Set<StudyMaterialSection>();
    public DbSet<QuestionStats> QuestionStats => Set<QuestionStats>();
    public DbSet<AnswerOptionStats> AnswerOptionStats => Set<AnswerOptionStats>();
    public DbSet<GuestVisit> GuestVisits => Set<GuestVisit>();
    public DbSet<TeacherClass> TeacherClasses => Set<TeacherClass>();
    public DbSet<ClassMember> ClassMembers => Set<ClassMember>();
    public DbSet<Assignment> Assignments => Set<Assignment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CraftQuestDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}