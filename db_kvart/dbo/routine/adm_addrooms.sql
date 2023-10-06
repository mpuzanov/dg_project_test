-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[adm_addrooms]
(
	@build_id INT
)
AS
BEGIN
	/*
	
	Добавляем все комнаты по дому, чтобы совпадало кол-во комнат
	exec adm_addrooms 1031

	*/
	SET NOCOUNT ON;

	DECLARE @flat_id	   INT
		   ,@kol_rooms_new SMALLINT
		   ,@kol_rooms_old SMALLINT

	DECLARE cur CURSOR LOCAL FOR
		SELECT
			id
		   ,f.ROOMS
		   ,COALESCE((SELECT
					COUNT(*)
				FROM dbo.ROOMS r
				WHERE f.id = r.flat_id)
			, 0)
		FROM dbo.FLATS f
		WHERE f.bldn_id = @build_id
		AND f.ROOMS > 0

	OPEN cur

	FETCH NEXT FROM cur INTO @flat_id, @kol_rooms_new, @kol_rooms_old

	WHILE @@fetch_status = 0
	BEGIN
		IF @kol_rooms_old = 0
			INSERT INTO dbo.ROOMS
			(flat_id
			,name)
				SELECT
					@flat_id
				   ,n
				FROM dbo.Fun_GetNums(1, @kol_rooms_new)

		FETCH NEXT FROM cur INTO @flat_id, @kol_rooms_new, @kol_rooms_old

	END

	CLOSE cur
	DEALLOCATE cur

END
go

