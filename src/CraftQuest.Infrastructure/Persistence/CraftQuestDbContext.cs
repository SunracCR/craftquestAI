using CraftQuest.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Persistence;

public class CraftQuestDbContext(DbContextOptions<CraftQuestDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<AuthProvider> AuthProviders => Set<AuthProvider>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();
    public DbSet<EmailVerificationToken> EmailVerificationTokens => Set<EmailVerificationToken>();
    public DbSet<ParentalConsentToken> ParentalConsentTokens => Set<ParentalConsentToken>();
    public DbSet<PasswordChangeToken> PasswordChangeTokens => Set<PasswordChangeToken>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<NotificationOutbox> NotificationOutbox => Set<NotificationOutbox>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<NotificationPreference> NotificationPreferences => Set<NotificationPreference>();
    public DbSet<QuestionType> QuestionTypes => Set<QuestionType>();
    public DbSet<Plan> Plans => Set<Plan>();
    public DbSet<Quiz> Quizzes => Set<Quiz>();
    public DbSet<QuizFolder> QuizFolders => Set<QuizFolder>();
    public DbSet<Question> Questions => Set<Question>();
    public DbSet<QuestionAnswerOption> QuestionAnswerOptions => Set<QuestionAnswerOption>();
    public DbSet<QuestionCorrectAnswerOption> QuestionCorrectAnswerOptions => Set<QuestionCorrectAnswerOption>();
    public DbSet<QuestionJustification> QuestionJustifications => Set<QuestionJustification>();
    public DbSet<QuestionJustificationSource> QuestionJustificationSources => Set<QuestionJustificationSource>();
    public DbSet<UserQuizPracticePreference> UserQuizPracticePreferences =>
        Set<UserQuizPracticePreference>();
    public DbSet<PracticeSession> PracticeSessions => Set<PracticeSession>();
    public DbSet<PracticeQuestionSnapshot> PracticeQuestionSnapshots => Set<PracticeQuestionSnapshot>();
    public DbSet<PracticeAnswerOptionSnapshot> PracticeAnswerOptionSnapshots => Set<PracticeAnswerOptionSnapshot>();
    public DbSet<QuestionImportBatch> QuestionImportBatches => Set<QuestionImportBatch>();
    public DbSet<QuestionImportRow> QuestionImportRows => Set<QuestionImportRow>();
    public DbSet<QuestionImportError> QuestionImportErrors => Set<QuestionImportError>();
    public DbSet<UserSubscription> UserSubscriptions => Set<UserSubscription>();
    public DbSet<ProviderWebhookEvent> ProviderWebhookEvents => Set<ProviderWebhookEvent>();
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
    public DbSet<PrepCategory> PrepCategories => Set<PrepCategory>();
    public DbSet<PrepCatalogItem> PrepCatalogItems => Set<PrepCatalogItem>();
    public DbSet<PrepAccessOffer> PrepAccessOffers => Set<PrepAccessOffer>();
    public DbSet<PrepSampleQuestion> PrepSampleQuestions => Set<PrepSampleQuestion>();
    public DbSet<PrepReferralCode> PrepReferralCodes => Set<PrepReferralCode>();
    public DbSet<PrepReferralConversion> PrepReferralConversions => Set<PrepReferralConversion>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CraftQuestDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        MaterializeUserEmailNormalizedForInMemory();
        return base.SaveChangesAsync(cancellationToken);
    }

    public override int SaveChanges()
    {
        MaterializeUserEmailNormalizedForInMemory();
        return base.SaveChanges();
    }

    /// <summary>
    /// InMemory no evalúa <see cref="User.EmailNormalized"/> (columna calculada en SQL Server).
    /// </summary>
    private void MaterializeUserEmailNormalizedForInMemory()
    {
        if (!Database.IsInMemory())
        {
            return;
        }

        foreach (var entry in ChangeTracker.Entries<User>())
        {
            if (entry.State is not (EntityState.Added or EntityState.Modified))
            {
                continue;
            }

            if (entry.State == EntityState.Modified && !entry.Property(u => u.Email).IsModified)
            {
                continue;
            }

            var normalized = entry.Entity.Email.Trim().ToUpperInvariant();
            entry.Property(u => u.EmailNormalized).CurrentValue = normalized;
            entry.Property(u => u.EmailNormalized).IsModified = true;
        }
    }
}