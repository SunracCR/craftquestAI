using CraftQuest.Application;

namespace CraftQuest.UnitTests.PrepPlus;

public class PrepSlugHelperTests
{
    [Fact]
    public void GenerateFromTitle_ShortTitle_DoesNotThrow()
    {
        var catalogItemId = Guid.Parse("cfd42d7b-abde-4fc1-8712-5be0e180dcbc");

        var slug = PrepSlugHelper.GenerateFromTitle("Matemáticas", catalogItemId);

        Assert.StartsWith("matematicas-", slug);
        Assert.Contains(catalogItemId.ToString("N"), slug);
        Assert.True(slug.Length <= 160);
    }

    [Fact]
    public void GenerateFromTitle_EmptyTitle_UsesFallback()
    {
        var catalogItemId = Guid.Parse("cfd42d7b-abde-4fc1-8712-5be0e180dcbc");

        var slug = PrepSlugHelper.GenerateFromTitle(string.Empty, catalogItemId);

        Assert.StartsWith("prep-item-", slug);
        Assert.True(slug.Length <= 160);
    }

    [Fact]
    public void GenerateFromTitle_LongTitle_TruncatesSafely()
    {
        var catalogItemId = Guid.NewGuid();
        var title = new string('a', 200);

        var slug = PrepSlugHelper.GenerateFromTitle(title, catalogItemId);

        Assert.True(slug.Length <= 160);
        Assert.Contains(catalogItemId.ToString("N"), slug);
    }
}
