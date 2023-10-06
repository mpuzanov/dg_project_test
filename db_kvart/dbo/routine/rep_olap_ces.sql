-- =============================================
-- Author:		Пузанов
-- Create date: 03.08.2012
-- Description:	Платежи по цессии
-- =============================================
CREATE       PROCEDURE [dbo].[rep_olap_ces] 
(
@build INT = NULL,
@fin_id1 SMALLINT = NULL, 
@fin_id2 SMALLINT = NULL,
@tip_id SMALLINT = NULL,
@sup_id INT = NULL
)
AS
/*
По Платежам цессии

*/
BEGIN
	SET NOCOUNT ON;

	
--IF @build IS NULL AND @tip_id IS NULL AND @sup_id IS NULL SET @build=0
--print @fin_start

IF @fin_id1=0 OR @fin_id1 IS NULL 
	SET @fin_id1=dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, NULL)
IF @fin_id2=0 OR @fin_id2 IS NULL 
	SET @fin_id2=@fin_id1

SELECT o.start_date
	 , dbo.Fun_NameFinPeriod(o.fin_id) AS 'Фин_период'
	 , o.occ AS [Единый лицевой]
	 , ces.occ_sup AS [Лицевой поставщика]
	 , dbo.Fun_InitialsFull(o.occ) AS Initials
	 , vb.street_name AS 'Улица'
	 , vb.nom_dom AS 'Дом'
	 , o.nom_kvr AS 'Квартира'
	 , vds.dog_name AS 'Договор'
	 , t.cessia_dolg_mes_old AS [Глубина долга]
	 , dolg_mes_start = ces.dolg_mes_start
	 , cast(p.date_edit AS DATE) as date_edit
	 , p.tip_paym AS [Тип платежа]
	 , o.tip_name AS [Тип фонда]
	 , sup.name as 'Поставщик'                       
	 , p.day
	 , p.source_name AS 'Банк'
     , p.value AS 'Оплата'
     , p.value-coalesce(pc.value_ces,0) AS 'Перечислить'
	 , PC.kol_ces AS 'Процент'
     , PC.value_ces AS 'Начисленно'   
     , vb.town_name as 'НаселенныйПункт'
	 , vb.adres AS 'Адрес_дома'
	 , o.address AS 'Адрес_квартиры'	 
	 , o.nom_kvr_sort
FROM dbo.View_payings AS p 
	LEFT JOIN dbo.PAYING_CESSIA AS PC 
		ON p.id = PC.paying_id    
    JOIN dbo.OCC_SUPPLIERS AS t 
		ON p.sup_id = t.sup_id 
		AND p.fin_id = t.fin_id 
		AND p.occ = t.occ
	JOIN dbo.CESSIA AS ces 
		ON t.occ_sup = ces.occ_sup
	JOIN dbo.View_occ_all AS o 
		ON t.occ = o.occ 
		AND t.fin_id = o.fin_id
	JOIN dbo.View_DOG_SUP AS vds 
		ON t.dog_int = vds.dog_int
	JOIN dbo.View_BUILDINGS AS vb 
		ON o.bldn_id=vb.id
	JOIN dbo.SUPPLIERS_ALL as sup 
		ON vds.sup_id=sup.id
WHERE 
	p.sup_id IS NOT NULL
	AND vb.id=coalesce(@build,vb.id)
	AND vds.sup_id=coalesce(@sup_id,vds.sup_id)
	AND p.fin_id BETWEEN @fin_id1 AND @fin_id2  --p.fin_id=coalesce(126,p.fin_id)      
	AND vds.tip_id=coalesce(@tip_id,vds.tip_id)  
	AND vds.is_cessia=1                                     

END
go

