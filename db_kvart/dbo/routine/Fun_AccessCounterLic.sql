CREATE   FUNCTION [dbo].[Fun_AccessCounterLic]
(
	@build_id1 INT
)
RETURNS TINYINT
AS
BEGIN
	/*
		 Проверка доступа для редактирования к заданному дому для работы со счетчиками
		
		 0 - Доступ запрещен;   1 - Разрешен
		
	*/
	DECLARE @result1 TINYINT
	SET @result1 = 0

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN -- База закрыта для редактирования
		RETURN @result1
	END

	DECLARE @group VARCHAR(10) -- максимальная группа доступа
	DECLARE @user_id SMALLINT
	SELECT
		@user_id = [dbo].[Fun_GetCurrentUserId]()

	SELECT
		@group = dbo.Fun_GetMaxGroupAccess(@user_id)

	IF @group = 'опер'
	BEGIN
		IF NOT EXISTS (SELECT
					1
				FROM dbo.BUILDINGS AS b 
				WHERE b.id = @build_id1
				AND EXISTS (SELECT
						1
					FROM dbo.AccessJeuOper 
					WHERE b.div_id = area_id
					AND group_id = @group))
		BEGIN
			SET @result1 = 0
		END
		ELSE
			SET @result1 = 1
	END

	IF @group = 'стрш'
	BEGIN
		IF NOT EXISTS (SELECT
					1
				FROM BUILDINGS AS b 
				WHERE b.id = @build_id1
				AND EXISTS (SELECT
						1
					FROM dbo.AccessJeuOper 
					WHERE b.div_id = area_id
					AND group_id = @group))
		BEGIN
			IF @result1 = 0
				SET @result1 = 0
			ELSE
				SET @result1 = 1
		END
		ELSE
			SET @result1 = 1
	END

	IF @group = 'адмн'
	BEGIN
		IF NOT EXISTS (SELECT
					1
				FROM dbo.AccessCounterOper 
				WHERE group_id = @group)
		BEGIN
			IF @result1 = 0
				SET @result1 = 0
			ELSE
				SET @result1 = 1
		END
		ELSE
			SET @result1 = 1
	END

	-- Проверяем состояние по типу фонда дома
	IF @result1 = 1
	BEGIN
		-- СуперАдминов не проверяем
		IF EXISTS (SELECT
					1
				FROM dbo.USERS u 
				WHERE (u.login = system_user
				AND u.SuperAdmin = 1)
				OR system_user = 'sa')
			RETURN 1;

		DECLARE @tip_id SMALLINT
		SELECT
			@tip_id = B.tip_id
		FROM dbo.BUILDINGS AS B
		WHERE B.id = @build_id1

		IF EXISTS (SELECT
					1
				FROM dbo.VOCC_TYPES AS VT
				WHERE VT.id = @tip_id
				AND VT.state_id <> 'норм')
			SET @result1 = 0

		IF @result1 = 1
			AND EXISTS (SELECT
					1
				FROM dbo.[USERS_OCC_TYPES] AS VT
				WHERE sysuser = system_user
				AND ONLY_TIP_ID = @tip_id
				AND VT.only_read = 1)
			SET @result1 = 0

	END

	RETURN @result1
END
go

