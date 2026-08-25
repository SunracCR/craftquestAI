/* Quita compras atascadas (pending / awaiting_payment) para poder volver a comprar.
 *
 * Cubre las 2 filas que lista DiagnosePendingPurchases.sql.
 *
 * El mensaje "There is a pending transaction for the same product" lo emite
 * Google Play. Este script solo borra filas en billing.Purchases.
 * Si ProviderCode = google_play, cancela también el pedido en Play Console
 * o el teléfono seguirá bloqueado.
 *
 * @Email NULL = todas las pending de la BD.
 * @DryRun = 1: solo lista.  @DryRun = 0: borra.
 *
 * No toca validated / refunded. No cancela suscripciones activas.
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

DECLARE @Email NVARCHAR(320) = NULL;   -- NULL = todas; o N'usuario@email.com'
DECLARE @DryRun BIT = 1;               -- 1 = vista previa, 0 = borrar

DECLARE @UserId UNIQUEIDENTIFIER = NULL;

IF @Email IS NOT NULL AND LTRIM(RTRIM(@Email)) <> N''
BEGIN
    SET @UserId = (
        SELECT TOP (1) UserId
        FROM core.Users
        WHERE (Email = @Email OR EmailNormalized = UPPER(LTRIM(RTRIM(@Email))))
          AND DeletedAt IS NULL
    );

    IF @UserId IS NULL
    BEGIN
        RAISERROR(N'Usuario no encontrado (o ya eliminado): %s', 16, 1, @Email);
        RETURN;
    END;
END;

IF OBJECT_ID('tempdb..#StuckIds') IS NOT NULL DROP TABLE #StuckIds;
CREATE TABLE #StuckIds (PurchaseId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #StuckIds (PurchaseId)
SELECT p.PurchaseId
FROM billing.Purchases p
WHERE p.Status IN (N'pending', N'awaiting_payment')
  AND (@UserId IS NULL OR p.UserId = @UserId);

PRINT N'--- ClearStuckPendingPurchases ---';
PRINT N'Alcance: ' + CASE WHEN @UserId IS NULL THEN N'TODA la BD' ELSE @Email END;
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ' ELSE N'NO (BORRANDO)' END;
PRINT N'Filas: ' + CAST((SELECT COUNT(*) FROM #StuckIds) AS NVARCHAR(20));
PRINT N'';

SELECT
    u.Email,
    p.PurchaseId,
    p.ProductType,
    p.ProductCode,
    p.ProviderCode,
    p.ProviderTransactionId,
    p.Amount,
    p.CurrencyCode,
    p.Status,
    p.CreatedAt,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM billing.CreditLedger cl
            WHERE cl.ReferenceType = N'purchase' AND cl.ReferenceId = p.PurchaseId
        ) THEN N'NO BORRAR: hay créditos (usa HealPendingPurchases)'
        WHEN EXISTS (
            SELECT 1 FROM sharing.QuizAccesses qa
            WHERE qa.GrantedByPurchaseId = p.PurchaseId
        ) THEN N'NO BORRAR: hay acceso Prep+ (usa HealPendingPurchases)'
        WHEN EXISTS (
            SELECT 1
            FROM billing.UserSubscriptions us
            WHERE us.UserId = p.UserId
              AND us.Status = N'active'
              AND us.ProviderCode = p.ProviderCode
              AND p.ProductType = N'subscription'
              AND us.StartedAt >= DATEADD(MINUTE, -5, p.CreatedAt)
        ) THEN N'NO BORRAR: hay suscripción activa (usa HealPendingPurchases)'
        ELSE N'OK borrar (checkout abandonado)'
    END AS Accion
FROM billing.Purchases p
INNER JOIN #StuckIds ids ON ids.PurchaseId = p.PurchaseId
INNER JOIN core.Users u ON u.UserId = p.UserId
ORDER BY p.CreatedAt DESC;

IF NOT EXISTS (SELECT 1 FROM #StuckIds)
BEGIN
    PRINT N'No hay compras pending / awaiting_payment.';
    RETURN;
END;

IF OBJECT_ID('tempdb..#SafeDeleteIds') IS NOT NULL DROP TABLE #SafeDeleteIds;
CREATE TABLE #SafeDeleteIds (PurchaseId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY);

INSERT INTO #SafeDeleteIds (PurchaseId)
SELECT p.PurchaseId
FROM billing.Purchases p
INNER JOIN #StuckIds ids ON ids.PurchaseId = p.PurchaseId
WHERE NOT EXISTS (
        SELECT 1 FROM billing.CreditLedger cl
        WHERE cl.ReferenceType = N'purchase' AND cl.ReferenceId = p.PurchaseId
    )
  AND NOT EXISTS (
        SELECT 1 FROM sharing.QuizAccesses qa
        WHERE qa.GrantedByPurchaseId = p.PurchaseId
    )
  AND NOT EXISTS (
        SELECT 1
        FROM billing.UserSubscriptions us
        WHERE us.UserId = p.UserId
          AND us.Status = N'active'
          AND us.ProviderCode = p.ProviderCode
          AND p.ProductType = N'subscription'
          AND us.StartedAt >= DATEADD(MINUTE, -5, p.CreatedAt)
    );

IF OBJECT_ID(N'catalog.PrepReferralConversions', N'U') IS NOT NULL
BEGIN
    DELETE s
    FROM #SafeDeleteIds s
    INNER JOIN catalog.PrepReferralConversions c ON c.PurchaseId = s.PurchaseId;
END;

DECLARE @Skipped INT = (SELECT COUNT(*) FROM #StuckIds)
                     - (SELECT COUNT(*) FROM #SafeDeleteIds);

PRINT N'Seguras para borrar: ' + CAST((SELECT COUNT(*) FROM #SafeDeleteIds) AS NVARCHAR(20));
PRINT N'Omitidas (beneficio ya otorgado): ' + CAST(@Skipped AS NVARCHAR(20));

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'DryRun: no se borró nada. Pon @DryRun = 0 para eliminar las filas OK borrar.';
    PRINT N'';
    PRINT N'Si ProviderCode = google_play: tras el DELETE, cancela el pedido pendiente';
    PRINT N'en Play Console (Order management) o en Play Store del teléfono.';
    PRINT N'Luego fuerza el cierre de CraftQuest y vuelve a abrirla.';
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM #SafeDeleteIds)
BEGIN
    PRINT N'Nada seguro para borrar. Si el plan/créditos sí se otorgaron, corre HealPendingPurchases.sql.';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'sharing.QuizAccesses', N'GrantedByPurchaseId') IS NOT NULL
    BEGIN
        UPDATE qa
        SET qa.GrantedByPurchaseId = NULL
        FROM sharing.QuizAccesses qa
        WHERE qa.GrantedByPurchaseId IN (SELECT PurchaseId FROM #SafeDeleteIds);
    END;

    DELETE p
    FROM billing.Purchases p
    WHERE p.PurchaseId IN (SELECT PurchaseId FROM #SafeDeleteIds)
      AND p.Status IN (N'pending', N'awaiting_payment');

    DECLARE @Deleted INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    PRINT N'';
    PRINT N'Compras pending eliminadas: ' + CAST(@Deleted AS NVARCHAR(20));
    PRINT N'Reejecuta DiagnosePendingPurchases.sql para confirmar que quedó en 0.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
