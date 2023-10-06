CREATE   PROCEDURE [dbo].[rep_pay_7]
(
	  @date1 DATETIME = NULL
	, @date2 DATETIME = NULL
	, @bank_id INT = NULL
	, @tip_id SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @service_id VARCHAR(10) = NULL
	, @sup_id INT = NULL
	, @build_id INT = NULL
	, @fin_id2 SMALLINT = NULL
	, @tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
)
AS
	/*
  Протокол ввода платежей
  по дате закрытия 
  по услугам

  SET STATISTICS IO, TIME ON
  
  EXEC	[dbo].[rep_pay_7]
		@tip_id = 1,
		@fin_id1 = 250,
		@fin_id2 = 250
		,@tip_str1='2'
  
  SET STATISTICS IO, TIME OFF

  EXEC	[dbo].[rep_pay_7]
		@tip_id = null,
		@fin_id1 = 175,
		@fin_id2 = 175
		,@tip_str1=null--'28'
		  
  dbo.rep_pay_7 '20210613 00:00:00','20210813 23:59:59',NULL,2,NULL,NULL,NULL,NULL    
  
*/	
	SET NOCOUNT ON

	IF @tip_id IS NULL
		AND @tip_str1 IS NULL
		AND @build_id IS NULL
		SET @tip_id = 0

	--REGION Таблица со значениями Типа жил.фонда *********************
	DROP TABLE IF EXISTS #tip_table;
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	select tip_id from dbo.fn_get_tips_tf(@tip_str1, @tip_id, @build_id)
	--IF @debug = 1 SELECT * FROM #tip_table
	--ENDREGION ************************************************************

	IF @date2 IS NULL
		SET @date2 = @date1
	IF @bank_id = 0
		SET @bank_id = NULL
	IF @fin_id1 IS NULL
		AND @date1 IS NULL
		AND @date2 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	IF @fin_id1 IS NOT NULL
		SELECT @date1 = '19000101'
			 , @date2 = '20500101'

	IF @fin_id1 IS NOT NULL
		AND @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	-- для ограничения доступа услуг
	CREATE TABLE #services (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, [name] VARCHAR(100) COLLATE database_default
	)
	INSERT INTO #services (id, name) SELECT id, name FROM dbo.View_services;
	
	;WITH tabl AS
	(
		SELECT 
			 CAST(pd.date_edit AS DATE) AS 'Дата закрытия'
			 , pd.[day] AS 'Дата платежа'
			 , b.short_name AS 'Банк'
			 , s.name AS 'Услуга'
			 , s.id AS 'Код услуги'
			 , t.name AS 'Населенный пункт'
			 , ot.name AS 'Тип фонда'
			 , CONCAT(s1.short_name, ' д.', vb.nom_dom) AS 'Адрес дома'
			 , F.nom_kvr AS 'Квартира'
			 , p.Occ AS 'Лицевой'
			 , PRT.name AS 'Тип собственности'
			 , CASE
				   WHEN vs.name IS NOT NULL THEN vs.name
				   ELSE (
						   SELECT TOP 1 vs1.name
						   FROM dbo.Consmodes_list AS vp
							   JOIN dbo.View_suppliers AS vs1 ON 
								vp.source_id = vs1.id
						   WHERE vp.Occ = p.Occ
							   AND vp.service_id = s.id
					   )
			   END AS 'Поставщик'
			 , dog.dog_id AS 'Договор'
			 , p.pack_id AS 'Код пачки'
			 , MIN(gv.StrMes) AS 'Фин.период'
			 , MIN(gv.start_date) AS 'Период'
			 , PT.name AS 'Тип платежа'
			 , SUM(ps.Value) AS 'Оплата'
			 , SUM(ps.PaymAccount_peny) AS 'из них пени'
			 , SUM(ps.Value - ps.PaymAccount_peny) AS 'Оплата без пени'
			 , SUM(COALESCE(ps.commission, 0)) AS 'Комиссия банка'
			 , SUM(ps.Value - COALESCE(ps.commission, 0)) AS 'Оплата без комиссии'
			 , SUM(ps.Value - ps.PaymAccount_peny - COALESCE(ps.commission, 0)) AS 'Оплата без пени и комиссии'
			 , MAX(COALESCE(bs.rasschet, '')) AS 'Расч_счёт'
			 , MAX(bs.filenamedbf) AS 'Файл'
			 , F.nom_kvr_sort
			 , CONCAT(s1.short_name, vb.nom_dom_sort) AS sort_dom
		FROM dbo.Occupations AS o 
			JOIN dbo.Flats F ON 
				F.id = o.flat_id
			JOIN dbo.Payings AS p ON 
				o.Occ = p.Occ
			JOIN dbo.Paydoc_packs AS pd ON 
				p.pack_id = pd.id
			JOIN #tip_table tt ON 
				pd.tip_id = tt.tip_id
			JOIN dbo.Global_values gv ON 
				pd.fin_id = gv.fin_id
			JOIN dbo.Paying_serv AS ps ON 
				p.id = ps.paying_id
			JOIN #services AS s ON 
				ps.service_id = s.id
			JOIN dbo.Paycoll_orgs AS po ON 
				pd.source_id = po.id
				AND pd.fin_id = po.fin_id
			JOIN dbo.Paying_types PT ON 
				po.vid_paym = PT.id
			JOIN dbo.Bank AS b ON 
				po.Bank = b.id
			JOIN dbo.Buildings AS vb ON 
				F.bldn_id = vb.id
			JOIN dbo.VStreets s1 ON 
				vb.street_id = s1.id
			JOIN dbo.Towns t ON 
				vb.town_id = t.id
			JOIN dbo.Occupation_Types ot ON 
				tt.tip_id = ot.id
			JOIN dbo.Property_types AS PRT ON 
				o.proptype_id = PRT.id
			LEFT JOIN dbo.Bank_tbl_spisok AS bs ON 
				p.filedbf_id = bs.filedbf_id
			LEFT JOIN dbo.Paym_history AS vca ON 
				vca.Occ = ps.Occ
				AND vca.fin_id = pd.fin_id
				AND vca.service_id = ps.service_id
				AND vca.sup_id = pd.sup_id
			LEFT JOIN dbo.View_suppliers AS vs ON 
				vca.source_id = vs.id
			LEFT JOIN dbo.View_dog_build AS dog ON 
				vb.id = dog.build_id
				AND pd.fin_id = dog.fin_id
				AND pd.sup_id = dog.sup_id
		WHERE 
			(
				(@fin_id1 IS NULL AND pd.fin_id BETWEEN pd.fin_id AND pd.fin_id) 
				OR (pd.fin_id BETWEEN @fin_id1 AND @fin_id2)
			)
			AND (@build_id IS NULL OR F.bldn_id = @build_id)			
			AND pd.date_edit BETWEEN @date1 AND @date2
			AND pd.forwarded = CAST(1 AS BIT)
			AND (@bank_id IS NULL OR po.Bank = @bank_id)
			AND (@service_id IS NULL OR s.id = @service_id)
			AND (@sup_id IS NULL OR pd.sup_id = @sup_id)
		GROUP BY dog.dog_id
			   , CAST(pd.date_edit AS DATE)
			   , pd.[day]
			   , b.short_name
			   , ot.name
			   , s.name
			   , s.id
			   , vb.id
			   , s1.short_name
			   , vb.nom_dom
			   , vb.nom_dom_sort
			   , F.nom_kvr
			   , F.nom_kvr_sort
			   , t.name
			   , pd.fin_id
			   , p.Occ
			   , p.pack_id
			   , p.id
			   , vs.name
			   , PT.name
			   , PRT.name
	)

	SELECT *
	FROM tabl AS t
	ORDER BY t.[Дата платежа]
		   , t.sort_dom
		   , t.nom_kvr_sort
	OPTION (RECOMPILE)
go

