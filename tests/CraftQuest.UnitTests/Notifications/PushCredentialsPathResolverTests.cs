using CraftQuest.Infrastructure.Notifications;

namespace CraftQuest.UnitTests.Notifications;

public class PushCredentialsPathResolverTests
{
    [Fact]
    public void Resolve_PrefersConfiguredPathWhenItExists()
    {
        var path = PushCredentialsPathResolver.Resolve(
            @"D:\home\site\secrets\custom.json",
            exists: candidate => candidate == @"D:\home\site\secrets\custom.json");

        Assert.Equal(@"D:\home\site\secrets\custom.json", path);
    }

    [Fact]
    public void Resolve_MapsAzureWindowsPathToLinuxWhenWindowsFileMissing()
    {
        var path = PushCredentialsPathResolver.Resolve(
            @"D:\home\site\secrets\firebase-credentials.json",
            exists: candidate => candidate == "/home/site/secrets/firebase-credentials.json");

        Assert.Equal("/home/site/secrets/firebase-credentials.json", path);
    }

    [Fact]
    public void Resolve_FallsBackToDefaultLinuxSecretPath()
    {
        var path = PushCredentialsPathResolver.Resolve(
            "",
            exists: candidate => candidate == "/home/site/secrets/firebase-credentials.json");

        Assert.Equal("/home/site/secrets/firebase-credentials.json", path);
    }

    [Fact]
    public void Resolve_ReturnsNullWhenNoCandidateExists()
    {
        var path = PushCredentialsPathResolver.Resolve(
            "missing.json",
            exists: _ => false);

        Assert.Null(path);
    }

    [Fact]
    public void MapAzureWindowsPathToLinux_RewritesDriveHomePrefix()
    {
        Assert.Equal(
            "/home/site/secrets/firebase-credentials.json",
            PushCredentialsPathResolver.MapAzureWindowsPathToLinux(
                @"D:\home\site\secrets\firebase-credentials.json"));
    }
}
