CREATE   PROCEDURE [dbo].[rep_dolg_12]
(
	  @div_id1 SMALLINT = NULL
	, -- код района
	  @jeu1 SMALLINT = NULL
	, -- код участка
	  @build_id1 INT = NULL
	, -- код дома
	  @kol_mes1 SMALLINT = 3
	, -- кол.месяцев долга
	  @dolg1 DECIMAL(9, 2) = 1
	, -- сумма долга
	  @proptype_id1 VARCHAR(10) = NULL
	, -- тип квартиры
	  @service_id1 VARCHAR(10) = NULL -- услуга
	, @tip_id SMALLINT = NULL-- Тип жилого фонда
)
AS
	--
	--  Список должников с разными выборками
	--
	/*
	
	дата создания: 27.03.2004
	автор: Пузанов М.А.
	
	дата последней модификации:  29.06.06
	автор изменений:  Антропов
	добавлена выборка по услуге
	добвлена переменная наличие банковских счетов лицевых
	
	дата последней модификации:  28.06.07
	коррекировка выборки сумм по субсидиям
	
	дата последней модификации:  20.02.09
	убрал выборку по банкам
	добавил тип жил.фонда
	
	дата последней модификации:  18.09.09
	
	Отчет: rep_dolg_11.fr3
	*/

	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
		  , @fin_pred SMALLINT
		  , @start_date SMALLDATETIME
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build_id1, NULL, NULL)

	SELECT @start_date = start_date
	FROM dbo.Global_values
	WHERE fin_id = @fin_current
	SET @fin_pred = @fin_current - 1

	IF @div_id1 < 0
		SET @div_id1 = NULL

	DECLARE @t TABLE (
		  occ INT PRIMARY KEY
		, kol_mes SMALLINT
		, dolg DECIMAL(9, 2)
		, service_id VARCHAR(10)
		, saldo DECIMAL(9, 2)
		, Paid DECIMAL(9, 2)
		, PaymAccount DECIMAL(9, 2)
		, Initials VARCHAR(50)
		, STREETS VARCHAR(50)
		, nom_dom VARCHAR(7)
		, nom_kvr VARCHAR(7)
		, div_id SMALLINT
		, div_name VARCHAR(30)
		, sector_id SMALLINT
		, sector_name VARCHAR(30)
		, proptype_id VARCHAR(10)
		, kol_people SMALLINT
		, lgotas VARCHAR(5)
		, lgota_name VARCHAR(50)
		, subsides VARCHAR(5)
		, telephon INT
		, total_sq DECIMAL(10, 4)
		, KolMesCal SMALLINT DEFAULT 0
		, last_paym_value DECIMAL(9, 2) DEFAULT NULL
		, last_paym_day SMALLDATETIME DEFAULT NULL
		, kolmes_paym AS (DATEDIFF(MONTH, last_paym_day, current_timestamp))
	)


	-- По всем услугам
	IF @service_id1 IS NULL
		INSERT INTO @t
		SELECT --top 100
			o.occ
		  , ROUND(i.KolMesDolg, 0) AS kol_mes
		  , (o.saldo - o.Paid_old - o.PaymAccount) AS dolg
		  , 'Все услуги' AS service_id
		  , o.saldo
		  , o.Paid
		  , o.PaymAccount
		  , dbo.Fun_Initials(o.occ) AS Initials
		  , s.name AS STREETS
		  , b.nom_dom
		  , f.nom_kvr
		  , d.id AS div_id
		  , d.name AS div_name
		  , sector_id = sec.id
		  , sector_name = sec.name
		  , o.proptype_id
		  , o.kol_people AS kol_people
		  , CASE
				WHEN o.discount > 0 THEN 'да'
				ELSE 'нет'
			END AS lgotas
		  , dbo.Fun_LgotaStr(o.occ) AS lgota_name
		  , CASE
				WHEN COALESCE(c.sumkomp, 0) > 0 THEN 'да'
				ELSE 'нет'
			END AS subsides
		  , f.telephon
		  , o.total_sq
		  , KolMesCal = 0 --round(i.KolMesDolg,0)+dbo.Fun_DolgMes3(@fin_current,o.occ) --dbo.Fun_DolgMesCal(@fin_current,o.occ)
		  , last_paym_value = pay.Value
		  , last_paym_day = pay.day
		FROM dbo.VOcc AS o 
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id = b.id
			JOIN dbo.Intprint AS i 
				ON i.occ = o.occ
			LEFT JOIN dbo.View_compensac AS c
				ON c.occ = o.occ
				AND c.fin_id = @fin_current
			JOIN dbo.VStreets AS s 
				ON s.id = b.street_id
			JOIN dbo.Divisions AS d 
				ON d.id = b.div_id
			JOIN dbo.Sector AS sec 
				ON sec.id = b.sector_id
			OUTER APPLY (
				SELECT TOP 1 p.[Value]
						   , pd.day
				FROM dbo.Payings AS p
					JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
				WHERE o.occ = p.occ
					AND service_id IS NULL
				ORDER BY pd.day DESC
			) AS pay
		WHERE o.status_id <> 'закр'
			AND i.fin_id = @fin_pred
			AND f.bldn_id = COALESCE(@build_id1, f.bldn_id) -- отбор по коду дома
			AND b.div_id = COALESCE(@div_id1, b.div_id) -- отбор по коду района
			AND o.jeu = COALESCE(@jeu1, o.jeu)
			AND (o.saldo - o.Paid_old - o.PaymAccount) > @dolg1 -- отбор по сумме долга
			AND i.KolMesDolg > @kol_mes1 -- отбор по кол.месяцев долга
			AND b.tip_id = COALESCE(@tip_id, b.tip_id)
			AND o.proptype_id = COALESCE(@proptype_id1, o.proptype_id) -- отбор по типу квартиры
		ORDER BY s.name
			   , b.nom_dom_sort
			   , f.nom_kvr_sort
	ELSE

		-- по одной заданной услуге
		INSERT INTO @t
		SELECT pl.occ
			 , ROUND(i.KolMesDolg, 0) AS kol_mes
			 , (pl.saldo - pl.Paid - pl.PaymAccount) AS dolg
			 , pl.service_id AS service_id
			 , pl.saldo
			 , pl.Paid
			 , pl.PaymAccount
			 , dbo.Fun_Initials(o.occ) AS Initials
			 , s.name AS STREETS
			 , b.nom_dom
			 , f.nom_kvr
			 , d.id AS div_id
			 , d.name AS div_name
			 , sector_id = sec.id
			 , sector_name = sec.name
			 , o.proptype_id
			 , o.kol_people AS kol_people
			 , CASE
				   WHEN o.discount > 0 THEN 'да'
				   ELSE 'нет'
			   END AS lgotas
			 , dbo.Fun_LgotaStr(o.occ) AS lgota_name
			 , CASE
				   WHEN COALESCE(c.sumkomp, 0) > 0 THEN 'да'
				   ELSE 'нет'
			   END AS subsides
			 , f.telephon
			 , o.total_sq
			 , 0
			 , 0
			 , NULL
		FROM dbo.VOcc AS o 
			JOIN dbo.View_paym AS pl 
				ON pl.occ = o.occ
				AND pl.fin_id = @fin_current
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id = b.id
			JOIN dbo.Intprint AS i 
				ON i.occ = o.occ
			LEFT JOIN dbo.View_compensac AS c 
				ON c.occ = o.occ
				AND c.fin_id = @fin_current
			JOIN dbo.VStreets AS s ON s.id = b.street_id
			JOIN dbo.Divisions AS d ON d.id = b.div_id
			JOIN dbo.Sector AS sec ON sec.id = b.sector_id
		WHERE o.status_id <> 'закр'
			AND pl.service_id = @service_id1
			AND i.fin_id = @fin_pred
			AND f.bldn_id = COALESCE(@build_id1, f.bldn_id) -- отбор по коду дома
			AND b.div_id = COALESCE(@div_id1, b.div_id) -- отбор по коду района
			AND b.sector_id = COALESCE(@jeu1, b.sector_id)
			AND (pl.saldo - pl.Paid - pl.PaymAccount) > @dolg1 -- отбор по сумме долга
			AND i.KolMesDolg > @kol_mes1 -- отбор по кол.месяцев долга
			AND b.tip_id = COALESCE(@tip_id, b.tip_id)
			AND o.proptype_id = COALESCE(@proptype_id1, o.proptype_id) -- отбор по типу квартиры
		ORDER BY s.name
			   , b.nom_dom_sort
			   , f.nom_kvr_sort

	SELECT *
	FROM @t

	--select t.*, mes.KolMesCal2
	--from @t as t
	-- OUTER APPLY (
	SELECT t.occ
		 , KolMesCal2 = DATEDIFF(MONTH, MAX(oh.start_date), @start_date) - 1
	FROM dbo.View_occ_all AS oh 
		JOIN @t AS t ON oh.occ = t.occ
	WHERE oh.fin_id < @fin_current
		AND oh.Value > 0
	GROUP BY t.occ
	--) as mes

	--JOIN dbo.Fun_GetDolgMesTableAdd(@t_occ,@fin_current) as t2 ON t.occ=t2.occ

	--select * from @t
go

