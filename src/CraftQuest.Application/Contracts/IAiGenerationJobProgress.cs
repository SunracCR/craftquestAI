namespace CraftQuest.Application.Contracts;

public interface IAiGenerationJobProgress
{
    void Attach(Guid aiJobId);

    void Detach();

    Task UpdateAsync(
        string stage,
        int? progressPercent,
        CancellationToken cancellationToken = default);
}
