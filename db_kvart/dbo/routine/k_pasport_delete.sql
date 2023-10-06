CREATE   PROCEDURE [dbo].[k_pasport_delete](
    @id1 INT
)
AS
    --
    -- Удаляем документ
    --
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Если удаляемый документ активный
    -- то надо найти нового активного если есть
    IF EXISTS(SELECT *
              FROM dbo.IDDOC 
              WHERE id = @id1
                AND active = 1)
        BEGIN
            DECLARE @owner_id1 INT

            SELECT @owner_id1 = owner_id
            FROM dbo.IDDOC 
            WHERE id = @id1

            DELETE
            FROM dbo.IDDOC 
            WHERE id = @id1

            UPDATE dbo.IDDOC 
            SET active = 1
            WHERE id = (SELECT TOP (1) id
                        FROM dbo.IDDOC 
                        WHERE owner_id = @owner_id1
                        ORDER BY issued DESC)
        END
    ELSE
        BEGIN
            DELETE
            FROM dbo.IDDOC 
            WHERE id = @id1
        END
go

