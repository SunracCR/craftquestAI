# CraftQuest 4.0 - Diagramas Mermaid

## Arquitectura general

```mermaid
flowchart LR
    Flutter[Flutter App] --> API[ASP.NET Core Web API]
    API --> SQL[(Azure SQL)]
    API --> Blob[(Azure Blob Storage)]
    API --> Bus[Azure Service Bus]
    API --> KeyVault[Azure Key Vault]
    API --> Insights[Application Insights]
    Bus --> Workers[Workers / Azure Functions]
    Workers --> SQL
    Workers --> Blob
    Workers --> Gemini[Gemini / IA]
```

## Importacion a CQIF v2

```mermaid
flowchart TD
    U[Usuario sube Excel/TXT/CSV/JSON/ZIP] --> API[POST /question-imports/process]
    API --> P[Parser deterministico]
    P --> CQIF[CQIF v2]
    P -->|formato irregular| AI[IA normaliza a CQIF v2]
    AI --> CQIF
    CQIF --> V[Validador de reglas]
    V --> Preview[Preview + errores]
    Preview --> Confirm[Usuario confirma]
    Confirm --> Q[Questions]
    Confirm --> AO[QuestionAnswerOptions]
    Confirm --> CA[QuestionCorrectAnswerOptions]
```

## Practica con respuestas aleatorias por intento

```mermaid
sequenceDiagram
    participant App as Flutter
    participant API as Web API
    participant SQL as Azure SQL

    App->>API: POST /practice-sessions { quizId }
    API->>SQL: Leer preguntas y AnswerOptionId
    API->>API: Aleatorizar respuestas por pregunta
    API->>SQL: Crear PracticeSession
    API->>SQL: Crear PracticeQuestionSnapshots
    API->>SQL: Crear PracticeAnswerOptionSnapshots con DisplayLabel
    API-->>App: Preguntas con answerOptionId + DisplayLabel sin isCorrect

    App->>API: POST /answer { selectedAnswerOptionIds }
    API->>SQL: Comparar selected IDs contra correct AnswerOptionIds
    API->>SQL: Marcar WasSelected, IsCorrect, PointsAwarded
    API-->>App: accepted=true

    App->>API: POST /finish
    API->>SQL: Calcular resultado
    API-->>App: resultado final
```

## Revision docente

```mermaid
flowchart TD
    Teacher[Profesor] --> API[GET /teacher/practice-sessions/{id}]
    API --> Auth[Validar clase/asignacion/permisos]
    Auth --> SQL[Leer snapshots historicos]
    SQL --> Review[Orden original + DisplayLabel + AnswerOptionId + WasSelected + IsCorrect]
    Review --> Teacher
```

## Modelo clave v4

```mermaid
erDiagram
    QUESTIONS ||--o{ QUESTION_ANSWER_OPTIONS : has
    QUESTIONS ||--o{ QUESTION_CORRECT_ANSWER_OPTIONS : correct
    QUESTION_ANSWER_OPTIONS ||--o{ QUESTION_CORRECT_ANSWER_OPTIONS : selected_as_correct
    PRACTICE_SESSIONS ||--o{ PRACTICE_QUESTION_SNAPSHOTS : contains
    PRACTICE_QUESTION_SNAPSHOTS ||--o{ PRACTICE_ANSWER_OPTION_SNAPSHOTS : displayed
    QUESTION_ANSWER_OPTIONS ||--o{ PRACTICE_ANSWER_OPTION_SNAPSHOTS : snapshotted
```
