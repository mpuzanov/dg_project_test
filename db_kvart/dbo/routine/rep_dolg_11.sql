CREATE   PROCEDURE [dbo].[rep_dolg_11]
(
	  @div_id1 SMALLINT = NULL -- код района
	, @jeu1 SMALLINT = NULL -- код участка
	, @build_id1 INT = NULL -- код дома
	, @kol_mes1 SMALLINT = 3 -- кол.месяцев долга
	, @dolg1 DECIMAL(9, 2) = NULL -- сумма долга
	, @proptype_id1 VARCHAR(10) = NULL -- тип квартиры
	, @service_id1 VARCHAR(10) = NULL -- услуга
	, @tip_id SMALLINT = NULL -- Тип жилого фонда
	, @kol_mes2 INT = NULL
	, @fin_id1 SMALLINT = NULL
	, @sup_id INT = NULL
	, @town_id SMALLINT = NULL
	, @all_serv BIT = 0
	, @socnaim BIT = NULL
	, @PrintGroup SMALLINT = NULL
)
AS
	/*
		
	Список должников с разными выборками
		
	rep_dolg_11 @tip_id=1,@sup_id=345,@fin_id1=238,@all_serv=1,@kol_mes1=1
	rep_dolg_11 @tip_id=1,@fin_id1=241,@all_serv=1,@kol_mes1=3
	rep_dolg_11 @tip_id=28,@fin_id1=170,@all_serv=0,@kol_mes1=1
	rep_dolg_11 @tip_id=57,@fin_id1=175,@build_id1=4208,@all_serv=1,@kol_mes1=1,@kol_mes2=999999
	
	дата создания: 27.03.2004
	автор: Пузанов М.А.
	
	дата последней модификации:  28.06.07
	коррекировка выборки сумм по субсидиям
	
	дата последней модификации:  20.02.09
	убрал выборку по банкам
	добавил тип жил.фонда
	
	дата последней модификации:  18.09.09
	дата последней модификации:  14.04.2010
	дата последней модификации:  19.07.2011   сделал через VIEW
	
	Отчет: rep_dolg_11.fr3
	*/

	SET NOCOUNT ON


	IF @all_serv IS NULL
		SET @all_serv = 0
	IF @socnaim = 0
		SET @socnaim = NULL

	DECLARE @fin_current SMALLINT
		  , @start_date SMALLDATETIME
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build_id1, NULL, NULL)

	SELECT @start_date = start_date
	FROM dbo.Global_values 
	WHERE fin_id = @fin_current

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current

	IF @dolg1 IS NULL
		SET @dolg1 = 0

	IF @div_id1 < 0
		SET @div_id1 = NULL

	IF @kol_mes1 IS NULL
		SET @kol_mes1 = 0

	IF @kol_mes2 IS NULL
		OR @kol_mes2 > 9999
		SET @kol_mes2 = 9999

	IF @sup_id > 0
		AND @all_serv = 0
	BEGIN
		EXEC [dbo].[rep_dolg_sup] @div_id1
								, @jeu1
								, @build_id1
								, @kol_mes1
								, @dolg1
								, @proptype_id1
								, @service_id1
								, @tip_id
								, @kol_mes2
								, @fin_id1
								, @sup_id
								, @town_id
								, @PrintGroup
		PRINT 'sup'
		RETURN
	END
	PRINT 'occ'



	-- По всем услугам
	IF @service_id1 IS NULL
		AND @all_serv = 0
	BEGIN
		PRINT 'по всем услугам. @all_serv = 0'
		--INSERT
		--INTO @t
		SELECT TOP 50000 o.occ
					   , o.KolMesDolg AS kol_mes
					   , (o.saldo - o.Paymaccount_serv) AS dolg
					   , 'Все услуги' AS service_id
					   , o.saldo
					   , o.Paid
					   , o.Paymaccount_serv AS Paymaccount
					   , dbo.Fun_Initials(o.occ) AS Initials
					   , b.street_name AS STREETS
					   , b.nom_dom
					   , o.nom_kvr
					   , b.div_id AS div_id
					   , b.div_name AS div_name
					   , b.sector_id AS sector_id
					   , b.sector_name AS sector_name
					   , o.proptype_id
					   , dbo.Fun_GetKolPeopleOccStatus(o.occ) AS kol_people
					   , CASE
							 WHEN o.Discount > 0 THEN 'да'
							 ELSE '-'
						 END AS lgotas
					   , '' AS lgota_name
					   , '-' AS subsides
					   , NULL AS telephon
					   , o.Total_sq
					   , mes.KolMesCal2 AS KolMesCal
					   , mes.LastPeriodValue
					   , pay.Value AS last_paym_value
					   , pay.day AS last_paym_day
					   , o.Penalty_old + COALESCE(os.Penalty_old,0) AS penalty_itog   --Penalty_itog  17.03.2022
					   , COUNT(o.occ) OVER (PARTITION BY b.street_name, b.nom_dom_sort) AS KolOccInBuild
					   , COUNT(o.occ) OVER (PARTITION BY b.street_name, b.nom_dom_sort, o.nom_kvr) AS KolOccInFlats
					   , (DATEDIFF(MONTH, pay.day, current_timestamp)) AS kolmes_paym
					   , o.tip_id
					   , b.build_id
					   , b.nom_dom_sort
					   , o.nom_kvr_sort
		FROM dbo.View_occ_all AS o
			JOIN dbo.View_build_all AS b  ON o.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
			LEFT JOIN dbo.Occ_Suppliers AS os  ON o.occ=os.occ and o.fin_id=os.fin_id
				and (os.sup_id=@sup_id OR @sup_id is NULL)
			OUTER APPLY (
				SELECT TOP (1) p.[Value]
						   , pd.day
				FROM dbo.Payings AS p 
					JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
				WHERE o.occ = p.occ
					AND service_id IS NULL
				ORDER BY pd.day DESC
			) AS pay
			OUTER APPLY (
				SELECT TOP (1) KolMesCal2 = DATEDIFF(MONTH, oh.start_date, @start_date)
						,oh.start_date AS LastPeriodValue
				FROM dbo.View_occ_all_lite AS oh 
				WHERE oh.fin_id <= @fin_current
					AND oh.Value > 0
					AND oh.occ = o.occ
				ORDER BY oh.fin_id DESC
			) AS mes
		WHERE o.status_id <> 'закр'
			AND o.fin_id = @fin_id1
			AND (o.Total_sq > 0)
			--OR o.PaidAll <> 0)         -- 06/07/2015
			AND o.fin_id = @fin_id1
			AND (b.bldn_id = @build_id1 OR @build_id1 IS NULL) -- отбор по коду дома
			AND (b.div_id = @div_id1 OR @div_id1 IS NULL) -- отбор по коду района
			AND (b.sector_id = @jeu1 OR @jeu1 IS NULL) -- отбор по коду участку
			AND (o.saldo - o.Paymaccount_serv) >= @dolg1 -- отбор по сумме долга	 -- 14/04/2010		-- добавил = 23.11.17
			AND (o.KolMesDolg >= @kol_mes1 AND o.KolMesDolg < @kol_mes2) -- отбор по кол.месяцев долга
			AND (b.tip_id = @tip_id OR @tip_id IS NULL)
			AND (o.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL) -- отбор по типу квартиры
			AND (b.town_id = @town_id OR @town_id IS NULL)
			AND (o.socnaim = @socnaim OR @socnaim IS NULL)
			AND (@PrintGroup IS NULL OR EXISTS (
				SELECT 1
				FROM dbo.Print_occ AS po 
				WHERE po.occ = o.occ
					AND po.group_id = @PrintGroup
			))
		ORDER BY b.street_name
			   , b.nom_dom_sort
			   , o.nom_kvr_sort
	END
	ELSE
	IF @service_id1 IS NULL
		AND @all_serv = 1
	BEGIN
		PRINT 'по всем услугам. @all_serv = 1'
		--INSERT INTO @t
		SELECT TOP 50000 o.occ
					   , i.KolMesDolgAll AS kol_mes
					   , (o.SaldoAll - o.Paymaccount_ServAll) AS dolg
					   , COALESCE(@service_id1, 'Все услуги') AS service_id
					   , o.SaldoAll AS saldo
					   , o.PaidAll AS paid
					   , o.Paymaccount_ServAll AS Paymaccount
					   , dbo.Fun_Initials(o.occ) AS Initials
					   , b.street_name AS STREETS
					   , b.nom_dom
					   , o.nom_kvr
					   , b.div_id AS div_id
					   , b.div_name AS div_name
					   , b.sector_id AS sector_id
					   , b.sector_name AS sector_name
					   , o.proptype_id
					   , dbo.Fun_GetKolPeopleOccStatus(o.occ) AS kol_people
					   , '' AS lgotas
					   , '' AS lgota_name
					   , '' AS subsides
					   , 0 AS telephon
					   , o.Total_sq
					   , mes.KolMesCal2 AS KolMesCal
					   , mes.LastPeriodValue
					   , pay.Value AS last_paym_value
					   , pay.day AS last_paym_day
					   , o.Penalty_old + COALESCE(os.Penalty_old,0)  AS penalty_itog   --Penalty_itog  17.03.2022
					   , COUNT(o.occ) OVER (PARTITION BY b.street_name, b.nom_dom) AS KolOccInBuild
					   , COUNT(o.occ) OVER (PARTITION BY b.street_name, b.nom_dom_sort, o.nom_kvr) AS KolOccInFlats
					   , (DATEDIFF(MONTH, pay.day, current_timestamp)) AS kolmes_paym
					   , o.tip_id
					   , b.build_id
					   , b.nom_dom_sort
					   , o.nom_kvr_sort
		FROM dbo.View_occ_all AS o 
			JOIN dbo.View_build_all AS b  ON o.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
			JOIN dbo.Intprint AS i ON i.occ = o.occ
				AND o.fin_id = i.fin_id
			LEFT JOIN dbo.Occ_Suppliers AS os ON o.occ=os.occ and o.fin_id=os.fin_id
				and (os.sup_id=@sup_id OR @sup_id is NULL)
			OUTER APPLY (
				SELECT TOP (1) p.[Value]
							 , pd.day
				FROM dbo.Payings AS p 
					JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
				WHERE o.occ = p.occ
					AND service_id IS NULL
				ORDER BY pd.day DESC
			) AS pay
			OUTER APPLY (
				SELECT TOP 1 KolMesCal2 = DATEDIFF(MONTH, oh.start_date, @start_date)
					,oh.start_date AS LastPeriodValue
				FROM dbo.View_occ_all_lite AS oh 
				WHERE oh.fin_id <= @fin_current
					AND oh.PaidAll > 0
					AND oh.occ = o.occ
				ORDER BY oh.fin_id DESC
			) AS mes
		WHERE o.status_id <> 'закр'
			AND o.fin_id = @fin_id1
			AND (o.Total_sq > 0)
			--AND o.PaidAll <> 0)         -- 06/07/2015
			AND i.fin_id = @fin_id1
			AND (o.bldn_id = @build_id1 OR @build_id1 IS NULL) -- отбор по коду дома
			AND (b.div_id = @div_id1 OR @div_id1 IS NULL) -- отбор по коду района
			AND (b.sector_id = @jeu1 OR @jeu1 IS NULL) -- отбор по коду участку
			AND (i.KolMesDolgAll >= @kol_mes1 AND i.KolMesDolgAll < @kol_mes2) -- отбор по кол.месяцев долга
			AND (b.tip_id = @tip_id OR @tip_id IS NULL)
			AND (o.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL) -- отбор по типу квартиры
			AND (b.town_id = @town_id OR @town_id IS NULL)
			AND (o.socnaim = @socnaim OR @socnaim IS NULL)
			AND (o.SaldoAll - o.Paymaccount_ServAll) > @dolg1 -- отбор по сумме долга
			AND (@PrintGroup IS NULL OR EXISTS (
				SELECT 1
				FROM dbo.Print_occ AS po 
				WHERE po.occ = o.occ
					AND po.group_id = @PrintGroup
			))
		ORDER BY b.street_name
			   , b.nom_dom_sort
			   , o.nom_kvr_sort
	END
	ELSE
	BEGIN
		PRINT 'по одной заданной услуге: ' + @service_id1 + ' ' + STR(@tip_id)
		--INSERT
		--INTO @t
		SELECT TOP 50000 pl.occ
					   , o.KolMesDolg AS kol_mes
					   , SUM((pl.saldo - pl.Paymaccount_serv)) AS dolg
					   , COALESCE(@service_id1, 'Все услуги') AS service_id
					   , SUM(pl.saldo) AS saldo
					   , SUM(pl.paid) AS paid
					   , SUM(pl.Paymaccount_serv) AS Paymaccount
					   , dbo.Fun_Initials(pl.occ) AS Initials
					   , s.name AS STREETS
					   , b.nom_dom
					   , o.nom_kvr
					   , b.div_id AS div_id
					   , b.div_name AS div_name
					   , b.sector_id AS sector_id
					   , b.sector_name AS sector_name
					   , o.proptype_id
					   , dbo.Fun_GetKolPeopleOccStatus(pl.occ) AS kol_people
					   , '' AS lgotas
					   , '' AS lgota_name
					   , '' AS subsides
					   , 0 AS telephon
					   , o.Total_sq
					   , 0 AS KolMesCal
					   , 0 AS last_paym_value
					   , NULL AS last_paym_day
					   , 0 AS penalty_itog
					   , COUNT(*) OVER (PARTITION BY s.name, b.nom_dom_sort) AS KolOccInBuild
					   , COUNT(*) OVER (PARTITION BY s.name, b.nom_dom_sort, o.nom_kvr) AS KolOccInFlats
					   , 0 AS kolmes_paym 
					   , MAX(o.tip_id) AS tip_id
					   , MAX(b.build_id) AS build_id
					   , MAX(b.nom_dom_sort) AS nom_dom_sort
					   , MAX(o.nom_kvr_sort) AS nom_kvr_sort
		FROM dbo.View_occ_all AS o 
			JOIN dbo.View_paym AS pl  ON pl.occ = o.occ
				AND o.fin_id = pl.fin_id
			JOIN dbo.View_build_all AS b ON o.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
			JOIN dbo.VStreets AS s ON s.id = b.street_id
		WHERE o.status_id <> 'закр'
			AND o.fin_id = @fin_id1
			AND (o.Total_sq > 0 AND o.PaidAll <> 0)         -- 06/07/2015
			AND pl.service_id = COALESCE(@service_id1, pl.service_id)
			AND o.fin_id = @fin_id1
			AND (o.bldn_id = @build_id1 OR @build_id1 IS NULL) -- отбор по коду дома
			AND (b.div_id = @div_id1 OR @div_id1 IS NULL) -- отбор по коду района
			AND (b.sector_id = @jeu1 OR @jeu1 IS NULL) -- отбор по коду участку
			AND (o.KolMesDolg >= @kol_mes1 AND o.KolMesDolg < @kol_mes2) -- отбор по кол.месяцев долга
			AND (b.tip_id = @tip_id OR @tip_id IS NULL)
			AND (o.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL) -- отбор по типу квартиры
			AND (b.town_id = @town_id OR @town_id IS NULL)
			AND (o.socnaim = @socnaim OR @socnaim IS NULL)
			AND (@PrintGroup IS NULL OR EXISTS (
				SELECT 1
				FROM dbo.Print_occ AS po 
				WHERE po.occ = o.occ
					AND po.group_id = @PrintGroup
			))
		GROUP BY pl.occ
			   , o.KolMesDolg
			   , s.name
			   , b.nom_dom
			   , b.nom_dom_sort
			   , o.nom_kvr
			   , o.nom_kvr_sort
			   , b.div_id
			   , b.div_name
			   , b.sector_id
			   , b.sector_name
			   , o.proptype_id
			   , o.Total_sq
		HAVING SUM(pl.saldo - pl.Paymaccount_serv) > @dolg1 -- отбор по сумме долга 
		ORDER BY s.name
			   , b.nom_dom_sort
			   , o.nom_kvr_sort

	END
go

