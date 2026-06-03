-- Alinea la FK con EF (DeleteBehavior.SetNull). Opcional si el código ya desvincula jobs antes del DELETE.
IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_AiJobs_StudyMaterials'
      AND parent_object_id = OBJECT_ID('ai.AiJobs'))
BEGIN
    ALTER TABLE ai.AiJobs DROP CONSTRAINT FK_AiJobs_StudyMaterials;

    ALTER TABLE ai.AiJobs
        ADD CONSTRAINT FK_AiJobs_StudyMaterials
        FOREIGN KEY (StudyMaterialId)
        REFERENCES content.StudyMaterials (StudyMaterialId)
        ON DELETE SET NULL;
END
