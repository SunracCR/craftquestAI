/* Concede a un usuario acceso de pago a todos los cuestionarios Prep+
   de una categorÃ­a (y, por defecto, de sus subcategorÃ­as).

   Por cada cuestionario hace lo mismo que una compra validada:
     - inserta billing.Purchases (ProductType = prep_access, Status = validated)
     - crea o actualiza sharing.QuizAccesses (AccessType = purchase)

   ProviderCode = manual_admin para distinguirlo de PayPal / tiendas.
   No aplica recompensas de referido. Una compra por cuestionario.

   Identifica el usuario con @Email.
   Identifica la categorÃ­a con UNO de: @CategoryId | @Slug | @Name

   @IncludeChildren = 1 (default): incluye subcategorÃ­as.
   @IncludeChildren = 0: solo los cuestionarios colgados de esa categorÃ­a.

   Tipo de acceso:
     @IsLifetime = 1 (default)  acceso de por vida a TODOS los cuestionarios,
                                tengan o no oferta vitalicia configurada.
     @IsLifetime = 0            temporal; exige @DurationDays (30/60/90/183) y
                                omite los cuestionarios sin esa oferta activa.

   Cuestionarios en los que el usuario ya tiene acceso de por vida se omiten.

   @DryRun = 1 (default): solo muestra quÃ© se harÃ­a.
   @DryRun = 0: ejecuta INSERT / UPDATE (todo o nada).

   Ejecutar en la base de CraftQuest (SSMS / Azure Data Studio).
*/

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('tempdb..#Plan') IS NOT NULL DROP TABLE #Plan;
IF OBJECT_ID('tempdb..#CategoryIds') IS NOT NULL DROP TABLE #CategoryIds;
IF OBJECT_ID('tempdb..#GrantCatPlan') IS NOT NULL DROP TABLE #GrantCatPlan;
IF OBJECT_ID('tempdb..#GrantCatIds') IS NOT NULL DROP TABLE #GrantCatIds;
GO

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Email NVARCHAR(320) = N'tu@email.com';             -- <-- cambiar
DECLARE @CategoryId UNIQUEIDENTIFIER = NULL;                -- opciÃ³n A: GUID de la categorÃ­a
DECLARE @Slug NVARCHAR(80) = NULL;                          -- opciÃ³n B: slug exacto
DECLARE @Name NVARCHAR(120) = NULL;                         -- opciÃ³n C: nombre exacto
DECLARE @IncludeChildren BIT = 1;                           -- 1 = categorÃ­a y subcategorÃ­as
DECLARE @IsLifetime BIT = 1;                                -- 1 = de por vida, 0 = temporal
DECLARE @DurationDays INT = NULL;                           -- solo si @IsLifetime = 0: 30, 60, 90 o 183
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

IF @CategoryId IS NULL
   AND ( @Slug IS NULL OR LTRIM(RTRIM(@Slug)) = N'' )
   AND ( @Name IS NULL OR LTRIM(RTRIM(@Name)) = N'' )
BEGIN
    RAISERROR(N'Indica @CategoryId, @Slug o @Name.', 16, 1);
    RETURN;
END;

IF @IsLifetime = 1
    SET @DurationDays = NULL;

IF @IsLifetime = 0 AND ( @DurationDays IS NULL OR @DurationDays NOT IN (30, 60, 90, 183) )
BEGIN
    RAISERROR(N'Con @IsLifetime = 0, @DurationDays debe ser 30, 60, 90 o 183.', 16, 1);
    RETURN;
END;

IF @CategoryId IS NULL AND @Slug IS NOT NULL AND LTRIM(RTRIM(@Slug)) <> N''
BEGIN
    DECLARE @SlugMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCategories
        WHERE Slug = LOWER(LTRIM(RTRIM(@Slug)))
    );

    IF @SlugMatches = 0
    BEGIN
        RAISERROR(N'No hay categorÃ­a con ese slug.', 16, 1);
        RETURN;
    END;

    IF @SlugMatches > 1
    BEGIN
        SELECT CategoryId, ParentCategoryId, Slug, Name, CategoryType
        FROM catalog.PrepCategories
        WHERE Slug = LOWER(LTRIM(RTRIM(@Slug)))
        ORDER BY ParentCategoryId, Name;

        RAISERROR(N'Hay varias categorÃ­as con ese slug. Usa @CategoryId.', 16, 1);
        RETURN;
    END;

    SELECT @CategoryId = CategoryId
    FROM catalog.PrepCategories
    WHERE Slug = LOWER(LTRIM(RTRIM(@Slug)));
END;

IF @CategoryId IS NULL AND @Name IS NOT NULL AND LTRIM(RTRIM(@Name)) <> N''
BEGIN
    DECLARE @NameMatches INT = (
        SELECT COUNT(*)
        FROM catalog.PrepCategories
        WHERE Name = LTRIM(RTRIM(@Name))
    );

    IF @NameMatches = 0
    BEGIN
        RAISERROR(N'No hay categorÃ­a con ese nombre.', 16, 1);
        RETURN;
    END;

    IF @NameMatches > 1
    BEGIN
        SELECT CategoryId, ParentCategoryId, Slug, Name, CategoryType
        FROM catalog.PrepCategories
        WHERE Name = LTRIM(RTRIM(@Name))
        ORDER BY ParentCategoryId, Name;

        RAISERROR(N'Hay varias categorÃ­as con ese nombre. Usa @CategoryId.', 16, 1);
        RETURN;
    END;

    SELECT @CategoryId = CategoryId
    FROM catalog.PrepCategories
    WHERE Name = LTRIM(RTRIM(@Name));
END;

IF NOT EXISTS (SELECT 1 FROM catalog.PrepCategories WHERE CategoryId = @CategoryId)
BEGIN
    RAISERROR(N'CategorÃ­a no encontrada.', 16, 1);
    RETURN;
END;

DECLARE @CategoryName NVARCHAR(120);
SELECT @CategoryName = Name
FROM catalog.PrepCategories
WHERE CategoryId = @CategoryId;

IF OBJECT_ID('tempdb..#GrantCatIds') IS NOT NULL DROP TABLE #GrantCatIds;
CREATE TABLE #GrantCatIds (
    CategoryId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Nivel INT NOT NULL
);

IF @IncludeChildren = 1
BEGIN
    ;WITH Rama AS (
        SELECT CategoryId, 0 AS Nivel
        FROM catalog.PrepCategories
        WHERE CategoryId = @CategoryId
        UNION ALL
        SELECT c.CategoryId, r.Nivel + 1
        FROM catalog.PrepCategories c
        INNER JOIN Rama r ON c.ParentCategoryId = r.CategoryId
    )
    INSERT INTO #GrantCatIds (CategoryId, Nivel)
    SELECT CategoryId, Nivel
    FROM Rama
    OPTION (MAXRECURSION 100);
END
ELSE
BEGIN
    INSERT INTO #GrantCatIds (CategoryId, Nivel)
    VALUES (@CategoryId, 0);
END;

DECLARE @Now DATETIME2(7) = SYSUTCDATETIME();

IF OBJECT_ID('tempdb..#GrantCatPlan') IS NOT NULL DROP TABLE #GrantCatPlan;
CREATE TABLE #GrantCatPlan (
    RowNum INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    CatalogItemId UNIQUEIDENTIFIER NOT NULL,
    QuizId UNIQUEIDENTIFIER NOT NULL,
    Titulo NVARCHAR(300) NULL,
    Slug NVARCHAR(160) NULL,
    CategoryName NVARCHAR(120) NULL,
    Nivel INT NOT NULL,
    IsPublished BIT NOT NULL,
    OfferId UNIQUEIDENTIFIER NULL,
    PriceAmount DECIMAL(12, 2) NULL,
    CurrencyCode NVARCHAR(10) NULL,
    ExistingAccessId UNIQUEIDENTIFIER NULL,
    ExistingAccessType NVARCHAR(40) NULL,
    ExistingIsLifetime BIT NULL,
    ExistingExpiresAt DATETIME2(7) NULL,
    Accion NVARCHAR(40) NULL,
    NewExpiresAt DATETIME2(7) NULL,
    KeepGrantedAt BIT NOT NULL DEFAULT (0),
    PurchaseId UNIQUEIDENTIFIER NULL
);

;WITH OfferPick AS (
    SELECT
        o.CatalogItemId,
        o.OfferId,
        o.PriceAmount,
        o.CurrencyCode,
        ROW_NUMBER() OVER (
            PARTITION BY o.CatalogItemId
            ORDER BY o.PriceAmount, o.OfferId
        ) AS rn
    FROM catalog.PrepAccessOffers o
    WHERE o.IsActive = 1
      AND (
            (@IsLifetime = 1 AND o.IsLifetimeAccess = 1)
         OR (@IsLifetime = 0 AND o.IsLifetimeAccess = 0 AND o.DurationDays = @DurationDays)
          )
),
AccessPick AS (
    SELECT
        qa.QuizAccessId,
        qa.QuizId,
        qa.AccessType,
        qa.IsLifetimeAccess,
        qa.ExpiresAt,
        ROW_NUMBER() OVER (
            PARTITION BY qa.QuizId
            ORDER BY qa.IsLifetimeAccess DESC, qa.ExpiresAt DESC
        ) AS rn
    FROM sharing.QuizAccesses qa
    WHERE qa.UserId = @UserId
      AND qa.ClassId IS NULL
      AND qa.AssignmentId IS NULL
)
INSERT INTO #GrantCatPlan (
    CatalogItemId, QuizId, Titulo, Slug, CategoryName, Nivel, IsPublished,
    OfferId, PriceAmount, CurrencyCode,
    ExistingAccessId, ExistingAccessType, ExistingIsLifetime, ExistingExpiresAt
)
SELECT
    i.CatalogItemId,
    i.QuizId,
    COALESCE(i.TitleOverride, q.Title),
    i.Slug,
    c.Name,
    ids.Nivel,
    i.IsPublished,
    o.OfferId,
    o.PriceAmount,
    o.CurrencyCode,
    a.QuizAccessId,
    a.AccessType,
    a.IsLifetimeAccess,
    a.ExpiresAt
FROM catalog.PrepCatalogItems i
INNER JOIN #GrantCatIds ids ON ids.CategoryId = i.CategoryId
INNER JOIN catalog.PrepCategories c ON c.CategoryId = i.CategoryId
INNER JOIN quiz.Quizzes q ON q.QuizId = i.QuizId
LEFT JOIN OfferPick o ON o.CatalogItemId = i.CatalogItemId AND o.rn = 1
LEFT JOIN AccessPick a ON a.QuizId = i.QuizId AND a.rn = 1
WHERE i.IsDeleted = 0;

UPDATE p
SET Accion = CASE
        WHEN p.ExistingAccessType = N'purchase' AND p.ExistingIsLifetime = 1 THEN N'omitido_ya_vitalicio'
        WHEN @IsLifetime = 0 AND p.OfferId IS NULL THEN N'omitido_sin_oferta'
        WHEN p.ExistingAccessId IS NULL THEN N'insertar'
        ELSE N'actualizar'
    END
FROM #GrantCatPlan p;

UPDATE p
SET KeepGrantedAt = 1
FROM #GrantCatPlan p
WHERE @IsLifetime = 0
  AND p.Accion = N'actualizar'
  AND p.ExistingAccessType = N'purchase'
  AND p.ExistingIsLifetime = 0
  AND p.ExistingExpiresAt > @Now;

UPDATE p
SET NewExpiresAt = DATEADD(
        DAY,
        @DurationDays,
        CASE WHEN p.KeepGrantedAt = 1 THEN p.ExistingExpiresAt ELSE @Now END)
FROM #GrantCatPlan p
WHERE @IsLifetime = 0
  AND p.Accion IN (N'insertar', N'actualizar');

DECLARE @CategoryCount INT = (SELECT COUNT(*) FROM #GrantCatIds);
DECLARE @ItemCount INT = (SELECT COUNT(*) FROM #GrantCatPlan);
DECLARE @GrantCount INT = (SELECT COUNT(*) FROM #GrantCatPlan WHERE Accion IN (N'insertar', N'actualizar'));
DECLARE @SkipOffer INT = (SELECT COUNT(*) FROM #GrantCatPlan WHERE Accion = N'omitido_sin_oferta');
DECLARE @SkipLifetime INT = (SELECT COUNT(*) FROM #GrantCatPlan WHERE Accion = N'omitido_ya_vitalicio');

PRINT N'--- GrantUserPrepPlusCategoryAccess ---';
PRINT N'Usuario: ' + @Email + N' (' + CONVERT(NVARCHAR(36), @UserId) + N')';
PRINT N'CategorÃ­a: ' + ISNULL(@CategoryName, N'?') + N' (' + CONVERT(NVARCHAR(36), @CategoryId) + N')';
PRINT N'Incluye subcategorÃ­as: ' + CASE WHEN @IncludeChildren = 1 THEN N'SÃ' ELSE N'NO' END;
PRINT N'CategorÃ­as en alcance: ' + CAST(@CategoryCount AS NVARCHAR(20));
PRINT N'Cuestionarios: ' + CAST(@ItemCount AS NVARCHAR(20));
PRINT N'Acceso: ' + CASE WHEN @IsLifetime = 1 THEN N'de por vida' ELSE CAST(@DurationDays AS NVARCHAR(10)) + N' dÃ­as' END;
PRINT N'A conceder: ' + CAST(@GrantCount AS NVARCHAR(20));
PRINT N'Omitidos (ya de por vida): ' + CAST(@SkipLifetime AS NVARCHAR(20));
PRINT N'Omitidos (sin oferta): ' + CAST(@SkipOffer AS NVARCHAR(20));
PRINT N'DryRun: ' + CASE WHEN @DryRun = 1 THEN N'SÃ (solo vista previa)' ELSE N'NO (ejecutando)' END;
PRINT N'';

SELECT
    p.Nivel,
    p.CategoryName,
    p.Titulo,
    p.Slug,
    p.IsPublished,
    p.Accion,
    p.ExistingAccessType,
    p.ExistingIsLifetime,
    p.ExistingExpiresAt,
    CASE WHEN @IsLifetime = 1 THEN N'de por vida' ELSE CONVERT(NVARCHAR(30), p.NewExpiresAt, 126) END AS NuevoAcceso,
    p.CatalogItemId,
    p.OfferId
FROM #GrantCatPlan p
ORDER BY p.Nivel, p.CategoryName, p.Titulo;

IF @ItemCount = 0
BEGIN
    RAISERROR(N'No hay cuestionarios Prep+ en esa categorÃ­a.', 16, 1);
    RETURN;
END;

IF @GrantCount = 0
BEGIN
    PRINT N'Nada que conceder.';
    RETURN;
END;

IF @DryRun = 1
BEGIN
    PRINT N'';
    PRINT N'Sin cambios (DryRun=1). Para aplicar: SET @DryRun = 0';
    RETURN;
END;

DECLARE @RowNum INT;
DECLARE @PCatalogItemId UNIQUEIDENTIFIER;
DECLARE @PQuizId UNIQUEIDENTIFIER;
DECLARE @POfferId UNIQUEIDENTIFIER;
DECLARE @PPrice DECIMAL(12, 2);
DECLARE @PCurrency NVARCHAR(10);
DECLARE @PExistingAccessId UNIQUEIDENTIFIER;
DECLARE @PAccion NVARCHAR(40);
DECLARE @PNewExpiresAt DATETIME2(7);
DECLARE @PKeepGrantedAt BIT;
DECLARE @PPurchaseId UNIQUEIDENTIFIER;
DECLARE @PTitulo NVARCHAR(300);

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE plan_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT RowNum, CatalogItemId, QuizId, OfferId, PriceAmount, CurrencyCode,
               ExistingAccessId, Accion, NewExpiresAt, KeepGrantedAt, Titulo
        FROM #GrantCatPlan
        WHERE Accion IN (N'insertar', N'actualizar')
        ORDER BY RowNum;

    OPEN plan_cursor;
    FETCH NEXT FROM plan_cursor INTO
        @RowNum, @PCatalogItemId, @PQuizId, @POfferId, @PPrice, @PCurrency,
        @PExistingAccessId, @PAccion, @PNewExpiresAt, @PKeepGrantedAt, @PTitulo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @PPurchaseId = NEWID();

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
            @PPurchaseId,
            @UserId,
            LOWER(REPLACE(CONVERT(NVARCHAR(36), @PCatalogItemId), N'-', N''))
                + N'|'
                + LOWER(REPLACE(CONVERT(NVARCHAR(36), ISNULL(@POfferId, '00000000-0000-0000-0000-000000000000')), N'-', N'')),
            N'prep_access',
            N'manual_admin',
            N'manual-' + LOWER(REPLACE(CONVERT(NVARCHAR(36), @PPurchaseId), N'-', N'')),
            ISNULL(@PPrice, 0),
            ISNULL(@PCurrency, N'USD'),
            N'validated',
            @Now,
            @Now
        );

        IF NOT EXISTS (SELECT 1 FROM billing.Purchases WHERE PurchaseId = @PPurchaseId)
        BEGIN
            RAISERROR(N'La compra no quedÃ³ registrada en billing.Purchases (cuestionario: %s).', 16, 1, @PTitulo);
        END;

        IF @PAccion = N'actualizar'
        BEGIN
            UPDATE sharing.QuizAccesses
            SET
                AccessType = N'purchase',
                IsLifetimeAccess = @IsLifetime,
                ExpiresAt = CASE WHEN @IsLifetime = 1 THEN NULL ELSE @PNewExpiresAt END,
                GrantedByPurchaseId = @PPurchaseId,
                PrepCatalogItemId = @PCatalogItemId,
                GrantedAt = CASE WHEN @PKeepGrantedAt = 1 THEN GrantedAt ELSE @Now END
            WHERE QuizAccessId = @PExistingAccessId;
        END
        ELSE
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
                @PQuizId,
                NULL,
                NULL,
                N'purchase',
                @Now,
                CASE WHEN @IsLifetime = 1 THEN NULL ELSE @PNewExpiresAt END,
                @IsLifetime,
                @PPurchaseId,
                @PCatalogItemId
            );
        END;

        UPDATE #GrantCatPlan SET PurchaseId = @PPurchaseId WHERE RowNum = @RowNum;

        FETCH NEXT FROM plan_cursor INTO
            @RowNum, @PCatalogItemId, @PQuizId, @POfferId, @PPrice, @PCurrency,
            @PExistingAccessId, @PAccion, @PNewExpiresAt, @PKeepGrantedAt, @PTitulo;
    END;

    CLOSE plan_cursor;
    DEALLOCATE plan_cursor;

    COMMIT TRANSACTION;

    PRINT N'Acceso concedido a ' + CAST(@GrantCount AS NVARCHAR(20)) + N' cuestionario(s).';

    SELECT
        p.CategoryName,
        p.Titulo,
        p.Accion,
        p.PurchaseId,
        qa.AccessType,
        qa.IsLifetimeAccess,
        qa.ExpiresAt
    FROM #GrantCatPlan p
    INNER JOIN sharing.QuizAccesses qa
        ON qa.UserId = @UserId
       AND qa.QuizId = p.QuizId
       AND qa.ClassId IS NULL
       AND qa.AssignmentId IS NULL
    WHERE p.PurchaseId IS NOT NULL
    ORDER BY p.Nivel, p.CategoryName, p.Titulo;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local', 'plan_cursor') >= -1
    BEGIN
        IF CURSOR_STATUS('local', 'plan_cursor') >= 0
            CLOSE plan_cursor;
        DEALLOCATE plan_cursor;
    END;

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) =
        ERROR_MESSAGE() + N' (lÃ­nea ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + N')';
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
