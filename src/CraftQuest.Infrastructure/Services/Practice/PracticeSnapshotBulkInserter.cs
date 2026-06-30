using System.Data;
using System.Diagnostics;
using CraftQuest.Domain.Entities;
using CraftQuest.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace CraftQuest.Infrastructure.Services.Practice;

/// <summary>
/// Persists a fully-built practice session graph using SqlBulkCopy on SQL Server,
/// or EF Core Add/SaveChanges for InMemory tests.
/// </summary>
internal static class PracticeSnapshotBulkInserter
{
    private const int BulkCopyTimeoutSeconds = 60;

    public sealed class PersistOptions
    {
        public Guid? GuestVisitId { get; init; }
        public DateTime? GuestVisitLastActivityAt { get; init; }

        /// <summary>
        /// When set, only answer-option snapshots for this question snapshot are persisted synchronously.
        /// Remaining options must be inserted separately (typically in the background).
        /// </summary>
        public Guid? SynchronousAnswerOptionsQuestionSnapshotId { get; init; }

        public Action<string, long>? OnPhaseTiming { get; init; }
    }

    public static async Task InsertAsync(
        CraftQuestDbContext dbContext,
        PracticeSession session,
        PersistOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        if (!dbContext.Database.IsSqlServer())
        {
            dbContext.PracticeSessions.Add(session);
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        var strategy = dbContext.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var connection = (SqlConnection)dbContext.Database.GetDbConnection();
                if (connection.State != ConnectionState.Open)
                {
                    var openStopwatch = Stopwatch.StartNew();
                    await connection.OpenAsync(cancellationToken);
                    openStopwatch.Stop();
                    options?.OnPhaseTiming?.Invoke("connectionOpen", openStopwatch.ElapsedMilliseconds);
                }

                var sqlTransaction = transaction.GetDbTransaction() is SqlTransaction sqlTx
                    ? sqlTx
                    : throw new InvalidOperationException("Expected SqlTransaction for bulk insert.");

                await BulkInsertAsync(
                    connection,
                    sqlTransaction,
                    session,
                    options?.SynchronousAnswerOptionsQuestionSnapshotId,
                    options?.OnPhaseTiming,
                    cancellationToken);

                if (options?.GuestVisitId is Guid guestVisitId
                    && options.GuestVisitLastActivityAt is DateTime lastActivityAt)
                {
                    await UpdateGuestVisitLastActivityAsync(
                        connection,
                        sqlTransaction,
                        guestVisitId,
                        lastActivityAt,
                        cancellationToken);
                }

                await transaction.CommitAsync(cancellationToken);
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    public static async Task InsertAnswerOptionsAsync(
        CraftQuestDbContext dbContext,
        IReadOnlyList<PracticeAnswerOptionSnapshot> answerOptions,
        CancellationToken cancellationToken = default)
    {
        if (answerOptions.Count == 0)
        {
            return;
        }

        if (!dbContext.Database.IsSqlServer())
        {
            dbContext.PracticeAnswerOptionSnapshots.AddRange(answerOptions);
            await dbContext.SaveChangesAsync(cancellationToken);
            return;
        }

        var strategy = dbContext.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var connection = (SqlConnection)dbContext.Database.GetDbConnection();
                if (connection.State != ConnectionState.Open)
                {
                    await connection.OpenAsync(cancellationToken);
                }

                var sqlTransaction = transaction.GetDbTransaction() is SqlTransaction sqlTx
                    ? sqlTx
                    : throw new InvalidOperationException("Expected SqlTransaction for bulk insert.");

                var optionsTable = BuildAnswerOptionSnapshotsTable(answerOptions);
                await BulkCopyTableAsync(
                    connection,
                    sqlTransaction,
                    "practice.PracticeAnswerOptionSnapshots",
                    optionsTable,
                    cancellationToken);

                await transaction.CommitAsync(cancellationToken);
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    private static async Task BulkInsertAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        PracticeSession session,
        Guid? synchronousAnswerOptionsQuestionSnapshotId,
        Action<string, long>? onPhaseTiming,
        CancellationToken cancellationToken)
    {
        var sessionsTable = BuildSessionsTable(session);
        var questionsTable = BuildQuestionSnapshotsTable(session);
        var optionsTable = synchronousAnswerOptionsQuestionSnapshotId is Guid firstQuestionSnapshotId
            ? BuildAnswerOptionSnapshotsTable(
                session.QuestionSnapshots
                    .Where(q => q.PracticeQuestionSnapshotId == firstQuestionSnapshotId)
                    .SelectMany(q => q.AnswerOptionSnapshots)
                    .ToList())
            : BuildAnswerOptionSnapshotsTable(session);

        var sessionCopyStopwatch = Stopwatch.StartNew();
        await BulkCopyTableAsync(
            connection,
            transaction,
            "practice.PracticeSessions",
            sessionsTable,
            cancellationToken);
        sessionCopyStopwatch.Stop();
        onPhaseTiming?.Invoke("bulkCopySession", sessionCopyStopwatch.ElapsedMilliseconds);

        if (questionsTable.Rows.Count > 0)
        {
            var questionCopyStopwatch = Stopwatch.StartNew();
            await BulkCopyTableAsync(
                connection,
                transaction,
                "practice.PracticeQuestionSnapshots",
                questionsTable,
                cancellationToken);
            questionCopyStopwatch.Stop();
            onPhaseTiming?.Invoke("bulkCopyQuestions", questionCopyStopwatch.ElapsedMilliseconds);
        }

        if (optionsTable.Rows.Count > 0)
        {
            var optionCopyStopwatch = Stopwatch.StartNew();
            await BulkCopyTableAsync(
                connection,
                transaction,
                "practice.PracticeAnswerOptionSnapshots",
                optionsTable,
                cancellationToken);
            optionCopyStopwatch.Stop();
            onPhaseTiming?.Invoke("bulkCopyOptions", optionCopyStopwatch.ElapsedMilliseconds);
        }
    }

    private static async Task BulkCopyTableAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        string destinationTable,
        DataTable table,
        CancellationToken cancellationToken)
    {
        using var bulkCopy = new SqlBulkCopy(connection, SqlBulkCopyOptions.Default, transaction)
        {
            DestinationTableName = destinationTable,
            BulkCopyTimeout = BulkCopyTimeoutSeconds,
        };

        foreach (DataColumn column in table.Columns)
        {
            bulkCopy.ColumnMappings.Add(column.ColumnName, column.ColumnName);
        }

        await bulkCopy.WriteToServerAsync(table, cancellationToken);
    }

    private static async Task UpdateGuestVisitLastActivityAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        Guid guestVisitId,
        DateTime lastActivityAt,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = """
            UPDATE guest.GuestVisits
            SET LastActivityAt = @lastActivityAt
            WHERE GuestVisitId = @guestVisitId
            """;
        command.Parameters.Add(new SqlParameter("@lastActivityAt", SqlDbType.DateTime2) { Value = lastActivityAt });
        command.Parameters.Add(new SqlParameter("@guestVisitId", SqlDbType.UniqueIdentifier) { Value = guestVisitId });
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static DataTable BuildSessionsTable(PracticeSession session)
    {
        var table = new DataTable();
        table.Columns.Add("PracticeSessionId", typeof(Guid));
        table.Columns.Add("StudentUserId", typeof(Guid));
        table.Columns.Add("QuizId", typeof(Guid));
        table.Columns.Add("ClassId", typeof(Guid));
        table.Columns.Add("AssignmentId", typeof(Guid));
        table.Columns.Add("StartedAt", typeof(DateTime));
        table.Columns.Add("FinishedAt", typeof(DateTime));
        table.Columns.Add("DurationSeconds", typeof(int));
        table.Columns.Add("ScoreObtained", typeof(decimal));
        table.Columns.Add("ScorePossible", typeof(decimal));
        table.Columns.Add("CorrectAnswers", typeof(int));
        table.Columns.Add("IncorrectAnswers", typeof(int));
        table.Columns.Add("OmittedAnswers", typeof(int));
        table.Columns.Add("Status", typeof(string));
        table.Columns.Add("RandomizationStrategy", typeof(string));
        table.Columns.Add("ShowElapsedTimer", typeof(bool));
        table.Columns.Add("CurrentQuestionIndex", typeof(int));
        table.Columns.Add("ElapsedSecondsBeforePause", typeof(int));
        table.Columns.Add("PausedAt", typeof(DateTime));
        table.Columns.Add("LastActivityAt", typeof(DateTime));
        table.Columns.Add("CreatedAt", typeof(DateTime));
        table.Columns.Add("GuestVisitId", typeof(Guid));

        table.Rows.Add(
            session.PracticeSessionId,
            ToDbValue(session.StudentUserId),
            session.QuizId,
            ToDbValue(session.ClassId),
            ToDbValue(session.AssignmentId),
            session.StartedAt,
            ToDbValue(session.FinishedAt),
            ToDbValue(session.DurationSeconds),
            session.ScoreObtained,
            session.ScorePossible,
            session.CorrectAnswers,
            session.IncorrectAnswers,
            session.OmittedAnswers,
            session.Status,
            session.RandomizationStrategy,
            session.ShowElapsedTimer,
            ToDbValue(session.CurrentQuestionIndex),
            session.ElapsedSecondsBeforePause,
            ToDbValue(session.PausedAt),
            ToDbValue(session.LastActivityAt),
            session.CreatedAt,
            ToDbValue(session.GuestVisitId));

        return table;
    }

    private static DataTable BuildQuestionSnapshotsTable(PracticeSession session)
    {
        var table = new DataTable();
        table.Columns.Add("PracticeQuestionSnapshotId", typeof(Guid));
        table.Columns.Add("PracticeSessionId", typeof(Guid));
        table.Columns.Add("QuestionId", typeof(Guid));
        table.Columns.Add("QuestionTypeCodeSnapshot", typeof(string));
        table.Columns.Add("QuestionTextSnapshot", typeof(string));
        table.Columns.Add("QuizSectionNameSnapshot", typeof(string));
        table.Columns.Add("PointsPossible", typeof(decimal));
        table.Columns.Add("PointsAwarded", typeof(decimal));
        table.Columns.Add("DisplayOrder", typeof(int));
        table.Columns.Add("AnswerStatus", typeof(string));
        table.Columns.Add("IsCorrect", typeof(bool));
        table.Columns.Add("TimeSpentSeconds", typeof(int));
        table.Columns.Add("RandomizationSeed", typeof(string));
        table.Columns.Add("SubmittedAt", typeof(DateTime));
        table.Columns.Add("JustificationTextSnapshot", typeof(string));
        table.Columns.Add("JustificationSourcesSnapshot", typeof(string));
        table.Columns.Add("CreatedAt", typeof(DateTime));

        foreach (var question in session.QuestionSnapshots)
        {
            table.Rows.Add(
                question.PracticeQuestionSnapshotId,
                question.PracticeSessionId,
                question.QuestionId,
                question.QuestionTypeCodeSnapshot,
                question.QuestionTextSnapshot,
                ToDbValue(question.QuizSectionNameSnapshot),
                question.PointsPossible,
                question.PointsAwarded,
                question.DisplayOrder,
                question.AnswerStatus,
                ToDbValue(question.IsCorrect),
                ToDbValue(question.TimeSpentSeconds),
                ToDbValue(question.RandomizationSeed),
                ToDbValue(question.SubmittedAt),
                ToDbValue(question.JustificationTextSnapshot),
                ToDbValue(question.JustificationSourcesSnapshot),
                question.CreatedAt);
        }

        return table;
    }

    private static DataTable BuildAnswerOptionSnapshotsTable(PracticeSession session) =>
        BuildAnswerOptionSnapshotsTable(
            session.QuestionSnapshots.SelectMany(q => q.AnswerOptionSnapshots).ToList());

    private static DataTable BuildAnswerOptionSnapshotsTable(
        IReadOnlyList<PracticeAnswerOptionSnapshot> answerOptions)
    {
        var table = new DataTable();
        table.Columns.Add("PracticeAnswerOptionSnapshotId", typeof(Guid));
        table.Columns.Add("PracticeQuestionSnapshotId", typeof(Guid));
        table.Columns.Add("AnswerOptionId", typeof(Guid));
        table.Columns.Add("StableKeySnapshot", typeof(string));
        table.Columns.Add("DisplayOrder", typeof(int));
        table.Columns.Add("DisplayLabel", typeof(string));
        table.Columns.Add("AnswerTextSnapshot", typeof(string));
        table.Columns.Add("MediaAssetIdSnapshot", typeof(Guid));
        table.Columns.Add("IsCorrectSnapshot", typeof(bool));
        table.Columns.Add("WasSelected", typeof(bool));
        table.Columns.Add("SelectedAt", typeof(DateTime));
        table.Columns.Add("CreatedAt", typeof(DateTime));

        foreach (var option in answerOptions)
        {
            table.Rows.Add(
                option.PracticeAnswerOptionSnapshotId,
                option.PracticeQuestionSnapshotId,
                option.AnswerOptionId,
                ToDbValue(option.StableKeySnapshot),
                option.DisplayOrder,
                option.DisplayLabel,
                ToDbValue(option.AnswerTextSnapshot),
                ToDbValue(option.MediaAssetIdSnapshot),
                option.IsCorrectSnapshot,
                option.WasSelected,
                ToDbValue(option.SelectedAt),
                option.CreatedAt);
        }

        return table;
    }

    private static object ToDbValue<T>(T? value) where T : struct =>
        value.HasValue ? value.Value : DBNull.Value;

    private static object ToDbValue(string? value) =>
        value is null ? DBNull.Value : value;
}
