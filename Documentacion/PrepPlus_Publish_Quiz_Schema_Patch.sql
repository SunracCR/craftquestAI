/* Prep+ — Parche para publicar cuestionarios curados
   Ejecutar en Azure SQL si falla POST /api/admin/prep/items/{id}/publish con error 500
   o restricción CHECK al guardar Visibility = 'curated'.

   Azure Portal → SQL Database → Query editor (o SSMS / Azure Data Studio).
   Ejecutar este script completo contra la base de datos de producción. */

/* 1) Columna IsCurated en Quizzes */
IF COL_LENGTH('quiz.Quizzes', 'IsCurated') IS NULL
BEGIN
    ALTER TABLE quiz.Quizzes
        ADD IsCurated BIT NOT NULL
            CONSTRAINT DF_Quizzes_IsCurated DEFAULT (0);
END
GO

/* 2) Ampliar CHECK de Visibility para incluir 'curated' */
IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'quiz.Quizzes')
      AND name = N'CK_Quizzes_Visibility')
BEGIN
    ALTER TABLE quiz.Quizzes DROP CONSTRAINT CK_Quizzes_Visibility;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'quiz.Quizzes')
      AND name = N'CK_Quizzes_Visibility')
BEGIN
    ALTER TABLE quiz.Quizzes
        ADD CONSTRAINT CK_Quizzes_Visibility CHECK (
            Visibility IN (
                'private',
                'shared_by_code',
                'class_only',
                'public',
                'curated'));
END
GO

/* 3) Verificación (debe devolver IsCurated=1 y Visibility con 'curated') */
SELECT
    CASE WHEN COL_LENGTH('quiz.Quizzes', 'IsCurated') IS NOT NULL THEN 1 ELSE 0 END AS HasIsCuratedColumn,
    cc.definition AS VisibilityCheckDefinition
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID(N'quiz.Quizzes')
  AND cc.name = N'CK_Quizzes_Visibility';
GO
