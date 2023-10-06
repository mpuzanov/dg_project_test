CREATE   PROCEDURE [dbo].[k_pasport_active]
(
    @id1 INT
)
AS
--
--  Сделать активным документ
--
SET NOCOUNT ON

UPDATE dbo.Iddoc 
SET active = CASE
                 WHEN id = @id1 THEN 1
                 ELSE 0
    END
WHERE owner_id = (SELECT TOP 1
		owner_id
	FROM dbo.Iddoc 
	WHERE id = @id1)
go

