CREATE   PROCEDURE [dbo].[adm_showusers_work]
(
	@data1  DATETIME
   ,@data2  DATETIME
   ,@occ1   INT		= NULL
   ,@user1  INT		= NULL
   ,@op_id1 VARCHAR(10) = NULL
)
AS
	/*
	--
	--  Наблюдение за работой(внесение изменений) пользователей
	--

	adm_showusers_work '20170201', '20170210'

	*/
	SET NOCOUNT ON

	IF @occ1 = 0
		SET @occ1 = NULL
	IF @user1 = 0
		SET @user1 = NULL


	SELECT
		t.*
	   ,ot.name AS tip_name
	FROM (SELECT
			o.done AS data
		   ,o.occ
		   ,u.Initials AS Initials
		   ,op.name AS Operations
		   ,o.op_id
		   ,o.[user_id]
		   ,o.comp
		   ,o.comments
		   ,o.id
		   ,'OP_LOG' AS TablName
		FROM dbo.OP_LOG AS o 
		JOIN dbo.USERS AS u 
			ON o.[user_id] = u.id
		JOIN dbo.Operations AS op 
			ON o.op_id = op.op_id
		WHERE (o.occ = @occ1
		OR @occ1 IS NULL)
		AND (o.[user_id] = @user1
		OR @user1 IS NULL)
		AND (o.op_id = @op_id1
		OR @op_id1 IS NULL)
		AND done BETWEEN @data1 AND @data2
		UNION ALL
		SELECT
			clog.date_edit AS data
		   ,occ = (SELECT TOP (1)
					cla.occ
				FROM COUNTER_LIST_ALL AS cla 
				WHERE clog.counter_id = cla.counter_id
				AND (cla.occ = @occ1
				OR @occ1 IS NULL))
		   ,u.Initials AS Initials
		   ,op.name AS Operations
		   ,clog.op_id
		   ,[user_id]
		   ,'' AS comp
		   ,clog.comments
		   ,clog.id
		   ,'COUNTER_LOG' AS TablName
		FROM [dbo].[COUNTER_LOG] AS clog 
		JOIN dbo.USERS AS u 
			ON clog.[user_id] = u.id
		JOIN dbo.Operations AS op 
			ON clog.op_id = op.op_id
		WHERE (clog.[user_id] = @user1
		OR @user1 IS NULL)
		AND (clog.op_id = @op_id1
		OR @op_id1 IS NULL)
		AND clog.date_edit BETWEEN @data1 AND @data2) AS t
	LEFT JOIN dbo.OCCUPATIONS o1 
		ON t.occ = o1.occ
	LEFT JOIN dbo.OCCUPATION_TYPES ot 
		ON o1.tip_id = ot.id
	ORDER BY data, t.occ
go

