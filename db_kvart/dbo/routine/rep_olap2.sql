CREATE   PROCEDURE [dbo].[rep_olap2]
(
	  @tip_id SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @build INT = NULL
	, @debug BIT = NULL
	, @sup_id INT = NULL
	, @tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
	, @serv_str1 VARCHAR(2000) = NULL -- список услуг через запятую
)
AS
/*
exec rep_olap2 @tip_id=28,@fin_id1=197,@fin_id2=197,@build=NULL,@debug=0,@sup_id=347
exec rep_olap2 @tip_id=131,@fin_id1=250,@fin_id2=250,@build=null,@debug=0,@sup_id=NULL
exec rep_olap2 @tip_id=1,@fin_id1=229,@fin_id2=229,@build=null,@debug=0,@sup_id=NULL,@tip_str1=null
exec rep_olap2 @tip_id=6,@fin_id1=250,@fin_id2=250,@build=null,@debug=0,@sup_id=NULL,@tip_str1='2,131', @serv_str1='гвод,хвод'
*/
BEGIN
	SET NOCOUNT ON;


	IF @tip_id IS NULL
		AND COALESCE(@tip_str1, '') = ''
		AND UPPER(DB_NAME()) <> 'NAIM'
		AND @build IS NULL
		SET @tip_id = -1

	IF @fin_id1 IS NULL
		SET @fin_id1 = 0

	IF @fin_id2 IS NULL
		AND @fin_id1 IS NOT NULL
		SET @fin_id2 = @fin_id1

	IF @fin_id1 = 0
		SET @fin_id2 = 0

	IF @fin_id1 > @fin_id2
		SET @fin_id2 = @fin_id1

	IF @serv_str1 = ''
		SET @serv_str1 = NULL

	IF @debug = 1
		SELECT @tip_id AS tip_id
			 , @tip_str1 AS tip_str1
			 , @build AS build
			 , @sup_id AS sup_id

	-- для ограничения доступа услуг
	DROP TABLE IF EXISTS #services;
	CREATE TABLE #services (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, short_name VARCHAR(50) COLLATE database_default
		, [name] VARCHAR(100) COLLATE database_default
		, is_build BIT
	)	
	INSERT INTO #services (id, short_name, name, is_build)
	SELECT id, short_name, name, is_build
	FROM dbo.services AS vs
		OUTER APPLY STRING_SPLIT(@serv_str1, ',') AS t
	WHERE @serv_str1 IS NULL OR t.value=vs.id
	
	--REGION Таблица со значениями Типа жил.фонда *********************
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	select tip_id from dbo.fn_get_tips_tf(@tip_str1, @tip_id, @build)
	IF @debug = 1 SELECT * FROM #tip_table
	--ENDREGION ************************************************************

	SELECT oh.start_date AS 'Период'
		 , p.fin_id AS 'КодПериода'
		 , b.id AS 'КодДома'
		 , T.name AS 'НаселенныйПункт'
		 , MIN(oh.tip_name) AS 'Тип фонда'
		 , MIN(d.name) AS 'Район'
		 , MIN(sec.name) AS 'Участок'
		 , st.name AS 'Улица'
		 , b.nom_dom AS 'Номер дома'
		 , (st.name + ' д.' + b.nom_dom) AS 'Адрес дома'
		 , oh.nom_kvr_prefix AS 'Квартира'
		 , CAST(oh.total_sq AS DECIMAL(9, 2)) AS 'Площадь'
		 , p.Occ AS 'Единый_Лицевой'
		 , CASE WHEN(p.sup_id > 0) THEN MIN(p.occ_sup_paym) ELSE dbo.Fun_GetFalseOccOut(p.Occ, oh.tip_id) END AS 'Лицевой'
		 --, dbo.Fun_Initials(p.Occ) AS 'ФИО'
		 , MIN(p1.Initials_people) AS 'ФИО сокр'
		 , MIN(p1.FIO) AS 'ФИО'
		   --,CASE WHEN(COALESCE(servt.service_name_full,'')='') THEN s.name ELSE servt.service_name_full END AS 'Услуга' -- заменяем наименования услуг по типам фонда
		 , CASE
			   --WHEN COALESCE(servb.service_name, '') <> '' 
			   --and COALESCE(servb.service_name, '') <> max(s.short_name) THEN servb.service_name
			   WHEN COALESCE(servt.service_name_full, '') <> '' THEN servt.service_name_full
			   ELSE s.name
		   END AS 'Услуга' -- заменяем наименования услуг по типам фонда
		 , MIN(s_kvit.service_name_kvit) AS 'Услуга в квитанции'
		 , p.service_id AS 'Код услуги'
		 , oh.flat_id AS 'Код квартиры'
		 , PT.name AS 'Тип собственности'
		 , RT.name AS 'Тип помещения'
		 , CASE WHEN(s.is_build = 1) THEN 'Общедомовая' ELSE 'Квартирная' END AS 'Тип услуги'
		 , CASE
			   WHEN p.is_counter = 1 THEN 'Внешний ИПУ'
			   WHEN p.is_counter = 2 THEN 'ИПУ'
			   ELSE 'Нет'
		   END AS 'Счетчик'
		 , CASE
			   WHEN p.metod = 0 THEN 'не начислять'
			   WHEN p.metod = 2 THEN 'по среднему'
			   WHEN p.metod = 3 THEN 'по счетчику'
			   WHEN p.metod = 4 THEN 'по домовому'
			   ELSE 'по норме'
		   END AS Метод
		 , CAST(p.tarif AS DECIMAL(12, 6)) AS 'Тариф'
		 , CAST(p.Koef AS DECIMAL(9, 6)) AS 'Коэффициент'
		 , p.subsid_only AS 'Внеш_услуга'
		 , CASE WHEN(p.account_one = 1) THEN 'Да' ELSE 'Нет' END AS 'Отд_квит'
		   --,bt.name AS 'Тип дома'
		 , (
			   SELECT bt.name
			   FROM dbo.Build_types AS bt 
			   WHERE MIN(b.build_type) = bt.id
		   ) AS 'Тип дома'
		 , CASE WHEN(MAX(b.build_total_sq) >= 1000) THEN 'более 1000м2' ELSE 'менее 1000м2' END AS 'Признак площади'
		 , SUM(p.SALDO - p.Paymaccount_Serv) AS 'Задолженность'
		 , CASE
			   WHEN SUM(p.SALDO - p.Paymaccount_Serv) > 0 THEN SUM(p.SALDO - p.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Задолженность без переплат'
		 , CASE WHEN(SUM(p.SALDO) < 0) THEN SUM(p.SALDO) ELSE 0 END AS 'Аванс'
		 , CAST(SUM(p.SALDO) AS MONEY) AS 'Сальдо'
		 , CAST(SUM(p.SALDO + p.Penalty_old + p.PaymAccount_peny) AS MONEY) AS 'Нач_сальдо с пени'
		   --, SUM(p.SALDO) + COALESCE((
		   --   SELECT (COALESCE(ph.Penalty_old,0) + COALESCE(ph.penalty_serv,0))
		   --   FROM dbo.Paym_history ph 
		   --   WHERE ph.fin_id = p.fin_id - 1
		   --	   AND ph.occ = p.occ
		   --	   AND ph.service_id = p.service_id
		   --	   AND ph.sup_id = p.sup_id
		   --  ), 0)
		   --  AS 'Нач_сальдо с пени2' -- неправильно, пени раскидывается на разные услуги и той услуги может не быть
		   --, SUM(p.SALDO) 
		   --	+ COALESCE(LAG(SUM(p.Penalty_old),1) OVER (PARTITION BY p.occ, p.service_id, p.sup_id ORDER BY p.fin_id),0)
		   --	+ COALESCE(LAG(SUM(p.penalty_serv),1) OVER (PARTITION BY p.occ, p.service_id, p.sup_id ORDER BY p.fin_id),0)
		   --		AS 'Нач_сальдо с пени2'
		 , SUM(p.SALDO + p.penalty_prev) AS 'Нач_сальдо с пени2'
		 , SUM(p.kol) AS 'Количество'
		 , SUM(p.Value) AS 'Начислено'

		 , (SUM(p.Added) - COALESCE(SUM(t_sub.Value), 0)) AS 'Разовые'
		 , CASE
			   WHEN (COALESCE(SUM(p.kol_added), 0)-COALESCE(SUM(t_sub.kol), 0)) <> 0 THEN (COALESCE(SUM(p.kol_added), 0)-COALESCE(SUM(t_sub.kol), 0))
			   WHEN p.tarif <= 0 THEN 0
			   ELSE (SUM(p.Added) - COALESCE(SUM(t_sub.Value), 0)) / p.tarif
		   END AS 'Кол_Разовых'
		 , (SUM(p.kol) +
						CASE
						    WHEN (COALESCE(SUM(p.kol_added), 0)-COALESCE(SUM(t_sub.kol), 0)) <> 0 THEN (COALESCE(SUM(p.kol_added), 0)-COALESCE(SUM(t_sub.kol), 0))
							WHEN tarif <= 0 THEN 0
							ELSE (SUM(p.added) - COALESCE(SUM(t_sub.value), 0)) / tarif
						END) AS 'Количество итог'	
		 , 0 AS 'Льгота'
		 , SUM(t_sub.Value) AS 'Субсидия'
		 , SUM(t_sub.kol) AS 'Кол_Субсидия'
		 , CAST(SUM(p.Paid) AS MONEY) AS 'Пост_Начисление'
		 , CAST(SUM(p.PaymAccount) AS MONEY) AS 'Оплачено'
		 , SUM(p.PaymAccount_peny) AS 'из_них_пени'
		 , SUM(p.Paymaccount_Serv) AS 'Оплата по услугам'
		 , CASE
			   WHEN (SUM(p.Paymaccount_Serv - p.Paid) >= SUM(p.SALDO)) AND
				   SUM(p.Paymaccount_Serv) > 0 AND
				   (SUM(p.SALDO) > 0) THEN SUM(p.SALDO)
			   WHEN SUM(p.Paymaccount_Serv - p.Paid - p.SALDO) > 0 AND
				   SUM(p.SALDO) > 0 AND
				   SUM(p.Paymaccount_Serv) > 0 THEN SUM(p.SALDO - p.Paid)
			   WHEN SUM(p.Paymaccount_Serv - p.Paid) > 0 AND
				   SUM(p.SALDO) > 0 AND
				   SUM(p.Paymaccount_Serv) > 0 THEN SUM(p.Paymaccount_Serv - p.Paid)
			   ELSE 0
		   END AS 'Оплата долга'
		 , CASE
			   WHEN SUM(p.Paid - p.Paymaccount_Serv) < 0 AND
				   SUM(p.Paymaccount_Serv) > 0 THEN SUM(p.Paid)
			   WHEN SUM(p.Paid - p.Paymaccount_Serv) >= 0 AND
				   SUM(p.Paymaccount_Serv) > 0 THEN SUM(p.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Текущая оплата'
		 , CASE
			   WHEN SUM(p.Paymaccount_Serv - p.Paid - p.SALDO) > 0 AND
				   SUM(p.Paymaccount_Serv) > 0 AND
				   SUM(p.SALDO) >= 0 THEN SUM(p.Paymaccount_Serv - p.Paid - p.SALDO)

			   WHEN SUM(p.Paymaccount_Serv - p.Paid - p.SALDO) > 0 AND
				   SUM(p.Paymaccount_Serv) > SUM(p.Paid) AND
				   SUM(p.SALDO) < 0 AND
				   SUM(p.Paymaccount_Serv) > 0 THEN SUM(p.Paymaccount_Serv - p.Paid)
			   ELSE 0
		   END AS 'Оплата авансом'
		 , CASE
			   WHEN SUM(p.Paymaccount_Serv) < 0 THEN SUM(p.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Отрицательная оплата'
		 , CAST(SUM(p.Debt) AS MONEY) AS 'Кон_Сальдо'
		 , CAST(SUM(p.Debt + p.Penalty_old + p.penalty_serv) AS MONEY) AS 'Кон_Сальдо с пени'
		 , SUM(p.Penalty_old + p.PaymAccount_peny) AS 'Пени старое'
		 , SUM(p.Penalty_old) AS 'Пени старое изм'
		 , SUM(p.penalty_serv) AS 'Пени новое'
		 , SUM(p.Penalty_old + p.penalty_serv) AS 'Пени итог'
		 , SUM(p.Paid + p.penalty_serv) AS 'Пост_Начисление с пени'
		 , MIN(kol_norma_single) AS 'Норматив'
		 , CASE WHEN(COALESCE(p.metod, 1) NOT IN (3, 4)) THEN SUM(p.kol) ELSE 0 END AS 'Объём по норме'
		 , CASE WHEN(p.metod = 3) THEN SUM(p.kol) ELSE 0 END AS 'Объём по ИПУ'
		 , CASE WHEN(p.metod = 4) THEN SUM(p.kol) ELSE 0 END AS 'Объём по ОПУ'
		 , MIN(COALESCE(t_ipu.kol_ipu, 0)) AS 'Кол-во ИПУ'
		 , oh.kol_people AS 'Кол-во граждан'
		 , MAX(p.date_start) AS 'Дата начала'
		 , MAX(p.date_end) AS 'Дата окончания'
		 , MAX(p.koef_day) AS 'Коэф_Дней'
		 , MIN(sa1.name) AS 'Поставщик'
		 , MIN(sa2.name) AS 'Поставщик услуги'
		 , MIN(cm.name) AS 'Режим услуги'
		 , MIN(b.levels) AS 'Этажей в доме'
		 , CASE WHEN(oh.total_sq = 0) THEN 'Нет' ELSE 'Да' END AS 'Площадь есть'
		 , CASE WHEN(b.is_paym_build = 1) THEN 'Да' ELSE 'Нет' END AS 'Начисляем по дому'
		 , oh.nom_kvr_sort
		 , b.nom_dom_sort
		 , CONCAT(st.name, b.nom_dom_sort) AS sort_dom
		 , MAX(oh.id_els_gis) AS 'ЕЛС ГИС ЖКХ'
		 , MAX(oh.id_jku_gis) AS 'УИ ГИС ЖКХ'
	--INTO #t
	FROM dbo.View_paym AS p 
		JOIN dbo.View_occ_all_lite AS oh ON 
			oh.Occ = p.Occ
			AND oh.fin_id = p.fin_id
		JOIN #tip_table tt ON 
			oh.tip_id = tt.tip_id
		JOIN dbo.Buildings AS b ON 
			oh.bldn_id = b.id
		JOIN #services AS s ON 
			p.service_id = s.id -- vs.id=s.id
		LEFT JOIN dbo.View_services_kvit AS s_kvit ON 
			oh.tip_id = s_kvit.tip_id 
			AND oh.build_id = s_kvit.build_id
			AND p.service_id = s_kvit.service_id
		JOIN dbo.VStreets AS st ON 
			b.street_id = st.id
		LEFT JOIN dbo.Towns AS T ON 
			b.town_id = T.id
		LEFT JOIN dbo.Property_types AS PT ON 
			oh.proptype_id = PT.id
		LEFT JOIN dbo.Room_types AS RT ON 
			oh.roomtype_id = RT.id
		LEFT JOIN dbo.Suppliers_all sa1 ON 
			p.sup_id = sa1.id
		LEFT JOIN dbo.Suppliers sa2 ON 
			p.source_id = sa2.id
		LEFT JOIN dbo.Cons_modes cm ON 
			p.mode_id = cm.id
		LEFT JOIN dbo.Divisions d ON 
			b.div_id = d.id
		LEFT JOIN dbo.Sector sec ON 
			b.sector_id = sec.id
		LEFT JOIN dbo.Services_types AS servt ON 
			servt.service_id = s.id
			AND servt.tip_id = tt.tip_id
		LEFT JOIN dbo.Services_build AS servb ON 
			servb.service_id = s.id
			AND servb.build_id = oh.build_id
		OUTER APPLY (
			SELECT TOP(1) 
				CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.') AS Initials_people, 
				CONCAT(RTRIM(Last_name), ' ', RTRIM(First_name), ' ', RTRIM(Second_name)) AS FIO -- на некоторых лицевых 2 отвл
			FROM dbo.People WHERE oh.occ=occ AND Fam_id='отвл' AND Del=0  
			) AS p1
		CROSS APPLY (
			SELECT SUM(va.Value) AS Value
				,SUM(va.kol) AS kol
			FROM dbo.View_added_lite va
			WHERE va.fin_id = p.fin_id
				AND va.Occ = p.Occ
				AND va.service_id = p.service_id
				AND va.sup_id = p.sup_id
				AND va.add_type = 15
		) AS t_sub

		CROSS APPLY (
			SELECT COUNT(id) AS kol_ipu
			FROM dbo.Counters C 
			WHERE C.flat_id = oh.flat_id
				AND C.service_id = p.service_id
				AND C.date_del IS NULL
		) AS t_ipu

	WHERE 
		p.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@build IS NULL OR b.id = @build)
		AND (@sup_id IS NULL OR p.sup_id = @sup_id)

	GROUP BY oh.start_date
		   , p.fin_id
		   , b.id
		   , T.name
		   , oh.tip_id
		   , st.name
		   , b.nom_dom
		   , b.nom_dom_sort
		   , b.is_paym_build
		   , oh.nom_kvr_prefix
		   , oh.nom_kvr_sort
		   , oh.flat_id
		   , oh.kol_people
		   , PT.name
		   , RT.name
		   , oh.total_sq
		   , p.Occ
		   , s.name
		   , s.is_build
		   , servb.service_name
		   , servt.service_name_full
		   , p.sup_id
		   , p.metod
		   , p.is_counter
		   , p.tarif
		   , p.Koef
		   , p.subsid_only
		   , p.service_id
		   , p.account_one
	
	OPTION (RECOMPILE)
	--OPTION (OPTIMIZE FOR UNKNOWN)

END
go

