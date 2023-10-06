CREATE   PROCEDURE [dbo].[adm_show_user_sup]
(
	@user_id1 SMALLINT
   ,@access1  BIT = 1
)
AS
	--
	--  Показываем список доступных поставщиков пользователю @access1 =1
	--
	SET NOCOUNT ON

	DECLARE @t TABLE
		(
			id			SMALLINT
		   ,name		VARCHAR(50)
		   ,account_one BIT DEFAULT 0
		)


	-- доступные
	IF @access1 = 1
	BEGIN
		INSERT @t
		(id
		,name
		,account_one)
			SELECT
				ot.id
			   ,ot.name
			   ,account_one
			FROM dbo.USERS_SUP AS pa 
			JOIN dbo.USERS AS u 
				ON pa.SYSUSER = u.login
			JOIN dbo.SUPPLIERS_ALL AS ot 
				ON pa.ONLY_SUP_ID = ot.id
			WHERE u.id = @user_id1
			AND ot.account_one = 1

		IF NOT EXISTS (SELECT
					*
				FROM @t)
			INSERT @t
			(name)
			VALUES ('Все')

	END
	ELSE
	BEGIN --  Показываем список не доступных типов жилого фонда пользователю @access1 = 0	
		INSERT @t
		(id
		,name
		,account_one)
			SELECT
				ot.id
			   ,ot.name
			   ,account_one
			FROM dbo.SUPPLIERS_ALL AS ot 
			WHERE NOT EXISTS (SELECT
					1
				FROM dbo.USERS_SUP AS pa
				JOIN dbo.USERS AS u 
					ON pa.SYSUSER = u.login
				JOIN dbo.SUPPLIERS_ALL AS ot2 
					ON pa.ONLY_SUP_ID = ot2.id
				WHERE u.id = @user_id1
				AND pa.ONLY_SUP_ID = ot.id)
			AND ot.account_one = 1
	END

	SELECT
		*
	FROM @t
go

