CREATE   PROCEDURE [dbo].[rep_dolg_socz]
(
	@tip_id		SMALLINT		= NULL -- Тип жилого фонда
	,@build_id1	INT				= NULL -- код дома
	,@kol_mes1	SMALLINT		= 6 -- кол.месяцев долга
	,@dolg1		DECIMAL(9, 2)	= NULL -- сумма долга
	,@fin_id1	SMALLINT		= NULL
	,@kol_mes2	SMALLINT		= NULL
	,@sup_id	INT				= NULL
)
AS
	/*
	rep_dolg_socz @tip_id=28,@sup_id=323,@fin_id1=173
	
	Список должников с разными выборками для Министерства соц.защиты
	
	
	дата создания: 22.11.2011
	автор: Пузанов М.А.
	
	Используется как
	Выгрузка в "Экспорте"
	*/

	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id, @build_id1, NULL, NULL)
	IF @dolg1 IS NULL
		SET @dolg1 = 0
	IF @kol_mes2 IS NULL
		SET @kol_mes2 = 9999
	IF @kol_mes1 IS NULL
		SET @kol_mes1 = 3

	DECLARE @t TABLE
		(
			occ			INT	PRIMARY KEY
			,kol_mes	DECIMAL(5, 1)
			,dolg		DECIMAL(9, 2)
			,service_id	VARCHAR(10)
			,FAMIL		VARCHAR(25)
			,IMJA		VARCHAR(25)
			,OTCH		VARCHAR(25)
			,DROG		SMALLDATETIME
			,NNASP		VARCHAR(30)
			,NYLIC		VARCHAR(36)
			,NDOM		VARCHAR(12)
			,NKORP		VARCHAR(3)
			,NKW		VARCHAR(15)
			,DOLGS		SMALLDATETIME
			,DOLGPO		SMALLDATETIME
		)

	-- По единой квитанции
	IF @sup_id IS NULL
		INSERT
		INTO @t
				SELECT
					o.occ
					,o.KolMesDolg AS kol_mes
					,(o.saldo - o.paymaccount) AS dolg
					,'Все' AS service_id
					,p.Last_name AS FAMIL
					,p.First_name
					,p.Second_name
					,p.Birthdate
					,b.town_name
					,b.street_name AS NYLIC
					,b.nom_dom
					,''
					,o.nom_kvr
					,DATEADD(MONTH, -@kol_mes1, o.start_date)
					,o.start_date
				FROM dbo.View_OCC_ALL AS o 
				JOIN dbo.View_BUILD_ALL AS b 
					ON o.bldn_id = b.bldn_id
					AND o.fin_id = b.fin_id
				JOIN dbo.PEOPLE AS p
					ON o.occ = p.occ
					AND p.Fam_id = 'отвл'
					AND p.Del = 0
				WHERE o.status_id <> 'закр'
				AND o.fin_id = @fin_id1
				AND (o.bldn_id = @build_id1
				OR @build_id1 IS NULL)  -- отбор по коду дома
				AND (o.KolMesDolg >= @kol_mes1
				AND o.KolMesDolg < @kol_mes2)  -- отбор по кол.месяцев долга
				AND (o.saldo - o.paymaccount) > @dolg1  -- отбор по сумме долга	 
				AND (b.tip_id = @tip_id
				OR @tip_id IS NULL)

	ELSE
		-- по поставщику
		INSERT
		INTO @t
				SELECT
					o.occ_sup
					,o.KolMesDolg AS kol_mes
					,(o.saldo - (o.paymaccount - o.paymaccount_peny)) AS dolg
					,'Все' AS service_id
					,p.Last_name AS FAMIL
					,p.First_name
					,p.Second_name
					,p.Birthdate
					,b.town_name
					,b.street_name AS NYLIC
					,b.nom_dom
					,''
					,f1.nom_kvr
					,DATEADD(MONTH, -@kol_mes1, b.start_date)
					,b.start_date
				FROM dbo.OCC_SUPPLIERS AS o 
				JOIN dbo.OCCUPATIONS O1 
					ON o.occ = O1.occ
				JOIN dbo.FLATS f1 
					ON O1.flat_id = f1.id
				JOIN dbo.View_BUILD_ALL AS b 
					ON f1.bldn_id = b.bldn_id
					AND o.fin_id = b.fin_id
				JOIN dbo.PEOPLE AS p
					ON o.occ = p.occ
					AND p.Fam_id = 'отвл'
					AND p.Del = 0
				WHERE O1.status_id <> 'закр'
				AND o.fin_id = @fin_id1
				AND o.sup_id = @sup_id
				AND (b.bldn_id = @build_id1
				OR @build_id1 IS NULL) -- отбор по коду дома
				AND (o.saldo - (o.paymaccount - o.paymaccount_peny)) > @dolg1 -- отбор по сумме долга	 -- 14/04/2010
				AND (o.KolMesDolg >= @kol_mes1
				AND o.KolMesDolg < @kol_mes2) -- отбор по кол.месяцев долга
				AND (b.tip_id = @tip_id
				OR @tip_id IS NULL)

	SELECT
		t.*
	FROM @t AS t
	ORDER BY NYLIC,
	dbo.Fun_SortDom(NDOM),
	dbo.Fun_SortDom(NKW)
go

