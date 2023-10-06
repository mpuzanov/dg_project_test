-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[k_peny_dolg_occ_2018_test]
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

exec k_peny_dolg_occ_2016 @occ=680000014,@sup_id=323,@debug=1
exec k_peny_dolg_occ_2016 @occ=680000014,@sup_id=345,@debug=1
exec k_peny_dolg_occ_2016 @occ=335336,@sup_id=0,@debug=1
exec k_peny_dolg_occ_2016 @occ=321342,@sup_id=365,@debug=1

exec k_peny_dolg_occ_2018_test @occ=700009304,@sup_id=0,@debug=1


*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @dolg_ost DECIMAL(15, 2) = 0
		  , @paid DECIMAL(15, 2) = 0
		  , @saldo DECIMAL(15, 2) = 0
		  , @sum_pay DECIMAL(15, 2) = 0
		  , @sum_pay_current DECIMAL(15, 2) = 0
		  , @paymaccount DECIMAL(15, 2) = 0
		  , @paymaccount_tmp DECIMAL(15, 2) = 0
		  , @fin_id SMALLINT
		  , @fin_pred SMALLINT
		  , @start_date SMALLDATETIME
		  , @end_date SMALLDATETIME
		  , @Last_fin_id SMALLINT


	IF @LastDay IS NULL
		SET @LastDay = 10

	IF @fin_current IS NULL
		SELECT @fin_current = gv.fin_id
			 , @start_date = gv.start_date
			 , @end_date = gv.end_date
		FROM dbo.Occupations AS o 
			JOIN dbo.Global_values gv ON o.fin_id = gv.fin_id
		WHERE o.Occ = @occ
	ELSE
		SELECT @start_date = gv.start_date
			 , @end_date = gv.end_date
		FROM dbo.Occupations AS o 
			JOIN dbo.Global_values gv ON o.fin_id = gv.fin_id
		WHERE o.Occ = @occ
			AND gv.fin_id = @fin_current

	SET @fin_pred = @fin_current - 5

	IF @date_current IS NULL
		SET @date_current = dbo.Fun_GetOnlyDate(current_timestamp)
	IF @date_current > @end_date
		SET @date_current = @end_date
	IF @sup_id IS NULL
		SET @sup_id = 0

	DECLARE @t TABLE (
		  fin_id SMALLINT
		, end_date SMALLDATETIME
		, fin_str VARCHAR(30) DEFAULT ''
		, debt DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paid DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, paymaccount DECIMAL(15, 2) DEFAULT 0 NOT NULL
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
		, end_date SMALLDATETIME
		, fin_str VARCHAR(30) DEFAULT ''
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
					  , debt
					  , paid
					  , dolg)
		SELECT ph.fin_id
			 , @end_date
			 , SUM(ph.debt)
			 , SUM(ph.paid)
			 , 0 AS paymaccount
		FROM dbo.Paym_history ph 
		WHERE ph.Occ = @occ
			--AND ph2.is_peny = 1 -- !!! для расчёта пени
			AND ph.sup_id = @sup_id
			AND ph.fin_id BETWEEN @fin_pred AND @fin_current
		GROUP BY ph.fin_id
		ORDER BY ph.fin_id DESC
		OPTION (RECOMPILE)
	ELSE
	BEGIN
		INSERT INTO @t (fin_id
					  , end_date
					  , debt
					  , paid
					  , paymaccount)
		SELECT ph.fin_id
			 , @end_date
			 , SUM(ph.debt)
			 , SUM(ph.paid)
			 , 0 AS PaymAccount
		FROM dbo.Paym_history AS ph 
		--JOIN dbo.SERVICES AS s
		--	ON ph.service_id = s.id
		--AND s.is_peny = 1 -- !!! для расчёта пени
		WHERE ph.Occ = @occ
			AND ph.sup_id = 0
			AND ph.fin_id BETWEEN @fin_pred AND @fin_current
		GROUP BY ph.fin_id
		ORDER BY ph.fin_id DESC
		OPTION (RECOMPILE)
	END
	--GOTO LABEL_END

	UPDATE t
	SET end_date = gv.end_date + @LastDay
	  , date_current = @date_current
	  , fin_str = gv.StrMes
	FROM @t AS t
		JOIN Global_values gv ON t.fin_id = gv.fin_id

	-- берём оплату до начала периода
	SELECT
		--@sum_pay = SUM(ps.Value - ps.PaymAccount_peny) 
		@sum_pay = SUM(ps.Value) -- - COALESCE(ps.paymaccount_peny, 0)) -- закоментировал 28.06.16
	FROM dbo.Paying_serv AS ps 
		JOIN dbo.Payings AS p ON ps.paying_id = p.id
		JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
		JOIN dbo.Services AS s ON ps.service_id = s.id
		--AND s.is_peny = 1 -- !!! для расчёта пени		
		JOIN dbo.Paycoll_orgs AS po ON pd.fin_id = po.fin_id
			AND pd.source_id = po.id
		JOIN dbo.Paying_types AS pt ON po.vid_paym = pt.id
	WHERE p.Occ = @occ
		AND p.fin_id >= @fin_current
		AND pd.day < @start_date
		AND p.forwarded = 1
		AND p.sup_id = @sup_id
		AND pt.peny_no = 0
	--OPTION (RECOMPILE)

	SELECT TOP 1 @Last_fin_id = fin_id
	FROM @t
	--WHERE dolg_ost>0
	ORDER BY fin_id --DESC
	IF @Last_fin_id IS NULL
		SET @Last_fin_id = @fin_current

	--**************************************************************************

	IF @sum_pay IS NULL
		SET @sum_pay = 0

	SELECT @dolg = debt
		 , @dolg_all = debt
		 , @paid = paid
	FROM @t
	WHERE fin_id = @fin_current - 1

	IF @dolg IS NULL
		SET @dolg = 0

	--SET @sum_pay=3000

	IF @debug = 1
		PRINT 'Долг: ' + STR(@dolg, 9, 2) + ', Оплата до начала периода: ' + STR(@sum_pay, 9, 2) + ' @Last_fin_id: ' + STR(@Last_fin_id)
	IF @debug = 1
		SELECT '@t' AS '@t'
			 , *
		FROM @t

	SELECT @dolg = @dolg - @sum_pay
		 , @dolg_all = @dolg_all - @sum_pay

	SELECT @dolg_ost = @dolg


	DECLARE curs_1 CURSOR LOCAL FOR
		SELECT fin_id
			 , paid
		FROM @t
		WHERE fin_id < @fin_current
		ORDER BY fin_id DESC
	OPEN curs_1
	FETCH NEXT FROM curs_1 INTO @fin_id, @paid

	WHILE (@@fetch_status = 0)
	BEGIN

		UPDATE @t
		SET dolg = @paid
		  , dolg_ost = @dolg_ost
		  , debt = @dolg_ost
		WHERE fin_id = @fin_id

		IF @debug = 1
			PRINT STR(@fin_id) + ' ' + STR(@dolg_ost, 9, 2) + ' ' + STR(@paid, 9, 2)

		--IF (@dolg_ost - @paid - @paymaccount) <= 0
		IF @dolg_ost <= 0
		BEGIN
			IF @debug = 1
				PRINT 'Выходим ' + STR(@dolg_ost, 9, 2)

			SET @Last_fin_id = @fin_id

			DELETE FROM @t
			WHERE fin_id < @fin_id
			BREAK
		END

		IF @Last_fin_id < @fin_id
			SET @dolg_ost = @dolg_ost - @paid

		FETCH NEXT FROM curs_1 INTO @fin_id, @paid
	END

	CLOSE curs_1
	DEALLOCATE curs_1


	UPDATE @t
	SET dolg = @dolg_ost
	WHERE fin_id = @Last_fin_id

	IF @debug = 1
		SELECT '@t 2' AS '@t'
			 , *
		FROM @t


LABEL_END:

	IF @dolg IS NULL
		SET @dolg = 0
	IF @dolg_all IS NULL
		SET @dolg_all = 0

	IF @debug = 1
		PRINT 'Долг пени: ' + STR(@dolg, 9, 2) + ' Общая сумма долга: ' + STR(@dolg_all, 9, 2)

	UPDATE t
	SET kolday_dolg = kolday
	FROM @t AS t

	INSERT INTO @t_fin (fin_id
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
			PRINT STR(@fin1) + ' ' + CONVERT(VARCHAR(20), @start_date, 104) + ' ' + CONVERT(VARCHAR(15), @end_date, 104) + ' ' + STR(@id)

		SET @dat_temp = DATEADD(MONTH, 1, @dat1)

		IF @dat_temp BETWEEN @start_date AND @end_date
		BEGIN
			IF @debug = 1
				PRINT CONVERT(VARCHAR(20), @dat_temp, 104)
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
				PRINT CONVERT(VARCHAR(20), @dat_temp, 104)
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

