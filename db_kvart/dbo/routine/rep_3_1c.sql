CREATE   PROCEDURE [dbo].[rep_3_1c]
(
	@fin_id1		SMALLINT
	,@build_str1	VARCHAR(400)	= ''
	,@div_id		SMALLINT		= NULL
	,@tip			SMALLINT		= NULL
)
AS
	/*
	
	Начисления по заданным домам или Району
	
	*/
	SET NOCOUNT ON

	IF (@tip IS NULL)
		OR (@tip = 0)
		SET @tip = 1  -- муниципальный жилой фонд

	DECLARE @fin_current SMALLINT

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)   -- находим значение текущего фин периода

	DECLARE @build TABLE
		(
			id		INT
			,adres	VARCHAR(50)
		)

	IF (@build_str1 = '')  -- дома не выбраны берем район
	BEGIN
		INSERT
		INTO @build
		(	id
			,adres)
			SELECT
				b.id
				,concat(s.name , ' д.' , b.nom_dom)
			FROM dbo.BUILDINGS AS b
			JOIN dbo.VSTREETS AS s
				ON b.street_id = s.id
			WHERE b.div_id = @div_id
			ORDER BY s.name, b.nom_dom_sort
	END
	ELSE
	BEGIN
		INSERT
		INTO @build
		(	id
			,adres)
			SELECT
				p.value
				,concat(s.name , ' д.' , b.nom_dom)
			FROM STRING_SPLIT(@build_str1, ';') AS p
			JOIN dbo.BUILDINGS AS b
				ON p.value = b.id
			JOIN dbo.VSTREETS AS s
				ON b.street_id = s.id
			ORDER BY s.name, b.nom_dom_sort
	END


	--select * from @build

	SELECT
		CASE
			WHEN (GROUPING(b.adres) = 1) THEN ' '
			ELSE coalesce(b.adres, '????')
		END AS 'Дом'
		,CASE
			WHEN (GROUPING(s.name) = 1) THEN 'Итого:'
			ELSE coalesce(s.name, '????')
		END AS 'Услуга'
		,SUM(pl.Value) AS 'Начислено'
		,SUM(pl.Added) AS 'Перерасчеты'
		,SUM(pl.Discount) AS 'Льготы'
		,SUM(pl.Compens) AS 'Субсидии'
		,SUM(pl.Paid) AS 'Пост_начисление'
		,SUM(pl.PaymAccount) AS 'Оплачено'
		,SUM(pl.PaymAccount_peny) AS 'из_них_пени'
	FROM	dbo.View_OCC_ALL AS o 
			,dbo.View_PAYM AS pl 
			,dbo.FLATS AS f 
			,@build AS b
			,dbo.View_SERVICES AS s
	WHERE o.tip_id = @tip
	AND o.status_id <> 'закр'
	AND o.flat_id = f.id
	AND f.bldn_id = b.id
	AND o.fin_id = @fin_id1
	AND o.fin_id = pl.fin_id
	AND o.occ = pl.occ
	AND pl.service_id = s.id
	AND pl.subsid_only = 0
	GROUP BY	b.adres
				,s.name WITH ROLLUP
go

