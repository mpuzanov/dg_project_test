CREATE   PROCEDURE [dbo].[rep_olap_dolg]
(
	  @tip_id SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @build INT = NULL
	, @debug BIT = NULL
	, @sup_id INT = NULL
	, @tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
	, @occ1 INT = NULL
)
AS
	/*
  	
  	Аналитика по лиц.счетам

  	rep_olap_dolg @tip_id=2,@fin_id1=230,@fin_id2=237,@build=6765,@debug=0,@tip_str1=NULL, @occ1=210042006  	

  	rep_olap_dolg @tip_id=131,@fin_id1=165,@fin_id2=165,@build=0,@debug=0,@tip_str1=NULL
  	rep_olap_dolg @tip_id=27,@fin_id1=165,@fin_id2=165,@build=0,@debug=0,@tip_str1=NULL
  	rep_olap_dolg @tip_id=1,@fin_id1=230,@fin_id2=230,@build=0,@debug=0,@tip_str1=NULL
  	rep_olap_dolg @tip_id=1,@fin_id1=230,@fin_id2=230,@build=0,@debug=0, @sup_id=345, @tip_str1='1'
  	
  	*/
	SET NOCOUNT ON

	DECLARE @db_name VARCHAR(30) = UPPER(DB_NAME())

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

	IF @build IS NOT NULL
		AND @tip_id IS NULL
		AND COALESCE(@tip_str1, '') = ''
		SELECT @tip_str1 = STUFF((
				SELECT ',' + LTRIM(STR(b.tip_id))
				FROM View_build_all b
				WHERE b.build_id = @build
				GROUP BY b.tip_id
				FOR XML PATH ('')
			), 1, 1, '')

	IF @tip_id IS NULL
		AND COALESCE(@tip_str1, '') = ''
		AND (dbo.strpos('NAIM', @db_name)=0)
		AND @build IS NULL
		SET @tip_id = -1
		
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
		 , CONCAT(st.short_name , ' д.' , b.nom_dom) AS 'Адрес дома'
		 , CONCAT(st.short_name , ' д.' , b.nom_dom , ' кв.' , oh.nom_kvr) AS 'Адрес'
		 , oh.nom_kvr AS 'Квартира'
		 , dbo.Fun_Initials(oh.Occ) AS 'ФИО'
		 , CAST(oh.total_sq AS DECIMAL(9, 2)) AS 'Площадь'
		 , oh.kol_people AS 'Кол-во граждан'
		 , PT.name AS 'Тип собственности'
		 , RT.name AS 'Тип помещения'
		 , CASE
			   WHEN oh.status_id = 'откр' THEN 'Открыт'
			   WHEN oh.status_id = 'своб' THEN 'Свободен'
			   ELSE 'Закрыт'
		   END AS 'Статус лицевого'
		 , CAST('' AS VARCHAR(30)) AS 'Поставщик'
		 , SUM(oh.SALDO) AS 'Сальдо'
		 , SUM(oh.SALDO + oh.Penalty_old) AS 'Нач_сальдо с пени'
		 , SUM(oh.Value) AS 'Начислено'
		 , SUM(oh.Added) AS 'Разовые'
		 , SUM(oh.Paid + oh.Paid_minus) AS 'Пост_Начисление'
		 , SUM(oh.PaymAccount) AS 'Оплачено'
		 , SUM(oh.PaymAccount_peny) AS 'из_них_пени'
		 , SUM(oh.Paymaccount_Serv) AS 'Оплата по услугам'
		 , SUM(CASE WHEN(oh.SALDO < 0) THEN oh.SALDO * -1 ELSE 0 END) AS 'Аванс'
		 , SUM(oh.Debt) AS 'Кон_Сальдо'
		 , SUM(oh.Debt + oh.Penalty_old_new + oh.Penalty_value) AS 'Кон_Сальдо с пени'

		 , SUM(oh.Penalty_old) AS 'Пени долг'
		 , SUM(oh.Penalty_old_new) AS 'Пени долг изм'
		 , SUM(oh.Penalty_added) AS 'Пени разовые'
		 , SUM(oh.Penalty_value) AS 'Пени нов'
		 , SUM(oh.Penalty_itog) AS 'Пени итог'
		 , SUM(oh.Paid + oh.Paid_minus + oh.Penalty_added + oh.Penalty_value) AS 'Пост_Начисление с пени'
		 , SUM(oh.Whole_payment) AS 'К оплате'
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
		 , SUM(oh.PaidItog - oh.Paymaccount_Serv) AS 'Сальдо за период'
		   --/////////////////////////////////////////////////////////////////////								
		 , oh.nom_kvr_sort AS nom_kvr_sort
		 , b.nom_dom_sort AS nom_dom_sort
		 , CONCAT(st.short_name, b.nom_dom_sort) AS sort_dom
		 , CONCAT(st.short_name, b.nom_dom_sort, oh.nom_kvr_sort) AS sort_adres
		 , oh.flat_id AS 'Код квартиры'
		 , b.id AS 'Код дома'
		 , CASE WHEN(oh.total_sq = 0) THEN 'Нет' ELSE 'Да' END AS 'Площадь есть'
		 , MAX(o2.date_create) AS 'Дата создания лицевого'
		 , CASE WHEN(b.is_paym_build = 1) THEN 'Да' ELSE 'Нет' END AS 'Начисляем по дому'
		 , CASE WHEN(SUM(oh.Paid + oh.Paid_minus) <> 0) THEN 'Есть' ELSE 'Нет' END AS 'Признак начислений'
		 , CASE WHEN(oh.penalty_calc = 1) THEN 'Да' ELSE 'Нет' END AS 'Признак расч. пени'
		 , MAX(o2.schtl_old) AS 'Стар_Лицевой(текст)'
		 , MAX(o2.telephon) AS 'Телефон'
		 , oh.KolMesDolg AS KolMesDolg
		 , MAX(mes.KolMesCal2) AS 'Кол месяцев от послед.начисления' --KolMesCal --
		 , MAX(mes.LastPeriodValue) AS 'Месяц посл.начисления'  --LastPeriodValue -- 
		 , MAX(pay.Value) AS 'Последняя оплата'  --last_paym_value --
		 , MAX(pay.day) AS 'Последний день платежа' --last_paym_day --
	INTO #table1
	FROM dbo.View_occ_all AS oh 
		JOIN #tip_table tt 
			ON oh.tip_id = tt.tip_id
		JOIN dbo.Buildings AS b  
			ON oh.bldn_id = b.id
		JOIN dbo.VStreets AS st 
			ON b.street_id = st.id
		JOIN dbo.Towns AS T ON b.town_id = T.id
		LEFT JOIN dbo.Divisions AS d 
			ON b.div_id = d.id
		LEFT JOIN dbo.Sector sec 
			ON b.sector_id = sec.id
		JOIN dbo.Property_types AS PT 
			ON oh.proptype_id = PT.id
		JOIN dbo.Room_types AS RT 
			ON oh.roomtype_id = RT.id
		JOIN dbo.Occupations o2 
			ON oh.Occ = o2.Occ
		OUTER APPLY (
				SELECT TOP (1) p.[Value]
						   , pd.day
				FROM dbo.Payings AS p 
					JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
				WHERE oh.occ = p.occ
					AND service_id IS NULL
					AND pd.sup_id=0
				ORDER BY pd.day DESC
			) AS pay
			OUTER APPLY (
				SELECT TOP (1) KolMesCal2 = DATEDIFF(MONTH, oh2.start_date, oh.start_date)
						,oh2.start_date AS LastPeriodValue
				FROM dbo.View_occ_all_lite AS oh2
				WHERE oh2.fin_id <= oh.fin_id
					AND oh2.Value > 0
					AND oh2.occ = oh.occ
				ORDER BY oh2.fin_id DESC
			) AS mes
	WHERE 
		oh.fin_id BETWEEN @fin_id1 AND @fin_id2
		--AND (oh.tip_id = @tip_id
		--OR @tip_id IS NULL)	
		AND (@build IS NULL OR oh.bldn_id = @build)
		AND (@occ1 IS NULL OR oh.occ=@occ1)
		AND (COALESCE(@sup_id,0)=0)
		AND oh.status_id <> 'закр'
		AND oh.total_sq>0
		--AND oh.KolMesDolg>0


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
		   , oh.KolMesDolg
		   , oh.nom_kvr_sort
		   , b.nom_dom_sort
	HAVING SUM(oh.SALDO - oh.Paymaccount_Serv)>=0
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
		 , CONCAT(st.short_name , ' д.' , b.nom_dom) AS 'Адрес дома'
		 , CONCAT(st.short_name , ' д.' , b.nom_dom , ' кв.' , oh.nom_kvr) AS 'Адрес'
		 , oh.nom_kvr AS 'Квартира'
		 , dbo.Fun_Initials(oh.Occ) AS 'ФИО'
		 , CAST(oh.total_sq AS DECIMAL(9, 2)) AS 'Площадь'
		 , oh.kol_people AS 'Кол-во граждан'
		 , PT.name AS 'Тип собственности'
		 , RT.name AS 'Тип помещения'
		 , CASE
			   WHEN oh.status_id = 'откр' THEN 'Открыт'
			   WHEN oh.status_id = 'своб' THEN 'Свободен'
			   ELSE 'Закрыт'
		   END AS 'Статус лицевого'
		 , sa.name AS 'Поставщик'
		 , SUM(os.SALDO) AS 'Сальдо'
		 , SUM(os.SALDO + os.Penalty_old) AS 'Нач_сальдо с пени'
		 , SUM(os.Value) AS 'Начислено'
		 , SUM(os.Added) AS 'Разовые'
		 , SUM(os.Paid) AS 'Пост_Начисление'
		 , SUM(os.PaymAccount) AS 'Оплачено'
		 , SUM(os.PaymAccount_peny) AS 'из_них_пени'
		 , SUM(os.Paymaccount_Serv) AS 'Оплата по услугам'
		 , SUM(CASE WHEN(os.SALDO < 0) THEN os.SALDO * -1 ELSE 0 END) AS 'Аванс'
		 , SUM(os.Debt) AS 'Кон_Сальдо'
		 , SUM(os.Debt + COALESCE(os.Penalty_old_new, 0) + COALESCE(os.Penalty_value, 0)) AS 'Кон_Сальдо с пени'		 
		 , SUM(os.Penalty_old) AS 'Пени долг'
		 , SUM(os.Penalty_old_new) AS 'Пени долг изм'
		 , SUM(os.Penalty_added) AS 'Пени разовые'
		 , SUM(os.Penalty_value) AS 'Пени нов'
		 , SUM(os.debt_peny) AS 'Пени итог'
		 , SUM(os.Paid + os.Penalty_added + os.Penalty_value) AS 'Пост_Начисление с пени'
		 , SUM(os.Whole_payment) AS 'К оплате'		 
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
		 , SUM(os.Paid - os.Paymaccount_Serv) AS 'Сальдо за период'
		   --/////////////////////////////////////////////////////////////////////								
		 , oh.nom_kvr_sort AS nom_kvr_sort
		 , b.nom_dom_sort AS nom_dom_sort
		 , CONCAT(st.short_name, b.nom_dom_sort) AS sort_dom
		 , CONCAT(st.short_name, b.nom_dom_sort, oh.nom_kvr_sort) AS sort_adres
		 , oh.flat_id AS 'Код квартиры'
		 , b.id AS 'Код дома'
		 , CASE WHEN(oh.total_sq = 0) THEN 'Нет' ELSE 'Да' END AS 'Площадь есть'
		 , MAX(o2.date_create) AS 'Дата создания лицевого'
		 , CASE WHEN(b.is_paym_build = 1) THEN 'Да' ELSE 'Нет' END AS 'Начисляем по дому'
		 , CASE WHEN(SUM(os.Paid) <> 0) THEN 'Есть' ELSE 'Нет' END AS 'Признак начислений'
		 , CASE WHEN(os.penalty_calc = 1) THEN 'Да' ELSE 'Нет' END AS 'Признак расч. пени'
		 , MAX(os.schtl_old) AS 'Стар_Лицевой(текст)'
		 , MAX(o2.telephon) AS 'Телефон'
		 , os.KolMesDolg AS KolMesDolg		 
		 , MAX(mes.KolMesCal2) AS KolMesCal
		 , MAX(mes.LastPeriodValue) AS LastPeriodValue
		 , MAX(pay.Value) AS last_paym_value
		 , MAX(pay.day) AS last_paym_day
	FROM dbo.View_occ_all AS oh 
		JOIN #tip_table tt 
			ON oh.tip_id = tt.tip_id
		JOIN dbo.VOcc_Suppliers AS os  
			ON oh.fin_id = os.fin_id
			AND oh.Occ = os.Occ
		JOIN dbo.Buildings AS b 
			ON oh.bldn_id = b.id
		JOIN dbo.VStreets AS st 
			ON b.street_id = st.id
		JOIN dbo.Towns AS T 
			ON b.town_id = T.id
		LEFT JOIN dbo.Divisions AS d
			ON b.div_id = d.id
		LEFT JOIN dbo.Sector sec 
			ON b.sector_id = sec.id
		JOIN dbo.Suppliers_all sa 
			ON os.sup_id = sa.id
		JOIN dbo.Property_types AS PT 
			ON oh.proptype_id = PT.id
		JOIN dbo.Room_types AS RT 
			ON oh.roomtype_id = RT.id
		JOIN dbo.Occupations o2 
			ON os.Occ = o2.Occ
		OUTER APPLY (
				SELECT TOP (1) p.[Value]
						   , pd.day
				FROM dbo.Payings AS p 
					JOIN dbo.Paydoc_packs AS pd 
						ON p.pack_id = pd.id
				WHERE oh.occ = p.occ
					AND service_id IS NULL
					AND (pd.sup_id=os.sup_id)
				ORDER BY pd.day DESC
			) AS pay
			OUTER APPLY (
				SELECT TOP (1) KolMesCal2 = oh.fin_id-oh2.fin_id
						,gb.start_date AS LastPeriodValue
				FROM dbo.Occ_Suppliers AS oh2 
				JOIN dbo.Global_values as gb  
					ON oh2.fin_id=gb.fin_id
				WHERE oh2.fin_id <= oh.fin_id
					AND oh2.Value > 0
					AND oh2.occ = oh.occ
					AND (oh2.sup_id=os.sup_id)
				ORDER BY oh2.fin_id DESC
			) AS mes
	WHERE 
		oh.fin_id BETWEEN @fin_id1 AND @fin_id2		
		AND (oh.bldn_id = @build OR @build IS NULL)
		AND (oh.occ=@occ1 OR @occ1 IS NULL)
		AND (os.sup_id = @sup_id OR @sup_id IS NULL)
		AND oh.status_id <> 'закр'
		--AND os.KolMesDolg>0		

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
		   , os.KolMesDolg
		   , oh.nom_kvr_sort
		   , b.nom_dom_sort
		HAVING SUM(os.SALDO - os.Paymaccount_Serv)>=0

	SELECT *
	, KolMesDolg AS [Кол-во мес долга]
	, CASE
			   WHEN KolMesDolg BETWEEN 0 AND 2.9 THEN '1 (0-2)'
			   WHEN KolMesDolg BETWEEN 3 AND 6.9 THEN '2 (3-6)'
			   WHEN KolMesDolg BETWEEN 7 AND 9.9 THEN '3 (7-9)'
			   WHEN KolMesDolg BETWEEN 10 AND 12.9 THEN '4 (10-12)'
			   WHEN KolMesDolg BETWEEN 13 AND 18.9 THEN '5 (13-18)'
			   WHEN KolMesDolg BETWEEN 19 AND 36 THEN '6 (19-36)'
			   WHEN KolMesDolg > 36 THEN N'более 36'
		   END
		   AS 'Группа задолженности'
	, CASE
			   WHEN [Задолженность] < 3000 THEN '1 (менее 3 тыс.р.)'
			   WHEN [Задолженность] BETWEEN 3000 AND 10000 THEN '2 (3-10)'
			   WHEN [Задолженность] BETWEEN 10001 AND 20000 THEN '3 (10-20)'
			   WHEN [Задолженность] BETWEEN 20001 AND 50000 THEN '4 (20-50)'
			   WHEN [Задолженность] BETWEEN 50001 AND 100000 THEN '5 (50-100)'
			   WHEN [Задолженность] > 100000 THEN N'более 100 тыс.р.'
		   END
		   AS 'Группа по сумме долга'
		, DATEADD(MONTH, -KolMesDolg, [Период]) as 'Период начала долга'
		, [Задолженность]+[Пени долг изм] AS [Задолженность с пени]
		, [Пени долг изм] AS [Задолженность пени]
	FROM #table1 t
	WHERE [Задолженность]>0

	IF @debug = 1
	BEGIN
		SELECT *
		FROM #table1
		WHERE [Оплата по услугам] <> ([Оплачено] - [из_них_пени])

	END
go

