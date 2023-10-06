CREATE   PROCEDURE [dbo].[adm_areas2]
--
-- Показывает недоступные данные для пользователя
--
(
	@user_id1  INT
   ,@group_id1 VARCHAR(10) = NULL
   ,@op_id1	   VARCHAR(10)
)
AS

	SET NOCOUNT ON

	DECLARE @area1 VARCHAR(10)
		   ,@name  VARCHAR(25)

	DECLARE @TempTable TABLE
		(
			id	 INT
		   ,name VARCHAR(30)
		)

	DECLARE @AllowTable TABLE
		(
			user_id	 INT
		   ,group_id VARCHAR(10)
		   ,op_id	 VARCHAR(10)
		   ,area_id	 INT
		)

	-- Находим группу пользователя с максимальными привелегиями
	IF @group_id1 IS NULL
		SELECT
			@group_id1 = dbo.Fun_GetMaxGroupAccess(@user_id1)

	SELECT
		@area1 = areatype_id
	FROM dbo.group_authorities 
	WHERE group_id = @group_id1
	AND op_id = @op_id1

	INSERT INTO @AllowTable
	(user_id
	,group_id
	,op_id
	,area_id)
		SELECT
			user_id
		   ,group_id
		   ,op_id
		   ,area_id
		FROM dbo.allowed_areas
		WHERE user_id = @user_id1
		AND group_id = @group_id1
		AND op_id = @op_id1

	IF @area1 = 'все!'
	BEGIN
		IF NOT EXISTS (SELECT
					*
				FROM @AllowTable)
			SELECT
				@name = 'Все данные'
		IF @name IS NOT NULL
			INSERT INTO @TempTable
			VALUES (0
				   ,@name)
	END

	IF @area1 = 'отд!'
	BEGIN
		IF EXISTS (SELECT
					*
				FROM @AllowTable)
		BEGIN
			INSERT INTO @TempTable
				SELECT
					div.id
				   ,div.name
				FROM dbo.divisions AS div
				WHERE NOT EXISTS (SELECT
						area_id
					FROM @AllowTable
					WHERE area_id = div.id)
		--and div.id>0
		END
		ELSE
		BEGIN
			INSERT INTO @TempTable
				SELECT
					div.id
				   ,div.name
				FROM dbo.divisions AS div
		--where id>0
		END
	END

	IF @area1 = 'тех!'
	BEGIN
		IF EXISTS (SELECT
					*
				FROM @AllowTable)
		BEGIN
			INSERT INTO @TempTable
				SELECT
					s.id
				   ,s.name
				FROM dbo.SECTOR AS s
				WHERE NOT EXISTS (SELECT
						area_id
					FROM @AllowTable
					WHERE area_id = s.id)
				AND s.id > 0
		END
		ELSE
		BEGIN
			INSERT INTO @TempTable
				SELECT
					s.id
				   ,s.name
				FROM dbo.SECTOR AS s
				WHERE s.id > 0
		END

	END

	SELECT
		id
	   ,concat(id , ', ' , RTRIM(name)) as name
	FROM @TempTable
go

