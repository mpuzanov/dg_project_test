CREATE   PROCEDURE [dbo].[adm_add_jeu]
(
	@name1	 VARCHAR(30)
   ,@jeu_new SMALLINT OUTPUT
   , -- ключ созданного участка
	@tip_id	 SMALLINT = NULL
)
AS
	/*
	
	  Добавляем новый участок
	
	*/
	SET NOCOUNT ON;

	IF EXISTS (SELECT
				1
			FROM dbo.SECTOR
			WHERE name = @name1)
	BEGIN
		RAISERROR ('Участок с таким названием уже есть!', 16, 1);
		RETURN 1;
	END;

	--declare @jeu smallint

	--*****************************************
	-- формируем код участка
	SELECT TOP 1
		@jeu_new = t.n
	FROM dbo.Fun_GetNums(1, 1000) AS t
	LEFT JOIN dbo.SECTOR AS s
		ON t.n = s.id
	WHERE s.id IS NULL
	ORDER BY t.n;
	--*****************************************

	IF @jeu_new IS NULL
	BEGIN
		RAISERROR ('Не удалось создать номер участка!', 16, 1);
		RETURN 1;
	END;

	BEGIN TRAN;

		INSERT INTO dbo.SECTOR
		(id
		,name)
		VALUES (@jeu_new
			   ,@name1);

		IF @tip_id IS NOT NULL
			INSERT INTO dbo.SECTOR_TYPES
			(tip_id
			,sector_id)
			VALUES (@tip_id
				   ,@jeu_new);

		COMMIT TRAN;
go

