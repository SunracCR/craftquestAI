/* Caduca el acceso Prep+ temporal de un usuario a un cuestionario (sharing.QuizAccesses.ExpiresAt).
 *
 * Útil para probar:
 *   - práctica online bloqueada tras expiración
 *   - descarga/actualización offline denegada en servidor
 *   - sync offline rechazado
 *   - nuevas descargas con TTL acotado al acceso Prep+
 *
 * Ajusta @Email y UNO de: @CatalogItemId | @PrepSlug | @QuizTitle
 *
 * @ExpiredAt: fecha UTC a la que quedará el acceso (default: ayer).
 * @DryRun = 1 (default): solo vista previa. @DryRun = 0: ejecuta UPDATE.
 *
 * NO caduca acceso vitalicio (IsLifetimeAccess = 1); en ese caso el script avisa y no modifica.
 *
 * NOTA — descargas offline ya en el dispositivo:
 *   El TTL local (SQLite expires_at) no se actualiza desde SQL. Tras caducar el acceso aquí:
 *   1) abre la app CON INTERNET,
 *   2) entra en Descargas offline o intenta practicar: la app consulta /api/prep/my-accesses,
 *      ajusta expires_at local y bloquea la práctica si Prep+ ya expiró.
 *   Sin internet solo aplica el expires_at que tenía guardado al descargar.
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';           -- <-- cambiar
DECLARE @CatalogItemId UNIQUEIDENTIFIER = NULL;             -- opción A: GUID del ítem Prep+
DECLARE @PrepSlug NVARCHAR(160) = NULL;                     -- opción B: slug, ej. N'mi-cuestionario-abc12345'
DECLARE @QuizTitle NVARCHAR(300) = NULL;                    -- opción C: título aproximado (LIKE)
DECLARE @ExpiredAt DATETIME2(7) = DATEADD(DAY, -1, SYSUTCDATETIME());  -- acceso caducado desde ayer (UTC)
DECLARE @DryRun BIT = 1;                                     -- 1 = vista previa, 0 = ejecutar

DECLARE @UserId UNIQUEIDENTIFIER = (
    SELECT TOP (1) UserId
    FROM core.Users
    WHERE (Email = @Email OR EmailNormalized = UPPER(@Email))
      AND DeletedAt IS NULL
);

IF @UserId IS NULL
BEGIN
    RAISERROR(N'Usuario no encontrado (o cuenta eliminada): %s', 16, 1, @Email);
    RETURN;
END;

IF @CatalogItemId IS NULL
   AND ( @PrepSlug IS NULL OR LTRIM(RTRIM(@PrepSlug)) = N'' )
   AND ( @QuizTitle IS NULL OR LTRIM(RTRIM(@QuizTitle)) = N'' )
BEGIN
    RAISERROR(N'Indica @CatalogItemId, @PrepSlug o @QuizTitle.', 16, 1);
    RETURN;
END;

IF @CatalogItemId IS NULL
BEGIN
    SELECT TOP (1) @CatalogItemId = i.CatalogItemId
    FROM catalog.PrepCatalogItems i
    INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
    WHERE i.IsDeleted = 0
      AND (
            ( @PrepSlug IS NOT NULL AND LTRIM(RTRIM(@PrepSlug)) <> N''
              AND i.Slug = LOWER(LTRIM(RTRIM(@PrepSlug))) )
         OR ( @QuizTitle IS NOT NULL AND LTRIM(RTRIM(@QuizTitle)) <> N''
              AND ( i.TitleOverride LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%'
                    OR q.Title LIKE N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%' ) )
          )
    ORDER BY i.CreatedAt DESC;
END;

IF @CatalogItemId IS NULL
BEGIN
    RAISERROR(N'Ítem Prep+ no encontrado con los criterios indicados.', 16, 1);
    RETURN;
END;

DECLARE @QuizId UNIQUEIDENTIFIER;
DECLARE @ItemTitle NVARCHAR(300);
DECLARE @ItemSlug NVARCHAR(160);

SELECT
    @QuizId = i.QuizId,
    @ItemTitle = COALESCE(i.TitleOverride, q.Title),
    @ItemSlug = i.Slug
FROM catalog.PrepCatalogItems i
INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
WHERE i.CatalogItemId = @CatalogItemId;

IF @QuizId IS NULL
BEGIN
    RAISERROR(
        N'CatalogItemId %s no existe en catalog.PrepCatalogItems.',
        16,
        1,
        CONVERT(NVARCHAR(36), @CatalogItemId));
    RETURN;
END;

PRINT N'--- ExpireUserPrepPlusAccess ---';
PRINT N'Usuario: ' + @Email + N' (' + CONVERT(NVARCHAR(36), @UserId) + N')';
PRINT N'Ítem Prep+: ' + ISNULL(@ItemTitle, N'?') + N' | slug=' + ISNULL(@ItemSlug, N'(null)');
PRINT N'CatalogItemId: ' + CONVERT(NVARCHAR(36), @CatalogItemId);
PRINT N'QuizId: ' + CONVERT(NVARCHAR(36), @QuizId);
PRINT N'Nueva ExpiresAt (UTC): ' + CONVERT(NVARCHAR(30), @ExpiredAt, 126);
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ (solo vista previa)' ELSE N'NO (ejecutando)' END;
PRINT N'';

/* Accesos Prep+ purchase del usuario para este ítem / quiz */
IF OBJECT_ID('tempdb..#PrepAccess') IS NOT NULL
    DROP TABLE #PrepAccess;

SELECT
    qa.QuizAccessId,
    qa.AccessType,
    qa.IsLifetimeAccess,
    qa.GrantedAt,
    qa.ExpiresAt AS ExpiresAtActual,
    qa.PrepCatalogItemId,
    qa.GrantedByPurchaseId
INTO #PrepAccess
FROM sharing.QuizAccesses qa
WHERE qa.UserId = @UserId
  AND qa.AccessType = N'purchase'
  AND qa.ClassId IS NULL
  AND qa.AssignmentId IS NULL
  AND (
        qa.PrepCatalogItemId = @CatalogItemId
        OR qa.QuizId = @QuizId
      );

IF NOT EXISTS (SELECT 1 FROM #PrepAccess)
BEGIN
    PRINT N'Sin acceso Prep+ (purchase) para este usuario e ítem. Nada que caducar.';
    RETURN;
END;

IF EXISTS (SELECT 1 FROM #PrepAccess WHERE IsLifetimeAccess = 1)
BEGIN
    PRINT N'AVISO: el usuario tiene acceso vitalicio (IsLifetimeAccess = 1). Este script no modifica accesos de por vida.';
    PRINT N'Si necesitas quitar acceso vitalicio, usa Documentacion/RemoveUserPrepPlusLifetimeAccess.sql';
END;

SELECT
    pa.QuizAccessId,
    pa.AccessType,
    pa.IsLifetimeAccess,
    pa.GrantedAt,
    pa.ExpiresAtActual,
    CASE
        WHEN pa.IsLifetimeAccess = 1 THEN N'(sin cambio — vitalicio)'
        WHEN pa.ExpiresAtActual IS NOT NULL AND pa.ExpiresAtActual <= @ExpiredAt THEN N'(ya expirado)'
        ELSE CONVERT(NVARCHAR(30), @ExpiredAt, 126)
    END AS ExpiresAtNuevo,
    CASE
        WHEN pa.IsLifetimeAccess = 1 THEN N'omitido'
        WHEN pa.ExpiresAtActual IS NOT NULL AND pa.ExpiresAtActual <= @ExpiredAt THEN N'omitido'
        ELSE N'actualizar'
    END AS Accion
FROM #PrepAccess pa
ORDER BY pa.GrantedAt DESC;

DECLARE @RowsToUpdate INT = (
    SELECT COUNT(*)
    FROM #PrepAccess
    WHERE IsLifetimeAccess = 0
      AND (ExpiresAtActual IS NULL OR ExpiresAtActual > @ExpiredAt)
);

PRINT N'';
PRINT N'Filas a actualizar: ' + CAST(@RowsToUpdate AS NVARCHAR(10));

IF @RowsToUpdate = 0
BEGIN
    PRINT N'Sin cambios pendientes.';
    RETURN;
END;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'Sin cambios (DryRun=1). Para aplicar: SET @DryRun = 0';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE qa
    SET qa.ExpiresAt = @ExpiredAt
    FROM sharing.QuizAccesses qa
    INNER JOIN #PrepAccess pa ON pa.QuizAccessId = qa.QuizAccessId
    WHERE pa.IsLifetimeAccess = 0
      AND (pa.ExpiresAtActual IS NULL OR pa.ExpiresAtActual > @ExpiredAt);

    COMMIT TRANSACTION;

    PRINT N'';
    PRINT N'Acceso Prep+ caducado. Estado final:';

    SELECT
        qa.QuizAccessId,
        qa.AccessType,
        qa.IsLifetimeAccess,
        qa.GrantedAt,
        qa.ExpiresAt,
        CASE
            WHEN qa.IsLifetimeAccess = 1 THEN N'owned'
            WHEN qa.ExpiresAt IS NULL THEN N'none'
            WHEN qa.ExpiresAt > SYSUTCDATETIME() THEN N'active'
            ELSE N'expired'
        END AS AccessStateEsperadoEnApp
    FROM sharing.QuizAccesses qa
    INNER JOIN #PrepAccess pa ON pa.QuizAccessId = qa.QuizAccessId
    ORDER BY qa.GrantedAt DESC;

    PRINT N'';
    PRINT N'Listo. En la app: refresca Prep+ / cierra sesión si hace falta para ver estado Expirado.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;

GO
