CREATE   PROCEDURE [dbo].[k_GetSumDolgPeny]
(
	  @occ1 INT
	, @fin_current SMALLINT
	, @data1 SMALLDATETIME
	, @LastDatePaym SMALLDATETIME
	, @debug BIT = 0
	, @Res DECIMAL(9, 2) OUTPUT
	, @Description VARCHAR(1000) = '' OUTPUT
)
AS
BEGIN
	/*
	ДЛЯ РАСЧЁТА ПЕНИ
	Возвращаем сумму долга по единой квитанции на заданную дату для расчёта пени с учётом текущих платежей
	
	declare @res DECIMAL(9, 2)=0
	exec dbo.k_GetSumDolgPeny 326673,135,'20130328','20130401',1, @res OUT
	select '@res'=@res
	
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

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occ_history 
			WHERE Occ = @occ1
				AND fin_id < @fin_id
		)
		SELECT @fin_id = (
				SELECT TOP 1 fin_id
				FROM dbo.Occ_history 
				WHERE Occ = @occ1
					AND fin_id < @fin_current
				ORDER BY fin_id
			)
	SELECT @sum_pay = SUM(ps.Value - COALESCE(ps.PaymAccount_peny, 0))
	--@sum_pay = SUM(ps.value)
	FROM dbo.Paying_serv AS ps 
		JOIN dbo.Payings AS p  ON ps.paying_id = p.id
		JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
		JOIN dbo.Paycoll_orgs AS po ON pd.fin_id = po.fin_id
			AND pd.source_id = po.id
		JOIN dbo.Paying_types AS pt ON po.vid_paym = pt.id
		JOIN dbo.Services AS s ON ps.service_id = s.id --AND s.is_peny = 1 -- !!! для расчёта пени
	WHERE p.Occ = @occ1
		AND p.fin_id >= @fin_id
		AND pd.day < @data1
		AND p.forwarded = 1
		AND p.sup_id = 0
		AND pt.peny_no = 0

	IF @sum_pay IS NULL
		SET @sum_pay = 0

	SELECT @saldo = COALESCE(SUM(p.SALDO), 0)
		 , @res_value = COALESCE(SUM(p.Paid), 0)
	FROM dbo.View_paym AS p 
		JOIN dbo.Services AS s ON p.service_id = s.id
			AND s.is_peny = 1 -- !!! для расчёта пени
	WHERE p.Occ = @occ1
		AND p.fin_id = @fin_id
		AND (p.account_one = 0)


	-- Если есть переплата на услугах на кот.пени не начисляется то прибавляем её
	SELECT @res2 = SUM(p.SALDO)
	FROM dbo.View_paym AS p 
		JOIN dbo.Services AS s ON p.service_id = s.id
			AND s.is_peny = 0
	WHERE p.Occ = @occ1
		AND p.fin_id = @fin_id
		AND p.SALDO < 0
		AND (p.account_one = 0)

	SET @Res = @saldo + COALESCE(@res2, 0)

	-- добавляем предыдущее начисление   24.09.13
	--IF (@day = 1) OR (@day = 31)  SET @res = @res + @res_value

	IF @Res IS NULL
		SET @Res = 0

	SET @Res = @Res - @sum_pay

	SET @Description = 'Фин_период=' + dbo.Fun_NameFinPeriod(@fin_id) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@saldo=' + STR(@saldo, 15, 4) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@sum_pay=' + STR(@sum_pay, 15, 4) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@day=' + STR(@day) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + '@Res2=' + STR(@res2, 15, 4) + ';' + CHAR(13) + CHAR(10)
	SET @Description = @Description + 'Результат=' + LTRIM(STR(@Res, 15, 4))

	IF @debug = 1
	BEGIN
		PRINT @Description
	END

END
go

