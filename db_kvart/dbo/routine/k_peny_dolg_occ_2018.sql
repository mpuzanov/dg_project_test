-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE             PROCEDURE [dbo].[k_peny_dolg_occ_2018]
(
	  @occ INT
	, @sup_id INT = 0
	, @fin_current SMALLINT = NULL
	, @date_current SMALLDATETIME = NULL
	, @dolg DECIMAL(15, 2) = 0 OUTPUT
	, @dolg_all DECIMAL(15, 2) = 0 OUTPUT
	, @debug BIT = 0
	, @LastDay SMALLINT = 10
)
AS
/*

exec k_peny_dolg_occ_2018 @occ=680000014,@sup_id=323,@debug=1
exec k_peny_dolg_occ_2018 @occ=680000014,@sup_id=345,@debug=1
exec k_peny_dolg_occ_2018 @occ=335336,@sup_id=0,@debug=1
exec k_peny_dolg_occ_2018 @occ=321342,@sup_id=365,@debug=1

exec k_peny_dolg_occ_2018 @occ=700009304,@sup_id=0,@debug=1


*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @mes DECIMAL(5, 1) = 0
		  , @dolg_ost DECIMAL(15, 2) = 0
		  , @paid DECIMAL(15, 2) = 0
		  , @saldo DECIMAL(15, 2) = 0
		  , @sum_pay DECIMAL(15, 2) = 0
		  , @sum_pay_current DECIMAL(15, 2) = 0
		  , @paymaccount DECIMAL(15, 2) = 0
		  , @paymaccount_tmp DECIMAL(15, 2) = 0
		  , @fin_id SMALLINT
		  , @fin_pred SMALLINT
		  , @fin_start SMALLINT
		  , @start_date SMALLDATETIME
		  , @end_date SMALLDATETIME
		  , @Last_fin_id SMALLINT
		  , @tip_id SMALLINT
		  , @DB_NAME VARCHAR(20) = UPPER(DB_NAME())

	IF @LastDay IS NULL
		SET @LastDay = 10

	IF @fin_current IS NULL
		SELECT @fin_current = b.fin_current
			 , @start_date = gv.start_date
			 , @end_date = gv.end_date
			 , @tip_id = o.tip_id
		FROM dbo.Occupations AS o 
			JOIN dbo.Flats AS f ON o.flat_id=f.id
			JOIN dbo.Buildings AS b ON f.bldn_id=b.id
			JOIN dbo.Global_values gv ON b.fin_current = gv.fin_id
		WHERE o.occ = @occ
	ELSE
		SELECT @start_date = gv.start_date
			 , @end_date = gv.end_date
			 , @tip_id = o.tip_id
		FROM dbo.Occupations AS o 
			JOIN dbo.Global_values gv ON o.fin_id = gv.fin_id
		WHERE o.occ = @occ
			AND gv.fin_id = @fin_current

	SELECT @fin_start = @fin_current - 5
		 , @fin_pred = @fin_current - 1

	IF @date_current IS NULL
		SET @date_current = dbo.Fun_GetOnlyDate(current_timestamp)
	IF @date_current > @end_date
		SET @date_current = @end_date
	IF @sup_id IS NULL
		SET @sup_id = 0

	IF @debug = 1
		SELECT @fin_current AS fin_current, @fin_start AS fin_start, @fin_pred as fin_pred, @start_date, @end_date, @tip_id

	DECLARE @t TABLE (
		  fin_id SMALLINT
		, fin_str VARCHAR(30) DEFAULT ''
		, end_date SMALLDATETIME
		, saldo DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, debt DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paid DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paymaccount DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, penalty_old DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, dolg DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, dolg_ost DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, date_current SMALLDATETIME DEFAULT current_timestamp
		, kolday AS CASE
			  WHEN date_current > end_date THEN DATEDIFF(DAY, end_date, date_current)
			  ELSE 0
		  END
		, kolday_dolg SMALLINT DEFAULT 0
		, id INT IDENTITY (1, 1)
	--,unique( fin_id, end_date, date_current )
	)


	DECLARE @t_fin TABLE (
		  fin_id SMALLINT
		, fin_str VARCHAR(30) DEFAULT ''
		, end_date SMALLDATETIME
		, debt DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paid DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paymaccount DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, dolg DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, date_current SMALLDATETIME DEFAULT current_timestamp
		, kolday AS CASE
			  WHEN date_current > end_date THEN DATEDIFF(DAY, end_date, date_current)
			  ELSE 0
		  END
		, kolday_dolg SMALLINT DEFAULT 0
		, id INT IDENTITY (1, 1)
		, UNIQUE (fin_id, end_date, date_current)
	)

	IF @sup_id <> 0
		INSERT INTO @t (fin_id
					  , end_date
					  , saldo
					  , debt
					  , paid
					  , paymaccount
					  , penalty_old)
		SELECT ph.fin_id
			 , @end_date
			 , SUM(ph.saldo)
			 , SUM(ph.debt)
			 , SUM(ph.paid)
			 , 0 AS paymaccount
			 , SUM(COALESCE(penalty_old, 0))
		FROM dbo.Paym_history ph 
		WHERE 
			ph.occ = @occ
			AND ph.sup_id = @sup_id
			AND ph.fin_id BETWEEN @fin_start AND @fin_current
			--AND ph2.is_peny = 1 -- !!! для расчёта пени
		GROUP BY ph.fin_id
		ORDER BY ph.fin_id DESC
		OPTION (RECOMPILE)
	ELSE
	BEGIN
		INSERT INTO @t (fin_id
					  , end_date
					  , saldo
					  , debt
					  , paid
					  , paymaccount
					  , penalty_old)
		SELECT ph.fin_id
			 , @end_date
			 , SUM(ph.saldo)
			 , SUM(ph.debt)
			 , SUM(ph.paid)
			 , 0 AS paymaccount
			 , SUM(COALESCE(penalty_old, 0))
		FROM dbo.Paym_history AS ph 
		WHERE 
			ph.occ = @occ
			AND ph.fin_id BETWEEN @fin_start AND @fin_current
			AND ph.sup_id = 0
		GROUP BY ph.fin_id
		ORDER BY ph.fin_id DESC
		OPTION (RECOMPILE)
	END

	--IF @DB_NAME LIKE '%KR1%'
	--	AND @tip_id = 1  -- ук Сити ИВЦ
	--BEGIN
	--	IF @debug = 1
	--		PRINT 'ivc_peny'

	--	UPDATE t
	--	SET saldo = t2.saldo
	--	  , debt = t2.debt
	--	  , paid = t2.paid  
	--	FROM @t AS t
	--		JOIN ivc_peny AS t2 ON t2.occ = @occ
	--			AND t.fin_id = t2.fin_id
	--			AND t2.sup_id = @sup_id

	--	UPDATE t
	--	SET debt = t2.saldo
	--	  , saldo = t2.saldo - t.paid
	--	FROM @t AS t
	--	   , @t AS t2
	--	WHERE t.fin_id = 229
	--		AND t2.fin_id = 230

	--	UPDATE t
	--	SET debt = t2.saldo
	--	  , saldo = t2.saldo - t.paid
	--	FROM @t AS t
	--	   , @t AS t2
	--	WHERE t.fin_id = 228
	--		AND t2.fin_id = 229

	--	UPDATE t
	--	SET debt = t2.saldo
	--	  , saldo = t2.saldo - t.paid
	--	FROM @t AS t
	--	   , @t AS t2
	--	WHERE t.fin_id = 227
	--		AND t2.fin_id = 228

	--	DELETE FROM @t
	--	WHERE fin_id <= @fin_start

	--	IF @debug = 1
	--		SELECT *
	--		FROM @t
	--END

	IF NOT EXISTS (SELECT * FROM @t)
	BEGIN
		IF @debug = 1
			PRINT 'Первый месяц расчётов, берём за долг сальдо текущего месяца'
		IF @sup_id = 0
			SELECT @dolg = o.saldo
				 , @dolg_all = o.saldo
			FROM dbo.View_occ_all_lite o
			WHERE o.occ = @occ
				AND o.fin_id = @fin_current
		ELSE
			INSERT INTO @t (fin_id
						  , end_date
						  , saldo
						  , debt
						  , paid
						  , paymaccount)
			SELECT ph.fin_id - 1
				 , @end_date
				 , ph.saldo
				 , ph.saldo
				 , ph.paid
				 , 0 AS paymaccount
			FROM dbo.Occ_Suppliers ph 
			WHERE ph.occ = @occ
				AND ph.sup_id = @sup_id
				AND ph.fin_id = @fin_current
			OPTION (RECOMPILE)

	END

	UPDATE t
	SET end_date =
				  CASE
					  WHEN @LastDay >= 31 THEN dbo.fn_end_month(dateadd(month, 1, gv.end_date)) -- берём последний день следующего месяца
					  ELSE DATEADD(DAY, @LastDay, gv.end_date)
				  END
		--,end_date	 = gv.end_date + @LastDay
	  , date_current = @date_current
	  , fin_str = gv.StrMes
	FROM @t AS t
		JOIN Global_values gv ON 
			t.fin_id = gv.fin_id

	-- берём оплату до начала периода
	SELECT
		--@sum_pay = SUM(ps.Value - ps.PaymAccount_peny) 
		@sum_pay = SUM(ps.value) -- - COALESCE(ps.paymaccount_peny, 0)) -- закоментировал 28.06.16
	FROM dbo.Paying_serv AS ps 
		JOIN dbo.Payings AS p ON 
			ps.paying_id = p.id
		JOIN dbo.Paydoc_packs AS pd ON 
			p.pack_id = pd.id
		JOIN dbo.Services AS s ON 
			ps.service_id = s.id
		--AND s.is_peny = 1 -- !!! для расчёта пени		
		JOIN dbo.Paycoll_orgs AS po ON 
			pd.fin_id = po.fin_id
			AND pd.source_id = po.id
		JOIN dbo.Paying_types AS pt ON 
			po.vid_paym = pt.id
	WHERE 
		p.occ = @occ
		AND p.fin_id >= @fin_current
		AND pd.day <= @start_date
		AND p.forwarded = cast(1 as bit)
		AND p.sup_id = @sup_id
		AND pt.peny_no = cast(0 as bit)
	--OPTION (RECOMPILE)
	
	--**************************************************************************
	SELECT TOP 1 @Last_fin_id = fin_id
	FROM @t
	--WHERE dolg_ost>0
	ORDER BY fin_id --DESC
	IF @Last_fin_id IS NULL
		SET @Last_fin_id = @fin_current

	IF @sum_pay IS NULL
		SET @sum_pay = 0

	SELECT @dolg = debt + CASE
                              WHEN penalty_old < 0 THEN penalty_old
                              ELSE 0
        END -- 27.05.2021
		 , @dolg_all = debt + CASE
                                  WHEN penalty_old < 0 THEN penalty_old
                                  ELSE 0
        END -- 27.05.2021
	FROM @t
	WHERE fin_id = @fin_pred

	IF @dolg IS NULL
		SET @dolg = 0

	SET @sum_pay_current = 0
	SELECT @sum_pay_current = COALESCE(paymaccount, 0)
	FROM @t
	WHERE fin_id = @fin_current - 1

	IF @debug = 1
		PRINT CONCAT('Долг: ', @dolg, ', Оплата по ', CONVERT(VARCHAR(10), @start_date, 104),': ', @sum_pay, ', Тек.оплата: ', @sum_pay_current)

	IF @debug = 1
		SELECT '@t 1' AS '@t'
			 , *
		FROM @t

	IF @fin_current <= 190	   -- 28.11.17
		SELECT @dolg = @dolg - @sum_pay
			 , @dolg_all = @dolg_all - @sum_pay

	--SELECT
	--	@dolg_ost = @dolg - @sum_pay_current
	SELECT @dolg_ost = @dolg - @sum_pay


	--IF @debug = 1
	--	SELECT
	--		'@t 2' AS '@t'
	--	   ,*
	--	FROM @t

	DECLARE curs_1 CURSOR LOCAL FOR
		SELECT fin_id
			 , paid
			 , paymaccount
		FROM @t
		WHERE fin_id < @fin_current
		ORDER BY fin_id DESC
	OPEN curs_1
	FETCH NEXT FROM curs_1 INTO @fin_id, @paid, @paymaccount

	WHILE (@@fetch_status = 0)
	BEGIN

		UPDATE @t
		SET dolg = @paid
		  , dolg_ost = @dolg_ost
		  , debt = @dolg_ost
		WHERE fin_id = @fin_id

		IF @debug = 1
			--PRINT STR(@fin_id) + ' @dolg_ost=' + STR(@dolg_ost, 9, 2) + ' @paid=' + STR(@paid, 9, 2)
			PRINT CONCAT('Период: ',@fin_id,' (',dbo.Fun_NameFinPeriod(@fin_id),'), @dolg_ost=',STR(@dolg_ost, 9, 2),', @paid=',STR(@paid, 9, 2))
			
		--IF (@dolg_ost - @paid - @paymaccount) <= 0
		IF @dolg_ost <= 0
		BEGIN
			IF @debug = 1
				PRINT 'Выходим ' + STR(@dolg_ost, 9, 2)

			SET @Last_fin_id = @fin_id

			DELETE FROM @t
			WHERE fin_id <= @fin_id
			BREAK
		END

		IF @Last_fin_id < @fin_id
			SET @dolg_ost = @dolg_ost - @paid

		FETCH NEXT FROM curs_1 INTO @fin_id, @paid, @paymaccount
	END

	CLOSE curs_1
	DEALLOCATE curs_1

	-- оплату до текущего периода закидываем в начальный период (чтобы уменьшить возможное пени)
	--;
	--WITH cte
	--AS
	--(SELECT TOP 1
	--		fin_id
	--	   ,paymaccount
	--	FROM @t
	--	WHERE fin_id < @fin_current
	--	ORDER BY fin_id)
	--UPDATE cte
	--SET paymaccount = @sum_pay

	--SELECT
	--	@dolg_ost = SUM(dolg)
	--FROM @t

	IF @debug = 1
		PRINT '@Last_fin_id=' + STR(@Last_fin_id)

	UPDATE @t
	SET dolg = @dolg_ost
	WHERE fin_id = @Last_fin_id

	--IF @dolg_ost >= 0
	--BEGIN
	--	IF @debug = 1
	--		PRINT '@dolg_ost >= 0   @dolg_ost=' + STR(@dolg_ost, 9, 2) + ' @dolg=' + STR(@dolg, 9, 2) + ' @fin_id=' + STR(@fin_id, 3)
	--	UPDATE t
	--	--SET dolg = dolg + (@dolg - @sum_pay_current - @dolg_ost) 
	--	SET dolg = dolg + (@dolg - paymaccount - @dolg_ost)
	--	--,fin_str=fin_str+' и ранее'
	--	FROM @t AS t
	--	WHERE t.fin_id = @fin_id
	--END
	-- оплату до текущего периода закидываем в начальный период (чтобы уменьшить возможное пени)

	IF @debug = 1
		SELECT '@t 3' AS '@t'
			 , *
		FROM @t

LABEL_END:

	IF @dolg IS NULL
		SET @dolg = 0
	IF @dolg_all IS NULL
		SET @dolg_all = 0

	IF @debug = 1
		PRINT CONCAT('Долг пени: ', @dolg, ' Общая сумма долга: ', @dolg_all)

	UPDATE t
	SET kolday_dolg = kolday
	FROM @t AS t

	INSERT INTO @t_fin (fin_id
					  , fin_str
					  , end_date
					  , debt
					  , paid
					  , paymaccount
					  , dolg
					  , date_current
					  , kolday_dolg)
	SELECT fin_id
		 , fin_str
		 , end_date
		 , debt
		 , paid
		 , paymaccount
		 , dolg
		 , date_current
		 , kolday_dolg
	FROM @t

	DECLARE @fin1 INT
		  , @id INT
		  , @dat1 SMALLDATETIME
		  , @dat_temp SMALLDATETIME

	DECLARE cur CURSOR LOCAL FOR
		SELECT fin_id
			 , end_date
			 , id
		FROM @t_fin
		WHERE kolday BETWEEN 30 AND 121
			AND dolg > 0

	OPEN cur

	FETCH NEXT FROM cur INTO @fin1, @dat1, @id

	WHILE @@fetch_status = 0
	BEGIN
		IF @debug = 1
			PRINT STR(@fin1) + ' ' + CONVERT(VARCHAR(10), @start_date, 104) + ' ' + CONVERT(VARCHAR(10), @end_date, 104) + ' ' + STR(@id)

		SET @dat_temp = DATEADD(MONTH, 1, @dat1)

		IF @dat_temp BETWEEN @start_date AND @end_date
		BEGIN
			IF @debug = 1
				PRINT CONVERT(VARCHAR(10), @dat_temp, 104)

			INSERT INTO @t (fin_id
						  , end_date
						  , fin_str
						  , debt
						  , paid
						  , paymaccount
						  , dolg
						  , date_current
						  , kolday_dolg)
			SELECT fin_id
				 , end_date
				 , fin_str
				 , debt
				 , paid
				 , paymaccount
				 , dolg
				 , @dat_temp --date_current
				 , 30
			FROM @t_fin
			WHERE fin_id = @fin1
			INSERT INTO @t (fin_id
						  , end_date
						  , fin_str
						  , debt
						  , paid
						  , paymaccount
						  , dolg
						  , date_current
						  , kolday_dolg)
			SELECT fin_id
				 , @dat_temp
				 , fin_str
				 , debt
				 , paid
				 , paymaccount
				 , dolg
				 , date_current
				 , 31
			FROM @t_fin
			WHERE fin_id = @fin1

			DELETE FROM @t
			WHERE id = @id
		END

		SET @dat_temp = DATEADD(MONTH, 3, @dat1)
		IF @dat_temp BETWEEN @start_date AND @end_date
		BEGIN
			IF @debug = 1
				PRINT CONVERT(VARCHAR(10), @dat_temp, 104)

			INSERT INTO @t (fin_id
						  , end_date
						  , fin_str
						  , debt
						  , paid
						  , paymaccount
						  , dolg
						  , date_current
						  , kolday_dolg)
			SELECT fin_id
				 , end_date
				 , fin_str
				 , debt
				 , paid
				 , paymaccount
				 , dolg
				 , @dat_temp
				 , 90
			FROM @t_fin
			WHERE fin_id = @fin1

			INSERT INTO @t (fin_id
						  , end_date
						  , fin_str
						  , debt
						  , paid
						  , paymaccount
						  , dolg
						  , date_current
						  , kolday_dolg)
			SELECT fin_id
				 , @dat_temp
				 , fin_str
				 , debt
				 , paid
				 , paymaccount
				 , dolg
				 , date_current
				 , 91
			FROM @t_fin
			WHERE fin_id = @fin1

			DELETE FROM @t
			WHERE id = @id
		END

		FETCH NEXT FROM cur INTO @fin1, @dat1, @id

	END

	CLOSE cur
	DEALLOCATE cur


	SELECT fin_id
		 , end_date
		 , fin_str
		 , debt
		 , paid
		 , paymaccount
		 , CASE
			   WHEN dolg < 0 THEN 0
			   WHEN dolg > debt THEN debt
			   ELSE dolg
		   END AS dolg
		 , date_current
		   --,kolday
		 , kolday_dolg
		 , id
	FROM @t
	WHERE kolday > 0
	ORDER BY fin_id DESC

END
go

