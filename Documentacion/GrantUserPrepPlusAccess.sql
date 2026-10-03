/* Concede a un usuario acceso de pago a un cuestionario Prep+.

   Hace lo mismo que una compra validada:
     - inserta billing.Purchases (ProductType = prep_access, Status = validated)
     - crea o extiende sharing.QuizAccesses (AccessType = purchase)

   ProviderCode = manual_admin para distinguirlo de PayPal / tiendas.
   No aplica recompensas de referido.

   Identifica el usuario con @Email.
   Identifica el cuestionario con UNO de: @CatalogItemId | @PrepSlug | @QuizTitle
   Identifica la oferta con UNO de:
     @OfferId
     @IsLifetime = 1          (acceso definitivo; exige oferta vitalicia activa)
     @DurationDays            (30, 60, 90 o 183; exige esa oferta activa)

   Si el usuario ya tiene acceso temporal vigente, se extiende desde ExpiresAt
   (igual que una compra nueva). Si ya tiene acceso vitalicio, no se modifica nada.

   @DryRun = 1 (default): solo muestra qué se haría.
   @DryRun = 0: ejecuta INSERT / UPDATE.

   Ejecutar en la base de CraftQuest (SSMS / Azure Data Studio).
*/

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';             -- <-- cambiar
DECLARE @CatalogItemId UNIQUEIDENTIFIER = NULL;             -- opción A: GUID del ítem Prep+
DECLARE @PrepSlug NVARCHAR(160) = NULL;                     -- opción B: slug exacto
DECLARE @QuizTitle NVARCHAR(300) = NULL;                    -- opción C: título parcial (LIKE)
DECLARE @OfferId UNIQUEIDENTIFIER = NULL;                   -- opción de oferta: GUID
DECLARE @DurationDays INT = NULL;                           -- opción de oferta: 30, 60, 90 o 183
DECLARE @IsLifetime BIT = 0;                                -- opción de oferta: 1 = acceso definitivo
DECLARE @DryRun BIT = 1;                                    -- 1 = vista previa, 0 = ejecutar

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

IF @IsLifetime = 1 AND @DurationDays IS NOT NULL
BEGIN
    RAISERROR(N'Indica @IsLifetime = 1 o @DurationDays, no ambos.', 16, 1);
    RETURN;
END;

IF @DurationDays IS NOT NULL AND @DurationDays NOT IN (30, 60, 90, 183)
BEGIN
    RAISERROR(N'@DurationDays debe ser 30, 60, 90 o 183.', 16, 1);
    RETURN;
END;

IF @CatalogItemId IS NULL AND @PrepSlug IS NOT NULL AND LTRIM(RTRIM(@PrepSlug)) <> N''
BEGIN
    DECLARE @SlugMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCatalogItems
        WHERE Slug = LOWER(LTRIM(RTRIM(@PrepSlug)))
          AND IsDeleted = 0
    );

    IF @SlugMatches = 0
    BEGIN
        RAISERROR(N'No hay ítem Prep+ activo con ese slug.', 16, 1);
        RETURN;
    END;

    IF @SlugMatches > 1
    BEGIN
        SELECT CatalogItemId, Slug, TitleOverride, QuizId, IsPublished
        FROM catalog.PrepCatalogItems
        WHERE Slug = LOWER(LTRIM(RTRIM(@PrepSlug)))
          AND IsDeleted = 0;

        RAISERROR(N'Hay varios ítems con ese slug. Usa @CatalogItemId.', 16, 1);
        RETURN;
    END;

    SELECT @CatalogItemId = CatalogItemId
    FROM catalog.PrepCatalogItems
    WHERE Slug = LOWER(LTRIM(RTRIM(@PrepSlug)))
      AND IsDeleted = 0;
END;

IF @CatalogItemId IS NULL AND @QuizTitle IS NOT NULL AND LTRIM(RTRIM(@QuizTitle)) <> N''
BEGIN
    DECLARE @TitlePattern NVARCHAR(302) = N'%' + LTRIM(RTRIM(@QuizTitle)) + N'%';

    DECLARE @TitleMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCatalogItems i
        INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
        WHERE i.IsDeleted = 0
          AND (
                i.TitleOverride LIKE @TitlePattern
                OR q.Title LIKE @TitlePattern
              )
    );

    IF @TitleMatches = 0
    BEGIN
        RAISERROR(N'No hay ítem Prep+ activo con ese título.', 16, 1);
        RETURN;
    END;

    IF @TitleMatches > 1
    BEGIN
        SELECT
            i.CatalogItemId,
            i.Slug,
            COALESCE(i.TitleOverride, q.Title) AS Titulo,
            c.Name AS Categoria,
            i.IsPublished,
            i.QuizId
        FROM catalog.PrepCatalogItems i
        INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
        INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
        WHERE i.IsDeleted = 0
          AND (
                i.TitleOverride LIKE @TitlePattern
                OR q.Title LIKE @TitlePattern
              )
        ORDER BY i.CreatedAt DESC;

        RAISERROR(N'Hay varios ítems con ese título. Usa @CatalogItemId.', 16, 1);
        RETURN;
    END;

    SELECT @CatalogItemId = i.CatalogItemId
    FROM catalog.PrepCatalogItems i
    INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
    WHERE i.IsDeleted = 0
      AND (
            i.TitleOverride LIKE @TitlePattern
            OR q.Title LIKE @TitlePattern
          );
END;

IF NOT EXISTS (
    SELECT 1
    FROM catalog.PrepCatalogItems
    WHERE CatalogItemId = @CatalogItemId
      AND IsDeleted = 0
)
BEGIN
    RAISERROR(N'Ítem Prep+ no encontrado o está eliminado.', 16, 1);
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

IF @OfferId IS NULL AND @IsLifetime = 0 AND @DurationDays IS NULL
BEGIN
    PRINT N'Ofertas activas de este cuestionario:';

    SELECT
        o.OfferId,
        o.DurationDays,
        o.IsLifetimeAccess,
        o.IsFree,
        o.PriceAmount,
        o.CurrencyCode,
        o.IsActive
    FROM catalog.PrepAccessOffers o
    WHERE o.CatalogItemId = @CatalogItemId
    ORDER BY o.IsLifetimeAccess, o.DurationDays;

    RAISERROR(N'Indica @OfferId, @DurationDays (30/60/90/183) o @IsLifetime = 1.', 16, 1);
    RETURN;
END;

IF @OfferId IS NULL
BEGIN
    DECLARE @OfferMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepAccessOffers o
        WHERE o.CatalogItemId = @CatalogItemId
          AND o.IsActive = 1
          AND (
                (@IsLifetime = 1 AND o.IsLifetimeAccess = 1)
             OR (@IsLifetime = 0 AND o.IsLifetimeAccess = 0 AND o.DurationDays = @DurationDays)
              )
    );

    IF @OfferMatches = 0
    BEGIN
        SELECT
            o.OfferId,
            o.DurationDays,
            o.IsLifetimeAccess,
            o.PriceAmount,
            o.CurrencyCode,
            o.IsActive
        FROM catalog.PrepAccessOffers o
        WHERE o.CatalogItemId = @CatalogItemId
        ORDER BY o.IsLifetimeAccess, o.DurationDays;

        RAISERROR(N'No hay oferta activa con esa duración o vitalicia. Revisa el listado.', 16, 1);
        RETURN;
    END;

    IF @OfferMatches > 1
    BEGIN
        SELECT OfferId, DurationDays, IsLifetimeAccess, PriceAmount, CurrencyCode
        FROM catalog.PrepAccessOffers
        WHERE CatalogItemId = @CatalogItemId
          AND IsActive = 1
          AND (
                (@IsLifetime = 1 AND IsLifetimeAccess = 1)
             OR (@IsLifetime = 0 AND IsLifetimeAccess = 0 AND DurationDays = @DurationDays)
              );

        RAISERROR(N'Hay varias ofertas que coinciden. Usa @OfferId.', 16, 1);
        RETURN;
    END;

    SELECT @OfferId = o.OfferId
    FROM catalog.PrepAccessOffers o
    WHERE o.CatalogItemId = @CatalogItemId
      AND o.IsActive = 1
      AND (
            (@IsLifetime = 1 AND o.IsLifetimeAccess = 1)
         OR (@IsLifetime = 0 AND o.IsLifetimeAccess = 0 AND o.DurationDays = @DurationDays)
          );
END;

DECLARE @OfferDurationDays INT;
DECLARE @OfferIsLifetime BIT;
DECLARE @PriceAmount DECIMAL(12, 2);
DECLARE @CurrencyCode NVARCHAR(10);
DECLARE @OfferIsActive BIT;

SELECT
    @OfferDurationDays = o.DurationDays,
    @OfferIsLifetime = o.IsLifetimeAccess,
    @PriceAmount = o.PriceAmount,
    @CurrencyCode = o.CurrencyCode,
    @OfferIsActive = o.IsActive
FROM catalog.PrepAccessOffers o
WHERE o.OfferId = @OfferId
  AND o.CatalogItemId = @CatalogItemId;

IF @OfferDurationDays IS NULL AND @OfferIsLifetime IS NULL
BEGIN
    RAISERROR(N'La oferta no pertenece a este ítem Prep+.', 16, 1);
    RETURN;
END;

IF @OfferIsActive = 0
BEGIN
    RAISERROR(N'La oferta está inactiva.', 16, 1);
    RETURN;
END;

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();

DECLARE @ExistingAccessId UNIQUEIDENTIFIER;
DECLARE @ExistingIsLifetime BIT;
DECLARE @ExistingExpiresAt DATETIME2(7);
DECLARE @ExistingAccessType NVARCHAR(40);
DECLARE @ExistingGrantedAt DATETIME2(7);

SELECT TOP (1)
    @ExistingAccessId = qa.QuizAccessId,
    @ExistingIsLifetime = qa.IsLifetimeAccess,
    @ExistingExpiresAt = qa.ExpiresAt,
    @ExistingAccessType = qa.AccessType,
    @ExistingGrantedAt = qa.GrantedAt
FROM sharing.QuizAccesses qa
WHERE qa.UserId = @UserId
  AND qa.QuizId = @QuizId
  AND qa.ClassId IS NULL
  AND qa.AssignmentId IS NULL
ORDER BY qa.IsLifetimeAccess DESC, qa.ExpiresAt DESC;

IF @ExistingIsLifetime = 1 AND @ExistingAccessType = N'purchase'
BEGIN
    PRINT N'El usuario ya tiene acceso vitalicio a este cuestionario. No se modifica nada.';
    SELECT
        @ExistingAccessId AS QuizAccessId,
        @ExistingAccessType AS AccessType,
        @ExistingIsLifetime AS IsLifetimeAccess,
        @ExistingGrantedAt AS GrantedAt,
        @ExistingExpiresAt AS ExpiresAt;
    RETURN;
END;

DECLARE @BaseDate DATETIME2(7) = @Now;
DECLARE @NewExpiresAt DATETIME2(7) = NULL;
DECLARE @KeepGrantedAt BIT = 0;

IF @OfferIsLifetime = 0
BEGIN
    IF @ExistingAccessId IS NOT NULL
       AND @ExistingAccessType = N'purchase'
       AND @ExistingIsLifetime = 0
       AND @ExistingExpiresAt > @Now
    BEGIN
        SET @BaseDate = @ExistingExpiresAt;
        SET @KeepGrantedAt = 1;
    END;

    SET @NewExpiresAt = DATEADD(DAY, @OfferDurationDays, @BaseDate);
END;

DECLARE @PurchaseId UNIQUEIDENTIFIER = NEWID();
DECLARE @ProductCode NVARCHAR(100) =
    LOWER(REPLACE(CONVERT(NVARCHAR(36), @CatalogItemId), N'-', N''))
    + N'|'
    + LOWER(REPLACE(CONVERT(NVARCHAR(36), @OfferId), N'-', N''));
DECLARE @ProviderTransactionId NVARCHAR(300) =
    N'manual-' + LOWER(REPLACE(CONVERT(NVARCHAR(36), @PurchaseId), N'-', N''));

PRINT N'--- GrantUserPrepPlusAccess ---';
PRINT N'Usuario: ' + @Email + N' (' + CONVERT(NVARCHAR(36), @UserId) + N')';
PRINT N'Ítem Prep+: ' + ISNULL(@ItemTitle, N'?') + N' | slug=' + ISNULL(@ItemSlug, N'(null)');
PRINT N'CatalogItemId: ' + CONVERT(NVARCHAR(36), @CatalogItemId);
PRINT N'QuizId: ' + CONVERT(NVARCHAR(36), @QuizId);
PRINT N'OfferId: ' + CONVERT(NVARCHAR(36), @OfferId);
PRINT N'Oferta: ' + CASE WHEN @OfferIsLifetime = 1 THEN N'vitalicia' ELSE CAST(@OfferDurationDays AS NVARCHAR(10)) + N' días' END;
PRINT N'Importe: ' + CONVERT(NVARCHAR(20), @PriceAmount) + N' ' + ISNULL(@CurrencyCode, N'');
PRINT N'Acceso actual: ' + CASE
    WHEN @ExistingAccessId IS NULL THEN N'ninguno'
    WHEN @ExistingIsLifetime = 1 THEN N'vitalicio'
    WHEN @ExistingExpiresAt IS NULL THEN ISNULL(@ExistingAccessType, N'?')
    WHEN @ExistingExpiresAt > @Now THEN ISNULL(@ExistingAccessType, N'?') + N' vigente hasta ' + CONVERT(NVARCHAR(30), @ExistingExpiresAt, 126)
    ELSE ISNULL(@ExistingAccessType, N'?') + N' expirado'
END;
PRINT N'Acceso nuevo: ' + CASE
    WHEN @OfferIsLifetime = 1 THEN N'vitalicio'
    ELSE N'hasta ' + CONVERT(NVARCHAR(30), @NewExpiresAt, 126) + N' UTC'
END;
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÍ (solo vista previa)' ELSE N'NO (ejecutando)' END;
PRINT N'';

SELECT
    @PurchaseId AS PurchaseId,
    @ProductCode AS ProductCode,
    N'prep_access' AS ProductType,
    N'manual_admin' AS ProviderCode,
    @ProviderTransactionId AS ProviderTransactionId,
    @PriceAmount AS Amount,
    @CurrencyCode AS CurrencyCode,
    N'validated' AS Status,
    CASE WHEN @ExistingAccessId IS NULL THEN N'insertar' ELSE N'actualizar' END AS AccionAcceso,
    CASE WHEN @OfferIsLifetime = 1 THEN CAST(NULL AS DATETIME2(7)) ELSE @NewExpiresAt END AS ExpiresAt,
    @OfferIsLifetime AS IsLifetimeAccess;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'Sin cambios (DryRun=1). Para aplicar: SET @DryRun = 0';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO billing.Purchases (
        PurchaseId,
        UserId,
        ProductCode,
        ProductType,
        ProviderCode,
        ProviderTransactionId,
        Amount,
        CurrencyCode,
        Status,
        PurchasedAt,
        CreatedAt
    )
    VALUES (
        @PurchaseId,
        @UserId,
        @ProductCode,
        N'prep_access',
        N'manual_admin',
        @ProviderTransactionId,
        @PriceAmount,
        @CurrencyCode,
        N'validated',
        @Now,
        @Now
    );

    IF @ExistingAccessId IS NULL
    BEGIN
        INSERT INTO sharing.QuizAccesses (
            QuizAccessId,
            UserId,
            QuizId,
            ClassId,
            AssignmentId,
            AccessType,
            GrantedAt,
            ExpiresAt,
            IsLifetimeAccess,
            GrantedByPurchaseId,
            PrepCatalogItemId
        )
        VALUES (
            NEWID(),
            @UserId,
            @QuizId,
            NULL,
            NULL,
            N'purchase',
            @Now,
            CASE WHEN @OfferIsLifetime = 1 THEN NULL ELSE @NewExpiresAt END,
            @OfferIsLifetime,
            @PurchaseId,
            @CatalogItemId
        );
    END
    ELSE
    BEGIN
        UPDATE qa
        SET
            qa.AccessType = N'purchase',
            qa.IsLifetimeAccess = @OfferIsLifetime,
            qa.ExpiresAt = CASE WHEN @OfferIsLifetime = 1 THEN NULL ELSE @NewExpiresAt END,
            qa.GrantedByPurchaseId = @PurchaseId,
            qa.PrepCatalogItemId = @CatalogItemId,
            qa.GrantedAt = CASE WHEN @KeepGrantedAt = 1 THEN qa.GrantedAt ELSE @Now END
        FROM sharing.QuizAccesses qa
        WHERE qa.QuizAccessId = @ExistingAccessId;
    END;

    COMMIT TRANSACTION;

    PRINT N'Acceso de pago concedido.';
    PRINT N'PurchaseId: ' + CONVERT(NVARCHAR(36), @PurchaseId);
    PRINT N'Expira: ' + CASE
        WHEN @OfferIsLifetime = 1 THEN N'nunca (vitalicio)'
        ELSE CONVERT(NVARCHAR(30), @NewExpiresAt, 126) + N' UTC'
    END;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
