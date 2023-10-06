CREATE   FUNCTION [dbo].[Fun_GetOccSUP]
(
	@occ		INT
	,@sup_id	INT
	,@dog_int	INT	= NULL
)
RETURNS INT
AS
BEGIN
	/*		
		Возвращаем лицевой счет по заданному поставщику и договору
		 
		select dbo.Fun_GetOccSUP(700009785,300,0)
		select dbo.Fun_GetOccSUP(700009101,313,6)
		select dbo.Fun_GetOccSUP(700009615,300,null)
		SELECT dbo.Fun_GetOccSUP(170000001,352,229)
		
	*/
	DECLARE	@res			INT
			,@tip_id		SMALLINT
			,@first_occ		SMALLINT
			,@account_one	BIT
			,@isfirst_occ_added BIT

	SET @res = NULL
	IF @dog_int=0 SET @dog_int=NULL

	SELECT TOP 1
		@res = occ_sup
	FROM dbo.OCC_SUPPLIERS AS OS
	WHERE Occ = @occ
		AND sup_id = @sup_id
		AND (dog_int = @dog_int
		OR @dog_int IS NULL)
		AND occ_sup > 9999
	ORDER BY fin_id DESC

	IF @res IS NOT NULL	
		RETURN @res

	IF @dog_int IS NOT NULL
		SELECT
			@first_occ = first_occ
			,@isfirst_occ_added=isfirst_occ_added
		FROM dbo.DOG_SUP
		WHERE id = @dog_int

	SELECT
		@account_one = account_one
	FROM dbo.SUPPLIERS_ALL
	WHERE id = @sup_id

	IF @account_one = 1
	BEGIN

		IF COALESCE(@first_occ, 0) = 0
		BEGIN
			-- Находим максимальный лиц.поставщика и +1
			SELECT
				@res = MAX(occ_sup)
			FROM OCC_SUPPLIERS os
			WHERE os.sup_id = @sup_id
			AND (os.dog_int = @dog_int
			OR @dog_int IS NULL)

			SELECT
				@res = COALESCE(@res, 0) + 1
		END
		ELSE
		BEGIN
			IF @isfirst_occ_added=1
			BEGIN  -- присоединение числа слева
				SELECT @res = LTRIM(STR(@first_occ)) + LTRIM(STR(@occ))  
			END
			ELSE
			BEGIN
				DECLARE @countLenOcc INT = LEN(LTRIM(STR(@occ)))

				IF LEN(@first_occ) = 3 AND @countLenOcc<=6
					SELECT
						@res = @first_occ * 1000000 + CAST(RIGHT(STR(@occ), 6) AS INT)
				ELSE
				IF LEN(@first_occ) = 2 AND @countLenOcc<=6
					SELECT
						@res = @first_occ * 1000000 + CAST(RIGHT(STR(@occ), 6) AS INT)
				ELSE
				IF LEN(@first_occ) = 1 AND @countLenOcc<=6
					SELECT
						@res = @first_occ * 1000000 + CAST(RIGHT(STR(@occ), 6) AS INT)
				ELSE
				IF LEN(@first_occ) = 1 AND @countLenOcc>=6
					SELECT
						@res = LTRIM(STR(@first_occ)) + LTRIM(STR(@occ))
						--@res = @first_occ * 1000000 + CAST(RIGHT(STR(@occ), 6) AS INT)
				ELSE
				IF LEN(@first_occ) = 3 AND @countLenOcc>6
					SELECT
						@res = @first_occ * 1000000 + CAST(RIGHT(STR(@occ), 6) AS INT)
				ELSE
				IF LEN(@first_occ) = 4
					SELECT
						@res = @first_occ * 100000 + CAST(RIGHT(STR(@occ), 5) AS INT)
				ELSE
				IF LEN(@first_occ) = 5
					SELECT
						@res = @first_occ * 10000 + CAST(RIGHT(STR(@occ), 4) AS INT)
				ELSE
				IF LEN(@first_occ) = 3 AND @countLenOcc=9   -- если 9 знаков лицевой
					SELECT @res = @first_occ * 1000000 + CAST(RIGHT(STR(@occ), 6) AS INT)
				
			END

			-- проверяем сущществует ли новый наш л/сч поставщика
			IF EXISTS (SELECT
						1
					FROM dbo.OCC_SUPPLIERS AS OS 
					WHERE OS.occ_sup = @res)
				OR EXISTS (SELECT
						1
					FROM dbo.OCCUPATIONS o 
					WHERE o.Occ = @res)
				SELECT
					@res = MAX(occ_sup) + 1
				FROM OCC_SUPPLIERS os
				WHERE os.sup_id = @sup_id
				AND (os.dog_int = @dog_int
				OR @dog_int IS NULL)

		END
	END

	RETURN COALESCE(@res, 0)
END
go

