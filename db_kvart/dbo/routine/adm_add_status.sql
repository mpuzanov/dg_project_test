CREATE   PROCEDURE [dbo].[adm_add_status]
(
	@id1 SMALLINT
)
AS
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT
				1
			FROM dbo.Status
			WHERE id = @id1)
	BEGIN
		INSERT dbo.Status
		(id
		,name)
		VALUES (@id1
			   ,'названия нет');
	END;
	ELSE
		RAISERROR ('Такой статус человека  уже есть!', 16, 10);
go

