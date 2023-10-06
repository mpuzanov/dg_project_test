CREATE   PROCEDURE [dbo].[k_provaccess]
AS
	--
	--  Проверка вхождения в группы 
	--  'адмн' - 1
	--  'стрш' - 2
	--  'опер' - 3
	--  если 123 входит в все группы
	-- 23 - старший оператор и просто оператор и.т.п
	--  3 - оператор

	SET NOCOUNT ON

	DECLARE	@user_id1	INT
			,@result	TINYINT
	SELECT
		@user_id1 = id
	FROM USERS
	WHERE login = system_user
	SET @result = 0

	IF EXISTS (SELECT
				1
			FROM GROUP_MEMBERSHIP 
			WHERE user_id = @user_id1
			AND group_id = 'адмн')
	BEGIN
		SET @result = 1
	END
	IF EXISTS (SELECT
				1
			FROM GROUP_MEMBERSHIP 
			WHERE user_id = @user_id1
			AND group_id = 'стрш')
	BEGIN
		SET @result = @result * 10 + 2
	END

	IF EXISTS (SELECT
				1
			FROM GROUP_MEMBERSHIP 
			WHERE user_id = @user_id1
			AND group_id = 'опер')
	BEGIN
		SET @result = @result * 10 + 3
	END
	SELECT
		'result' = @result
go

