-- =============================================
-- Author:		Пузанов
-- Create date: 13/12/17
-- Description:	
-- =============================================
CREATE             PROCEDURE [dbo].[rep_dolg_occ_period]
	@P1				SMALLINT  -- 1-по всем услугам, 2- по единой, 3- по поставщику  из rep_vibor
	,@OCC			INT			= NULL
	,@fin_id1		SMALLINT
	,@fin_id2		SMALLINT
	,@sup_id		INT			= NULL
	,@PrintGroup	SMALLINT	= NULL
	,@debug			SMALLINT	= 0
AS
/*
для отчёта Задолженность по периодам
в Картотеке

exec [rep_dolg_occ_period] 1,40093,108,142,null,null
exec [rep_dolg_occ_period] 1,700002131,108,142,null,null
exec [rep_dolg_occ_period] 2,680004256,152,188,323,null,1
exec [rep_dolg_occ_period] 2,680002998,169,172,323,1
exec [rep_dolg_occ_period] 3,700103553,132,150,null,null
*/
BEGIN
	SET NOCOUNT ON;
	IF @OCC IS NULL
		AND @PrintGroup IS NULL
		SET @OCC = 0
	IF @OCC IS NOT NULL
		AND @PrintGroup IS NOT NULL
		SET @OCC = 0
	IF @P1 IS NULL
		OR @P1 NOT IN (1, 2, 3)
		SET @P1 = 1
	IF @fin_id1 IS NULL
		OR @fin_id2 IS NULL
		SELECT
			@fin_id1 = 0
			,@fin_id2 = 0

	IF @P1 = 2
		AND @sup_id IS NULL  -- нужно вернуть пустую выборку
		SET @OCC = 0

	DECLARE @t_occ TABLE
		(
			occ			INT				PRIMARY KEY
			,address	VARCHAR(60)		DEFAULT ''
			,KolMesDolg	DECIMAL(5, 1)	DEFAULT 0
			,Initials	VARCHAR(120)	DEFAULT ''
		)

	IF @PrintGroup IS NULL
	BEGIN
		;
		WITH cte_intprint
		AS
		(SELECT TOP 1
				occ
				,Initials
				,KolMesDolg
				,KolMesDolgAll
			FROM dbo.INTPRINT
			WHERE occ = @OCC
			AND fin_id <= @fin_id2
			ORDER BY fin_id DESC)
		INSERT
		INTO @t_occ
		(	occ
			,address
			,KolMesDolg
			,Initials)
				SELECT
					O.occ
					,O.address
					,CASE
						WHEN @P1 = 1 THEN i.KolMesDolgAll
						ELSE i.KolMesDolg
					END
					,i.Initials
				FROM dbo.OCCUPATIONS AS O 
				LEFT JOIN cte_intprint AS i 
					ON O.occ = i.occ
				WHERE O.occ = @OCC
	END
	ELSE
		INSERT
		INTO @t_occ
		(	occ
			,address
			,KolMesDolg
			,Initials)
				SELECT
					po.occ
					,O.address
					,CASE
						WHEN @P1 = 1 THEN i.KolMesDolgAll
						ELSE i.KolMesDolg
					END
					,i.Initials
				FROM dbo.PRINT_OCC AS po 
				JOIN dbo.OCCUPATIONS AS O 
					ON po.occ = O.occ
				LEFT JOIN dbo.INTPRINT AS i 
					ON O.occ = i.occ
					AND i.fin_id = @fin_id2 -- кол-во месяцев долга только в последнем периоде
				WHERE po.group_id = @PrintGroup
	--IF @debug=1 SELECT * FROM @t_occ

	CREATE TABLE #t
	(
		occ						INT
		,fin_id					SMALLINT
		,occ1					INT				DEFAULT NULL
		,fin_name				VARCHAR(15)		COLLATE database_default DEFAULT NULL
		,saldo					DECIMAL(9, 2)	DEFAULT 0
		,value					DECIMAL(9, 2)	DEFAULT 0
		--,Penalty_old_new		DECIMAL(9, 2)	DEFAULT 0
		--,Penalty_value			DECIMAL(9, 2)	DEFAULT 0
		--,Penalty_itog			DECIMAL(9, 2)	DEFAULT 0
		,added					DECIMAL(9, 2)	DEFAULT 0
		,paid					DECIMAL(9, 2)	DEFAULT 0
		,paymaccount			DECIMAL(9, 2)	DEFAULT 0
		,paymaccount_peny		DECIMAL(9, 2)	DEFAULT 0
		,paymaccount_serv		DECIMAL(9, 2)	DEFAULT 0
		,debt					DECIMAL(9, 2)	DEFAULT 0
		--,Whole_payment			DECIMAL(9, 2)	DEFAULT 0
		,YEAR					SMALLINT
		,[address]				VARCHAR(60)		COLLATE database_default DEFAULT ''
		,KolMesDolg				DECIMAL(5, 1)	DEFAULT 0
		--,total_sq				DECIMAL(10, 4)		DEFAULT 0
		,kol_people				SMALLINT		DEFAULT 0
		,Initials				VARCHAR(120)	COLLATE database_default DEFAULT ''
		,dolg_period			DECIMAL(9, 2)	DEFAULT 0
		,dolg_period_ostatok	DECIMAL(9, 2)	DEFAULT 0
	)

	-- по всем услугам
	IF @P1 = 1
	BEGIN
		INSERT
		INTO #t
				SELECT
					p.occ
					,p.fin_id
					,p.occ AS occ1
					,dbo.Fun_NameFinPeriodDate(p.start_date) AS 'fin_name' --'MMMM yyyy'
					,CAST(p.saldo + COALESCE(os.saldo, 0) AS DECIMAL(9, 2)) AS 'saldo'
					,CAST(p.value + COALESCE(os.value, 0) AS DECIMAL(9, 2)) AS 'value'
					--,CAST(p.Penalty_old_new + COALESCE(os.Penalty_old_new, 0) AS DECIMAL(9, 2)) AS 'Penalty_old_new'
					--,CAST(p.Penalty_value + COALESCE(os.Penalty_value, 0) AS DECIMAL(9, 2)) AS 'Penalty_value'
					--,CAST((p.Penalty_old_new + p.Penalty_value) + (COALESCE(os.Penalty_old_new, 0) + COALESCE(os.Penalty_value, 0)) AS DECIMAL(9, 2)) AS 'Penalty_itog'
					,CAST(p.added + COALESCE(os.added, 0) AS DECIMAL(9, 2)) AS 'added'
					,CAST(p.paid + COALESCE(os.paid, 0) AS DECIMAL(12, 2)) AS 'paid'
					,CAST(p.paymaccount + COALESCE(os.paymaccount, 0) AS DECIMAL(9, 2)) AS 'paymaccount'
					,CAST(p.paymaccount_peny + COALESCE(os.paymaccount_peny, 0) AS DECIMAL(9, 2)) AS 'paymaccount_peny'
					--,CAST(p.Paymaccount_serv + COALESCE(os.Paymaccount_serv, 0) AS DECIMAL(9, 2)) AS 'Paymaccount_serv'
					,CAST(LAG(p.Paymaccount_serv + COALESCE(os.Paymaccount_serv, 0)) OVER(PARTITION BY p.occ ORDER BY p.occ, p.fin_id DESC) AS DECIMAL(9, 2)) AS 'paymaccount_serv'
					,CAST(p.debt + COALESCE(os.debt, 0) AS DECIMAL(9, 2)) AS 'debt'
					,YEAR(p.start_date) AS 'YEAR'
					,t.address
					,t.KolMesDolg
					--,p.total_sq
					,p.kol_people
					,t.Initials
					,0 AS dolg_period
					,0 AS dolg_period_ostatok
				FROM @t_occ AS t
				JOIN dbo.View_OCC_ALL AS p 
					ON p.occ = t.occ
				LEFT JOIN (SELECT
						os1.fin_id
						,os1.occ
						,SUM(os1.saldo) AS saldo
						,SUM(os1.value) AS value
						,SUM(os1.added) AS added
						,SUM(os1.paid) AS paid
						--,SUM(os1.Penalty_old_new) AS Penalty_old_new
						--,SUM(os1.Penalty_value) AS Penalty_value
						,SUM(os1.paymaccount) AS paymaccount
						,SUM(os1.PaymAccount_peny) AS PaymAccount_peny
						,SUM(os1.paymaccount-os1.PaymAccount_peny) AS PaymAccount_serv
						--,LEAD(SUM(os1.paymaccount)-SUM(os1.paymaccount_peny)) OVER(PARTITION BY os1.occ ORDER BY os1.occ, os1.fin_id DESC) AS 'paymaccount_serv'
						,SUM(os1.debt) AS debt
					FROM @t_occ AS t1
					JOIN dbo.OCC_SUPPLIERS os1 
						ON os1.occ = t1.occ
						AND os1.fin_id BETWEEN @fin_id1 AND @fin_id2
					GROUP BY	os1.fin_id
								,os1.occ) AS os
					ON p.fin_id = os.fin_id
					AND p.occ = os.occ
				WHERE p.fin_id BETWEEN @fin_id1 AND @fin_id2
	--ORDER BY vba.street_name, vba.nom_dom_sort, p.nom_kvr_sort, p.occ
	--, p.fin_id DESC
	END

	-- По единой лицевому счёту
	IF @P1 = 2
	BEGIN
		INSERT
		INTO #t
				SELECT
					p.occ
					,p.fin_id
					,p.occ AS occ1
					,dbo.Fun_NameFinPeriodDate(p.start_date) AS 'fin_name' --'MMMM yyyy'
					,CAST(p.saldo AS DECIMAL(9, 2)) AS 'saldo'
					,CAST(p.value AS DECIMAL(9, 2)) AS 'value'
					--,CAST(p.Penalty_old_new AS DECIMAL(9, 2)) AS 'Penalty_old_new'
					--,CAST(p.Penalty_value AS DECIMAL(9, 2)) AS 'Penalty_value'
					--,CAST((p.Penalty_old_new + p.Penalty_value) AS DECIMAL(9, 2)) AS 'Penalty_itog'
					,CAST(p.added AS DECIMAL(9, 2)) AS 'added'
					,CAST(p.paid AS DECIMAL(12, 2)) AS 'paid'
					,CAST(p.paymaccount AS DECIMAL(9, 2)) AS 'paymaccount'
					,CAST(p.paymaccount_peny AS DECIMAL(9, 2)) AS 'paymaccount_peny'
					--,CAST(p.paymaccount_serv AS DECIMAL(9, 2)) AS 'paymaccount_serv'
					,CAST(LAG(p.paymaccount_serv) OVER(PARTITION BY p.occ ORDER BY p.occ, p.fin_id DESC) AS DECIMAL(9, 2)) AS 'paymaccount_serv'
					,CAST(p.debt AS DECIMAL(9, 2)) AS 'debt'
					,YEAR(p.start_date) AS 'Year'
					,t.address
					,t.KolMesDolg
					--,p.total_sq
					,p.kol_people
					,t.Initials
					,0 AS dolg_period
					,0 AS dolg_period_ostatok
				FROM dbo.View_OCC_ALL AS p 
				JOIN @t_occ AS t
					ON p.occ = t.occ
				WHERE p.fin_id BETWEEN @fin_id1 AND @fin_id2
	--ORDER BY vba.street_name, vba.nom_dom_sort, p.nom_kvr_sort, p.occ
	--, p.fin_id DESC
	END

	-- По поставщику
	IF @P1 = 3
	BEGIN

		UPDATE t
		SET KolMesDolg = p.KolMesDolg
		FROM @t_occ AS t
		JOIN dbo.OCC_SUPPLIERS AS p 
			ON p.occ = t.occ
		WHERE p.fin_id = @fin_id2
		AND p.sup_id = @sup_id

		INSERT
		INTO #t
				SELECT
					p.occ_sup AS occ
					,p.fin_id
					,p.occ AS occ1
					,dbo.Fun_NameFinPeriodDate(o.start_date) AS 'fin_name' --'MMMM yyyy'
					,CAST(p.saldo AS DECIMAL(9, 2)) AS 'saldo'
					,CAST(p.value AS DECIMAL(9, 2)) AS 'value'
					--,CAST(p.Penalty_old_new AS DECIMAL(9, 2)) AS 'Penalty_old_new'
					--,CAST(p.Penalty_value AS DECIMAL(9, 2)) AS 'Penalty_value'
					--,CAST((p.Penalty_old_new + p.Penalty_value) AS DECIMAL(9, 2)) AS 'Penalty_itog'
					,CAST(p.added AS DECIMAL(9, 2)) AS 'added'
					,CAST(p.paid AS DECIMAL(12, 2)) AS 'paid'
					,CAST(p.paymaccount AS DECIMAL(9, 2)) AS 'paymaccount'
					,CAST(p.paymaccount_peny AS DECIMAL(9, 2)) AS 'paymaccount_peny'
					--,CAST(p.paymaccount-p.paymaccount_peny AS DECIMAL(9, 2)) AS 'paymaccount_serv'
					,CAST(LAG(p.paymaccount-p.paymaccount_peny) OVER(PARTITION BY p.occ ORDER BY p.occ, p.fin_id DESC) AS DECIMAL(9, 2)) AS 'paymaccount_serv'
					,CAST(p.debt AS DECIMAL(9, 2)) AS 'debt'
					,YEAR(o.start_date) AS 'YEAR'
					,t.address
					,p.KolMesDolg
					--,o.total_sq
					,o.kol_people
					,t.Initials
					,0 AS dolg_period
					,0 AS dolg_period_ostatok
				FROM @t_occ AS t
				JOIN dbo.OCC_SUPPLIERS AS p 
					ON t.occ = p.occ
				JOIN dbo.View_OCC_ALL_LITE AS o 
					ON p.occ = o.occ
					AND p.fin_id = o.fin_id
				WHERE (p.sup_id = @sup_id
				OR @sup_id IS NULL)
				AND p.fin_id BETWEEN @fin_id1 AND @fin_id2
	--ORDER BY vba.street_name, vba.nom_dom_sort, o.nom_kvr_sort, o.occ
	--, p.fin_id DESC
	END

	IF @debug=1
	SELECT
		*
	FROM #t t
	ORDER BY t.occ, t.fin_id DESC

	DECLARE	@var1				INT
			,@paid				DECIMAL(9, 2)
			,@paymaccount		DECIMAL(9, 2)
			,@paymaccount_tmp	DECIMAL(9, 2)
			,@dolg_period		DECIMAL(9, 2)
			,@dolg_ostatok		DECIMAL(9, 2)
			,@fin_id_cur		SMALLINT
			,@dolg				DECIMAL(9, 2)

	DECLARE cur1 CURSOR LOCAL FOR
		SELECT DISTINCT
			t1.occ
		FROM #t t1
		ORDER BY t1.occ

	OPEN cur1

	FETCH NEXT FROM cur1 INTO @var1

	WHILE @@fetch_status = 0
	BEGIN
		-- долг по лицевому
		SELECT TOP 1
			@dolg = saldo, @fin_id_cur=fin_id
		FROM #t
		WHERE occ = @var1
		ORDER BY fin_id DESC

		UPDATE #t
			SET	paid=0
			WHERE occ = @var1
			AND fin_id = @fin_id_cur

		SELECT
			@dolg_period = 0, @dolg_ostatok=0

		DECLARE cur2 CURSOR LOCAL FOR
			SELECT
				t.fin_id
				,t.paid
				,COALESCE(t.paymaccount_serv,0)
			FROM #t t
			WHERE t.occ = @var1
			ORDER BY t.fin_id DESC

		OPEN cur2

		FETCH NEXT FROM cur2 INTO @fin_id_cur, @paid, @paymaccount

		WHILE @@fetch_status = 0
		BEGIN
			SELECT
				@dolg_period = @paid - @paymaccount
			SELECT
				@dolg = @dolg + @dolg_period

			UPDATE #t
			SET	dolg_period		= @dolg_period 
				,dolg_period_ostatok	= @dolg
			WHERE occ = @var1
			AND fin_id = @fin_id_cur

			FETCH NEXT FROM cur2 INTO @fin_id_cur, @paid, @paymaccount

		END

		CLOSE cur2
		DEALLOCATE cur2


		FETCH NEXT FROM cur1 INTO @var1

	END

	CLOSE cur1
	DEALLOCATE cur1

	SELECT
		*
	FROM #t t
	ORDER BY t.occ, t.fin_id DESC

END
go

