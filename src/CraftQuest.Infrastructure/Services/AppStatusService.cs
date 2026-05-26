using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CraftQuest.Infrastructure.Services;

public class AppStatusService(CraftQuestDbContext dbContext) : IAppStatusService
{
    public async Task<AppStatusDto> GetStatusAsync(CancellationToken cancellationToken = default)
    {
        if (!await dbContext.Database.CanConnectAsync(cancellationToken))
        {
            throw new InvalidOperationException("Cannot connect to CraftQuest database.");
        }

        return new AppStatusDto
        {
            Service = "CraftQuest.Api",
            Version = typeof(AppStatusService).Assembly.GetName().Version?.ToString() ?? "0.0.0",
            Database = dbContext.Database.GetDbConnection().Database,
            RoleCount = await dbContext.Roles.CountAsync(cancellationToken),
            QuestionTypeCount = await dbContext.QuestionTypes.CountAsync(cancellationToken),
            PlanCount = await dbContext.Plans.CountAsync(cancellationToken),
        };
    }
}