-- =============================================
-- Author:		Пузанов
-- Create date: 28.02.2012
-- Description:	Платежи
-- =============================================
CREATE             PROCEDURE [dbo].[rep_olap_pay]
(
	  @build INT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @sup_id INT = NULL
	, @tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
)
AS
/*
По Платежам

exec rep_olap_pay null, 250,250,1,null,''
exec rep_olap_pay null, 176,176,null,null,'3'

*/
BEGIN
	SET NOCOUNT ON;

	--IF @build IS NULL AND @tip_id IS NULL AND @sup_id IS NULL SET @build=0
	--print @fin_start

	--DECLARE @fin_current SMALLINT
	--SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = 0
	IF @fin_id2 IS NULL
		SET @fin_id2 = 0
	IF @fin_id2 < @fin_id1
		SET @fin_id2 = @fin_id1

	IF @tip_id IS NULL
		AND @tip_str1 IS NULL
		AND @build IS NULL
		SET @tip_id = 0

	--REGION Таблица со значениями Типа жил.фонда *********************
	DROP TABLE IF EXISTS #tip_table;
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	select tip_id from dbo.fn_get_tips_tf(@tip_str1, @tip_id, @build)
	--IF @debug = 1 SELECT * FROM #tip_table
	--ENDREGION ************************************************************

	SELECT
		gb.start_date AS 'Период'
	  , ba.town_name AS 'Населенный пункт'
	  , ba.tip_name AS 'Тип фонда'
	  , ba.street_name AS 'Улица'
	  , ba.nom_dom AS 'Номер дома'
	  , F.nom_kvr AS 'Квартира'
	  , ba.adres AS 'Адрес дома'
	  , p.pack_id AS 'Код пачки'
	  , p.occ AS 'Лицевой'
	  , p.occ_sup AS 'Лицевой поставщика'
	  , p.service_id AS 'Код услуги'
	  , p.value AS 'Оплата'
	  , COALESCE(p.paymaccount_peny, 0) AS 'из них пени'
	  , p.value - COALESCE(p.paymaccount_peny, 0) AS 'Оплата без пени'
	  , p.commission AS 'Комиссия банка'
	  , (p.value - COALESCE(p.commission, 0)) AS 'Оплата без комиссии'
	  , (p.value - COALESCE(p.paymaccount_peny, 0) - COALESCE(p.commission, 0)) AS 'Оплата без пени и комиссии'
	  , pd.day AS 'Дата платежа'
	  , CASE
			WHEN p.forwarded = CAST(1 AS BIT) THEN 'Да'
			ELSE 'Нет'
		END AS 'Пачка закрыта'
	  , CAST(pd.date_edit AS DATE) AS 'Дата закрытия'
	  , b.short_name AS 'Банк'
	  , PT.name AS 'Тип платежа'
	  , sup.name AS 'Поставщик'
	  , dog.dog_name AS 'Договор'
	  , PRT.name AS 'Тип собственности'
	  , gb.StrMes AS 'Фин.период'
	  , COALESCE(bs.rasschet, '') AS 'Расч_счёт'
	  , bs.filenamedbf AS 'Файл'
	  , p.id AS 'Код платежа'
	  , ba.nom_dom_sort
	  , F.nom_kvr_sort
	  , CONCAT(ba.street_name, ba.nom_dom_sort) AS sort_dom
	  , p.paying_uid AS 'УИД платежа'
	  , pd.pack_uid AS 'УИД пачки'
	FROM dbo.Payings AS p 
		JOIN dbo.Paydoc_packs AS pd  
			ON p.pack_id = pd.id
		JOIN #tip_table tt 
			ON pd.tip_id = tt.tip_id
		JOIN dbo.Paycoll_orgs AS po 
			ON pd.source_id = po.id
			AND pd.fin_id = po.fin_id
		JOIN dbo.Paying_types PT 
			ON po.vid_paym = PT.id
		JOIN dbo.bank AS b 
			ON po.bank = b.id
		JOIN dbo.Global_values AS gb  
			ON pd.fin_id = gb.fin_id
		LEFT JOIN dbo.Suppliers_all AS sup 
			ON p.sup_id = sup.id
		JOIN dbo.Occupations AS o 
			ON p.occ = o.occ
		JOIN dbo.Flats F 
			ON F.id = o.flat_id
		JOIN dbo.View_buildings AS ba 
			ON F.bldn_id = ba.id
		JOIN dbo.Property_types AS PRT 
			ON o.proptype_id = PRT.id
		LEFT JOIN dbo.Bank_tbl_spisok AS bs 
			ON p.filedbf_id = bs.filedbf_id
		LEFT JOIN dbo.Dog_sup AS dog 
			ON p.dog_int = dog.id
	WHERE 
		pd.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@sup_id IS NULL OR p.sup_id = @sup_id)
		AND (@build IS NULL OR F.bldn_id = @build)
	OPTION (MAXDOP 1, FAST 10);




END
go

