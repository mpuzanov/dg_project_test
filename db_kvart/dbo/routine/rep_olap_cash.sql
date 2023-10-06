-- =============================================
-- Author:		Пузанов
-- Create date: 12.07.2019
-- Description:	Аналитика по платежам для фискализации чеков
-- =============================================
CREATE           PROCEDURE [dbo].[rep_olap_cash]
(
	@build	  INT			= NULL
   ,@fin_id1  SMALLINT		= NULL
   ,@fin_id2  SMALLINT		= NULL
   ,@tip_id	  SMALLINT		= NULL
   ,@sup_id	  INT			= NULL
   ,@tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
)
AS
/*
Аналитика по платежам для фискализации чеков

rep_olap_cash 1037, 203,203,28,323
rep_olap_cash null, 203,203,28,null,''
rep_olap_cash null, 252,252,60,null

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
	DECLARE @tip_table TABLE
		(
			tip_id SMALLINT DEFAULT NULL PRIMARY KEY
		)

	INSERT INTO @tip_table
		SELECT CASE
                   WHEN value = 'Null' THEN NULL
                   ELSE value
                   END
		FROM STRING_SPLIT(@tip_str1, ',')
		WHERE RTRIM(value) <> ''

	IF @tip_id IS NOT NULL
	BEGIN
		INSERT INTO @tip_table
			SELECT
				id
			FROM dbo.VOCC_TYPES
			WHERE id = @tip_id
			AND NOT EXISTS (SELECT
					1
				FROM @tip_table
				WHERE tip_id = @tip_id)
	END
	--select * from @tip_table
	--ENDREGION ************************************************************

	SELECT 
		gb.start_date   AS 'Период'
	   ,ba.town_name    AS 'Населенный пункт'
	   ,ba.tip_name     AS 'Тип фонда'
	   ,ba.street_name  AS 'Улица'
	   ,ba.nom_dom      AS 'Номер дома'
	   ,F.nom_kvr       AS 'Квартира'
	   ,ba.adres        AS 'Адрес дома'
	   ,p.pack_id       AS 'Код пачки'
	   , CASE
             WHEN p.sup_id > 0 THEN P.occ_sup
             ELSE p.occ
        END             AS 'Лицевой'
	   ,pc.service_name AS 'Услуга'
	   ,pc.value_cash   AS 'Оплата'
	   ,pd.day          AS 'Дата платежа'
	   ,CASE
			WHEN p.forwarded = 1 THEN 'Да'
			ELSE 'Нет'
		END             AS 'Пачка закрыта'
	   ,CAST(pd.date_edit AS DATE) AS 'Дата закрытия'
	   ,b.short_name AS 'Банк'
	   ,PT.name AS 'Тип платежа'
	   ,sup.name AS 'Поставщик'
	   ,PRT.name AS 'Тип собственности'
	   ,gb.StrMes AS 'Фин.период'
	   ,COALESCE(bs.rasschet, '') AS 'Расч_счёт'
	   ,bs.filenamedbf AS 'Файл'
	   ,p.id AS 'Код платежа'
	   ,ba.nom_dom_sort
	   ,F.nom_kvr_sort
	   ,CONCAT(ba.street_name, ba.nom_dom_sort) AS sort_dom
	FROM dbo.PAYINGS AS p 
	JOIN dbo.PAYDOC_PACKS AS pd
		ON p.pack_id = pd.id
	JOIN dbo.PAYING_CASH pc 
		ON p.id = pc.paying_id 
	JOIN @tip_table tt
		ON pd.tip_id = tt.tip_id
	JOIN dbo.PAYCOLL_ORGS AS po
		ON pd.source_id = po.id
		AND pd.fin_id = po.fin_id
	JOIN dbo.PAYING_TYPES PT 
		ON po.vid_paym = PT.id
	JOIN dbo.BANK AS b 
		ON po.BANK = b.id
	JOIN dbo.GLOBAL_VALUES AS gb 
		ON pd.fin_id = gb.fin_id
	LEFT JOIN dbo.SUPPLIERS_ALL AS sup 
		ON p.sup_id = sup.id
	JOIN dbo.OCCUPATIONS AS o 
		ON p.occ = o.occ
	JOIN dbo.FLATS F 
		ON F.id = o.flat_id
	JOIN dbo.View_BUILDINGS AS ba
		ON F.bldn_id = ba.id
	JOIN dbo.PROPERTY_TYPES AS PRT 
		ON o.PROPTYPE_ID = PRT.id
	LEFT JOIN dbo.BANK_TBL_SPISOK AS bs 
		ON p.filedbf_id = bs.filedbf_id
	WHERE 
		pd.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@sup_id IS NULL OR p.sup_id = @sup_id)
		AND (@build IS NULL	OR F.bldn_id = @build)
	OPTION (OPTIMIZE FOR UNKNOWN, MAXDOP 1)

END
go

