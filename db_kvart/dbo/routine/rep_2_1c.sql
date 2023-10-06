CREATE   PROCEDURE [dbo].[rep_2_1c]
(
	@fin_id1		SMALLINT
	,@service_str1	VARCHAR(1000)
	,@tip			SMALLINT	= NULL
)
AS
	/*
	
	Начисления по Поставщикам
	
	*/
	SET NOCOUNT ON


	IF (@tip IS NULL) OR (@tip = 0)
		SET @tip = 1 -- муниципальный жилой фонд

	DECLARE @Fin_current SMALLINT
	-- находим значение текущего фин периода
	SELECT
		@Fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	DECLARE @servises TABLE
		(
			service_id	VARCHAR(10)	PRIMARY KEY
			,serv_name	VARCHAR(100)
		)

	INSERT INTO @servises
	(	service_id
		,serv_name)
		SELECT
			p.value
			,s.Name
		FROM	 STRING_SPLIT(@service_str1, ';') AS p
				,SERVICES AS s
		WHERE p.value = s.id

	SELECT
		CASE
			WHEN (GROUPING(s.serv_name) = 1) THEN 'Итого:'
		ELSE COALESCE(s.serv_name, '????')
		END AS 'Услуга'
		,CASE
			WHEN (GROUPING(sp.Name) = 1) THEN ' '
		ELSE COALESCE(sp.Name, '????')
		END AS 'Поставщик'
		,SUM(pl.value) AS 'Начислено'
		,SUM(pl.added) AS 'Перерасчеты'
		,SUM(pl.discount) AS 'Льготы'
		,SUM(pl.compens) AS 'Субсидии'
		,SUM(pl.paid) AS 'Пост_начисление'
		,SUM(pl.paymaccount) AS 'Оплачено'
		,SUM(pl.paymaccount_peny) AS 'из_них_пени'
	FROM	dbo.View_OCC_ALL AS o 
			,dbo.View_SUPPLIERS AS sp 
			,dbo.View_PAYM AS pl 
			,@servises AS s
	WHERE o.tip_id = @tip
	--and o.status_id<>'закр'
		AND o.fin_id = @fin_id1
		AND o.occ = pl.occ
		AND pl.fin_id = o.fin_id
		AND pl.service_id = s.service_id
		AND pl.service_id = s.service_id
		AND pl.source_id = sp.id
		AND pl.subsid_only = 0
	GROUP BY	s.serv_name
				,sp.Name WITH ROLLUP
go

