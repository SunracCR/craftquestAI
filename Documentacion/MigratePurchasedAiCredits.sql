-- Migra compras de créditos IA al tipo permanente ai_purchased (no expiran en reinicio mensual).
-- Requisito previo: AlterCreditLedger_AiPurchased.sql
-- Ejecutar una vez en BD existente si ya hubo compras con CreditType = 'ai' y Reason = 'purchase'.

UPDATE billing.CreditLedger
SET CreditType = 'ai_purchased'
WHERE CreditType = 'ai'
  AND Reason = 'purchase';
GO
