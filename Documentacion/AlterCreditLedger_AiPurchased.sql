-- Permite el tipo ai_purchased (créditos IA comprados, sin vencimiento mensual).
IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_CreditLedger_CreditType'
      AND parent_object_id = OBJECT_ID('billing.CreditLedger'))
BEGIN
    ALTER TABLE billing.CreditLedger DROP CONSTRAINT CK_CreditLedger_CreditType;
END
GO

ALTER TABLE billing.CreditLedger
ADD CONSTRAINT CK_CreditLedger_CreditType
    CHECK (CreditType IN ('ai', 'ai_purchased', 'share_code', 'teacher_seat'));
GO
