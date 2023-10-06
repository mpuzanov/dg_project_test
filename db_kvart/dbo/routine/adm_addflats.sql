CREATE   PROCEDURE [dbo].[adm_addflats]
(
	  @bldn_id1 INT
	, @nom1 VARCHAR(20)
	, @nom2 VARCHAR(20) = NULL
)
AS
	/*
	 добавление квартир в доме
	*/

	SET NOCOUNT ON

	IF COALESCE(@nom2, '') = ''
		SET @nom2 = @nom1

	-- если надо ввести одну квартиру
	IF @nom1 = @nom2
	BEGIN
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Flats
				WHERE bldn_id = @bldn_id1
					AND nom_kvr = @nom1
			)
		BEGIN
			INSERT INTO dbo.Flats
				(bldn_id
			   , nom_kvr)
				VALUES (@bldn_id1
					  , @nom1)
		END

	END
	ELSE
	BEGIN
		-- @nom1 = 'Гараж 1', @nom2='Гараж 30'

		DECLARE @s VARCHAR(20) = SUBSTRING(@nom1, 1, PATINDEX('%[0-9]%', @nom1) - 1)    -- строковый шаблон перед числом (Гараж)
			  , @n1 INT = CAST(SUBSTRING(@nom1, PATINDEX('%[0-9]%', @nom1), 20) AS INT)
			  , @n2 INT = CAST(SUBSTRING(@nom2, PATINDEX('%[0-9]%', @nom2), 20) AS INT)

		INSERT INTO Flats
			(bldn_id
		   , nom_kvr)
		SELECT @bldn_id1
			 , @s + LTRIM(STR(n))
		FROM dbo.Fun_GetNums(@n1, @n2)

	END
go

