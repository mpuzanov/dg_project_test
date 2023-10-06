CREATE   PROCEDURE [dbo].[adm_del_type](
    @id1 SMALLINT
)
AS
    --
    --  Удаление типа жил.фонда
    --
    SET NOCOUNT ON

    IF NOT EXISTS(SELECT 1
                  FROM dbo.Buildings
                  WHERE tip_id = @id1)
        BEGIN
            DELETE
            FROM dbo.Occupation_Types
            WHERE id = @id1
        END
    ELSE
        RAISERROR (N'Тип используется!', 16, 10)
go

