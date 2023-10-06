CREATE   PROCEDURE [dbo].[k_GetSumDolg]
(
	  @occ1 INT
	, @fin_current SMALLINT
	, @data1 SMALLDATETIME
	, @LastDatePaym SMALLDATETIME
	, @debug BIT = 0
	, @Res DECIMAL(9, 2) OUTPUT
	, @fin_dolg SMALLINT = 0 OUTPUT
	, @Description VARCHAR(1000) = '' OUTPUT
)
AS
BEGIN
	/*
	ДЛЯ РАСЧЁТА ПЕНИ
	Возвращаем сумму долга по единой квитанции на заданную дату
	
	declare @res DECIMAL(9, 2)=0,@fin_dolg SMALLINT, @Description VARCHAR(1000)
	exec dbo.k_GetSumDolg 326673,135,'20130328','20130401',1, @res OUT, @fin_dolg OUT, @Description	OUT
	select '@res'=@res,'@fin_dolg'=@fin_dolg,'@Description'=@Description
	
	дата: 29.03.12
	*/

	DECLARE @res2 DECIMAL(9, 2) = 0
		  , @res_value DECIMAL(9, 2) = 0
		  , @sum_pay DECIMAL(9, 2) = 0
		  , @fin_id SMALLINT
		  , @start_date SMALLDATETIME
		  , @day TINYINT
		  , @saldo DECIMAL(9, 2) = 0

	SET @day = DAY(@LastDatePaym)
	SELECT @start_date = start_date
	FROM dbo.Global_values
	WHERE fin_id = @fin_current

	IF (@day = 1)
		OR (@day = 31)
	BEGIN

		--IF (@data1 < @start_date) AND (@LastDatePaym < @start_date)
		--IF (@data1 < @LastDatePaym) 
		--IF (@LastDatePaym < @start_date) 
		--IF @data1 < @LastDatePaym
		IF (@data1 < @start_date)
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

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occ_history
			WHERE occ = @occ1
				AND fin_id < @fin_id
		)
		SELECT @fin_id = COALESCE((
				SELECT TOP 1 fin_id
				FROM dbo.Occ_history
				WHERE occ = @occ1
					AND fin_id < @fin_current
				ORDER BY fin_id
			), @fin_current)

	SET @fin_dolg = @fin_id

	SELECT @sum_pay = SUM(ps.value - COALESCE(ps.paymaccount_peny, 0))
	--@sum_pay = SUM(ps.value)
	FROM dbo.Paying_serv AS ps
		JOIN dbo.Payings AS p ON ps.paying_id = p.id
		JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
		JOIN dbo.Paycoll_orgs AS po ON pd.fin_id = po.fin_id
			AND pd.source_id = po.id
		JOIN dbo.Paying_types AS pt ON po.vid_paym = pt.id
		JOIN dbo.Services AS s ON ps.service_id = s.id --AND s.is_peny = 1 -- !!! для расчёта пени
	WHERE p.occ = @occ1
		AND p.fin_id >= @fin_id --AND ps.fin_id<@fin_current  --18/03/2014
		AND pd.day < @data1   -- AND pd.day <= @data1 21.08.13
		AND p.forwarded = CAST(1 AS BIT)
		AND p.sup_id = 0
	--AND pt.peny_no = 0

	IF @sum_pay IS NULL
		SET @sum_pay = 0

	SELECT @saldo = COALESCE(SUM(p.saldo), 0)
		 , @res_value = COALESCE(SUM(p.paid), 0)
	FROM dbo.View_paym AS p
		JOIN dbo.Services AS s ON p.service_id = s.id
	--AND s.is_peny = 1 -- !!! для расчёта пени
	WHERE p.occ = @occ1
		AND p.fin_id = @fin_id
		AND p.account_one = CAST(0 AS BIT)

	--SET @saldo = @saldo + COALESCE(@res2, 0)
	SET @Res = @saldo + COALESCE(@res2, 0)

	---- добавляем предыдущее начисление   24.09.13
	--IF (@day = 1) OR (@day = 31)
	IF @fin_current > @fin_dolg
		SET @Res = @saldo + @res_value
	ELSE
		SET @res_value = 0

	IF @Res IS NULL
		SET @Res = 0

	SET @Res = @Res - @sum_pay

	SET @Description = 'Фин_период=' + LTRIM(dbo.Fun_NameFinPeriod(@fin_id)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@saldo=' + LTRIM(STR(@saldo, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@res_value=' + LTRIM(STR(@res_value, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@sum_pay=' + LTRIM(STR(@sum_pay, 9, 2)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@day=' + LTRIM(STR(@day)) + ';' + '@fin_dolg=' + LTRIM(STR(@fin_dolg)) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + 'Результат=' + LTRIM(STR(@Res, 9, 2))

	IF @debug = 1
		PRINT @Description

END
go

