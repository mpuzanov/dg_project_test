CREATE   PROCEDURE [dbo].[rep_dolg_olap]
(
	  @fin_id1 SMALLINT = NULL
	, @tip_id SMALLINT = NULL -- Тип жилого фонда
	, @build_id INT = NULL -- код дома
	, @sup_id INT = NULL
)
AS
	/*		
	Список должников с разными выборками
		
	exec rep_dolg_olap @fin_id1=238, @tip_id=1,@sup_id=345
	exec rep_dolg_olap @fin_id1=238, @tip_id=1	
	*/

	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	CREATE TABLE #t (
		  occ INT PRIMARY KEY
		, kol_mes DECIMAL(5, 1)
		, dolg DECIMAL(9, 2)
		, service_id VARCHAR(10) COLLATE database_default
		, saldo DECIMAL(9, 2)
		, Paid DECIMAL(9, 2)
		, PaymAccount DECIMAL(9, 2)
		, Initials VARCHAR(50) COLLATE database_default
		, STREETS VARCHAR(100) COLLATE database_default
		, nom_dom VARCHAR(12) COLLATE database_default
		, nom_kvr VARCHAR(20) COLLATE database_default
		, div_id SMALLINT
		, div_name VARCHAR(30) COLLATE database_default
		, sector_id SMALLINT
		, sector_name VARCHAR(30) COLLATE database_default
		, proptype_id VARCHAR(10) COLLATE database_default
		, kol_people SMALLINT
		, lgotas VARCHAR(5) COLLATE database_default
		, lgota_name VARCHAR(50) COLLATE database_default
		, subsides VARCHAR(5) COLLATE database_default
		, telephon BIGINT
		, total_sq DECIMAL(10, 4)
		, KolMesCal SMALLINT DEFAULT 0
		, LastPeriodValue SMALLDATETIME DEFAULT NULL
		, last_paym_value DECIMAL(9, 2) DEFAULT NULL
		, last_paym_day SMALLDATETIME DEFAULT NULL
		, penalty_itog DECIMAL(9, 2)
		, KolOccInBuild SMALLINT DEFAULT NULL
		, KolOccInFlats SMALLINT DEFAULT NULL
		, kolmes_paym SMALLINT DEFAULT NULL
		, tip_id SMALLINT DEFAULT NULL
		, build_id INT DEFAULT NULL
		, nom_dom_sort VARCHAR(12) COLLATE database_default DEFAULT NULL
		, nom_kvr_sort VARCHAR(30) COLLATE database_default DEFAULT NULL
	)

	INSERT INTO #t
	EXEC [dbo].[rep_dolg_11] @build_id1 = @build_id
						   , @kol_mes1 = 3
						   , @tip_id = @tip_id
						   , @fin_id1 = @fin_id1
						   , @sup_id = @sup_id
						   , @all_serv = 1

	SELECT gv.start_date AS 'Период' 
	    , t.occ AS 'Лицевой'
		, t.kol_mes AS 'Кол-во месяцев долга'
		, CASE
			   WHEN t.kol_mes BETWEEN 0 AND 2.9 THEN '1 (0-2)'
			   WHEN t.kol_mes BETWEEN 3 AND 6.9 THEN '2 (3-6)'
			   WHEN t.kol_mes BETWEEN 7 AND 9.9 THEN '3 (7-9)'
			   WHEN t.kol_mes BETWEEN 10 AND 12.9 THEN '4 (10-12)'
			   WHEN t.kol_mes BETWEEN 13 AND 18.9 THEN '5 (13-18)'
			   WHEN t.kol_mes BETWEEN 19 AND 36 THEN '6 (19-36)'
			   WHEN t.kol_mes > 36 THEN N'более 36'
		   END
		   AS 'Группа задолженности'
		, t.dolg AS 'Задолженность'
		, CASE
			   WHEN t.dolg < 3000 THEN '1 (менее 3 тыс.р.)'
			   WHEN t.dolg BETWEEN 3000 AND 10000 THEN '2 (3-10)'
			   WHEN t.dolg BETWEEN 10001 AND 20000 THEN '3 (10-20)'
			   WHEN t.dolg BETWEEN 20001 AND 50000 THEN '4 (20-50)'
			   WHEN t.dolg BETWEEN 50001 AND 100000 THEN '5 (50-100)'
			   WHEN t.dolg > 100000 THEN N'более 100 тыс.р.'
		   END
		   AS 'Группа по сумме долга'
		, t.dolg + t.penalty_itog AS 'Задолженность с пени'
		, t.saldo AS 'Нач.сальдо'
		, t.Paid AS 'Начисленно'
		, t.PaymAccount AS 'Оплата'
		, t.penalty_itog AS 'Пени итог'
		, t.Initials AS 'ФИО'
		, t.STREETS + ' д. ' + t.nom_dom AS 'Адрес дома'
		, t.STREETS + ' ' + t.nom_dom + '-' + t.nom_kvr AS 'Адрес'
		, t.STREETS AS 'Улица'
		, t.nom_dom AS 'Номер дома'
		, t.nom_kvr AS 'Номер помещения'
		, t.div_name AS 'Район'
		, t.sector_name AS 'Участок'
		, vta.name AS 'Тип фонда'
		, t.proptype_id AS 'Тип собственности'
		, t.kol_people AS 'Кол-во граждан'
		, t.telephon AS 'Телефон'
		, t.total_sq AS 'Площадь'
		, t.KolMesCal AS 'Кол месяцев от послед.начисления'
		, t.LastPeriodValue AS 'Месяц посл.начисления'
		, t.last_paym_value AS 'Последняя оплата'
		, t.last_paym_day AS 'Последний день платежа'		
		, t.KolOccInBuild AS 'Лицевых в доме'
		, t.KolOccInFlats AS 'Лицевых в помещении'
		, t.kolmes_paym AS 'Месяцев от последней оплаты'
		, t.nom_dom_sort
		, t.nom_kvr_sort
		, (select top 1 [start_date] 
		from dbo.Calendar_period  
		where fin_id=gv.fin_id-round(t.kol_mes,0)) as 'Период начала долга'
	FROM #t t
	JOIN dbo.Global_values gv ON gv.fin_id=@fin_id1
	LEFT JOIN dbo.VOcc_types_all vta ON T.tip_id=vta.id and vta.fin_id=gv.fin_id
go

