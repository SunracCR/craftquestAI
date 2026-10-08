/* Pasa a publicados los cuestionarios que siguen en borrador.

   Los cuestionarios nuevos ya nacen con PublicationStatus = 'published'.
   Este script alinea los que se crearon antes, cuando el alta los dejaba
   en 'draft'. No toca review, archived ni deleted.

   @DryRun = 1 (default): solo muestra cuántos cambiarían.
   @DryRun = 0: ejecuta el UPDATE.

   Ejecutar en la base de CraftQuest (SSMS / Azure Data Studio).
*/

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DryRun BIT = 1; -- 1 = vista previa, 0 = ejecutar

DECLARE @DraftCount INT = (
    SELECT COUNT(*)
    FROM quiz.Quizzes
    WHERE PublicationStatus = N'draft'
);

SELECT
    @DraftCount AS DraftQuizzesToPublish,
    @DryRun AS DryRun;

IF @DryRun = 1
BEGIN
    SELECT
        QuizId,
        Title,
        CreatedByUserId,
        CreatedAt,
        DeletedAt
    FROM quiz.Quizzes
    WHERE PublicationStatus = N'draft'
    ORDER BY CreatedAt;
    RETURN;
END;

BEGIN TRAN;

UPDATE quiz.Quizzes
SET PublicationStatus = N'published',
    UpdatedAt = SYSUTCDATETIME()
WHERE PublicationStatus = N'draft';

SELECT @@ROWCOUNT AS QuizzesPublished;

COMMIT TRAN;
