namespace CraftQuest.Infrastructure.Services.PrepPlus;

internal sealed class PrepPlusCustomPracticeFilter
{
    public IReadOnlyList<Guid>? SectionIds { get; init; }
    public IReadOnlyList<Guid>? TopicIds { get; init; }
    public string? Difficulty { get; init; }
    public bool RequireTaggedSection { get; init; }

    public IQueryable<Domain.Entities.Question> Apply(
        IQueryable<Domain.Entities.Question> query,
        IReadOnlyDictionary<Guid, Guid> topicSectionMap)
    {
        if (RequireTaggedSection)
        {
            query = query.Where(q => q.QuizSectionId != null);
        }

        if (TopicIds is { Count: > 0 })
        {
            var topicSet = TopicIds.ToHashSet();
            query = query.Where(q => q.QuizTopicId != null && topicSet.Contains(q.QuizTopicId.Value));
        }
        else if (SectionIds is { Count: > 0 })
        {
            var sectionSet = SectionIds.ToHashSet();
            query = query.Where(q => q.QuizSectionId != null && sectionSet.Contains(q.QuizSectionId.Value));
        }

        if (!string.IsNullOrWhiteSpace(Difficulty))
        {
            var difficulty = Difficulty.Trim().ToLowerInvariant();
            query = query.Where(q => q.Difficulty == difficulty);
        }

        return query;
    }

    public bool MatchesTopicSectionConstraints(
        Guid? sectionId,
        Guid? topicId,
        IReadOnlyDictionary<Guid, Guid> topicSectionMap)
    {
        if (TopicIds is { Count: > 0 })
        {
            if (topicId is null || !TopicIds.Contains(topicId.Value))
            {
                return false;
            }

            if (SectionIds is { Count: > 0 }
                && topicSectionMap.TryGetValue(topicId.Value, out var topicSection)
                && !SectionIds.Contains(topicSection))
            {
                return false;
            }

            return true;
        }

        if (SectionIds is { Count: > 0 })
        {
            return sectionId is not null && SectionIds.Contains(sectionId.Value);
        }

        return true;
    }
}
