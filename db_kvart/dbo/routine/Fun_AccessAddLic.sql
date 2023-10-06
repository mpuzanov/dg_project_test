CREATE   FUNCTION [dbo].[Fun_AccessAddLic]
(
	@occ1 INT
)
RETURNS TINYINT
AS
BEGIN
	--
	-- Проверка доступа к заданному лицевому для работы с Разовыми
	--
	-- 0 - Доступ запрещен;   1 - Разрешен
	--

	DECLARE	@result1	TINYINT
			,@group		VARCHAR(10) -- максимальная группа доступа
			,@user_id	SMALLINT;
	SET @result1 = 0;

	SELECT
		@user_id = id
	FROM dbo.USERS 
	WHERE login = system_user;
	SELECT
		@group = dbo.Fun_GetMaxGroupAccess(@user_id);

	IF @group = 'опер'
	BEGIN
		IF NOT EXISTS (SELECT
					1
				FROM dbo.VOCC AS o 
				JOIN dbo.BUILDINGS AS b 
					ON o.bldn_id = b.id
				WHERE o.occ = @occ1
				AND EXISTS (SELECT
						1
					FROM dbo.AccessJeuOper
					WHERE b.sector_id = area_id
					AND group_id = @group))
		BEGIN
			SET @result1 = 0;
		END;
		ELSE
			SET @result1 = 1;
	END;

	IF @group = 'стрш'
	BEGIN
		IF NOT EXISTS (SELECT
					1
				FROM dbo.VOCC AS o 
				JOIN dbo.BUILDINGS AS b 
					ON o.bldn_id = b.id
				WHERE occ = @occ1
				AND EXISTS (SELECT
						1
					FROM dbo.AccessJeuOper 
					WHERE b.div_id = area_id
					AND group_id = @group))
		BEGIN
			IF @result1 = 0
				SET @result1 = 0;
			ELSE
				SET @result1 = 1;
		END;
		ELSE
			SET @result1 = 1;
	END;

	IF @group = 'адмн'
	BEGIN
		IF NOT EXISTS (SELECT
					1
				FROM dbo.AccessAddOper 
				WHERE group_id = @group)
		BEGIN
			IF @result1 = 0
				SET @result1 = 0;
			ELSE
				SET @result1 = 1;
		END;
		ELSE
			SET @result1 = 1;
	END;

	RETURN @result1;

END;
go

