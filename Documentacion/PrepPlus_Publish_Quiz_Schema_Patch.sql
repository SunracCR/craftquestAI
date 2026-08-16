/* Prep+ — Parche para publicar cuestionarios curados
   Ejecutar en Azure SQL si falla POST /api/admin/prep/items/{id}/publish con error 500
   o restricción CHECK al guardar Visibility = 'curated'. */

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
