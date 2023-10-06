CREATE   PROCEDURE [dbo].[rep_dolg0]
(
	@str		SMALLINT	= 1 --если @str=1 то отчет "плательщики без задолжности"
	--иначе отчет "авансовые платежи"
	,@div_id1	SMALLINT	= NULL -- код района
	,@jeu1		SMALLINT	= NULL -- код участка
	,@build_id1	INT			= NULL --код дома
	,@fin_id1	SMALLINT	= NULL --нижний  ограничитель дат 
	,@fin_id2	SMALLINT	= NULL --верхний ограничитель дат 
	,@bank_id	SMALLINT	= NULL --код банка
	,@is_bank	SMALLINT	= NULL --код типа учереждения 1-банки 0-организации
	,@tip_id	SMALLINT	= NULL --код тип жил. фонда
	,@sup_id	INT			= NULL --по всем поставщикам
)
AS
	/*
	Список должников с разными выборками


	exec [rep_dolg0] @str=1,@tip_id=28,@sup_id=0
	exec [rep_dolg0] @str=1,@tip_id=28,@sup_id=NULL
	exec [rep_dolg0] @str=1,@tip_id=28,@sup_id=345
	exec [rep_dolg0] @str=2,@tip_id=28,@sup_id=345
	*/

	SET NOCOUNT ON


	IF @fin_id2 IS NULL
		SET @fin_id2 = dbo.Fun_GetFinCurrent(@tip_id, @build_id1, NULL, NULL)
	IF @fin_id1 IS NULL
		OR @fin_id1 > @fin_id2
		SET @fin_id1 = @fin_id2

	--SET @fin_id1 = @fin_id1 + 1 --нижний ограничитель дат (+1 т.к. оплата за месяц происходит 
	----в следующем месяце)

	--SET @fin_id2 = @fin_id2 + 1 --верхний ограничитель дат

	DECLARE @kol_fin SMALLINT -- кол-во фин.периодов
	SET @kol_fin = @fin_id2 - @fin_id1 + 1

	--PRINT @fin_id1
	--PRINT @fin_id2
	--PRINT @kol_fin

	IF @str = 1 --отчет плательщики без задолжности
	BEGIN

		CREATE TABLE #t1
		(
			occ		INT
			,counts	SMALLINT
			,paid DECIMAL(9,2) DEFAULT 0
			,dolg DECIMAL(9,2) DEFAULT 0			
		)


		IF @sup_id = 0
			INSERT
			INTO #t1
					SELECT
						oh.occ
						,COUNT(oh.occ) AS counts
						,SUM(CASE WHEN oh.fin_id=@fin_id2 THEN oh.paid ELSE 0 END) as paid
						,SUM(CASE WHEN oh.fin_id=@fin_id2 THEN (oh.saldo - oh.PaymAccount_serv) ELSE 0 END) AS dolg
					FROM dbo.View_OCC_ALL AS oh 
					JOIN dbo.BUILDINGS AS b	ON 
						oh.bldn_id = b.id
					WHERE 
						oh.fin_id BETWEEN @fin_id1 AND @fin_id2
						AND oh.saldo - oh.PaymAccount_serv <= 0
						AND oh.bldn_id = COALESCE(@build_id1, oh.bldn_id) -- отбор по коду дома
						AND b.div_id = COALESCE(@div_id1, b.div_id) -- отбор по коду района
						AND oh.jeu = COALESCE(@jeu1, oh.jeu)
						AND oh.tip_id = COALESCE(@tip_id, oh.tip_id)
						AND oh.status_id <> 'закр'
					GROUP BY oh.occ
					HAVING COUNT(oh.occ) = @kol_fin

		IF @sup_id IS NULL
			INSERT
			INTO #t1
					SELECT
						oh.occ
						,COUNT(oh.occ)
						,SUM(CASE WHEN oh.fin_id=@fin_id2 THEN oh.PaidAll ELSE 0 END) as paid
						,SUM(CASE WHEN oh.fin_id=@fin_id2 THEN (oh.SaldoAll - oh.Paymaccount_ServAll) ELSE 0 END) AS dolg
					FROM dbo.View_OCC_ALL AS oh 
					JOIN dbo.BUILDINGS AS b ON 
						oh.bldn_id = b.id
					WHERE 
						oh.fin_id BETWEEN @fin_id1 AND @fin_id2
						AND oh.SaldoAll - oh.Paymaccount_ServAll <= 0
						AND oh.bldn_id = COALESCE(@build_id1, oh.bldn_id) -- отбор по коду дома
						AND b.div_id = COALESCE(@div_id1, b.div_id) -- отбор по коду района
						AND oh.jeu = COALESCE(@jeu1, oh.jeu)
						AND oh.tip_id = COALESCE(@tip_id, oh.tip_id)
						AND oh.status_id <> 'закр'
					GROUP BY oh.occ
					HAVING COUNT(oh.occ) = @kol_fin

			IF @sup_id>0
			INSERT
			INTO #t1
					SELECT
						oh.occ
						,COUNT(oh.occ)
						,SUM(CASE WHEN oh.fin_id=@fin_id2 THEN oh.Paid ELSE 0 END) as paid
						,SUM(CASE WHEN oh.fin_id=@fin_id2 THEN (oh.Saldo - (oh.paymaccount-oh.paymaccount_peny)) ELSE 0 END) AS dolg
					FROM dbo.Occ_Suppliers AS oh 
					JOIN dbo.Occupations o ON 
						oh.occ = o.Occ
					JOIN dbo.FLATS f ON 
						o.flat_id = f.id
					JOIN dbo.BUILDINGS AS b ON 
						f.bldn_id = b.id
					WHERE 
						oh.fin_id BETWEEN @fin_id1 AND @fin_id2
						AND oh.sup_id=@sup_id
						AND (oh.Saldo - (oh.paymaccount-oh.paymaccount_peny)) <= 0
						AND f.bldn_id = COALESCE(@build_id1,f.bldn_id) -- отбор по коду дома
						AND b.div_id = COALESCE(@div_id1, b.div_id) -- отбор по коду района
						AND b.sector_id = COALESCE(@jeu1, b.sector_id)
						AND o.tip_id = COALESCE(@tip_id, o.tip_id)
						AND o.status_id <> 'закр'
					GROUP BY oh.occ
					HAVING COUNT(oh.occ) = @kol_fin


			SELECT
				o.occ
				,t.paid --= o.PaidAll
				,t.dolg  --= (o.SaldoAll - o.Paymaccount_ServAll)
				,Initials = dbo.Fun_Initials(o.occ)
				,STREETS = s.name
				,b.nom_dom
				,o.nom_kvr
				,b.div_id
				,sector_id
				,o.proptype_id
				,kol_people = o.kol_people
				,occ_sup = 
				CASE 
				WHEN @sup_id=0 THEN ''
				ELSE (SELECT	[dbo].[Fun_GetOccSupStr](o.occ, @fin_id2,@sup_id))
				END
			FROM dbo.VOCC AS o 
			JOIN dbo.BUILDINGS AS b 
				ON o.bldn_id = b.id
			JOIN dbo.VSTREETS AS s 
				ON b.street_id = s.id
			JOIN #t1 AS t
				ON o.occ = t.occ

			ORDER BY s.name,
			b.nom_dom_sort,
			o.nom_kvr_sort
	END

	ELSE
	--***********************************************************************
	BEGIN

		CREATE TABLE #t2
		(
			occ		INT
			,counts	SMALLINT
			,paid	DECIMAL(9, 2)
			,dolg	DECIMAL(9, 2)
		)

		IF @bank_id IS NULL --2 --авансовые платежи без ограничений по банкам
		BEGIN
			IF @sup_id = 0
				INSERT
				INTO #t2
						SELECT
							oh.occ
							,COUNT(oh.occ)
							,oh2.paid
							,(oh2.saldo - oh2.paymaccount)
						FROM	dbo.View_OCC_ALL AS oh 
								,dbo.View_OCC_ALL AS oh2 
						WHERE oh.fin_id BETWEEN @fin_id1 AND @fin_id2
						AND oh.saldo - oh.paymaccount < 0
						AND oh.occ = oh2.occ
						AND oh2.fin_id = @fin_id2
						AND oh.tip_id = COALESCE(@tip_id, oh.tip_id)

						GROUP BY	oh.occ
									,oh2.paid
									,oh2.saldo
									,oh2.paymaccount
						HAVING COUNT(oh.occ) = @kol_fin

			IF @sup_id IS NULL
				INSERT
				INTO #t2
						SELECT
							oh.occ
							,COUNT(oh.occ)
							,oh2.PaidAll
							,(oh2.SaldoAll - oh2.Paymaccount_ServAll)
						FROM	dbo.View_OCC_ALL AS oh 
								,dbo.View_OCC_ALL AS oh2 
						WHERE oh.fin_id BETWEEN @fin_id1 AND @fin_id2
						AND oh.SaldoAll - oh.Paymaccount_ServAll < 0
						AND oh.occ = oh2.occ
						AND oh2.fin_id = @fin_id2
						AND oh.tip_id = COALESCE(@tip_id, oh.tip_id)
						GROUP BY	oh.occ
									,oh2.PaidAll
									,oh2.SaldoAll
									,oh2.Paymaccount_ServAll
						HAVING COUNT(oh.occ) = @kol_fin

			IF @sup_id > 0
			BEGIN
				INSERT
				INTO #t2
						SELECT
							oh.occ
							,COUNT(oh.occ)
							,oh2.paid
							,(oh2.saldo - oh2.paymaccount)
						FROM dbo.OCC_SUPPLIERS AS oh 
						JOIN dbo.OCC_SUPPLIERS AS oh2 ON oh.occ = oh2.occ AND oh.sup_id = oh2.sup_id
						JOIN dbo.OCC_HISTORY oh1 ON oh.fin_id = oh1.fin_id AND oh.occ = oh1.occ
						AND oh.sup_id = oh2.sup_id
						WHERE oh.fin_id BETWEEN @fin_id1 AND @fin_id2
						AND (oh.saldo - oh.paymaccount < 0)
						AND oh2.fin_id = @fin_id2
						AND oh.sup_id=@sup_id
						AND oh1.tip_id = COALESCE(@tip_id, oh1.tip_id)
						GROUP BY	oh.occ
									,oh2.paid
									,oh2.saldo
									,oh2.paymaccount
						HAVING COUNT(oh.occ) = @kol_fin
						--SELECT * FROM #t2 t
				END
		END

		ELSE --авансовые платежи с ограничениями по банкам

		BEGIN
			INSERT
			INTO #t2
					SELECT
						oh.occ
						,COUNT(oh.occ)
						,(oh2.saldo - oh2.paymaccount)
					FROM	dbo.VOCC_HISTORY AS oh 
							,dbo.VOCC_HISTORY AS oh2 
							,dbo.FLATS AS f 
							,dbo.BUILDINGS_HISTORY AS b 
					WHERE 
						oh.fin_id BETWEEN @fin_id1 AND @fin_id2
						AND oh.saldo - oh.paymaccount < 0
						AND EXISTS (SELECT
								1
							FROM dbo.PAYINGS AS p
								,dbo.PAYDOC_PACKS AS pp 
								,dbo.BANK AS bk 
								,dbo.PAYCOLL_ORGS AS po 
						WHERE p.PACK_ID = pp.id
						AND p.occ = oh.occ
						AND pp.fin_id BETWEEN @fin_id1 AND @fin_id2
						AND pp.source_id = po.id
						AND po.BANK = bk.id
						AND bk.id = COALESCE(@bank_id, bk.id)
						AND bk.is_bank = COALESCE(@is_bank, bk.is_bank))
					AND oh.occ = oh2.occ
					AND oh2.fin_id = @fin_id2
					AND oh.tip_id = COALESCE(@tip_id, oh.tip_id)
					AND oh.flat_id = f.id
					AND f.bldn_id = b.bldn_id
					AND b.fin_id = oh.fin_id
					AND f.bldn_id = COALESCE(@build_id1, f.bldn_id) -- отбор по коду дома
					AND b.div_id = COALESCE(@div_id1, b.div_id) -- отбор по коду района
					AND oh.jeu = COALESCE(@jeu1, oh.jeu)

					GROUP BY	oh.occ
								,oh2.saldo
								,oh2.paymaccount
					HAVING COUNT(oh.occ) = @kol_fin

		END

		SELECT
			o.occ
			,#t2.paid as paid
			,#t2.dolg as dolg
			,Initials = dbo.Fun_Initials(o.occ)
			,STREETS = s.name
			,b.nom_dom
			,o.nom_kvr
			,b.div_id
			,sector_id
			,o.proptype_id
			,o.kol_people as kol_people
			,occ_sup = (SELECT [dbo].[Fun_GetOccSupStr](o.occ, @fin_id2,@sup_id))
		FROM dbo.VOCC AS o 
		JOIN dbo.BUILDINGS AS b  ON o.bldn_id = b.id
		JOIN dbo.VSTREETS AS s ON b.street_id = s.id 
		JOIN #t2 ON o.occ = #t2.occ
		WHERE 
			o.status_id <> 'закр'
			AND o.bldn_id = COALESCE(@build_id1, o.bldn_id) -- отбор по коду дома
			AND b.div_id = COALESCE(@div_id1, b.div_id) -- отбор по коду района
			AND o.jeu = COALESCE(@jeu1, o.jeu)

		ORDER BY s.name,
			b.nom_dom_sort,
			o.nom_kvr_sort

	END
go

