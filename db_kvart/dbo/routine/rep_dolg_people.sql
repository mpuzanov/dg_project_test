CREATE   PROCEDURE [dbo].[rep_dolg_people]
(
	@div_id1		SMALLINT		= NULL -- код района
	,@jeu1			SMALLINT		= NULL -- код участка
	,@build_id1		INT				= NULL -- код дома
	,@kol_mes1		SMALLINT		= 3 -- кол.месяцев долга
	,@dolg1			DECIMAL(9, 2)	= NULL -- сумма долга
	,@proptype_id1	VARCHAR(10)		= NULL -- тип квартиры
	,@service_id1	VARCHAR(10)		= NULL    -- услуга
	,@tip_id		SMALLINT		= NULL       -- Тип жилого фонда
	,@kol_mes2		SMALLINT		= NULL
	,@fin_id1		SMALLINT		= NULL
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
	
	дата последней модификации:  14.04.2010
	
	Отчет: rep_dolg_11.fr3
	*/

	SET NOCOUNT ON


	DECLARE	@fin_current	SMALLINT
			,@start_date	SMALLDATETIME
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build_id1, NULL, NULL)
	SELECT
		@start_date = start_date
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


	DECLARE @t TABLE
		(
			occ					INT				PRIMARY KEY
			,kol_mes			DECIMAL(5, 1)
			,dolg				DECIMAL(9, 2)
			,service_id			VARCHAR(10)
			,saldo				DECIMAL(9, 2)
			,paid				DECIMAL(9, 2)
			,paymaccount		DECIMAL(9, 2)
			,Initials			VARCHAR(200)
			,streets			VARCHAR(50)
			,nom_dom			VARCHAR(12)
			,nom_kvr			VARCHAR(20)
			,div_id				SMALLINT
			,div_name			VARCHAR(30)
			,sector_id			SMALLINT
			,sector_name		VARCHAR(30)
			,proptype_id		VARCHAR(10)
			,kol_people			SMALLINT
			,lgotas				VARCHAR(5)
			,lgota_name			VARCHAR(50)
			,subsides			VARCHAR(5)
			,telephon			INT
			,total_sq			DECIMAL(10, 4)
			,KolMesCal			SMALLINT		DEFAULT 0
			,last_paym_value	DECIMAL(9, 2)	DEFAULT NULL
			,last_paym_day		SMALLDATETIME	DEFAULT NULL
			,kolmes_paym		AS (DATEDIFF(MONTH, last_paym_day, current_timestamp))
		)

	-- По всем услугам

	IF @service_id1 IS NULL
		INSERT
		INTO @t
			SELECT --top 100
				o.occ
				,o.KolMesDolg AS kol_mes
				,(o.saldo - o.paymaccount) AS dolg
				,'Все услуги' AS service_id
				,o.saldo
				,o.paid
				,o.paymaccount
				,dbo.Fun_Initials_StrPeople(o.occ, @fin_id1) AS Initials
				,s.name AS streets
				,b.nom_dom
				,f.nom_kvr
				,d.Id AS div_id
				,d.name AS div_name
				,sec.Id as sector_id
				,sec.name as sector_name
				,o.proptype_id
				,dbo.Fun_GetKolPeopleOccStatus(o.occ) AS kol_people
				,CASE
					WHEN o.Discount > 0 THEN 'да'
					ELSE '-'
				END AS lgotas
				,dbo.Fun_LgotaStr(o.occ) AS lgota_name
				,CASE
					WHEN COALESCE(c.sumkomp, 0) > 0 THEN 'да'
					ELSE '-'
				END AS subsides
				,f.telephon
				,o.total_sq
				,mes.KolMesCal2 as KolMesCal
				,pay.Value as last_paym_value
				,pay.day as last_paym_day
			FROM dbo.View_OCC_ALL AS o 
			JOIN dbo.FLATS AS f
				ON o.flat_id = f.Id
			JOIN dbo.View_BUILD_ALL AS b 
				ON f.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
			LEFT JOIN dbo.View_COMPENSAC AS c 
				ON o.occ = c.occ
				AND o.fin_id = c.fin_id
			JOIN dbo.VSTREETS AS s 
				ON s.Id = b.street_id
			JOIN dbo.DIVISIONS AS d 
				ON d.Id = b.div_id
			JOIN dbo.SECTOR AS sec 
				ON sec.Id = b.sector_id
			OUTER APPLY (SELECT TOP 1
					p.[Value]
					,pd.day
				FROM dbo.PAYINGS AS p 
				JOIN dbo.PAYDOC_PACKS AS pd 
					ON p.pack_id = pd.Id
				WHERE o.occ = p.occ
				AND service_id IS NULL
				ORDER BY pd.day DESC) AS pay
			OUTER APPLY (SELECT TOP 1
							KolMesCal2 = DATEDIFF(MONTH, gb.start_date, @start_date) - 1
						FROM dbo.View_occ_all_lite AS oh 
						JOIN dbo.Global_values AS gb 
							ON oh.fin_id = gb.fin_id
						WHERE oh.fin_id < @fin_current
						AND oh.Value > 0
						AND oh.occ = o.occ
						ORDER BY oh.fin_id DESC
					) AS mes
			WHERE 
				o.status_id <> 'закр'
				AND o.fin_id = @fin_id1
				--AND i.fin_id = @fin_id1
				AND (f.bldn_id = @build_id1 OR @build_id1 IS NULL)  -- отбор по коду дома
				AND (b.div_id = @div_id1 OR @div_id1 IS NULL)  -- отбор по коду района
				AND (o.saldo - o.paymaccount) > @dolg1  -- отбор по сумме долга	 -- 14/04/2010
				AND (o.KolMesDolg >= @kol_mes1
				AND o.KolMesDolg < @kol_mes2)  -- отбор по кол.месяцев долга
				AND (b.tip_id = @tip_id OR @tip_id IS NULL)
				AND (o.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL)  -- отбор по типу квартиры

	ELSE
		-- по одной заданной услуге
		INSERT
		INTO @t
			SELECT
				pl.occ
				,o.KolMesDolg AS kol_mes
				,(pl.saldo - pl.paymaccount) AS dolg
				,  -- 14/04/2010
				pl.service_id AS service_id
				,pl.saldo
				,pl.paid
				,pl.paymaccount
				,dbo.Fun_Initials(o.occ) AS Initials
				,s.name AS streets
				,b.nom_dom
				,f.nom_kvr
				,d.Id AS div_id
				,d.name AS div_name
				,sector_id = sec.Id
				,sector_name = sec.name
				,o.proptype_id
				,dbo.Fun_GetKolPeopleOccStatus(o.occ) AS kol_people
				,CASE
					WHEN o.Discount > 0 THEN 'да'
					ELSE 'нет'
				END AS lgotas
				,dbo.Fun_LgotaStr(o.occ) AS lgota_name
				,CASE
					WHEN COALESCE(c.sumkomp, 0) > 0 THEN 'да'
					ELSE 'нет'
				END AS subsides
				,f.telephon
				,o.total_sq
				,0
				,0
				,NULL
			FROM dbo.View_occ_all AS o 
			JOIN dbo.View_paym AS pl 
				ON pl.occ = o.occ
				AND o.fin_id = pl.fin_id
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.Id
			JOIN dbo.View_BUILD_ALL AS b 
				ON f.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
			LEFT JOIN dbo.View_COMPENSAC AS c
				ON c.occ = o.occ
				AND o.fin_id = c.fin_id
			JOIN dbo.VSTREETS AS s
				ON s.Id = b.street_id
			JOIN dbo.DIVISIONS AS d
				ON d.Id = b.div_id
			JOIN dbo.SECTOR AS sec
				ON sec.Id = b.sector_id
			WHERE 
				o.status_id <> 'закр'
				AND o.fin_id = @fin_id1
				AND pl.service_id = @service_id1
				--AND i.fin_id = @fin_id1
				AND (f.bldn_id = @build_id1 OR @build_id1 IS NULL)  -- отбор по коду дома
				AND (b.div_id = @div_id1 OR @div_id1 IS NULL)  -- отбор по коду района
				AND (pl.saldo - pl.paymaccount) > @dolg1  -- отбор по сумме долга  -- 14/04/20101
				AND (o.KolMesDolg >= @kol_mes1
				AND o.KolMesDolg < @kol_mes2) -- отбор по кол.месяцев долга
				AND (b.tip_id = @tip_id OR @tip_id IS NULL)
				AND (o.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL)  -- отбор по типу квартиры

	SELECT
		t.*
	FROM @t AS t
	ORDER BY streets,
		dbo.Fun_SortDom(nom_dom),
		dbo.Fun_SortDom(nom_kvr)
go

