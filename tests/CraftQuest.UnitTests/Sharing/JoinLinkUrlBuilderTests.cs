using CraftQuest.Application;
using CraftQuest.Application.Options;

namespace CraftQuest.UnitTests.Sharing;

public class JoinLinkUrlBuilderTests
{
    [Fact]
    public void BuildJoinUrl_UsesWebAppDomainWithPathFormat()
    {
        var options = new JoinLinkOptions
        {
            LinkBaseUrl = "https://api.craftquestai.com",
            WebAppUrl = "https://app.craftquestai.com",
        };

        var url = JoinLinkUrlBuilder.BuildJoinUrl(options, "CQ-563141");

        Assert.Equal("https://app.craftquestai.com/join/CQ-563141", url);
    }

    [Fact]
    public void BuildWebJoinUrl_MatchesBuildJoinUrl()
    {
        var options = new JoinLinkOptions
        {
            WebAppUrl = "https://app.craftquestai.com",
        };

        Assert.Equal(
            JoinLinkUrlBuilder.BuildJoinUrl(options, "CQ-000001"),
            JoinLinkUrlBuilder.BuildWebJoinUrl(options, "CQ-000001"));
    }
}
