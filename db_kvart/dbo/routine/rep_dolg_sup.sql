CREATE   PROCEDURE [dbo].[rep_dolg_sup]
(
	  @div_id1 SMALLINT = NULL -- код района
	, @jeu1 SMALLINT = NULL -- код участка
	, @build_id1 INT = NULL -- код дома
	, @kol_mes1 SMALLINT = 3 -- кол.месяцев долга
	, @dolg1 DECIMAL(9, 2) = NULL -- сумма долга
	, @proptype_id1 VARCHAR(10) = NULL -- тип квартиры
	, @service_id1 VARCHAR(10) = NULL -- услуга
	, @tip_id SMALLINT = NULL -- Тип жилого фонда
	, @kol_mes2 SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @sup_id INT
	, @town_id SMALLINT = NULL
	, @PrintGroup SMALLINT = NULL
)
AS
/*
Список должников с разными выборками по поставщику

дата создания: 27.03.2004
автор: Пузанов М.А.

дата последней модификации:  21.12.12

Отчет: rep_dolg_11.fr3
*/

	SET NOCOUNT ON


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

	IF @kol_mes2 IS NULL
		SET @kol_mes2 = 9999


	DECLARE @t TABLE (
		  occ INT PRIMARY KEY
		, kol_mes DECIMAL(5, 1)
		, dolg DECIMAL(9, 2)
		, service_id VARCHAR(10)
		, saldo DECIMAL(9, 2)
		, Paid DECIMAL(9, 2)
		, PaymAccount DECIMAL(9, 2)
		, Initials VARCHAR(50)
		, STREETS VARCHAR(50)
		, nom_dom VARCHAR(12)
		, nom_kvr VARCHAR(20)
		, div_id SMALLINT
		, div_name VARCHAR(30)
		, sector_id SMALLINT
		, sector_name VARCHAR(30)
		, proptype_id VARCHAR(10)
		, kol_people SMALLINT
		, lgotas VARCHAR(5)
		, lgota_name VARCHAR(50)
		, subsides VARCHAR(5)
		, telephon BIGINT
		, total_sq DECIMAL(10, 4)
		, KolMesCal SMALLINT DEFAULT 0
		, LastPeriodValue SMALLDATETIME DEFAULT NULL
		, last_paym_value DECIMAL(9, 2) DEFAULT NULL
		, last_paym_day SMALLDATETIME DEFAULT NULL
		, penalty_itog DECIMAL(9, 2)
		, KolOccInBuild SMALLINT DEFAULT NULL
		, KolOccInFlats SMALLINT DEFAULT NULL
		, kolmes_paym AS (DATEDIFF(MONTH, last_paym_day, current_timestamp))
		, tip_id SMALLINT DEFAULT NULL
		, build_id INT DEFAULT NULL
		, nom_dom_sort VARCHAR(12) DEFAULT NULL
		, nom_kvr_sort VARCHAR(30) DEFAULT NULL
	)

	-- По всем услугам
	IF @service_id1 IS NULL
		SELECT o.occ_sup AS occ
			 , o.KolMesDolg AS kol_mes
			 , (o.saldo - (o.paymaccount-o.paymaccount_peny)) AS dolg
			 , 'Все услуги' AS service_id
			 , o.saldo
			 , o.Paid
			 , (o.paymaccount-o.paymaccount_peny) AS PaymAccount
			 , dbo.Fun_Initials(o.occ) AS Initials
			 , b.street_name AS STREETS
			 , b.nom_dom
			 , f1.nom_kvr
			 , b.div_id AS div_id
			 , b.div_name AS div_name
			 , b.sector_id AS sector_id
			 , b.sector_name AS sector_name
			 , O1.proptype_id
			 , dbo.Fun_GetKolPeopleOccStatus(o.occ) AS kol_people
			 , '' AS lgotas
			 , '' AS lgota_name
			 , '' AS subsides
			 , telephon = O1.telephon
			 , O1.total_sq
			 , mes.KolMesCal2 AS KolMesCal
			 , mes.LastPeriodValue
			 , pay.Value AS last_paym_value
			 , pay.day AS last_paym_day
			 , o.Penalty_old AS penalty_itog  
			 , COUNT(o.occ) OVER (PARTITION BY b.street_name, nom_dom) AS KolOccInBuild
			 , COUNT(o.occ) OVER (PARTITION BY b.street_name, nom_dom, f1.nom_kvr) AS KolOccInFlats
			 , (DATEDIFF(MONTH, pay.day, current_timestamp)) AS kolmes_paym
			 , o1.tip_id
			 , b.build_id
			 , b.nom_dom_sort
			 , f1.nom_kvr_sort
		FROM dbo.Occ_Suppliers AS o 
			JOIN dbo.Occupations O1 
				ON o.occ = O1.occ
			JOIN dbo.Flats f1 
				ON O1.flat_id = f1.id
			JOIN dbo.View_build_all AS b 
				ON f1.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
			OUTER APPLY (
				SELECT TOP (1) p.[Value]
							 , pd.day
				FROM dbo.Payings AS p 
					JOIN dbo.Paydoc_packs AS pd 
						ON p.pack_id = pd.id
				WHERE o.occ = p.occ
					AND service_id IS NULL
					AND p.sup_id = @sup_id
				ORDER BY pd.day DESC
			) AS pay
			OUTER APPLY (
				SELECT TOP (1) KolMesCal2 = DATEDIFF(MONTH, gb.start_date, @start_date) - 1
							,gb.start_date AS LastPeriodValue
				FROM dbo.Occ_Suppliers AS oh 
					JOIN dbo.Global_values AS gb ON oh.fin_id = gb.fin_id
				WHERE oh.fin_id < @fin_current
					AND oh.Value > 0
					AND oh.occ = o.occ
				ORDER BY oh.fin_id DESC
			) AS mes
		WHERE 
			O1.status_id <> 'закр'
			AND o.fin_id = @fin_id1
			AND o.sup_id = @sup_id
			AND (b.bldn_id = @build_id1 OR @build_id1 IS NULL) -- отбор по коду дома
			AND (b.div_id = @div_id1 OR @div_id1 IS NULL) -- отбор по коду района
			AND (b.sector_id = @jeu1 OR @jeu1 IS NULL) -- отбор по коду участку
			AND (o.saldo - (o.PaymAccount - o.PaymAccount_peny)) > @dolg1 -- отбор по сумме долга	 -- 14/04/2010
			AND (o.KolMesDolg >= @kol_mes1 AND o.KolMesDolg < @kol_mes2) -- отбор по кол.месяцев долга
			AND (b.tip_id = @tip_id OR @tip_id IS NULL)
			AND (O1.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL) -- отбор по типу квартиры
			AND (b.town_id = @town_id OR @town_id IS NULL)
			AND (@PrintGroup IS NULL OR EXISTS (
				SELECT 1
				FROM dbo.Print_occ AS po
				WHERE po.occ = o.occ
					AND po.group_id = @PrintGroup
			))
		ORDER BY b.street_name
			   , b.nom_dom_sort
			   , f1.nom_kvr_sort
	ELSE
		-- по одной заданной услуге
		SELECT o.occ_sup AS occ
			 , o.KolMesDolg AS kol_mes
			 , (pl.saldo - pl.Paymaccount_Serv) AS dolg
			 , pl.service_id AS service_id
			 , pl.saldo
			 , pl.Paid
			 , pl.Paymaccount_Serv AS PaymAccount
			 , dbo.Fun_Initials(o.occ) AS Initials
			 , b.street_name AS STREETS
			 , b.nom_dom
			 , f.nom_kvr
			 , b.div_id AS div_id
			 , b.div_name AS div_name
			 , b.sector_id AS sector_id
			 , b.sector_name AS sector_name
			 , O1.proptype_id
			 , dbo.Fun_GetKolPeopleOccStatus(o.occ) AS kol_people
			 , '' AS lgotas
			 , '' AS lgota_name
			 , '' AS subsides
			 , O1.telephon
			 , O1.total_sq
			 , 0 AS KolMesCal
			 , NULL AS LastPeriodValue
			 , 0 AS last_paym_value
			 , NULL AS last_paym_day
			 , 0 AS penalty_itog
			 , COUNT(o.occ) OVER (PARTITION BY b.street_name, nom_dom) AS KolOccInBuild
			 , COUNT(o.occ) OVER (PARTITION BY b.street_name, nom_dom, f.nom_kvr) AS KolOccInFlats
			 , NULL AS kolmes_paym
			 , o1.tip_id
			 , b.build_id
			 , b.nom_dom_sort
			 , f.nom_kvr_sort
		FROM dbo.Occ_Suppliers AS o 
			JOIN dbo.Occupations O1 
				ON o.occ = O1.occ
			JOIN dbo.View_paym AS pl 
				ON pl.occ = o.occ
				AND o.fin_id = pl.fin_id
			JOIN dbo.Flats AS f 
				ON O1.flat_id = f.id
			JOIN dbo.View_build_all AS b 
				ON f.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
		WHERE 
			O1.status_id <> 'закр'
			AND o.fin_id = @fin_id1
			AND pl.service_id = @service_id1
			AND (b.bldn_id = @build_id1 OR @build_id1 IS NULL) -- отбор по коду дома
			AND (b.div_id = @div_id1 OR @div_id1 IS NULL) -- отбор по коду района
			AND (b.sector_id = @jeu1 OR @jeu1 IS NULL) -- отбор по коду участку
			AND (pl.saldo - pl.Paymaccount_Serv) > @dolg1 -- отбор по сумме долга  -- 14/04/20101
			AND (o.KolMesDolg >= @kol_mes1 AND o.KolMesDolg < @kol_mes2) -- отбор по кол.месяцев долга
			AND (b.tip_id = @tip_id OR @tip_id IS NULL)
			AND (O1.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL) -- отбор по типу квартиры
			AND (b.town_id = @town_id OR @town_id IS NULL)
			AND (@PrintGroup IS NULL OR EXISTS (
				SELECT 1
				FROM dbo.Print_occ AS po 
				WHERE po.occ = o.occ
					AND po.group_id = @PrintGroup
			))
		ORDER BY b.street_name
			   , b.nom_dom_sort
			   , f.nom_kvr_sort
go

