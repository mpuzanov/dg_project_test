-- =============================================
-- Author:		Пузанов
-- Create date: 07/12/13
-- Description:	
-- =============================================
CREATE       PROCEDURE [dbo].[rep_dolg_occ_serv2]
	@P1				SMALLINT
	,@OCC			INT			= NULL
	,@fin_id1		SMALLINT
	,@fin_id2		SMALLINT
	,@sup_id		INT			= NULL
	,@PrintGroup	SMALLINT	= NULL
	,@div_id		SMALLINT	= NULL
AS
/*
для судов

для отчёта Задолженность по группе (Задолженность по услугам)
в Картотеке

С группировкой услуг 

exec [rep_dolg_occ_serv2] 1,910000121,130,142,null,null,null
*/
BEGIN
	SET NOCOUNT ON;
	IF @OCC IS NULL AND @PrintGroup IS NULL
		SET @OCC = 0
	IF @OCC IS NOT NULL AND @PrintGroup IS NOT NULL
		SET @OCC = 0
	IF @P1 IS NULL OR @P1 NOT IN (1, 2, 3)
		SET @P1 = 1

	DECLARE @t_occ TABLE
		(
			occ			INT	PRIMARY KEY
			,tip_id		SMALLINT
			,bldn_id	INT
		)
	IF @PrintGroup IS NULL
		INSERT INTO @t_occ
		(	occ
			,tip_id
			,bldn_id)
			SELECT
				occ
				,tip_id
				,bldn_id
			FROM dbo.View_OCC_ALL AS voa
			WHERE voa.occ = @OCC
			AND voa.fin_id = @fin_id1
	ELSE
		INSERT INTO @t_occ
		(occ)
			SELECT
				po.occ
			FROM dbo.PRINT_OCC AS po
			JOIN dbo.View_OCC_ALL AS voa
				ON po.occ = voa.occ
			WHERE po.group_id = @PrintGroup
			AND voa.fin_id = @fin_id1

	-- для ограничения доступа услуг
	CREATE TABLE #s
	(
		id			VARCHAR(10)	COLLATE database_default PRIMARY KEY
		,name		VARCHAR(100) COLLATE database_default
		,is_build	BIT
	)

	INSERT INTO #s
	(	id
		,name
		,is_build)
		SELECT
			id
			,name
			,is_build
		FROM dbo.View_SERVICES

	SELECT
		p.occ
		,p.fin_id
		,p.occ AS occ1
		,gb.StrMes AS StrMes
		,p.service_id
		,s.name AS serv_name
		,u.short_id
		,COALESCE(ST.owner_id, 0) AS owner_id
		,p.tarif
		,p.kol		
		,p.saldo AS saldo
		,p.value AS value
		,p.added AS added
		,p.paid AS paid
		,p.paymaccount_serv AS paymaccount_serv
		,p.Debt AS Debt INTO #t
	FROM @t_occ AS t
	JOIN dbo.View_PAYM AS p 
		ON p.occ = t.occ
	JOIN #s AS s
		ON p.service_id = s.id -- vs.id=s.id		
	JOIN dbo.BUILDINGS AS B
		ON t.bldn_id = B.id
	JOIN dbo.GLOBAL_VALUES AS gb 
		ON p.fin_id = gb.fin_id
	LEFT JOIN dbo.UNITS AS U 
		ON p.unit_id=U.id
	LEFT JOIN dbo.SERVICES_TYPES AS ST 
		ON p.service_id = COALESCE(ST.service_id, '') AND t.tip_id = ST.tip_id
	WHERE p.fin_id BETWEEN @fin_id1 AND @fin_id2
	AND B.div_id = COALESCE(@div_id, B.div_id)
	AND (p.saldo<>0 OR p.value<>0 OR p.added<>0 OR p.paid<>0 AND p.paymaccount_serv<>0 OR p.Debt<>0)
	ORDER BY p.occ
	, p.fin_id DESC

	UPDATE t
	SET serv_name = ST.service_name
	FROM #t AS t
	JOIN dbo.SERVICES_TYPES AS ST 
		ON t.owner_id = ST.id


	SELECT
		fin_id 
		,occ
		,StrMes
		,serv_name
		,short_id 
		,kol
		,SUM(tarif) AS tarif
		,CAST(SUM(saldo) AS DECIMAL(9, 2)) AS saldo
		,SUM(value) AS value
		,SUM(added) AS added
		,SUM(paid) AS paid
		,SUM(paymaccount_serv) AS paymaccount_serv
		,SUM(Debt) AS Debt
	FROM #t
	GROUP BY fin_id ,occ
		,StrMes
		,serv_name
		,short_id 
		,kol
	ORDER BY fin_id desc

	--SELECT
	--	*
	--FROM #t
END
go

