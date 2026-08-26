/*
  Añade 'awaiting_payment' al CHECK de billing.Purchases.Status.

  La app usa PurchaseStatuses.AwaitingPayment (= 'awaiting_payment') cuando el usuario
  inicia checkout PayPal pero aún no completa el pago. Sin este valor, INSERT falla con:
  "The INSERT statement conflicted with the CHECK constraint CK_Purchases_Status".

  Ejecutar una vez en Azure SQL (producción/staging).
*/
SET NOCOUNT ON;

IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Purchases_Status'
      AND parent_object_id = OBJECT_ID(N'billing.Purchases'))
BEGIN
    ALTER TABLE billing.Purchases DROP CONSTRAINT CK_Purchases_Status;
    PRINT N'Constraint CK_Purchases_Status eliminado.';
END

ALTER TABLE billing.Purchases
    ADD CONSTRAINT CK_Purchases_Status
        CHECK (Status IN (
            N'pending',
            N'awaiting_payment',
            N'validated',
            N'rejected',
            N'refunded',
            N'cancelled'));

PRINT N'Constraint CK_Purchases_Status actualizado (incluye awaiting_payment).';
