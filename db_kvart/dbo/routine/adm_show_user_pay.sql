CREATE   PROCEDURE [dbo].[adm_show_user_pay]
(
	@login	 VARCHAR(30)
   ,@access1 BIT = 1
)
AS
	--
	--  Показываем список доступных ВИДОВ ПЛАТЕЖЕЙ пользователю @access1 =1
	--
	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	DECLARE @t TABLE
		(
			ext					VARCHAR(10)	DEFAULT NULL
		   ,name				VARCHAR(50)
		   ,description			VARCHAR(50) DEFAULT NULL
		   ,sup_processing_name VARCHAR(50)
		   ,paying_type			VARCHAR(50)
		)


	-- доступные
	IF @access1 = 1
	BEGIN
		INSERT @t
		(ext
		,name
		,description
		,sup_processing_name
		,paying_type)
			SELECT DISTINCT
				t.[ext]
			   ,b.short_name
			   ,t.[description]
			   ,sup_processing_name =
					CASE
						WHEN sup_processing = 0 THEN 'обработка всех платежей'
						WHEN sup_processing = 1 THEN 'обработка только поставщиков'
						WHEN sup_processing = 2 THEN 'обработка только единых лицевых'
						ELSE '?'
					END
			   ,pt.name
			FROM dbo.paycoll_orgs AS t 
			JOIN dbo.paying_types pt 
				ON t.vid_paym = pt.id
			JOIN dbo.BANK AS b 
				ON t.BANK = b.id
			INNER JOIN dbo.users_pay_orgs AS upo 
				ON t.ext = upo.ONLY_PAY_ORGS
				AND upo.SYSUSER = @login
			WHERE FIN_ID = @fin_current


		IF NOT EXISTS (SELECT
					*
				FROM @t)
			INSERT @t
			(name)
			VALUES ('Все')
	END
	ELSE
	BEGIN --  Показываем список не доступных ВИДОВ ПЛАТЕЖЕЙ пользователю @access1 = 0	
		INSERT @t
		(ext
		,name
		,description
		,sup_processing_name
		,paying_type)
			SELECT DISTINCT
				t.ext
			   ,b.short_name
			   ,t.description
			   ,sup_processing_name =
					CASE
						WHEN sup_processing = 0 THEN 'обработка всех платежей'
						WHEN sup_processing = 1 THEN 'обработка только поставщиков'
						WHEN sup_processing = 2 THEN 'обработка только единых лицевых'
						ELSE '?'
					END
			   ,pt.name
			FROM dbo.[PAYCOLL_ORGS] AS t 
			JOIN dbo.PAYING_TYPES pt 
				ON t.vid_paym = pt.id
			JOIN dbo.BANK AS b 
				ON t.BANK = b.id
			WHERE NOT EXISTS (SELECT
					*
				FROM dbo.USERS_PAY_ORGS AS upo 
				WHERE t.ext = upo.ONLY_PAY_ORGS
				AND upo.SYSUSER = @login)
			AND FIN_ID = @fin_current

	END

	SELECT
		*
	FROM @t
	ORDER BY name
go

