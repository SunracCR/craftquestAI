using CraftQuest.Infrastructure.Persistence;
using CraftQuest.Infrastructure.Services;
using Microsoft.Extensions.Caching.Memory;

namespace CraftQuest.UnitTests.Billing;

internal static class BillingTestHelpers
{
    public static BillingService CreateService(CraftQuestDbContext db) =>
        new(db, new MemoryCache(new MemoryCacheOptions()));
}
