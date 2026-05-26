using CraftQuest.Application.Models.Practice;

namespace CraftQuest.Application.Contracts;

public interface IQuizPracticePreferenceService
{
    Task<QuizPracticePreferenceDto> GetAsync(
        Guid userId,
        Guid quizId,
        CancellationToken cancellationToken = default);

    Task<QuizPracticePreferenceDto> UpsertAsync(
        Guid userId,
        Guid quizId,
        UpsertQuizPracticePreferenceRequest request,
        CancellationToken cancellationToken = default);
}
