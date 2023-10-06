CREATE   FUNCTION [dbo].[Fun_GetSumDolgPeny]
(
	@occ1			INT
	,@fin_current	SMALLINT
	,@data1			SMALLDATETIME
	,@LastDatePaym	SMALLDATETIME
)
RETURNS DECIMAL(9, 2)
AS
BEGIN
	/*
	ДЛЯ РАСЧЁТА ПЕНИ
	Возвращаем сумму долга по единой квитанции на заданную дату для расчёта пени с учётом текущих платежей
	
	select dbo.Fun_GetSumDolg(326673,135,'20130328','20130401')
	
	дата: 29.03.12
	*/

	DECLARE	@res			DECIMAL(9, 2)	= 0
			,@res2			DECIMAL(9, 2)	= 0
			,@res_value		DECIMAL(9, 2)	= 0
			,@sum_pay		DECIMAL(9, 2)	= 0
			,@fin_id		SMALLINT
			,@start_date	SMALLDATETIME
			,@day			TINYINT

	SET @day = DAY(@LastDatePaym)
	--SELECT @start_date=start_date  FROM dbo.GLOBAL_VALUES WHERE fin_id=@fin_current

	IF @day = 1
	BEGIN

		IF @data1 < @LastDatePaym
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

	SELECT
		@sum_pay = SUM(ps.value - COALESCE(ps.paymaccount_peny, 0))
	--@sum_pay = SUM(ps.value)
	FROM dbo.PAYING_SERV AS ps 
	JOIN dbo.PAYINGS AS p 
		ON ps.paying_id = p.id AND p.occ=ps.occ
	JOIN dbo.PAYDOC_PACKS AS pd 
		ON p.pack_id = pd.id
	JOIN dbo.PAYCOLL_ORGS AS po 
		ON pd.fin_id = po.fin_id
		AND pd.source_id = po.id
	JOIN dbo.PAYING_TYPES AS pt 
		ON po.vid_paym = pt.id
	JOIN dbo.SERVICES AS s 
		ON ps.service_id = s.id --AND s.is_peny = 1 -- !!! для расчёта пени
	WHERE ps.occ = @occ1
	AND p.fin_id >= @fin_id
	AND pd.day < @data1
	AND p.forwarded = cast(1 as bit)
	AND p.sup_id=0
	AND pt.peny_no = cast(0 as bit)

	IF @sum_pay IS NULL
		SET @sum_pay = 0

	IF EXISTS (SELECT 1
			FROM dbo.OCC_HISTORY 
			WHERE occ = @occ1
			AND fin_id < @fin_id)  --@fin_current 16/03/2015
		SELECT
			@res = COALESCE(SUM(p.saldo), 0)
			,@res_value = COALESCE(SUM(p.value), 0)
		FROM dbo.View_PAYM AS p 
		JOIN dbo.SERVICES AS s 
			ON p.service_id = s.id
			AND s.is_peny = 1 -- !!! для расчёта пени
		WHERE p.occ = @occ1
		AND p.fin_id = @fin_id
		AND (p.account_one = cast(0 as bit))
	ELSE
		SELECT
			@res = COALESCE(SUM(p.saldo), 0)
			,@res_value = COALESCE(SUM(p.value), 0)
		FROM dbo.View_PAYM AS p 
		JOIN dbo.SERVICES AS s 
			ON p.service_id = s.id
			AND s.is_peny = 1 -- !!! для расчёта пени
		WHERE p.occ = @occ1
		AND p.fin_id = @fin_current
		AND (p.account_one = cast(0 as bit))


	-- Если есть переплата на услугах на кот.пени не начисляется то прибавляем её
	SELECT
		@res2 = SUM(p.saldo)
	FROM dbo.View_PAYM AS p 
	JOIN dbo.SERVICES AS s 
		ON p.service_id = s.id
		AND s.is_peny = 0
	WHERE p.occ = @occ1
	AND p.fin_id = @fin_id
	AND p.saldo < 0
	AND (p.account_one = cast(0 as bit))

	SET @res = @res + COALESCE(@res2, 0)

	---- добавляем предыдущее начисление   24.09.13
	--IF @day=1 SET @res = @res + @res_value

	IF @res IS NULL
		SET @res = 0

	SET @res = @res - @sum_pay

	RETURN @res
END
go

