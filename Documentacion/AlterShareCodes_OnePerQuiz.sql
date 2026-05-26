/* Un código de compartir general por cuestionario (AssignmentId IS NULL).
   Elimina duplicados (revoked también bloqueaba el índice), reactiva exhausted
   y crea índice único filtrado. Seguro re-ejecutar tras un fallo parcial. */

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('tempdb..#ShareCodeKeepers') IS NOT NULL
    DROP TABLE #ShareCodeKeepers;
GO

;WITH Ranked AS (
    SELECT
        ShareCodeId,
        QuizId,
        ROW_NUMBER() OVER (
            PARTITION BY QuizId
            ORDER BY
                CASE WHEN Status = N'active' THEN 0
                     WHEN Status = N'exhausted' THEN 1
                     ELSE 2 END,
                CreatedAt DESC
        ) AS rn
    FROM sharing.ShareCodes
    WHERE AssignmentId IS NULL
      AND QuizId IS NOT NULL
)
SELECT ShareCodeId AS KeeperShareCodeId, QuizId
INTO #ShareCodeKeepers
FROM Ranked
WHERE rn = 1;
GO

;WITH Ranked AS (
    SELECT
        ShareCodeId,
        QuizId,
        ROW_NUMBER() OVER (
            PARTITION BY QuizId
            ORDER BY
                CASE WHEN Status = N'active' THEN 0
                     WHEN Status = N'exhausted' THEN 1
                     ELSE 2 END,
                CreatedAt DESC
        ) AS rn
    FROM sharing.ShareCodes
    WHERE AssignmentId IS NULL
      AND QuizId IS NOT NULL
),
Duplicates AS (
    SELECT ShareCodeId, QuizId
    FROM Ranked
    WHERE rn > 1
)
UPDATE qa
SET GrantedByShareCodeId = k.KeeperShareCodeId
FROM sharing.QuizAccesses qa
JOIN Duplicates d ON d.ShareCodeId = qa.GrantedByShareCodeId
JOIN #ShareCodeKeepers k ON k.QuizId = d.QuizId;
GO

;WITH Ranked AS (
    SELECT
        ShareCodeId,
        ROW_NUMBER() OVER (
            PARTITION BY QuizId
            ORDER BY
                CASE WHEN Status = N'active' THEN 0
                     WHEN Status = N'exhausted' THEN 1
                     ELSE 2 END,
                CreatedAt DESC
        ) AS rn
    FROM sharing.ShareCodes
    WHERE AssignmentId IS NULL
      AND QuizId IS NOT NULL
)
DELETE sc
FROM sharing.ShareCodes sc
JOIN Ranked r ON r.ShareCodeId = sc.ShareCodeId
WHERE r.rn > 1;
GO

UPDATE sharing.ShareCodes
SET Status = N'active'
WHERE AssignmentId IS NULL
  AND Status = N'exhausted';
GO

IF EXISTS (
    SELECT QuizId
    FROM sharing.ShareCodes
    WHERE AssignmentId IS NULL
      AND QuizId IS NOT NULL
    GROUP BY QuizId
    HAVING COUNT(*) > 1
)
BEGIN
    RAISERROR(N'Aun hay QuizId duplicados en sharing.ShareCodes. Revise antes de crear el indice.', 16, 1);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UQ_ShareCodes_Quiz_General'
      AND object_id = OBJECT_ID(N'sharing.ShareCodes')
)
BEGIN
    CREATE UNIQUE INDEX UQ_ShareCodes_Quiz_General
    ON sharing.ShareCodes(QuizId)
    WHERE AssignmentId IS NULL AND QuizId IS NOT NULL;
END
GO

SELECT QuizId, Code, Status, AccessPolicy, CreatedAt
FROM sharing.ShareCodes
WHERE AssignmentId IS NULL
ORDER BY CreatedAt DESC;
GO
