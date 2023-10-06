CREATE   PROCEDURE [dbo].[rep_dolg_people_sup]
(
	@div_id1		SMALLINT		= NULL  -- код района
	,@build_id1		INT				= NULL -- код дома
	,@kol_mes1		SMALLINT		= 3 -- кол.месяцев долга
	,@dolg1			DECIMAL(9, 2)	= NULL -- сумма долга
	,@proptype_id1	VARCHAR(10)		= NULL -- тип квартиры
	,@tip_id		SMALLINT		= NULL        -- Тип жилого фонда
	,@kol_mes2		SMALLINT		= NULL
	,@fin_id1		SMALLINT
	,@sup_id1		INT				= NULL
)
AS
	/*
	exec rep_dolg_people_sup @tip_id=1,@fin_id1=255
	exec rep_dolg_people_sup @tip_id=1,@sup_id1=345,@fin_id1=255
	
	Список должников с разными выборками
	
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
	
	дата последней модификации:  16.09.2016
	
	Отчет: rep_dolg_11.fr3
	*/

	SET NOCOUNT ON

	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id, @build_id1, NULL, NULL)

	DECLARE	@start_date	SMALLDATETIME
	SELECT
		@start_date = start_date
	FROM dbo.Global_values
	WHERE fin_id = @fin_id1
	
	IF @dolg1 IS NULL
		SET @dolg1 = 0
	IF @div_id1 < 0
		SET @div_id1 = NULL
	IF @kol_mes2 IS NULL
		SET @kol_mes2 = 9999


	SELECT
		t.*
		,DATEDIFF(MONTH, last_paym_day, current_timestamp) as kolmes_paym
	FROM (
		SELECT
			os.occ_sup as occ
			,os.KolMesDolg AS kol_mes
			,(os.saldo - os.Paid_old - os.paymaccount) AS dolg
			,os.saldo
			,os.paid
			,os.paymaccount
			,dbo.Fun_Initials_StrPeople(os.occ, @fin_id1) AS Initials
			,s.name AS streets
			,b.nom_dom
			,f.nom_kvr
			,d.name AS div_name
			,sec.name AS sec_name
			,o.proptype_id
			,dbo.Fun_GetKolPeopleOccStatus(o.occ) AS kol_people
			,pay.VALUE AS last_paym_value
			,pay.day AS last_paym_day
		FROM dbo.OCC_SUPPLIERS AS os
		JOIN dbo.View_OCC_ALL AS o 
			ON os.occ = o.occ
			AND os.fin_id = o.fin_id
		JOIN dbo.FLATS AS f
			ON o.flat_id = f.Id
		JOIN dbo.View_BUILD_ALL AS b 
			ON f.bldn_id = b.bldn_id
			AND os.fin_id = b.fin_id
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
			WHERE 
				o.occ = p.occ
				AND service_id IS NULL
				AND os.sup_id = @sup_id1
			ORDER BY pd.day DESC) AS pay
		WHERE 
			os.fin_id = @fin_id1
			AND (os.sup_id = @sup_id1 OR @sup_id1 IS NULL)
			AND o.status_id <> 'закр'
			AND (f.bldn_id = @build_id1 OR @build_id1 IS NULL)  -- отбор по коду дома
			AND (b.div_id = @div_id1 OR @div_id1 IS NULL)  -- отбор по коду района
			AND (os.saldo - os.paymaccount) > @dolg1  -- отбор по сумме долга	 -- 
			AND (os.KolMesDolg >= @kol_mes1
			AND os.KolMesDolg < @kol_mes2)  -- отбор по кол.месяцев долга
			AND (b.tip_id = @tip_id OR @tip_id IS NULL)
			AND (o.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL)  -- отбор по типу квартиры
	) AS t
	ORDER BY streets,
		dbo.Fun_SortDom(nom_dom),
		dbo.Fun_SortDom(nom_kvr)
go

