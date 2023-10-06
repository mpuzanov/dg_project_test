-- =============================================
-- Author:		Пузанов
-- Create date: 11.02.2011
-- Description:	Аналитика по домам
-- =============================================
CREATE          PROCEDURE [dbo].[rep_olap1]
(
	  @build INT = NULL
	, @fin_id1 SMALLINT
	, @fin_id2 SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @sup_id INT = NULL
	, @debug BIT = NULL
	, @tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
	, @serv_str1 VARCHAR(2000) = NULL -- список услуг через запятую
)
AS
/*

exec rep_olap1 @build=1047, @fin_id1=197, @fin_id2=197, @tip_id=28, @sup_id=323, @serv_str1='лифт', @debug=1
exec rep_olap1 @build=null, @fin_id1=230, @fin_id2=230, @tip_id=1, @sup_id=345
exec rep_olap1 @build=null, @fin_id1=230, @fin_id2=230, @tip_id=2, @sup_id=NULL, @serv_str1='гвод'

*/
BEGIN
	SET NOCOUNT ON;


	IF @fin_id1 = 0
		SET @fin_id2 = 0

	IF @fin_id2 IS NULL
		AND @fin_id1 IS NOT NULL
		SET @fin_id2 = @fin_id1

	IF @serv_str1 = ''
		SET @serv_str1 = NULL

	IF @tip_id IS NULL
		AND COALESCE(@tip_str1, '') = ''
		AND UPPER(DB_NAME()) <> 'NAIM'
		AND @build IS NULL
		SET @tip_id = -1

	IF @debug = 1
		SELECT @tip_id AS tip_id
			 , @tip_str1 AS tip_str1
			 , @build AS build
			 , @sup_id AS sup_id

	-- для ограничения доступа услуг
	CREATE TABLE #services (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, short_name VARCHAR(50) COLLATE database_default
		, [name] VARCHAR(100) COLLATE database_default
		, is_build BIT
	)
	INSERT INTO #services (id, short_name, name, is_build)
	SELECT vs.id, vs.short_name, vs.name, vs.is_build
	FROM dbo.services AS vs
		OUTER APPLY STRING_SPLIT(@serv_str1, ',') AS t
	WHERE @serv_str1 IS NULL OR t.value=vs.id

	--CREATE UNIQUE INDEX SERV ON #services (id)

	--REGION Таблица со значениями Типа жил.фонда *********************
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	select tip_id from dbo.fn_get_tips_tf(@tip_str1, @tip_id, @build)
	--ENDREGION ************************************************************

	IF @debug = 1
	BEGIN
		SELECT @build AS build
			 , @fin_id1 AS fin_id1
			 , @fin_id2 AS fin_id2
		SELECT '@tip_table'
			 , *
		FROM #tip_table
	END

	SELECT oh.start_date AS 'Период'
		 , b.id AS 'КодДома'
		 , T.name AS 'НаселенныйПункт'
		 , MIN(oh.tip_name) AS 'Тип фонда'
		 , st.name AS 'Улица'
		 , b.nom_dom AS 'Номер дома'
		 , CONCAT(st.name, ' д.', b.nom_dom) AS 'Адрес дома'
		 , oh.nom_kvr_prefix AS 'Квартира'
		 , p.occ AS 'Единый_Лицевой'
		 , CASE WHEN(p.sup_id > 0) THEN MIN(p.occ_sup_paym) ELSE dbo.Fun_GetFalseOccOut(p.occ, oh.tip_id) END AS 'Лицевой'
		   --, dbo.Fun_Initials(p.Occ) AS 'ФИО'
		 , MIN(p1.Initials_people) AS 'ФИО сокр'
		 , MIN(p1.FIO) AS 'ФИО'
		 , MIN(sa1.name) AS 'Поставщик'
		 , MIN(sa2.name) AS 'Поставщик услуги'
		 , MIN(cm.name) AS 'Режим услуги'
		 , CASE
			   --WHEN COALESCE(servb.service_name, '') <> '' 
			   --and COALESCE(servb.service_name, '') <> max(s.short_name) THEN servb.service_name
			   WHEN COALESCE(servt.service_name_full, '') <> '' THEN servt.service_name_full -- заменяем наименования услуг по типам фонда
			   ELSE s.name
		   END AS 'Услуга'
		 , MIN(s_kvit.service_name_kvit) AS 'Услуга в квитанции'
		 , oh.flat_id AS 'Код квартиры'
		 , PT.name AS 'Тип собственности'
		 , RT.name AS 'Тип помещения'
		 , CAST(oh.total_sq AS DECIMAL(9, 2)) AS 'Площадь'
		 , oh.kol_people AS 'Кол-во граждан'
		 , CASE s.is_build
			   WHEN 1 THEN 'Общедомовая'
			   ELSE 'Квартирная'
		   END AS 'Тип услуги'
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
		 , CAST(MAX(p.koef) AS DECIMAL(9, 6)) AS 'Коэффициент'
		 , p.subsid_only AS 'Внеш_услуга'
		 , SUM(p.saldo - p.paymaccount_serv) AS 'Задолженность'
		 , CAST(SUM(p.saldo) AS MONEY) AS 'Сальдо'
		 , CAST(SUM(p.saldo + COALESCE(p.penalty_old, 0) + p.paymaccount_peny) AS MONEY) AS 'Нач_сальдо с пени'

		 , SUM(p.saldo + p.penalty_prev) AS 'Нач_сальдо с пени2'
		 , CASE
			   WHEN SUM(p.saldo - p.paymaccount_serv) > 0 THEN SUM(p.saldo - p.paymaccount_serv)
			   ELSE 0
		   END AS 'Задолженность без переплат'
		 , CASE
			   WHEN SUM(p.saldo) < 0 THEN SUM(p.saldo)
			   ELSE 0
		   END 'Аванс'
		 , SUM(p.kol) AS 'Количество'
		 , MIN(u.name) AS 'Ед. измерения'
		 , CAST(SUM(p.value) AS MONEY) AS 'Начислено'
		 , (SUM(p.added) -
		   COALESCE(SUM(t_sub.value), 0)) AS 'Разовые'
		 , CASE
			   WHEN (COALESCE(SUM(p.kol_added), 0)-COALESCE(SUM(t_sub.kol),0)) <> 0 THEN SUM(p.kol_added)-COALESCE(SUM(t_sub.kol),0)
			   WHEN tarif <= 0 THEN 0
			   ELSE (SUM(p.added) - COALESCE(SUM(t_sub.value), 0)) / tarif
		   END AS 'Кол_Разовых'		 
		 , (SUM(p.kol) +
						CASE
							WHEN (COALESCE(SUM(p.kol_added), 0)-COALESCE(SUM(t_sub.kol),0)) <> 0 THEN SUM(p.kol_added)-COALESCE(SUM(t_sub.kol),0)
							WHEN tarif <= 0 THEN 0
							ELSE (SUM(p.added) - COALESCE(SUM(t_sub.value), 0)) / tarif
						END
			) AS 'Количество итог'
		 , 0 AS 'Льгота'
		 , SUM(t_sub.value) AS 'Субсидия'
		 , CASE
			   WHEN SUM(t_sub.kol)<>0 THEN SUM(t_sub.kol)
			   WHEN tarif <= 0 THEN 0
			   ELSE SUM(t_sub.value) / tarif
		   END AS 'Кол_Субсидия'
		 , CAST(SUM(p.paid) AS MONEY) AS 'Пост_Начисление'
		 , CAST(SUM(p.paymaccount) AS MONEY) AS 'Оплачено'
		 , CAST(SUM(p.paymaccount_peny) AS MONEY) AS 'из_них_пени'
		 , CAST(SUM(p.paymaccount_serv) AS MONEY) AS 'Оплата по услугам'
		 , CASE
			   WHEN (SUM(p.paymaccount_serv - p.paid) >= SUM(p.saldo)) AND
				   SUM(p.paymaccount_serv) > 0 AND
				   (SUM(p.saldo) > 0) THEN SUM(p.saldo)
			   WHEN SUM(p.paymaccount_serv - p.paid - p.saldo) > 0 AND
				   SUM(p.saldo) > 0 AND
				   SUM(p.paymaccount_serv) > 0 THEN SUM(p.saldo - p.paid)
			   WHEN SUM(p.paymaccount_serv - p.paid) > 0 AND
				   SUM(p.saldo) > 0 AND
				   SUM(p.paymaccount_serv) > 0 THEN SUM(p.paymaccount_serv - p.paid)
			   ELSE 0
		   END AS 'Оплата долга'
		 , CASE
			   WHEN SUM(p.paid - p.paymaccount_serv) < 0 AND
				   SUM(p.paymaccount_serv) > 0 THEN SUM(p.paid)
			   WHEN SUM(p.paid - p.paymaccount_serv) >= 0 AND
				   SUM(p.paymaccount_serv) > 0 THEN SUM(p.paymaccount_serv)
			   ELSE 0
		   END AS 'Текущая оплата'
		 , CASE
			   WHEN SUM(p.paymaccount_serv - p.paid - p.saldo) > 0 AND
				   SUM(p.paymaccount_serv) > 0 AND
				   SUM(p.saldo) >= 0 THEN SUM(p.paymaccount_serv - p.paid - p.saldo)

			   WHEN SUM(p.paymaccount_serv - p.paid - p.saldo) > 0 AND
				   SUM(p.paymaccount_serv) > SUM(p.paid) AND
				   SUM(p.saldo) < 0 AND
				   SUM(p.paymaccount_serv) > 0 THEN SUM(p.paymaccount_serv - p.paid)
			   ELSE 0
		   END AS 'Оплата авансом'
		 , CASE
			   WHEN SUM(p.paymaccount_serv) < 0 THEN SUM(p.paymaccount_serv)
			   ELSE 0
		   END AS 'Отрицательная оплата'
		 , CAST(SUM(p.debt) AS MONEY) AS 'Кон_Сальдо'
		 , CAST(SUM(p.debt + p.penalty_old + p.penalty_serv) AS MONEY) AS 'Кон_Сальдо с пени'
		 , SUM(p.penalty_old + p.paymaccount_peny) AS 'Пени старое'
		 , SUM(p.penalty_old) AS 'Пени старое изм'
		 , SUM(p.penalty_serv) AS 'Пени новое'
		 , SUM(p.penalty_old + p.penalty_serv) AS 'Пени итог'
		 , SUM(p.paid + p.penalty_serv) AS 'Пост_Начисление с пени'
		 , CASE WHEN COALESCE(p.metod, 1) NOT IN (3, 4) THEN SUM(p.kol) ELSE 0 END AS 'Объём по норме'
		 , CASE WHEN p.metod = 3 THEN SUM(p.kol) ELSE 0 END AS 'Объём по ИПУ'
	     , CASE WHEN p.metod = 4 THEN SUM(p.kol) ELSE 0 END AS 'Объём по ОПУ'
		 , MAX(COALESCE(t_ipu.kol_ipu, 0)) AS 'Кол-во ИПУ'
		 , MAX(kol_norma_single) AS 'Норматив'
		 , MAX(p.date_start) AS 'Дата начала'
		 , MAX(p.date_end) AS 'Дата окончания'
		 , MAX(p.koef_day) AS 'Коэф_Дней'
		 , p.fin_id AS 'КодПериода'
		 , MAX(b.levels) AS 'Этажей в доме'
		 , CASE WHEN(oh.total_sq = 0) THEN 'Нет' ELSE 'Да' END AS 'Площадь есть'
		 , CASE WHEN(b.is_paym_build = 1) THEN 'Да' ELSE 'Нет' END AS 'Начисляем по дому'
		 , SUM(p.kol_norma) AS kol_norma
		 , MAX(oh.id_els_gis) AS 'ЕЛС ГИС ЖКХ'
		 , MAX(oh.id_jku_gis) AS 'УИ ГИС ЖКХ'
		 , MAX(p.metod_old_name) AS metod_old_name
		 , CONCAT(st.name, b.nom_dom_sort) AS sort_dom
		 , b.nom_dom_sort
		 , oh.nom_kvr_sort		 		 		 
	FROM dbo.View_paym AS p 
		JOIN dbo.View_occ_all_lite AS oh 
			ON oh.occ = p.occ
			AND oh.fin_id = p.fin_id
		JOIN #tip_table tt 
			ON oh.tip_id = tt.tip_id
		JOIN dbo.Buildings AS b 
			ON oh.bldn_id = b.id
		JOIN #services AS s ON 
			p.service_id = s.id
		LEFT JOIN dbo.View_services_kvit AS s_kvit ON 
			oh.tip_id = s_kvit.tip_id 
			AND oh.build_id = s_kvit.build_id
			AND p.service_id = s_kvit.service_id
		JOIN dbo.VStreets AS st 
			ON b.street_id = st.id
		JOIN dbo.Towns AS T 
			ON b.town_id = T.id
		JOIN dbo.Property_types AS PT 
			ON oh.proptype_id = PT.id
		LEFT JOIN dbo.Room_types AS RT 
			ON oh.roomtype_id = RT.id
		LEFT JOIN dbo.Suppliers_all sa1 
			ON p.sup_id = sa1.id
		LEFT JOIN dbo.Suppliers sa2 
			ON p.source_id = sa2.id
		LEFT JOIN dbo.Cons_modes cm 
			ON p.mode_id = cm.id
		LEFT JOIN dbo.Services_types AS servt
			ON servt.service_id = s.id
			AND servt.tip_id = tt.tip_id
		LEFT JOIN dbo.Services_build AS servb 
			ON servb.service_id = s.id
			AND servb.build_id = oh.build_id
		LEFT JOIN dbo.Units AS u 
			ON u.id = p.unit_id
		OUTER APPLY (
			SELECT TOP (1) 
				CONCAT(RTRIM([Last_name]),' ',LEFT([First_name],1),'. ',LEFT(Second_name,1),'.') AS Initials_people, 
				CONCAT(RTRIM([Last_name]), ' ', RTRIM([First_name]), ' ', RTRIM([Second_name])) AS FIO
			FROM dbo.People 
			WHERE oh.occ = occ
				AND Fam_id = 'отвл'
				AND Del = CAST(0 AS BIT)
		) AS p1
		CROSS APPLY (
			SELECT SUM(va.Value) AS Value
				,SUM(va.kol) AS kol
			FROM dbo.View_added_lite va 
			WHERE va.fin_id = p.fin_id
				AND va.occ = p.occ
				AND va.service_id = p.service_id
				AND va.sup_id = p.sup_id
				AND va.add_type = 15
		) AS t_sub

		CROSS APPLY (
			SELECT COUNT(id) AS kol_ipu
			FROM dbo.Counters c
			WHERE c.flat_id = oh.flat_id
				AND c.service_id = p.service_id
				AND c.date_del IS NULL
		) AS t_ipu
	WHERE 
		p.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@build IS NULL OR b.id = @build)
		AND (@sup_id IS NULL OR p.sup_id = @sup_id)
	GROUP BY oh.start_date
		   , p.fin_id
		   , T.name
		   , oh.tip_id
		   , st.name
		   , b.id
		   , b.nom_dom
		   , b.nom_dom_sort
		   , b.is_paym_build
		   , oh.flat_id
		   , oh.nom_kvr_prefix
		   , oh.nom_kvr_sort
		   , p.occ
		   , oh.total_sq
		   , oh.kol_people
		   , s.name
		   , servb.service_name
		   , servt.service_name_full
		   , s.is_build
		   , p.metod
		   , PT.name
		   , RT.name
		   , oh.kol_people
		   , p.is_counter
		   , p.tarif
		   , p.subsid_only
		   , p.service_id
		   , p.sup_id
	OPTION (RECOMPILE)
END
go

