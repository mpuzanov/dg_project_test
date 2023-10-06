CREATE   PROCEDURE [dbo].[k_GetSumDolgSup]
(
	@occ1			INT
	,@fin_current	SMALLINT
	,@data1			SMALLDATETIME
	,@LastDatePaym	SMALLDATETIME
	,@sup_id		INT
	,@debug			BIT				= 0
	,@Res			DECIMAL(9, 2)	OUTPUT
	,@fin_dolg		SMALLINT		= 0 OUTPUT
	,@Description	VARCHAR(1000)	= '' OUTPUT
)
AS
BEGIN
	/*
	ДЛЯ РАСЧЁТА ПЕНИ
	Возвращаем сумму долга по единой квитанции на заданную дату
	
	declare @res DECIMAL(9, 2)=0
	exec dbo.k_GetSumDolgSup 216462,123,'20120329','20120410',300,0,@res OUT
	select @res
		
	дата: 29.03.12
	*/

	DECLARE	@sum_pay		DECIMAL(9, 2)	= 0
			,@res_value		DECIMAL(9, 2)	= 0
			,@fin_id		SMALLINT
			,@start_date	SMALLDATETIME
			,@day			TINYINT
			,@saldo			DECIMAL(9, 2)

	SELECT
		@start_date = start_date
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_current

	SELECT @day = DAY(@LastDatePaym)

	IF (@day = 1)
		OR (@day = 31)
	BEGIN
		IF @data1 < @start_date
			--IF @data1 < @LastDatePaym
			SET @fin_id = @fin_current - 2
		ELSE
			SET @fin_id = @fin_current - 1
	END

	IF (@day > 1
		AND @day < 31)
	BEGIN
		IF @data1 < @LastDatePaym
			SET @fin_id = @fin_current - 1
		ELSE
			SET @fin_id = @fin_current
	END

	IF (@day < 1
		OR @day > 31)
		SET @fin_id = @fin_current

	SET @fin_dolg = @fin_id

	SELECT
		@sum_pay = SUM(p.Value - COALESCE(p.PaymAccount_peny, 0))
	FROM dbo.PAYINGS AS p 
	JOIN dbo.PAYDOC_PACKS AS pd
		ON pd.id = p.pack_id
	JOIN dbo.PAYCOLL_ORGS AS po 
		ON pd.fin_id = po.fin_id
		AND pd.source_id = po.id
	JOIN dbo.PAYING_TYPES AS pt 
		ON po.vid_paym = pt.id
	WHERE pd.fin_id >= @fin_id
	AND p.occ = @occ1
	AND p.sup_id = @sup_id
	AND pd.day < @data1  --AND pd.day <= @data1  15/10/2015
	AND p.forwarded = 1
	--AND pt.peny_no = 0

	IF @sum_pay IS NULL
		SET @sum_pay = 0

	SELECT
		@saldo = SUM(p.saldo)
		,@res_value = COALESCE(SUM(p.Paid), 0)
	FROM dbo.OCC_SUPPLIERS AS os 
	JOIN dbo.View_PAYM AS p
		ON os.occ = p.occ
		AND os.fin_id = p.fin_id
	JOIN dbo.CONSMODES_LIST AS cl 
		ON p.occ = cl.occ
		AND p.service_id = cl.service_id
		AND os.occ_sup = cl.occ_serv
	JOIN dbo.View_SERVICES AS s 
		ON p.service_id = s.id
	--AND s.is_peny = 1  -- !!! для расчёта пени
	WHERE os.occ = @occ1
	AND os.fin_id = @fin_id
	AND os.sup_id = @sup_id
	AND (p.account_one = 1)

	IF @saldo IS NULL
		SET @saldo = 0

	--IF (@day = 1) OR (@day = 31) SET @saldo = @saldo + @res_value
	IF @fin_current > @fin_dolg
		SET @Res = @saldo + @res_value
	ELSE
		SET @res_value = 0

	SET @Res = @Res - @sum_pay

	SET @Description = 'Фин_период=' + LTRIM(dbo.Fun_NameFinPeriod(@fin_id)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@saldo=' + LTRIM(STR(@saldo, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@res_value=' + LTRIM(STR(@res_value, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@sum_pay=' + LTRIM(STR(@sum_pay, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@day=' + LTRIM(STR(@day)) + ';' + '@fin_dolg=' + LTRIM(STR(@fin_dolg)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + 'Результат=' + LTRIM(STR(@Res, 9, 2))

	IF @debug = 1
	BEGIN
		PRINT @Description
	END

END
go

