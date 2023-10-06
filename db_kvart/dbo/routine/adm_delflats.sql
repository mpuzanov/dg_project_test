CREATE   PROCEDURE [dbo].[adm_delflats]
(
	  @bldn_id1 INT
	, @nom1 VARCHAR(20)
	, @nom2 VARCHAR(20)
	, @flat_id_del INT = NULL
)
AS
	/*
		удаление квартир в доме
	
	*/

	IF (@nom1 = ''
		OR @nom2 = '')
		AND @flat_id_del IS NULL
		RETURN

	SET NOCOUNT ON

	-- если надо удалить одну квартиру
	IF (@nom1 = @nom2)
		OR @flat_id_del IS NOT NULL
	BEGIN
		IF EXISTS (
				SELECT 1
				FROM dbo.Occupations AS o
					JOIN dbo.Flats AS f ON o.flat_id = f.id
				WHERE f.bldn_id = @bldn_id1
					AND f.nom_kvr = @nom1
			)
		BEGIN
			RAISERROR ('Квартиру удалить нельзя! Так как там есть лицевые счета.', 16, 1)
			RETURN 1
		END

		DELETE FROM dbo.Flats
		WHERE bldn_id = @bldn_id1
			AND (nom_kvr = @nom1
			OR id = @flat_id_del)
	END
	ELSE
	BEGIN
		-- если надо удалить несколько квартир, номера домов должны быть числовыми
		-- пробуем перевести номер квартиры в число
		DECLARE @n1 INT
			  , @n2 INT
			  , @n3 INT
			  , @n3str VARCHAR(20)
		SELECT @n1 = CONVERT(INT, @nom1)
			 , @n2 = CONVERT(INT, @nom2)

		SELECT @n3 = @n1

		WHILE @n3 <= @n2
		BEGIN
			SELECT @n3str = CONVERT(VARCHAR(20), @n3)
			IF EXISTS (
					SELECT 1
					FROM dbo.Occupations AS o 
						JOIN dbo.Flats AS f ON o.flat_id = f.id
					WHERE f.bldn_id = @bldn_id1
						AND f.nom_kvr = @n3str
				)
			BEGIN
				RAISERROR ('Квартиру удалить нельзя! Так как там есть лицевые счета.', 16, 1)
				RETURN 1
			END
			DELETE FROM dbo.Flats
			WHERE bldn_id = @bldn_id1
				AND nom_kvr = @n3str

			SELECT @n3 = @n3 + 1
		END --while

	END -- if
go

