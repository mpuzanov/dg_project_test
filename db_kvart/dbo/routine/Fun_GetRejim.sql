CREATE   FUNCTION [dbo].[Fun_GetRejim] ()
RETURNS VARCHAR(10)
AS
BEGIN
	/*
		select [dbo].[Fun_GetRejim]()
		Функция возвращает текущий режим базы  (норм, стоп, чтен, адмн, адмч)
		
	*/
	DECLARE	@Rejim			VARCHAR(10)
			,@SuperAdmin	BIT				= 0

	SELECT
		@Rejim = COALESCE(dbstate_id, 'стоп')
	FROM dbo.Db_states 
	WHERE is_current = 1;

	SELECT
		@SuperAdmin = SuperAdmin
	FROM dbo.USERS AS u
	WHERE login = system_user;

	IF EXISTS (SELECT
				1
			FROM dbo.USERS u
			WHERE (u.login = system_user
			AND u.SuperAdmin = 1)
			OR system_user in ('sa'))
	BEGIN
		SELECT
			@SuperAdmin = 1
			,@Rejim = 'норм';
	END
	ELSE
		SELECT
			@Rejim =
				CASE
					WHEN (@Rejim = 'адмн' AND
					@SuperAdmin = 0) THEN 'стоп'
					WHEN (@Rejim = 'адмч' AND
					@SuperAdmin = 0) THEN 'чтен'
					ELSE @Rejim
				END;

	RETURN (@Rejim)

END
go

