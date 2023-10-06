CREATE   PROCEDURE [dbo].[k_GetSumDolg2016]
(
	@occ1			INT
	,@fin_current	SMALLINT
	,@data1			SMALLDATETIME
	,@Peny_metod	SMALLINT
	,@debug			BIT				= 0
	,@dolg1			DECIMAL(9, 2)	= 0 OUTPUT
	,@dolg2			DECIMAL(9, 2)	= 0 OUTPUT
	,@dolg3			DECIMAL(9, 2)	= 0 OUTPUT
	,@Description	VARCHAR(1000)	= '' OUTPUT
)
AS
BEGIN
	/*
	ДЛЯ РАСЧЁТА ПЕНИ
	Возвращаем сумму долга по единой квитанции на заданную дату
	
	declare @res DECIMAL(9, 2)=0,@fin_dolg SMALLINT, @Description VARCHAR(1000)
	exec dbo.k_GetSumDolg 326673,135,'20130328','20130401',1, @res OUT, @fin_dolg OUT, @Description	OUT
	select '@res'=@res,'@fin_dolg'=@fin_dolg,'@Description'=@Description
	
	дата: 
	*/

	DECLARE	@res2			DECIMAL(9, 2)	= 0
			,@res_value		DECIMAL(9, 2)	= 0
			,@sum_pay		DECIMAL(9, 2)	= 0
			,@fin_id		SMALLINT
			,@start_date	SMALLDATETIME
			,@day			TINYINT
			,@saldo			DECIMAL(9, 2)	= 0

	IF @fin_current IS NULL 
		SET @fin_current = dbo.Fun_GetFinCurrent(NULL,NULL,NULL,@occ1)

	IF @fin_id IS NULL 
		SET @fin_id = @fin_current

	IF NOT EXISTS (SELECT TOP 1
				*
			FROM dbo.OCC_HISTORY 
			WHERE occ = @occ1
			AND fin_id < @fin_id)
		SELECT
			@fin_id = COALESCE((SELECT TOP 1
					fin_id
				FROM dbo.OCC_HISTORY 
				WHERE occ = @occ1
				AND fin_id < @fin_current
				ORDER BY fin_id)
			, @fin_current)

	SELECT
		@sum_pay = SUM(ps.Value - COALESCE(ps.PaymAccount_peny, 0))
	--@sum_pay = SUM(ps.value)
	FROM dbo.PAYING_SERV AS ps 
	JOIN dbo.PAYINGS AS p 
		ON ps.paying_id = p.id
	JOIN dbo.PAYDOC_PACKS AS pd 
		ON p.pack_id = pd.id
	JOIN dbo.PAYCOLL_ORGS AS po 
		ON pd.fin_id = po.fin_id
		AND pd.source_id = po.id
	JOIN dbo.PAYING_TYPES AS pt
		ON po.vid_paym = pt.id
	JOIN dbo.SERVICES AS s
		ON ps.service_id = s.id --AND s.is_peny = 1 -- !!! для расчёта пени
	WHERE p.occ = @occ1
	AND p.fin_id >= @fin_id --AND ps.fin_id<@fin_current  --18/03/2014
	AND pd.day < @data1   -- AND pd.day <= @data1 21.08.13
	AND p.forwarded = 1
	AND p.sup_id=0
	--AND pt.peny_no = 0

	IF @sum_pay IS NULL
		SET @sum_pay = 0


	SELECT
		@saldo = COALESCE(SUM(p.saldo), 0)
		,@res_value = COALESCE(SUM(p.Paid), 0)
	FROM dbo.View_PAYM AS p 
	JOIN dbo.SERVICES AS s 
		ON p.service_id = s.id
	--AND s.is_peny = 1 -- !!! для расчёта пени
	WHERE p.occ = @occ1
	AND p.fin_id = @fin_id
	AND (p.account_one = 0)

	SET @saldo = @saldo + COALESCE(@res2, 0)

	SET @dolg1 = @saldo + @res_value

	IF @dolg1 IS NULL
		SET @dolg1 = 0

	SET @dolg1 = @dolg1 - @sum_pay

	SET @Description = 'Фин_период=' + LTRIM(dbo.Fun_NameFinPeriod(@fin_id)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@saldo=' + LTRIM(STR(@saldo, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@res_value=' + LTRIM(STR(@res_value, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@sum_pay=' + LTRIM(STR(@sum_pay, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@day=' + LTRIM(STR(@day)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + 'Результат=' + LTRIM(STR(@dolg1, 9, 2))

	IF @debug = 1
		PRINT @Description

END
go

