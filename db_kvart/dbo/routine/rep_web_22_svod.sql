-- =============================================
-- Author:		Антропов
-- Create date: 29.10.2007
-- Предоставление лгот по ЖКУ(по  шифрам с разбивкой по услугам)
-- =============================================
CREATE       PROCEDURE [dbo].[rep_web_22_svod](@fin_id1 sysname = null,
                                         @tip_str1 varchar(2000), -- список типов фонда через запятую
                                         @law_id smallint =null
)
AS
SET NOCOUNT ON;


if @fin_id1 is null 
	SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

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

select dbo.Fun_NameFinPeriod(@fin_id1) AS 'Фин_пер'
       ,dl.name                         AS 'Закон'
       ,dr.lgotaall                     AS 'Льгота'
       ,dr.service_id                   as 'Услуга'
       ,sum(dr.discount)                as 'итого'
From dbo.View_PAYM_LGOTA_ALL as dr
         JOIN dbo.VOCC_HISTORY as o  ON dr.occ = o.occ and dr.fin_id = o.fin_id
         JOIN dbo.dsc_groups as dg ON dr.lgotaall = dg.id
         JOIN dbo.DSC_LAWS as dl ON dg.law_id = dl.id
         JOIN dbo.View_SERVICES as s ON dr.service_id = s.id
where dr.fin_id = @fin_id1
  and dr.discount > 0
  and o.status_id <> 'закр'
  and EXISTS(select 1 from #tip_table where tip_id = o.tip_id)
  and dl.id = COALESCE(@law_id, dl.id)
group by dl.name, dr.lgotaall, dr.service_id, s.service_no
order by dl.name, dr.lgotaall, s.service_no
go

