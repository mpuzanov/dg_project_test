/*

дата создания: 11.09.2003
автор: Антропов С.В.

дата последней модификации: 23.06.2004
автор изменений: Кривобоков А.В.
убрано условие p.paid>0 
и добавлено количество подключений по кабельной антенне 'kolvo'=sum(c.mode_id%1000)

дата последней модификации: 22.12.2004
автор изменений: Кривобоков А.В.
добавлена возможность выбора поставщика 
*/ 




CREATE   PROCEDURE [dbo].[rep_kab_tv]
(  
   @fin_id1 SMALLINT = NULL,  -- Фин.период
   @tip SMALLINT=NULL ,-- тип жилого фонда
   @service_id VARCHAR(10),
   @source_id INT=NULL -- поставщик
)
AS

--
SET NOCOUNT ON


DECLARE @fin_current SMALLINT
SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

IF @fin_id1=NULL SET @fin_id1=@fin_current

SELECT	d.id
	,d.name
	,b.sector_id
    ,kolvo=SUM(c.mode_id%1000)
	,kolocc=COUNT(p.occ)
	,SUM(p.paid) AS nachisleno
	,SUM(p.paymaccount) AS oplacheno
FROM dbo.View_PAYM AS p,
	dbo.View_BUILD_ALL AS b ,
	dbo.DIVISIONS AS d ,
	dbo.View_OCC_ALL AS o,
    dbo.View_CONSMODES_ALL AS c
WHERE	p.occ=o.occ
	AND p.fin_id=@fin_id1
	AND o.fin_id=@fin_id1
	AND b.fin_id=@fin_id1
	AND p.service_id=@service_id
	AND o.status_id<>'закр'
	AND o.bldn_id=b.bldn_id
	AND b.div_id=d.id
        AND (c.mode_id%1000)<>0
        AND c.service_id=@service_id
        AND c.occ=p.occ
        AND c.fin_id=@fin_id1
        AND c.source_id BETWEEN COALESCE(@source_id,0) AND COALESCE(@source_id,99999)
	AND o.tip_id=COALESCE(@tip,o.tip_id)
GROUP BY d.id,d.name, b.sector_id
ORDER BY d.id DESC,b.sector_id
go

