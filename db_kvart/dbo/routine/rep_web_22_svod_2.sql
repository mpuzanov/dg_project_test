-- =============================================
-- Author:		Антропов
-- Create date: 30.10.2007
-- Description:	Предоставление лгот по ЖКУ(по  шифрам с разбивкой по услугам)
-- =============================================
CREATE       PROCEDURE [dbo].[rep_web_22_svod_2]
(@fin_id1 SMALLINT = NULL,
@tip_str1 VARCHAR(2000), -- список типов фонда через запятую
@law_id SMALLINT =NULL
)
AS
SET NOCOUNT ON

IF @fin_id1 IS NULL 
	SELECT @fin_id1=dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

--************************************************************************************
-- Таблица значениями Типа жил.фонда
CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
INSERT INTO #tip_table(tip_id)
SELECT vs.id
FROM dbo.VOcc_types AS vs
	OUTER APPLY STRING_SPLIT(@tip_str1, ',') AS t
WHERE @tip_str1 IS NULL OR t.value=vs.id
--select * from #tip_table
--************************************************************************************

SELECT 
	dbo.Fun_NameFinPeriod(@fin_id1) AS 'Фин_пер',
	dl.name AS 'Закон',
	dr.lgotaall AS 'Льгота',
	dr.service_id AS 'Услуга',
	COUNT(DISTINCT owner_id) AS Kol_people, 
	COUNT(DISTINCT owner_lgota) AS Kol_lg,
	SUM(dr.discount) AS 'итого'
FROM dbo.View_PAYM_LGOTA_ALL AS dr
     JOIN dbo.View_OCC_ALL AS o ON dr.occ=o.occ AND dr.fin_id=o.fin_id
     JOIN dbo.dsc_groups AS dg ON dr.lgotaall=dg.id
     JOIN dbo.DSC_LAWS AS dl ON dg.law_id=dl.id
	 JOIN dbo.View_SERVICES AS s ON dr.service_id=s.id
WHERE 
	dr.fin_id=@fin_id1 
	AND dr.discount>0
	AND o.status_id<>'закр'
	AND EXISTS (SELECT 1 FROM #tip_table WHERE tip_id=o.tip_id)
	AND dl.id = COALESCE(@law_id,dl.id)
GROUP BY dl.name, dr.lgotaall,dr.service_id,s.service_no
ORDER BY dl.name,dr.lgotaall,s.service_no
go

