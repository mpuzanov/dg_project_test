CREATE   PROCEDURE [dbo].[rep_olap2_itog]
(
	  @tip_id SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @build INT = NULL
	, @debug BIT = NULL
	, @sup_id INT = NULL
	, @tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
)
AS
	/*
  	
  	Аналитика по лиц.счетам
  	
  	exec rep_olap2_itog @tip_id=131,@fin_id1=165,@fin_id2=165,@build=0,@debug=0,@tip_str1=NULL
  	exec rep_olap2_itog @tip_id=28,@fin_id1=165,@fin_id2=165,@build=0,@debug=0,@tip_str1=NULL
  	exec rep_olap2_itog @tip_id=27,@fin_id1=165,@fin_id2=165,@build=0,@debug=0,@tip_str1=NULL
  	exec rep_olap2_itog @tip_id=1,@fin_id1=230,@fin_id2=230,@build=0,@debug=0,@tip_str1=NULL
  	exec rep_olap2_itog @tip_id=1,@fin_id1=230,@fin_id2=230,@build=0,@debug=0, @sup_id=345, @tip_str1='1'
  	
  	*/
	SET NOCOUNT ON

	IF @fin_id1 IS NULL
		SET @fin_id1 = 0

	IF @fin_id2 IS NULL
		AND @fin_id1 IS NOT NULL
		SET @fin_id2 = @fin_id1

	IF @fin_id1 = 0
		SET @fin_id2 = 0

	IF @fin_id1 > @fin_id2
		SET @fin_id2 = @fin_id1

	IF @build = 0
		SET @build = NULL

	IF @tip_id IS NULL
		AND COALESCE(@tip_str1, '') = ''
		AND UPPER(DB_NAME()) <> 'NAIM'
		AND @build IS NULL
		SET @tip_id = -1
	--************************************************************************************
	--REGION Таблица со значениями Типа жил.фонда *********************
	DROP TABLE IF EXISTS #tip_table;
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	select tip_id from dbo.fn_get_tips_tf(@tip_str1, @tip_id, @build)
	IF @debug = 1 SELECT * FROM #tip_table
	--ENDREGION ************************************************************

	SELECT oh.start_date AS 'Период'
		 , oh.Occ AS 'Единый_Лицевой'
		 , dbo.Fun_GetFalseOccOut(oh.Occ, oh.tip_id) AS 'Лицевой'
		 , CAST(NULL AS INT) AS 'Лицевой поставщика'
		 , T.name AS 'Населенный пункт'
		 , d.name AS 'Район'
		 , oh.tip_name AS 'Тип фонда'
		 , MAX(sec.name) AS 'Участок'
		 , st.short_name AS 'Улица'
		 , b.nom_dom AS 'Номер дома'
		 , CONCAT(st.short_name, ' д.', b.nom_dom) AS 'Адрес дома'
		 , oh.nom_kvr AS 'Квартира'
		 , dbo.Fun_Initials(oh.Occ) AS 'ФИО сокр'
		 , dbo.Fun_InitialsFull(oh.Occ) AS 'ФИО'
		 , CAST(oh.total_sq AS DECIMAL(9, 2)) AS 'Площадь'
		 , oh.kol_people AS 'Кол-во граждан'
		 , PT.name AS 'Тип собственности'
		 , RT.name AS 'Тип помещения'
		 , CASE
			   WHEN oh.status_id = 'откр' THEN 'Открыт'
			   WHEN oh.status_id = 'своб' THEN 'Свободен'
			   ELSE 'Закрыт'
		   END AS 'Статус лицевого'
		 , CAST('' AS VARCHAR(30))                              AS 'Поставщик'
		 , SUM(oh.SALDO)                                        AS 'Сальдо'
		 , SUM(oh.SALDO + oh.Penalty_old)                       AS 'Нач_сальдо с пени'
		 , SUM(oh.Value)                                        AS 'Начислено'
		 , SUM(oh.Added - COALESCE(ap_sub.val, 0))              AS 'Разовые'
		 , SUM(COALESCE(ap_sub.val, 0))                         AS 'Субсидия'
		 , SUM(oh.Paid + oh.Paid_minus)                         AS 'Пост_Начисление'
		 , SUM(oh.PaymAccount)                                  AS 'Оплачено'
		 , SUM(oh.PaymAccount_peny)                             AS 'из_них_пени'
		 , SUM(oh.Paymaccount_Serv)                             AS 'Оплата по услугам'
		 , SUM(CASE
                   WHEN oh.SALDO < 0 THEN oh.SALDO * -1
                   ELSE 0
        END)                                                    AS 'Аванс'
		 , SUM(CASE
                   WHEN oh.SALDO > 0 THEN oh.SALDO
                   ELSE 0
        END)                                                    AS 'Дебет Вх_сальдо'
		 , SUM(CASE
                   WHEN oh.SALDO < 0 THEN -1 * oh.SALDO
                   ELSE 0
        END)                                                    AS 'Кредит Вх_сальдо'
		 , SUM(oh.Debt)                                         AS 'Кон_Сальдо'
		 , SUM(oh.Debt + oh.Penalty_old_new + oh.Penalty_value) AS 'Кон_Сальдо с пени'
		 , SUM(CASE
                   WHEN oh.Debt > 0 THEN oh.Debt
                   ELSE 0
        END)                                                    AS 'Дебет Кон_Сальдо'
		 , SUM(CASE
                   WHEN oh.Debt < 0 THEN -1 * oh.Debt
                   ELSE 0
        END)                                                    AS 'Кредит Кон_Сальдо'
		 , COALESCE((
			   SELECT TOP (1) COALESCE(sum_new, 0) - COALESCE(sum_old, 0)
			   FROM dbo.Penalty_log pl 
			   WHERE pl.fin_id = oh.fin_id
				   AND pl.Occ = oh.Occ
		   ), 0)                                                AS 'Пени ручн.изм.'
		 , SUM(oh.Penalty_old)                                  AS 'Пени старое'
		 , SUM(oh.Penalty_old_new) AS 'Пени старое изм'
		 , SUM(oh.Penalty_added) AS 'Пени разовые'
		 , SUM(oh.Penalty_value) AS 'Пени нов'
		 , SUM(oh.Penalty_itog) AS 'Пени итог'
		 , SUM(oh.Paid + oh.Paid_minus + oh.Penalty_added + oh.Penalty_value) AS 'Пост_Начисление с пени'
		 , SUM(oh.Whole_payment) AS 'К оплате'
		 , SUM(oh.Whole_payment_minus * -1) AS 'К оплате(кредит)'
		 , SUM(oh.Whole_payment + oh.Whole_payment_minus) AS 'К оплате(итого)'
		 , SUM(oh.SALDO - oh.Paymaccount_Serv) AS 'Задолженность'
		   --/////////////////////////////////////////////////////////////////////			
		 , CASE
			   WHEN SUM(oh.SALDO - oh.Paymaccount_Serv) > 0 THEN SUM(oh.SALDO - oh.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Задолженность без переплат'
		 , CASE
			   WHEN (SUM(oh.Paymaccount_Serv - oh.PaidItog) >= SUM(oh.SALDO)) AND
				   SUM(oh.Paymaccount_Serv) > 0 AND
				   (SUM(oh.SALDO) > 0) THEN SUM(oh.SALDO)
			   WHEN SUM(oh.Paymaccount_Serv - oh.PaidItog - oh.SALDO) > 0 AND
				   SUM(oh.SALDO) > 0 AND
				   SUM(oh.Paymaccount_Serv) > 0 THEN SUM(oh.SALDO - oh.PaidItog)
			   WHEN SUM(oh.Paymaccount_Serv - oh.PaidItog) > 0 AND
				   SUM(oh.SALDO) > 0 AND
				   SUM(oh.Paymaccount_Serv) > 0 THEN SUM(oh.Paymaccount_Serv - oh.PaidItog)
			   ELSE 0
		   END AS 'Оплата долга'
		 , CASE
			   WHEN SUM(oh.PaidItog - oh.Paymaccount_Serv) < 0 AND
				   SUM(oh.Paymaccount_Serv) > 0 THEN SUM(oh.PaidItog)
			   WHEN SUM(oh.PaidItog - oh.Paymaccount_Serv) >= 0 AND
				   SUM(oh.Paymaccount_Serv) > 0 THEN SUM(oh.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Текущая оплата'
		 , CASE
			   WHEN SUM(oh.Paymaccount_Serv - oh.PaidItog - oh.SALDO) > 0 AND
				   SUM(oh.Paymaccount_Serv) > 0 AND
				   SUM(oh.SALDO) >= 0 THEN SUM(oh.Paymaccount_Serv - oh.PaidItog - oh.SALDO)

			   WHEN SUM(oh.Paymaccount_Serv - oh.PaidItog - oh.SALDO) > 0 AND
				   SUM(oh.Paymaccount_Serv) > SUM(oh.PaidItog) AND
				   SUM(oh.SALDO) < 0 AND
				   SUM(oh.Paymaccount_Serv) > 0 THEN SUM(oh.Paymaccount_Serv - oh.PaidItog)
			   ELSE 0
		   END AS 'Оплата авансом'
		 , CASE
			   WHEN SUM(oh.Paymaccount_Serv) < 0 THEN SUM(oh.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Отрицательная оплата'
		 , CASE
			   WHEN SUM(oh.PaidItog - oh.Paymaccount_Serv) > 0 THEN SUM(oh.PaidItog - oh.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Сальдо за период дебет'
		 , CASE
			   WHEN SUM(oh.PaidItog - oh.Paymaccount_Serv) < 0 THEN -1 * SUM(oh.PaidItog - oh.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Сальдо за период кредит'
		 , SUM(oh.PaidItog - oh.Paymaccount_Serv) AS 'Сальдо за период'
		   --/////////////////////////////////////////////////////////////////////								
		 , MIN(oh.nom_kvr_sort) AS nom_kvr_sort
		 , MIN(b.nom_dom_sort) AS nom_dom_sort
		 , MIN(st.short_name  + b.nom_dom_sort) AS sort_dom
		 , oh.flat_id AS 'Код квартиры'
		 , b.id AS 'Код дома'
		 , MIN(o2.id_jku_gis) AS 'Уникальный идентификатор ГИС ЖКХ'
		 , MIN(o2.id_els_gis) AS 'ЕЛС ГИС ЖКХ'
		 , MIN(o2.id_nom_gis) AS 'Уникальный номер помещения ГИС ЖКХ'
		 , CAST('' AS VARCHAR(20)) AS 'Расчётный счёт'
		 , MAX(b.levels) AS 'Этажей в доме'
		 , MAX(ops.name) AS 'ОПС'
		 , MAX(oh.KolMesDolg) AS 'Кол-во мес долга'
		 , CASE
               WHEN oh.total_sq = 0 THEN 'Нет'
               ELSE 'Да'
        END AS 'Площадь есть'
		 , MAX(o2.date_create) AS 'Дата создания лицевого'
		 , CASE
               WHEN b.is_paym_build = 1 THEN 'Да'
               ELSE 'Нет'
        END AS 'Начисляем по дому'
		 , CASE
               WHEN SUM(oh.Paid + oh.Paid_minus) <> 0 THEN 'Есть'
               ELSE 'Нет'
        END AS 'Признак начислений'
		 , CASE
               WHEN oh.penalty_calc = 1 THEN 'Да'
               ELSE 'Нет'
        END AS 'Признак расч. пени'
		 , MAX(COALESCE(o2.schtl_old,'')) AS 'Стар_Лицевой(текст)'
		 , MAX(o2.telephon) AS 'Телефон'
		 , MAX(o2.email) AS 'Эл.почта'
	INTO #table1
	FROM dbo.View_occ_all AS oh 
		JOIN #tip_table tt ON 
			oh.tip_id = tt.tip_id
		JOIN dbo.Buildings AS b ON 
			oh.bldn_id = b.id
		JOIN dbo.VStreets AS st ON 
			b.street_id = st.id
		JOIN dbo.Towns AS T ON 
			b.town_id = T.id
		LEFT JOIN dbo.Divisions AS d ON 
			b.div_id = d.id
		LEFT JOIN dbo.Sector sec ON 
			b.sector_id = sec.id
		JOIN dbo.Property_types AS PT ON 
			oh.proptype_id = PT.id
		JOIN dbo.Room_types AS RT ON 
			oh.roomtype_id = RT.id
		JOIN dbo.Occupations o2 ON 
			oh.Occ = o2.Occ
		LEFT JOIN dbo.ops ops ON 
			b.index_id = ops.id
		CROSS APPLY (
			SELECT SUM(va.value) AS val
			FROM dbo.View_added va
			WHERE va.fin_id = oh.fin_id
				AND va.occ = oh.occ
				AND va.add_type = 15
		) AS ap_sub
	WHERE 
		oh.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@build IS NULL OR oh.bldn_id = @build)
		AND (COALESCE(@sup_id,0)=0)
		AND oh.status_id <> 'закр'

	GROUP BY oh.start_date
		   , oh.fin_id
		   , T.name
		   , d.name
		   , oh.tip_id
		   , oh.tip_name
		   , st.short_name
		   , b.nom_dom
		   , b.id
		   , b.is_paym_build
		   , oh.nom_kvr
		   , oh.flat_id
		   , oh.Occ
		   , oh.status_id
		   , oh.total_sq
		   , oh.kol_people
		   , oh.penalty_calc
		   , PT.name
		   , RT.name
		   , oh.nom_kvr_sort
		   , b.nom_dom_sort

	--////////  По поставщикам

	INSERT #table1
	SELECT oh.start_date AS 'Период'
		 , oh.Occ AS 'Лицевой_Единый'
		 , os.occ_sup AS 'Лицевой'
		 , os.occ_sup AS 'Лицевой поставщика'
		 , T.name AS 'Населенный пункт'
		 , d.name AS 'Район'
		 , oh.tip_name AS 'Тип фонда'
		 , MAX(sec.name) AS 'Участок'
		 , st.short_name AS 'Улица'
		 , b.nom_dom AS 'Номер дома'
		 , (st.short_name + ' д.' + b.nom_dom) AS 'Адрес дома'
		 , oh.nom_kvr AS 'Квартира'
		 , dbo.Fun_Initials(oh.Occ) AS 'ФИО сокр'
		 , dbo.Fun_InitialsFull(oh.Occ) AS 'ФИО'
		 , CAST(oh.total_sq AS DECIMAL(9, 2)) AS 'Площадь'
		 , oh.kol_people AS 'Кол-во граждан'
		 , PT.name AS 'Тип собственности'
		 , RT.name AS 'Тип помещения'
		 , CASE
			   WHEN oh.status_id = 'откр' THEN 'Открыт'
			   WHEN oh.status_id = 'своб' THEN 'Свободен'
			   ELSE 'Закрыт'
		   END AS 'Статус лицевого'
		 , sa.name                                                                        AS 'Поставщик'
		 , SUM(os.SALDO)                                                                  AS 'Сальдо'
		 , SUM(os.SALDO + os.Penalty_old)                                                 AS 'Нач_сальдо с пени'
		 , SUM(os.Value)                                                                  AS 'Начислено'
		 , SUM(os.Added)                                                                  AS 'Разовые'
		 , 0                                                                              AS 'Субсидия'
		 , SUM(os.Paid)                                                                   AS 'Пост_Начисление'
		 , SUM(os.PaymAccount)                                                            AS 'Оплачено'
		 , SUM(os.PaymAccount_peny)                                                       AS 'из_них_пени'
		 , SUM(os.Paymaccount_Serv)                                                       AS 'Оплата по услугам'
		 , SUM(CASE
                   WHEN os.SALDO < 0 THEN os.SALDO * -1
                   ELSE 0
        END)                                                                              AS 'Аванс'
		 , SUM(CASE
                   WHEN os.SALDO > 0 THEN os.SALDO
                   ELSE 0
        END)                                                                              AS 'Дебет Вх_сальдо'
		 , SUM(CASE
                   WHEN os.SALDO < 0 THEN -1 * os.SALDO
                   ELSE 0
        END)                                                                              AS 'Кредит Вх_сальдо'
		 , SUM(os.Debt)                                                                   AS 'Кон_Сальдо'
		 , SUM(os.Debt + COALESCE(os.Penalty_old_new, 0) + COALESCE(os.Penalty_value, 0)) AS 'Кон_Сальдо с пени'
		 , SUM(CASE
                   WHEN os.Debt > 0 THEN os.Debt
                   ELSE 0
        END)                                                                              AS 'Дебет Кон_Сальдо'
		 , SUM(CASE
                   WHEN os.Debt < 0 THEN -1 * os.Debt
                   ELSE 0
        END)                                                                              AS 'Кредит Кон_Сальдо'
		 , COALESCE((
			   SELECT TOP 1 COALESCE(sum_new, 0) - COALESCE(sum_old, 0)
			   FROM dbo.Penalty_log pl 
			   WHERE pl.fin_id = oh.fin_id
				   AND pl.Occ = os.occ_sup
		   ), 0)                                                                          AS 'Пени ручн.изм.'
		 , SUM(os.Penalty_old)                                                            AS 'Пени старое'
		 , SUM(os.Penalty_old_new) AS 'Пени старое изм'
		 , SUM(os.Penalty_added) AS 'Пени разовые'
		 , SUM(os.Penalty_value) AS 'Пени нов'
		 , SUM(os.debt_peny) AS 'Пени итог'
		 , SUM(os.Paid + os.Penalty_added + os.Penalty_value) AS 'Пост_Начисление с пени'
		 , SUM(os.Whole_payment) AS 'К оплате'		 
		 , SUM(os.Whole_payment_minus * -1) AS 'К оплате(кредит)'
		 , SUM(os.Whole_payment + os.Whole_payment_minus) AS 'К оплате(итого)'
		 , SUM(os.SALDO - os.Paymaccount_Serv) AS 'Задолженность'
		   --/////////////////////////////////////////////////////////////////////			
		 , CASE
			   WHEN SUM(os.SALDO - os.Paymaccount_Serv) > 0 THEN SUM(os.SALDO - os.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Задолженность без переплат'
		 , CASE
			   WHEN (SUM(os.Paymaccount_Serv - os.Paid) >= SUM(os.SALDO)) AND
				   SUM(os.Paymaccount_Serv) > 0 AND
				   (SUM(os.SALDO) > 0) THEN SUM(os.SALDO)
			   WHEN SUM(os.Paymaccount_Serv - os.Paid - os.SALDO) > 0 AND
				   SUM(os.SALDO) > 0 AND
				   SUM(os.Paymaccount_Serv) > 0 THEN SUM(os.SALDO - os.Paid)
			   WHEN SUM(os.Paymaccount_Serv - os.Paid) > 0 AND
				   SUM(os.SALDO) > 0 AND
				   SUM(os.Paymaccount_Serv) > 0 THEN SUM(os.Paymaccount_Serv - os.Paid)
			   ELSE 0
		   END AS 'Оплата долга'
		 , CASE
			   WHEN SUM(os.Paid - os.Paymaccount_Serv) < 0 AND
				   SUM(os.Paymaccount_Serv) > 0 THEN SUM(os.Paid)
			   WHEN SUM(os.Paid - os.Paymaccount_Serv) >= 0 AND
				   SUM(os.Paymaccount_Serv) > 0 THEN SUM(os.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Текущая оплата'
		 , CASE
			   WHEN SUM(os.Paymaccount_Serv - os.Paid - os.SALDO) > 0 AND
				   SUM(os.Paymaccount_Serv) > 0 AND
				   SUM(os.SALDO) >= 0 THEN SUM(os.Paymaccount_Serv - os.Paid - os.SALDO)

			   WHEN SUM(os.Paymaccount_Serv - os.Paid - os.SALDO) > 0 AND
				   SUM(os.Paymaccount_Serv) > SUM(os.Paid) AND
				   SUM(os.SALDO) < 0 AND
				   SUM(os.Paymaccount_Serv) > 0 THEN SUM(os.Paymaccount_Serv - os.Paid)
			   ELSE 0
		   END AS 'Оплата авансом'
		 , CASE
			   WHEN SUM(os.Paymaccount_Serv) < 0 THEN SUM(os.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Отрицательная оплата'
		 , CASE
			   WHEN SUM(os.Paid - os.Paymaccount_Serv) > 0 THEN SUM(os.Paid - os.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Сальдо за период дебет'
		 , CASE
			   WHEN SUM(os.Paid - os.Paymaccount_Serv) < 0 THEN -1 * SUM(os.Paid - os.Paymaccount_Serv)
			   ELSE 0
		   END AS 'Сальдо за период кредит'
		 , SUM(os.Paid - os.Paymaccount_Serv) AS 'Сальдо за период'
		   --/////////////////////////////////////////////////////////////////////								
		 , MIN(oh.nom_kvr_sort) AS nom_kvr_sort
		 , MIN(b.nom_dom_sort) AS nom_dom_sort
		 , MIN(st.short_name + b.nom_dom_sort) AS sort_dom
		 , oh.flat_id AS 'Код квартиры'
		 , b.id AS 'Код дома'
		 , MIN(o2.id_jku_gis) AS 'Идентификатор ЖКУ'
		 , MIN(o2.id_els_gis) AS 'ЕЛС'
		 , MIN(o2.id_nom_gis) AS 'Уникальный номер помещения'
		 , MIN(os.rasschet) AS 'Расчётный счёт'
		 , MAX(b.levels) AS 'Этажей в доме'
		 , MAX(ops.name) AS 'ОПС'
		 , MAX(os.KolMesDolg) AS 'Кол-во мес долга'
		 , CASE
               WHEN oh.total_sq = 0 THEN 'Нет'
               ELSE 'Да'
        END AS 'Площадь есть'
		 , MAX(o2.date_create) AS 'Дата создания лицевого'
		 , CASE
               WHEN b.is_paym_build = 1 THEN 'Да'
               ELSE 'Нет'
        END AS 'Начисляем по дому'
		 , CASE
               WHEN SUM(os.Paid) <> 0 THEN 'Есть'
               ELSE 'Нет'
        END AS 'Признак начислений'
		 , CASE
               WHEN os.penalty_calc = 1 THEN 'Да'
               ELSE 'Нет'
        END AS 'Признак расч. пени'
		 , MAX(COALESCE(os.schtl_old,'')) AS 'Стар_Лицевой(текст)'
		 , MAX(o2.telephon) AS 'Телефон'
		 , MAX(o2.email) AS 'Эл.почта'
	FROM dbo.View_occ_all AS oh
		JOIN #tip_table tt ON 
			oh.tip_id = tt.tip_id
		JOIN dbo.VOcc_Suppliers AS os ON 
			oh.fin_id = os.fin_id
			AND oh.Occ = os.Occ
		JOIN dbo.Buildings AS b ON 
			oh.bldn_id = b.id
		JOIN dbo.VStreets AS st ON 
			b.street_id = st.id
		JOIN dbo.Towns AS T ON 
			b.town_id = T.id
		LEFT JOIN dbo.Divisions AS d 
			ON b.div_id = d.id
		LEFT JOIN dbo.Sector sec ON 
			b.sector_id = sec.id
		JOIN dbo.Suppliers_all sa ON 
			os.sup_id = sa.id
		JOIN dbo.Property_types AS PT ON 
			oh.proptype_id = PT.id
		JOIN dbo.Room_types AS RT ON 
			oh.roomtype_id = RT.id
		JOIN dbo.Occupations o2 ON 
			os.Occ = o2.Occ
		LEFT JOIN dbo.ops ops ON 
			b.index_id = ops.id
	WHERE 
		oh.fin_id BETWEEN @fin_id1 AND @fin_id2		
		AND (@build IS NULL OR oh.bldn_id = @build)
		AND (@sup_id IS NULL OR os.sup_id = @sup_id)
		AND oh.status_id <> 'закр'

	GROUP BY oh.start_date
		   , oh.fin_id
		   , T.name
		   , d.name
		   , oh.tip_name
		   , st.short_name
		   , b.nom_dom
		   , b.id
		   , b.is_paym_build
		   , oh.nom_kvr
		   , oh.flat_id
		   , oh.Occ
		   , oh.status_id
		   , os.occ_sup
		   , oh.total_sq
		   , sa.name
		   , oh.kol_people
		   , os.penalty_calc
		   , PT.name
		   , RT.name
		   , oh.nom_kvr_sort
		   , b.nom_dom_sort

	SELECT *
	FROM #table1 t

	DROP TABLE IF EXISTS #table1;
go

