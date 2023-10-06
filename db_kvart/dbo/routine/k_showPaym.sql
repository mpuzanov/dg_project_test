CREATE   PROCEDURE [dbo].[k_showPaym]
(
	  @occ1 INT
	, @s1 SMALLINT = 1
	, @debug BIT = 0

/*
если @s1=1 выдавать все
если @s1=2 выдавать без итогов      -- убрал 24.09.09
если @s1=3 выдавать только итоги

k_showPaym 910010129  680000038
k_showPaym 910010016, 1, 1
k_showPaym 177029
*/
)
AS
	SET NOCOUNT ON
	DECLARE @fin_current SMALLINT
		  , @sup_id INT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	DECLARE @t TABLE (
		  short_name VARCHAR(20)
		, service_no SMALLINT
		, occ INT
		, service_id VARCHAR(10)
		, sup_id INT
		, subsid_only BIT
		, account_one BIT
		, is_counter TINYINT
		, kol DECIMAL(15, 6) DEFAULT NULL
		, tarif DECIMAL(10, 4)
		, koef DECIMAL(10, 4) DEFAULT NULL
		, saldo DECIMAL(15, 4)
		, socvalue DECIMAL(15, 4)
		, value DECIMAL(15, 4)
		, added DECIMAL(15, 4)
		, paid DECIMAL(15, 4)
		, paymaccount DECIMAL(15, 4)
		, paymaccount_peny DECIMAL(15, 4)
		, debt DECIMAL(15, 4)
		, short_id VARCHAR(6)
		, metod VARCHAR(12) DEFAULT NULL
		, kol_norma DECIMAL(10, 4) DEFAULT NULL
		, kol_counter SMALLINT DEFAULT NULL
		, penalty_prev DECIMAL(15, 4)
		, penalty_old DECIMAL(15, 4)
		, penalty_serv DECIMAL(15, 4)
		, penalty_itog DECIMAL(15, 4)
		, avg_vday DECIMAL(10, 4) DEFAULT NULL
		, unit_id VARCHAR(10) DEFAULT NULL
		, date_start DATE DEFAULT NULL
		, date_end DATE DEFAULT NULL
		, kol_added DECIMAL(15, 6) DEFAULT NULL
		, debt_peny DECIMAL(15, 6) DEFAULT NULL
		, koef_day DECIMAL(9, 4) DEFAULT NULL
	    , comments VARCHAR(100) DEFAULT NULL
	)

	DECLARE @t2 TABLE (
		  short_name VARCHAR(20)
		, service_no SMALLINT
		, occ INT
		, service_id VARCHAR(10)
		, subsid_only BIT
		, account_one BIT
		, is_counter TINYINT
		, kol DECIMAL(15, 6) DEFAULT NULL
		, tarif DECIMAL(10, 4)
		, koef DECIMAL(10, 4) DEFAULT NULL
		, saldo DECIMAL(15, 4)
		, socvalue DECIMAL(15, 4)
		, value DECIMAL(15, 4)
		, added DECIMAL(15, 4)
		, paid DECIMAL(15, 4)
		, paymaccount DECIMAL(15, 4)
		, paymaccount_peny DECIMAL(15, 4)
		, debt DECIMAL(15, 4)
		, short_id VARCHAR(6)
		, metod VARCHAR(12) DEFAULT NULL
		, kol_norma DECIMAL(10, 4) DEFAULT NULL
		, kol_counter SMALLINT DEFAULT NULL
		, penalty_prev DECIMAL(15, 4)
		, penalty_old DECIMAL(15, 4)
		, penalty_serv DECIMAL(15, 4)
		, penalty_itog DECIMAL(15, 4)
		, avg_vday DECIMAL(10, 4) DEFAULT NULL
		, unit_id VARCHAR(10) DEFAULT NULL
		, date_start DATE DEFAULT NULL
		, date_end DATE DEFAULT NULL
		, kol_added DECIMAL(15, 6) DEFAULT NULL
		, debt_peny DECIMAL(15, 6) DEFAULT NULL
		, koef_day DECIMAL(9, 4) DEFAULT NULL
	    , comments VARCHAR(100) DEFAULT NULL
	)

	INSERT INTO @t (short_name
				  , service_no
				  , occ
				  , service_id
				  , sup_id
				  , subsid_only
				  , account_one
				  , is_counter
				  , kol
				  , tarif
				  , koef
				  , saldo
				  , socvalue
				  , value
				  , added
				  , paid
				  , paymaccount
				  , paymaccount_peny
				  , debt
				  , short_id
				  , metod
				  , kol_norma
				  , kol_counter
				  , penalty_prev
				  , penalty_old
				  , penalty_serv
				  , penalty_itog
				  , avg_vday
				  , unit_id
				  , date_start
				  , date_end
				  , kol_added
				  , debt_peny
				  , koef_day)
	SELECT s.short_name
		 , ROW_NUMBER() OVER (ORDER BY s.short_name)                    AS service_no  --s.sort_no
		 , COALESCE(p.occ_sup_paym, p.occ)                              AS occ
		 , p.service_id
		 , p.sup_id
		 , p.subsid_only
		 , p.account_one
		 , NULLIF(p.is_counter, 0)                                      AS is_counter
		 , CASE
               WHEN p.kol = 0 THEN NULL
               ELSE ROUND(p.kol, COALESCE(u.precision, 4))
        END AS kol
		 , NULLIF(p.tarif, 0)                                           AS tarif
		 , CASE
               WHEN p.koef = 0 OR p.koef = 1 THEN NULL
               ELSE p.koef
        END AS koef
		 , NULLIF(p.saldo, 0)                                           AS saldo
		 , 0                                                            AS socvalue
		 , NULLIF(p.VALUE, 0) AS VALUE
		 , NULLIF(p.added, 0) AS added
		 , NULLIF(p.paid, 0) AS paid
		 , NULLIF(p.paymaccount, 0) AS paymaccount
		 , NULLIF(p.paymaccount_peny, 0) AS paymaccount_peny
		 , p.debt
		 , u.short_id
		 --, CASE
			--   WHEN p.metod = 0 THEN 'не начислять'
			--   WHEN p.metod = 2 THEN 'по среднему'
			--   WHEN p.metod = 3 THEN 'по счетчику'
			--   WHEN p.metod = 4 THEN 'по домовому'
			--   WHEN p.is_counter > 0 THEN 'по норме'
		 --  END AS metod
		 , dbo.Fun_GetMetodText(p.metod) AS metod
		 , kol_norma
		 , t_count.FCount                 AS kol_counter
		 , NULLIF(p.penalty_prev,0) AS penalty_prev
		 , NULLIF(p.penalty_old,0)  AS penalty_old
		 , NULLIF(p.penalty_serv,0) AS penalty_serv
		 , NULLIF(p.penalty_old + p.penalty_serv,0) AS penalty_itog
		 , pca.avg_vday
		 , p.unit_id
		 , date_start
		 , date_end
		 , kol_added
		 , p.debt + p.penalty_old + p.penalty_serv
		 , p.koef_day
	FROM dbo.Paym_list AS p 
		JOIN dbo.View_services AS s  ON p.service_id = s.id
		LEFT JOIN dbo.Units AS u  ON p.unit_id = u.id
		LEFT JOIN (
			SELECT CL1.service_id
				 , COUNT(*) AS FCount
			FROM dbo.Counter_list_all AS CL1 
			JOIN dbo.Counters as c ON CL1.counter_id = c.id
			WHERE CL1.occ = @occ1
				AND CL1.fin_id = @fin_current
			    AND c.date_del is NULL
			GROUP BY CL1.service_id
		) AS t_count ON t_count.service_id = p.service_id
		LEFT JOIN dbo.Paym_counter_all AS pca ON p.fin_id = pca.fin_id
			AND p.occ = pca.occ
			AND p.service_id = pca.service_id
	WHERE p.occ = @occ1
	    AND p.fin_id = @fin_current
		AND (p.saldo <> 0 OR p.VALUE <> 0 OR p.added <> 0 OR p.paid <> 0 OR p.paymaccount <> 0 OR p.paymaccount_peny <> 0 
		OR p.penalty_serv <> 0 OR p.penalty_old <> 0  OR p.penalty_prev <> 0 OR p.tarif <> 0 OR p.kol <> 0 
		OR (p.mode_id % 1000 <> 0 AND p.source_id % 1000 <> 0)
		)

    -- Изменим даты начала и окончания
    UPDATE s
	SET date_start = dt.date_ras_start
		,date_end   = dt.date_ras_end
        ,comments = dt.comments
	FROM @t AS s
		CROSS APPLY dbo.Fun_GetOccDataStartEnd(@occ1, @fin_current, 0) AS dt
	WHERE s.service_id=dt.service_id
    
	IF @debug = 1
		SELECT *
		FROM @t

	UPDATE @t
	SET account_one = 0
	WHERE occ = @occ1

	DECLARE @var1 INT
		  , @account_one BIT
		  , @count_occ SMALLINT = 0;

	DECLARE cursor_name CURSOR LOCAL FOR
		SELECT DISTINCT occ
					  , account_one
					  , sup_id
		FROM @t
		ORDER BY sup_id
			   , account_one

	OPEN cursor_name;

	FETCH NEXT FROM cursor_name INTO @var1, @account_one, @sup_id;

	WHILE @@fetch_status = 0
	BEGIN
		SET @count_occ = @count_occ + 1

		IF @debug = 1
			PRINT @var1

		INSERT INTO @t2
		SELECT short_name
			 , service_no
			 , occ
			 , service_id
			 , subsid_only
			 , account_one
			 , is_counter
			 , kol
			 , tarif
			 , koef
			 , saldo
			 , socvalue
			 , value
			 , added
			 , paid
			 , paymaccount
			 , paymaccount_peny
			 , debt
			 , short_id
			 , metod
			 , kol_norma
			 , kol_counter
			 , penalty_prev
			 , penalty_old
			 , penalty_serv
			 , CASE
                   WHEN penalty_itog = 0 THEN NULL
                   ELSE penalty_itog
            END AS penalty_itog
			 , avg_vday
			 , unit_id
			 , date_start
			 , date_end
			 , kol_added
			 , debt_peny
			 , koef_day
		     , comments
		FROM @t
		WHERE occ = @var1
			AND sup_id = @sup_id
		UNION ALL
		SELECT N'Итого по ' + LTRIM(STR(@var1)) + ':'
			 , 200
			 , NULL
			 , NULL
			 , NULL
			 , NULL
			 , NULL
			 , NULL
			 , NULL
			 , NULL
			 , SUM(COALESCE(saldo, 0))
			 , SUM(COALESCE(socvalue, 0))
			 , SUM(COALESCE(value, 0))
			 , SUM(COALESCE(added, 0))
			 , SUM(COALESCE(paid, 0))
			 , SUM(COALESCE(paymaccount, 0))
			 , SUM(COALESCE(paymaccount_peny, 0))
			 , SUM(debt)
			 , NULL
			 , NULL
			 , NULL
			 , SUM(COALESCE(kol_counter, 0))
			 , SUM(COALESCE(penalty_prev, 0))
			 , SUM(COALESCE(penalty_old, 0))
			 , SUM(COALESCE(penalty_serv, 0))
			 , SUM(COALESCE(penalty_itog, 0))
			 , NULL
			 , NULL
			 , NULL
			 , NULL
			 , NULL
			 , SUM(COALESCE(debt_peny, 0))
			 , NULL
		     , NULL
		FROM @t
		WHERE occ = @var1
			AND sup_id = @sup_id
		ORDER BY service_no

		FETCH NEXT FROM cursor_name INTO @var1, @account_one, @sup_id;

	END

	CLOSE cursor_name;
	DEALLOCATE cursor_name;

	INSERT INTO @t2
	SELECT N'Всего:'
		 , 999
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , SUM(COALESCE(saldo, 0))
		 , SUM(COALESCE(socvalue, 0))
		 , SUM(COALESCE(value, 0))
		 , SUM(COALESCE(added, 0))
		 , SUM(COALESCE(paid, 0))
		 , SUM(COALESCE(paymaccount, 0))
		 , SUM(COALESCE(paymaccount_peny, 0))
		 , SUM(debt)
		 , NULL
		 , NULL
		 , NULL
		 , SUM(COALESCE(kol_counter, 0))
		 , SUM(COALESCE(penalty_prev, 0))
		 , SUM(COALESCE(penalty_old, 0))
		 , SUM(COALESCE(penalty_serv, 0))
		 , SUM(COALESCE(penalty_itog, 0))
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , NULL
		 , SUM(COALESCE(debt_peny, 0))
		 , NULL
	     , NULL
	FROM @t


	IF @count_occ = 0
		DELETE FROM @t2
		WHERE service_no <= 200

	IF @count_occ = 1
		DELETE FROM @t2
		WHERE service_no > 200

	SELECT *
	FROM @t2
go

