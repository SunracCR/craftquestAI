# Checklist de scripts SQL — CraftQuest

La base de datos se evoluciona con **scripts idempotentes** en `Documentacion/` (no hay migraciones EF automáticas; no usar `dotnet ef migrations add` — los índices y DDL van en scripts SQL como `AlterIndexes_Quiz_Question_AiJob.sql`).  
Ejecutar en **dev → staging → producción** en el orden indicado. Marcar cada fila al aplicarla.

## Cómo verificar si un script ya está aplicado

Antes de ejecutar, comprueba la columna **Verificación**. Si ya cumple la condición, puedes marcar como aplicado sin re-ejecutar.

## Orden recomendado

| # | Script | Propósito | Verificación rápida | Dev | Staging | Prod |
|---|--------|-----------|---------------------|-----|---------|------|
| 38 | `CraftQuest_AzureSQL_DDL_MVP_Completo_v4.sql` | DDL completo MVP (schemas, tablas base) | Existe `core.Users` | ☐ | ☐ | ☐ |
| 39 | `AddUserProfileFields.sql` | `AvatarId`, `PreferredLanguage` en usuarios | `COL_LENGTH('core.Users','AvatarId')` NOT NULL | ☐ | ☐ | ☐ |
| 40 | `AddUserQuizPracticePreferences.sql` | Preferencias de práctica por usuario/cuestionario | Tabla `practice.UserQuizPracticePreferences` | ☐ | ☐ | ☐ |
| 41 | `AddPracticeSessionResumeFields.sql` | Reanudar sesiones de práctica | Columnas resume en `practice.PracticeSessions` | ☐ | ☐ | ☐ |
| 42 | `AddPracticeSessionShowElapsedTimer.sql` | Timer visible en sesión | `ShowElapsedTimer` en `practice.PracticeSessions` | ☐ | ☐ | ☐ |
| 43 | `AlterGuestMode.sql` | Schema `guest`, visitas y sesiones invitado | Schema `guest` existe | ☐ | ☐ | ☐ |
| 44 | `AlterShareCodes_OnePerQuiz.sql` | Un código compartido por cuestionario | Restricción/índice según script | ☐ | ☐ | ☐ |
| 45 | `AlterShareCodes_AccessPolicy.sql` | Política de acceso en códigos | Columnas/policy del script | ☐ | ☐ | ☐ |
| 46 | `AlterPlans_MonthlyAiCredits.sql` | Créditos IA mensuales en planes | Columna en `billing.Plans` | ☐ | ☐ | ☐ |
| 47 | `UpdateFreePlanLimits.sql` | Límites plan free (2 cuestionarios, 50 preguntas) | `MaxQuizzes`/`MaxQuestionsPerQuiz` en `free` | ☐ | ☐ | ☐ |
| 48 | `AlterStudyMaterials_AI_Generation.sql` | Materiales de estudio para IA | Tablas/columnas de study materials | ☐ | ☐ | ☐ |
| 49 | `AlterAiJobs_Progress.sql` | Progreso en jobs de IA | Columnas progreso en `ai` jobs | ☐ | ☐ | ☐ |
| 50 | `AlterAiJobs_DeferredRetry.sql` | Reintentos diferidos IA | Columnas retry en jobs IA | ☐ | ☐ | ☐ |
| 51 | `AlterAiJobs_StudyMaterial_SetNull.sql` | FK material nullable en jobs | Nullable según script | ☐ | ☐ | ☐ |
| 52 | `QuestionJustifications_Feature.sql` | Fuentes justificación + snapshot práctica | `SourcePageNumber` en `quiz.QuestionJustificationSources` | ☐ | ☐ | ☐ |
| 53 | `PrepPlus_Schema_F1.sql` | Preparación+: catálogo, ofertas, accesos | Schema `catalog`, tablas Prep+ | ☐ | ☐ | ☐ |
| 54 | `PrepPlus_Seed_Categories.sql` | Categorías iniciales Prep+ | Filas en categorías seed | ☐ | ☐ | ☐ |
| 55 | `Assign_ContentAdmin_carlossm01.sql` | Rol content_admin a usuario concreto | **Solo si aplica** — editar email antes | ☐ | ☐ | ☐ |
| 56 | `AssignTestPlan_User.sql` | Plan de prueba a usuario | **Solo dev/test** — no producción | ☐ | — | — |
| 57 | `PasswordReset_Feature.sql` | Tokens de recuperación de contraseña | Tabla `core.PasswordResetTokens` | ☐ | ☐ | ☐ |
| 58 | `AlterIndexes_Quiz_Question_AiJob.sql` | Índices listado quizzes, preguntas e imports IA pendientes | `IX_Quizzes_CreatedByUser_CreatedAt`, `IX_Questions_Quiz`, `IX_AiJobs_PendingImportByQuiz` | ☐ | ☐ | ☐ |
| 59 | *(verificación, sin script)* | Índices login: `EmailNormalized` y OAuth `AuthProviders` | `UQ_Users_EmailNormalized` en `core.Users`; `UQ_AuthProviders_ProviderSubject` en `core.AuthProviders` (incluidos en ítem 38) | ☐ | ☐ | ☐ |
| 60 | `AddQuizFolders.sql` | Carpetas jerárquicas para cuestionarios (`quiz.QuizFolders`, `Quizzes.FolderId`) | Tabla `quiz.QuizFolders`; `COL_LENGTH('quiz.Quizzes','FolderId')` NOT NULL | ☐ | ☐ | ☐ |
| 61 | `AddEmailVerificationAndPasswordChange.sql` | Verificación de email (`pending`), `EmailVerifiedAt`, tokens de verificación y confirmación de cambio de contraseña | `COL_LENGTH('core.Users','EmailVerifiedAt')`; tablas `core.EmailVerificationTokens`, `core.PasswordChangeTokens`; `CK_Users_Status` incluye `pending` | ☐ | ☐ | ☐ |
| 62 | `AddNotifications.sql` | Centro in-app, outbox fan-out, device tokens, preferencias | Tabla `core.Notifications`; `core.NotificationOutbox`; `core.DeviceTokens`; `core.NotificationPreferences` | ☐ | ☐ | ☐ |
| 63 | `AddParentalConsent.sql` | Consentimiento parental (DOB, guardian, tokens) y estado `pending_parental_consent` | `COL_LENGTH('core.Users','DateOfBirth')`; tabla `core.ParentalConsentTokens`; `CK_Users_Status` incluye `pending_parental_consent` | ☐ | ☐ | ☐ |
| 64 | `AlterIndexes_PrepPlus.sql` | Índices hub Prep+ (conteo por categoría y mis accesos) | `IX_PrepCatalogItems_CategoryId_IsPublished_IsDeleted`, `IX_QuizAccesses_UserId_AccessType_PrepCatalogItemId` | ☐ | ☐ | ☐ |
| 65 | `AlterPlans_MonthlyAiCredits_Pro15_Teacher30.sql` | Pro 90 cr / Teacher 180 cr (15 y 30 gen. de 40 preg.) | `MonthlyAiCredits` en `pro`=90, `teacher`=180 | ☐ | ☐ | ☐ |

## Estrategia (ítem 58)

1. **Fuente de verdad:** scripts en `Documentacion/` versionados en git.  
2. **Nunca** aplicar solo en un entorno sin actualizar esta tabla.  
3. Tras cada release, revisar si hay scripts nuevos y añadirlos al final de la tabla.  
4. Para cambios nuevos, preferir scripts **idempotentes** (`IF COL_LENGTH` / `IF NOT EXISTS`).  
5. Producción: backup antes del lote; ejecutar en ventana de mantenimiento si hay DDL pesado.
6. **Índices EF (`HasIndex` en configuraciones):** reflejan el modelo; la aplicación en Azure SQL es vía script (p. ej. ítem 58), no vía `dotnet ef database update`.

## Scripts operativos (no obligatorios en todos los entornos)

| Script | Cuándo usarlo |
|--------|----------------|
| `Assign_ContentAdmin_*.sql` | Dar rol admin de contenido a un usuario específico |
| `AssignTestPlan_User.sql` | Pruebas locales de billing |

## Relación con la API

La API asume que las columnas/tablas de los scripts **38–54** existen. Si falta alguno, aparecerán errores SQL en runtime (p. ej. Prep+ sin schema `catalog`, justificaciones sin `SourcePageNumber`).

## Checklist de release general

Ver también: `RELEASE_CHECKLIST.md`, `CraftQuest_Configuracion_Media_Pagos_v4.md` (§10), `Billing_API_Routes.md`.
