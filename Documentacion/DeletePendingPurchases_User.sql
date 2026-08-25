/* Elimina pagos PENDIENTES de la lista de transacciones de un usuario.
 *
 * Esas filas salen en GET /api/billing/purchases (historial de pagos de la app)
 * y viven en billing.Purchases con Status = 'pending'. Se crean al iniciar un
 * cobro PayPal / tienda y quedan ahí si el usuario no captura o abandona el flujo.
 *
 * Ajusta @Email antes de ejecutar.
 *
 * @DryRun = 1 (default): solo muestra las filas; no borra nada.
 * @DryRun = 0: borra las pendientes en una transacción.
 *
 * Qué NO hace:
 *   - No toca compras validated / refunded / rejected / cancelled.
 *   - No cancela órdenes ni suscripciones en PayPal / Google Play / App Store.
 *   - No cambia billing.UserSubscriptions ni PaymentIssuePending.
 *
 * Aborta si alguna pendiente tiene conversión de referido o asiento en CreditLedger
 * (eso no debería ocurrir en pending; indica datos inconsistentes).
 */

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';   -- <-- cambiar
DECLARE @DryRun BIT = 1;                          -- 1 = vista previa, 0 = ejecutar

DECLARE @UserId UNIQUEIDENTIFIER = (
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

IF OBJECT_ID('tempdb..#PendingPurchaseIds') IS NOT NULL
    DROP TABLE #PendingPurchaseIds;

CREATE TABLE #PendingPurchaseIds (
    PurchaseId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY
);

INSERT INTO #PendingPurchaseIds (PurchaseId)
SELECT p.PurchaseId
FROM billing.Purchases p
WHERE p.UserId = @UserId
  AND p.Status = N'pending';

PRINT N'--- DeletePendingPurchases_User ---';
PRINT N'Email: ' + @Email;
PRINT N'UserId: ' + CONVERT(NVARCHAR(36), @UserId);
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ' ELSE N'NO (BORRANDO)' END;
PRINT N'Pendientes: ' + CAST((SELECT COUNT(*) FROM #PendingPurchaseIds) AS NVARCHAR(20));
PRINT N'';

SELECT
    p.PurchaseId,
    p.ProductCode,
    p.ProductType,
    p.ProviderCode,
    p.ProviderTransactionId,
    p.Amount,
    p.CurrencyCode,
    p.Status,
    p.BillingCycle,
    p.PurchasedAt,
    p.CreatedAt
FROM billing.Purchases p
INNER JOIN #PendingPurchaseIds ids ON ids.PurchaseId = p.PurchaseId
ORDER BY ISNULL(p.PurchasedAt, p.CreatedAt) DESC;

IF NOT EXISTS (SELECT 1 FROM #PendingPurchaseIds)
BEGIN
    PRINT N'No hay compras pendientes para este usuario.';
    RETURN;
END;

DECLARE @ReferralCount INT = 0;
DECLARE @LedgerCount INT = 0;
DECLARE @QuizAccessCount INT = 0;

IF OBJECT_ID(N'catalog.PrepReferralConversions', N'U') IS NOT NULL
BEGIN
    SELECT @ReferralCount = COUNT(*)
    FROM catalog.PrepReferralConversions c
    WHERE c.PurchaseId IN (SELECT PurchaseId FROM #PendingPurchaseIds);
END;

SELECT @LedgerCount = COUNT(*)
FROM billing.CreditLedger cl
WHERE cl.ReferenceType = N'purchase'
  AND cl.ReferenceId IN (SELECT PurchaseId FROM #PendingPurchaseIds);

IF COL_LENGTH(N'sharing.QuizAccesses', N'GrantedByPurchaseId') IS NOT NULL
BEGIN
    SELECT @QuizAccessCount = COUNT(*)
    FROM sharing.QuizAccesses qa
    WHERE qa.GrantedByPurchaseId IN (SELECT PurchaseId FROM #PendingPurchaseIds);
END;

SELECT N'PrepReferralConversions' AS [TablaRelacionada], @ReferralCount AS [Filas]
UNION ALL
SELECT N'CreditLedger (purchase)', @LedgerCount
UNION ALL
SELECT N'QuizAccesses.GrantedByPurchaseId', @QuizAccessCount;

IF @ReferralCount > 0 OR @LedgerCount > 0
BEGIN
    RAISERROR(
        N'Abortado: hay conversiones de referido o asientos de crédito ligados a compras pending. Revisa los datos; no se borra nada.',
        16,
        1);
    RETURN;
END;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'DryRun: no se borró nada. Pon @DryRun = 0 para eliminar las filas listadas.';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'sharing.QuizAccesses', N'GrantedByPurchaseId') IS NOT NULL
       AND @QuizAccessCount > 0
    BEGIN
        UPDATE qa
        SET qa.GrantedByPurchaseId = NULL
        FROM sharing.QuizAccesses qa
        WHERE qa.GrantedByPurchaseId IN (SELECT PurchaseId FROM #PendingPurchaseIds);
    END;

    DELETE p
    FROM billing.Purchases p
    WHERE p.PurchaseId IN (SELECT PurchaseId FROM #PendingPurchaseIds)
      AND p.UserId = @UserId
      AND p.Status = N'pending';

    DECLARE @Deleted INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    PRINT N'';
    PRINT N'Compras pending eliminadas: ' + CAST(@Deleted AS NVARCHAR(20));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
