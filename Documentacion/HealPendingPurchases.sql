-- Cierra compras huérfanas: el beneficio ya se otorgó pero la fila quedó pending.
-- Ejecutar en Azure SQL después de desplegar la API con reconciliación.

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- Suscripciones móviles/PayPal: plan activo tras la compra pending
UPDATE p
SET
    p.Status = N'validated',
    p.PurchasedAt = COALESCE(p.PurchasedAt, us.StartedAt, SYSUTCDATETIME())
FROM billing.Purchases p
INNER JOIN billing.UserSubscriptions us
    ON us.UserId = p.UserId
   AND us.Status = N'active'
   AND us.ProviderCode = p.ProviderCode
   AND us.StartedAt >= DATEADD(MINUTE, -5, p.CreatedAt)
WHERE p.Status IN (N'pending', N'awaiting_payment')
  AND p.ProductType = N'subscription';

PRINT CONCAT(N'Suscripciones corregidas: ', @@ROWCOUNT);

-- Créditos IA: ledger ya registrado para esa compra
UPDATE p
SET
    p.Status = N'validated',
    p.PurchasedAt = COALESCE(p.PurchasedAt, cl.CreatedAt, SYSUTCDATETIME())
FROM billing.Purchases p
INNER JOIN billing.CreditLedger cl
    ON cl.UserId = p.UserId
   AND cl.ReferenceId = p.PurchaseId
WHERE p.Status IN (N'pending', N'awaiting_payment')
  AND p.ProductType = N'ai_credits';

PRINT CONCAT(N'Créditos IA corregidos: ', @@ROWCOUNT);

-- Prep+: acceso ya concedido
UPDATE p
SET
    p.Status = N'validated',
    p.PurchasedAt = COALESCE(p.PurchasedAt, qa.GrantedAt, SYSUTCDATETIME())
FROM billing.Purchases p
INNER JOIN sharing.QuizAccesses qa
    ON qa.GrantedByPurchaseId = p.PurchaseId
WHERE p.Status IN (N'pending', N'awaiting_payment')
  AND p.ProductType = N'prep_access';

PRINT CONCAT(N'Prep+ corregidos: ', @@ROWCOUNT);

-- PayPal sin pagar > 48 h: cancelar (no confundir con pago completado)
UPDATE billing.Purchases
SET Status = N'cancelled'
WHERE Status = N'awaiting_payment'
  AND ProviderCode = N'paypal'
  AND CreatedAt < DATEADD(HOUR, -48, SYSUTCDATETIME());

PRINT CONCAT(N'PayPal sin completar cancelados: ', @@ROWCOUNT);

COMMIT TRANSACTION;

SELECT TOP 20
    ProviderCode,
    ProductType,
    Status,
    COUNT(*) AS Qty
FROM billing.Purchases
GROUP BY ProviderCode, ProductType, Status
ORDER BY Qty DESC;

GO
