using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace CraftQuest.IntegrationTests;

public class QuizDeleteTests : IClassFixture<CraftQuestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CraftQuestWebApplicationFactory _factory;

    public QuizDeleteTests(CraftQuestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task DeleteQuiz_AfterPracticeSession_ReturnsNoContent()
    {
        var email = $"delete-quiz-{Guid.NewGuid():N}@craftquest.test";
        _factory.EmailSender.Reset();

        var registerResponse = await _client.PostAsJsonAsync(
            "/api/auth/register",
            new
            {
                email,
                password = "TestPass123!",
                displayName = "Delete Quiz Test",
            });

        Assert.Equal(HttpStatusCode.Created, registerResponse.StatusCode);

        var token = _factory.EmailSender.ExtractTokenFromLastEmail();
        Assert.False(string.IsNullOrWhiteSpace(token));

        var verifyResponse = await _client.PostAsJsonAsync(
            "/api/auth/verify-email",
            new { token });
        Assert.Equal(HttpStatusCode.OK, verifyResponse.StatusCode);

        var authBody = await verifyResponse.Content.ReadFromJsonAsync<JsonElement>();
        var accessToken = authBody.GetProperty("tokens").GetProperty("accessToken").GetString();
        Assert.False(string.IsNullOrWhiteSpace(accessToken));

        using var authed = new HttpRequestMessage(HttpMethod.Post, "/api/quizzes");
        authed.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        authed.Content = JsonContent.Create(new
        {
            title = "Quiz to delete",
            visibility = "private",
        });

        var createQuizResponse = await _client.SendAsync(authed);
        Assert.Equal(HttpStatusCode.Created, createQuizResponse.StatusCode);

        var quizBody = await createQuizResponse.Content.ReadFromJsonAsync<JsonElement>();
        var quizId = quizBody.GetProperty("quizId").GetGuid();

        using var createQuestion = new HttpRequestMessage(
            HttpMethod.Post,
            $"/api/quizzes/{quizId}/questions");
        createQuestion.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        createQuestion.Content = JsonContent.Create(new
        {
            questionType = "single_choice",
            text = "Sample question?",
            answerOptions = new[]
            {
                new { clientKey = "A", text = "Yes", defaultSortOrder = 0 },
                new { clientKey = "B", text = "No", defaultSortOrder = 1 },
            },
            correctAnswerKeys = new[] { "A" },
        });

        var createQuestionResponse = await _client.SendAsync(createQuestion);
        Assert.Equal(HttpStatusCode.Created, createQuestionResponse.StatusCode);

        using var publishQuiz = new HttpRequestMessage(HttpMethod.Patch, $"/api/quizzes/{quizId}");
        publishQuiz.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        publishQuiz.Content = JsonContent.Create(new { publicationStatus = "published" });

        var publishResponse = await _client.SendAsync(publishQuiz);
        Assert.Equal(HttpStatusCode.OK, publishResponse.StatusCode);

        using var startPractice = new HttpRequestMessage(HttpMethod.Post, "/api/practice-sessions");
        startPractice.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        startPractice.Content = JsonContent.Create(new
        {
            quizId,
            mode = "practice",
        });

        var practiceResponse = await _client.SendAsync(startPractice);
        Assert.Equal(HttpStatusCode.Created, practiceResponse.StatusCode);

        using var deleteQuiz = new HttpRequestMessage(HttpMethod.Delete, $"/api/quizzes/{quizId}");
        deleteQuiz.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        var deleteResponse = await _client.SendAsync(deleteQuiz);

        var deleteBody = await deleteResponse.Content.ReadAsStringAsync();
        Assert.True(
            deleteResponse.StatusCode == HttpStatusCode.NoContent,
            $"Expected 204, got {(int)deleteResponse.StatusCode}: {deleteBody}");
    }
}
