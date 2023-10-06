CREATE   PROCEDURE [dbo].[adm_areas]
(
	@user_id1	INT -- код пользователя
	,@group_id1	VARCHAR(10)	= NULL -- код группы
	,@op_id1	VARCHAR(10)-- код работы(работа с субсидиями ит.п.)
)
AS
/*
	Показывает список доступных участков для пользователя
	EXEC adm_areas @user_id1=2, @op_id1='прлс'
*/	
	SET NOCOUNT ON

	DECLARE	@area1	VARCHAR(10)
			,@name	VARCHAR(25)

	CREATE TABLE #temp
	(
		id		INT
		,name	VARCHAR(30) COLLATE database_default
	)

	IF @group_id1 IS NULL
		-- Находим группу пользователя с максимальными привелегиями
		SELECT @group_id1=dbo.Fun_GetMaxGroupAccess(@user_id1)
		
	SELECT
		@area1 = areatype_id
	FROM dbo.GROUP_AUTHORITIES 
	WHERE group_id = @group_id1
	AND op_id = @op_id1;
		
	IF @area1 = 'все!'
	BEGIN
		IF EXISTS (SELECT
					area_id
				FROM dbo.ALLOWED_AREAS 
				WHERE [user_id] = @user_id1
				AND group_id = @group_id1
				AND op_id = @op_id1)
		BEGIN
			SELECT
				@name = 'Все данные';
			INSERT INTO #temp
			VALUES (0
					,@name);
		END
	END

	IF @area1 = 'отд!'
	BEGIN
		INSERT INTO #temp
			SELECT
				div.id
				,div.name
			FROM dbo.ALLOWED_AREAS AS a 
			JOIN dbo.DIVISIONS AS div 
				ON area_id = div.id
			WHERE [user_id] = @user_id1
			AND group_id = @group_id1
			AND op_id = @op_id1
	END

	IF @area1 = 'тех!'
	BEGIN
		INSERT INTO #temp
			SELECT
				s.id
				,s.name
			FROM dbo.ALLOWED_AREAS AS a 
			JOIN dbo.SECTOR AS s 
				ON area_id = s.id
			WHERE [user_id] = @user_id1
			AND group_id = @group_id1
			AND op_id = @op_id1
	END

	SELECT
		id
		,concat(id , ', ' , RTRIM(name)) AS 'name'
	FROM #temp;

	DROP TABLE IF EXISTS #temp;
go

