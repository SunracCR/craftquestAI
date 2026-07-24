using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using CraftQuest.Infrastructure.Email;
using CraftQuest.Infrastructure.Notifications;
using CraftQuest.Infrastructure.Media;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.HostedServices;
using CraftQuest.Infrastructure.Services;
using CraftQuest.Infrastructure.Services.Ai;
using CraftQuest.Infrastructure.Services.Offline;
using CraftQuest.Infrastructure.Services.Practice;
using CraftQuest.Infrastructure.StudyMaterials;
using CraftQuest.Infrastructure.Security;
using CraftQuest.Infrastructure.Services.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace CraftQuest.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        if (configuration.GetValue<bool>("Testing:UseInMemoryDatabase"))
        {
            services.AddDbContext<CraftQuestDbContext>(options =>
                options.UseInMemoryDatabase("CraftQuestIntegrationTests"));
        }
        else
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

            services.AddDbContextPool<CraftQuestDbContext>(options =>
                options.UseSqlServer(connectionString, sql =>
                {
                    sql.MigrationsHistoryTable("__EFMigrationsHistory", "core");
                    sql.EnableRetryOnFailure(maxRetryCount: 3, maxRetryDelay: TimeSpan.FromSeconds(5), errorNumbersToAdd: null);
                    sql.CommandTimeout(60);
                    sql.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
                }));
        }

        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        services.Configure<PasswordResetOptions>(configuration.GetSection(PasswordResetOptions.SectionName));
        services.Configure<ExternalAuthOptions>(configuration.GetSection(ExternalAuthOptions.SectionName));
        services.Configure<EmailOptions>(configuration.GetSection(EmailOptions.SectionName));
        services.Configure<PushOptions>(configuration.GetSection(PushOptions.SectionName));
        services.AddMemoryCache();
        services.AddHttpClient(nameof(AppleIdTokenValidator));
        services.AddScoped<IGoogleIdTokenValidator, GoogleIdTokenValidator>();
        services.AddScoped<IAppleIdTokenValidator, AppleIdTokenValidator>();

        var emailOptions = configuration.GetSection(EmailOptions.SectionName).Get<EmailOptions>() ?? new EmailOptions();
        if (emailOptions.Enabled && !string.IsNullOrWhiteSpace(emailOptions.Host))
        {
            services.AddSingleton<IEmailSender, SmtpEmailSender>();
        }
        else
        {
            services.AddSingleton<IEmailSender, LoggingEmailSender>();
        }

        var pushOptions = configuration.GetSection(PushOptions.SectionName).Get<PushOptions>() ?? new PushOptions();
        if (pushOptions.Enabled && !string.IsNullOrWhiteSpace(pushOptions.CredentialsPath))
        {
            services.AddScoped<IPushSender, FirebasePushSender>();
        }
        else
        {
            services.AddSingleton<IPushSender, LoggingPushSender>();
        }

        services.AddScoped<INotificationService, NotificationService>();
        services.Configure<AiOptions>(configuration.GetSection(AiOptions.SectionName));
        services.Configure<AiGenerationOptions>(configuration.GetSection(AiGenerationOptions.SectionName));
        services.Configure<PracticeOptions>(configuration.GetSection(PracticeOptions.SectionName));
        services.Configure<OfflineOptions>(configuration.GetSection(OfflineOptions.SectionName));
        services.Configure<MediaOptions>(configuration.GetSection(MediaOptions.SectionName));
        services.Configure<PaymentOptions>(configuration.GetSection(PaymentOptions.SectionName));
        services.AddHttpClient("Gemini", client =>
        {
            client.Timeout = TimeSpan.FromMinutes(8);
        });
        services.AddScoped<HeuristicCqifNormalizationProvider>();
        services.AddScoped<GeminiContentClient>();
        services.AddScoped<GeminiCqifNormalizationProvider>();
        services.AddScoped<ICqifNormalizationProvider, CompositeCqifNormalizationProvider>();
        services.AddScoped<AiGenerationTraceContext>();
        services.AddScoped<IAiGenerationJobProgress, AiGenerationJobProgress>();
        services.AddScoped<IQuizGenerationProvider, GeminiQuizGenerationProvider>();
        services.AddScoped<IPageTextExtractor, PdfPageTextExtractor>();
        services.AddScoped<IPageTextExtractor, DocxPageTextExtractor>();
        services.AddScoped<IStudyMaterialService, StudyMaterialService>();
        services.AddScoped<IQuizGenerationService, QuizGenerationService>();
        services.AddHostedService<AiProcessingHostedService>();
        services.AddPracticeSnapshotDeferredWriter();
        services.AddHostedService<DatabaseKeepWarmHostedService>();
        services.AddSingleton<JwtTokenService>();
        services.AddScoped<IAppStatusService, AppStatusService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IQuizService, QuizService>();
        services.AddScoped<IQuizPdfExportService, QuizPdfExportService>();
        services.AddScoped<IOfflineQuizService, OfflineQuizService>();
        services.AddScoped<OfflinePackageCryptoService>();
        services.AddScoped<IQuizFolderService, QuizFolderService>();
        services.AddScoped<IPracticeService, PracticeService>();
        services.AddScoped<IQuizPracticePreferenceService, QuizPracticePreferenceService>();
        services.AddScoped<IQuestionImportService, QuestionImportService>();
        services.AddScoped<ITeacherReviewService, TeacherReviewService>();
        services.AddScoped<IBillingService, BillingService>();
        services.AddScoped<IShareCodeService, ShareCodeService>();
        services.AddScoped<IClassService, ClassService>();
        services.AddScoped<IAssignmentService, AssignmentService>();
        services.AddScoped<IStudentService, StudentService>();
        services.AddScoped<ITeacherDashboardService, TeacherDashboardService>();
        services.AddScoped<IAiService, AiService>();
        services.AddScoped<IGuestService, GuestService>();
        services.AddHostedService<GuestCleanupHostedService>();
        services.AddHostedService<SubscriptionRenewalHostedService>();
        services.AddHostedService<NotificationReminderHostedService>();
        services.AddScoped<IAnalyticsService, AnalyticsService>();
        services.AddSingleton<LocalMediaStorageProvider>();
        services.AddSingleton<AzureBlobMediaStorageProvider>();
        services.AddScoped<IMediaService, MediaService>();
        services.AddScoped<IMediaAccessService, MediaAccessService>();
        services.AddHttpClient(nameof(AppleAppStoreSubscriptionVerifier));
        services.AddSingleton<GooglePlaySubscriptionVerifier>();
        services.AddSingleton<AppleAppStoreSubscriptionVerifier>();
        services.AddScoped<IMobileStoreSubscriptionVerifier, MobileStoreSubscriptionVerifier>();
        services.AddScoped<AppleAppStoreJwsVerifier>();
        services.AddScoped<GooglePubSubJwtValidator>();
        services.AddScoped<PaymentWebhookSecurityService>();
        services.AddScoped<MobileStoreWebhookProcessor>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IPrepPlusAdminService, PrepPlusAdminService>();
        services.AddScoped<IPrepPlusAccessService, PrepPlusAccessService>();
        services.AddScoped<IPrepPlusCatalogService, PrepPlusCatalogService>();
        services.AddScoped<IPrepPlusPaymentService, PrepPlusPaymentService>();
        services.AddScoped<IPrepReferralService, PrepReferralService>();
        services.AddHttpClient<PayPalApiClient>((sp, client) =>
        {
            var paymentOptions = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<PaymentOptions>>().Value;
            client.BaseAddress = new Uri(paymentOptions.PayPal.ApiBaseUrl.TrimEnd('/') + "/");
        });

        return services;
    }
}
