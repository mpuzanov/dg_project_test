CREATE   PROCEDURE [dbo].[k_foto_add]
(
	@owner_id1	INT
	,@foto1		VARBINARY(MAX)
)
AS
/*
Добавляем или изменяем фотографию человека в базе 
*/

	SET NOCOUNT ON

	IF EXISTS (SELECT
				*
			FROM dbo.People_image
			WHERE owner_id = @owner_id1)
	BEGIN
		UPDATE dbo.People_image
		SET foto = @foto1
		WHERE owner_id = @owner_id1
	END
	ELSE
	BEGIN
		INSERT INTO dbo.People_image
		(	owner_id
			,foto)
		VALUES (@owner_id1
				,@foto1)
	END
go

