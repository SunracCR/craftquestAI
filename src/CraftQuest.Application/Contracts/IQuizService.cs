using CraftQuest.Application.Models.Quizzes;

namespace CraftQuest.Application.Contracts;

public interface IQuizService
{
    Task<IReadOnlyList<QuestionTypeDto>> GetQuestionTypesAsync(CancellationToken cancellationToken = default);
    Task<QuizDto> CreateQuizAsync(Guid userId, CreateQuizRequest request, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<QuizDto>> GetMyQuizzesAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<QuizDto> GetQuizAsync(Guid userId, Guid quizId, CancellationToken cancellationToken = default);
    Task<QuizDto> UpdateQuizAsync(Guid userId, Guid quizId, UpdateQuizRequest request, CancellationToken cancellationToken = default);
    Task DeleteQuizAsync(Guid userId, Guid quizId, CancellationToken cancellationToken = default);
    Task<QuestionDto> CreateQuestionAsync(Guid userId, Guid quizId, CreateQuestionRequest request, CancellationToken cancellationToken = default);
    Task<QuestionDto> UpdateQuestionAsync(
        Guid userId,
        Guid quizId,
        Guid questionId,
        CreateQuestionRequest request,
        CancellationToken cancellationToken = default);
    Task DeleteQuestionAsync(
        Guid userId,
        Guid quizId,
        Guid questionId,
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<QuestionDto>> GetQuestionsForAuthorAsync(Guid userId, Guid quizId, CancellationToken cancellationToken = default);
}
