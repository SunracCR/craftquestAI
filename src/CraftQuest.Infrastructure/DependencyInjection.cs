using CraftQuest.Application.Contracts;
using CraftQuest.Application.Options;
using CraftQuest.Infrastructure.Media;
using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.HostedServices;
using CraftQuest.Infrastructure.Services;
using CraftQuest.Infrastructure.Services.Ai;
using CraftQuest.Infrastructure.StudyMaterials;
using CraftQuest.Infrastructure.Security;
using CraftQuest.Infrastructure.Services;
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
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

        services.AddDbContext<CraftQuestDbContext>(options =>
            options.UseSqlServer(connectionString, sql =>
                sql.MigrationsHistoryTable("__EFMigrationsHistory", "core")));

        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        services.Configure<AiOptions>(configuration.GetSection(AiOptions.SectionName));
        services.Configure<AiGenerationOptions>(configuration.GetSection(AiGenerationOptions.SectionName));
        services.Configure<MediaOptions>(configuration.GetSection(MediaOptions.SectionName));
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
        services.AddSingleton<JwtTokenService>();
        services.AddScoped<IAppStatusService, AppStatusService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IQuizService, QuizService>();
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
        services.AddScoped<IAnalyticsService, AnalyticsService>();
        services.AddSingleton<LocalMediaStorageProvider>();
        services.AddSingleton<AzureBlobMediaStorageProvider>();
        services.AddScoped<IMediaService, MediaService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddHttpClient<PayPalApiClient>((sp, client) =>
        {
            var paymentOptions = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<PaymentOptions>>().Value;
            client.BaseAddress = new Uri(paymentOptions.PayPal.ApiBaseUrl.TrimEnd('/') + "/");
        });

        return services;
    }
}
