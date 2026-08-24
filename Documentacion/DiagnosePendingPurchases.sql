-- Diagnóstico de compras que quedan en pending tras pagar en pasarelas.
-- Ejecutar en Azure SQL después de reproducir un pago fallido.

SET NOCOUNT ON;

PRINT N'=== Compras pending recientes ===';
SELECT TOP 30
    p.PurchaseId,
    u.Email,
    p.ProductCode,
    p.ProductType,
    p.ProviderCode,
    p.ProviderTransactionId,
    p.Status,
    p.Amount,
    p.CurrencyCode,
    p.BillingCycle,
    p.CreatedAt,
    p.PurchasedAt
FROM billing.Purchases p
JOIN core.Users u ON u.UserId = p.UserId
WHERE p.Status = N'pending'
ORDER BY p.CreatedAt DESC;

PRINT N'';
PRINT N'=== Pending por proveedor ===';
SELECT
    ProviderCode,
    ProductType,
    COUNT(*) AS PendingCount,
    MIN(CreatedAt) AS Oldest,
    MAX(CreatedAt) AS Newest
FROM billing.Purchases
WHERE Status = N'pending'
GROUP BY ProviderCode, ProductType
ORDER BY PendingCount DESC;

PRINT N'';
PRINT N'=== ¿Hay plan activo para usuarios con pending? ===';
SELECT TOP 30
    u.Email,
    p.ProviderCode,
    p.ProductCode,
    p.Status AS PurchaseStatus,
    p.CreatedAt AS PurchaseCreatedAt,
    pl.Code AS ActivePlanCode,
    us.Status AS SubscriptionStatus,
    us.ProviderCode AS SubProviderCode
FROM billing.Purchases p
JOIN core.Users u ON u.UserId = p.UserId
LEFT JOIN billing.UserSubscriptions us
    ON us.UserId = p.UserId AND us.Status = N'active'
LEFT JOIN billing.Plans pl ON pl.PlanId = us.PlanId
WHERE p.Status = N'pending'
ORDER BY p.CreatedAt DESC;

GO
