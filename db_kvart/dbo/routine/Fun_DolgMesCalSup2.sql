CREATE   FUNCTION [dbo].[Fun_DolgMesCalSup2]
(
	@fin_id		SMALLINT
	,@occ		INT
	,@sup_id	INT
)
RETURNS SMALLINT
AS
/*
Количество календарных месяцев долга по поставщику  
  
SELECT [dbo].Fun_DolgMesCalSup2(180,680000008,347)
SELECT [dbo].Fun_DolgMesCalSup2 (175,680000008,323)

*/

BEGIN
	RETURN
	COALESCE((SELECT CASE
                         WHEN t2.Itog = 0 THEN kol_month - 1
                         ELSE kol_month
                         END + CAST((Itog / CASE
                                                                     WHEN t2.paid = 0 THEN 1
                                                                     ELSE t2.paid
        END) AS SMALLINT)
		FROM (SELECT
				COUNT(*) AS kol_month
				,MIN(t2.Itog) AS Itog
				,MAX(t2.paid) AS paid
			FROM (SELECT
					fin_id
					,paid
					,FIRST_VALUE(dolg) OVER (PARTITION BY sup_id ORDER BY fin_id DESC) AS dolg
					,FIRST_VALUE(dolg) OVER (PARTITION BY sup_id ORDER BY fin_id DESC)
					- SUM(paid) OVER (PARTITION BY sup_id ORDER BY fin_id DESC
					ROWS BETWEEN UNBOUNDED PRECEDING
					AND CURRENT ROW) AS Itog
				FROM (SELECT
						fin_id
						,sup_id
						,os.saldo - os.paymaccount + os.value AS dolg
						,os.value AS paid
					FROM OCC_SUPPLIERS os
					WHERE fin_id <= @fin_id
					AND occ = @occ
					AND sup_id = @sup_id) AS t) AS t2
			WHERE t2.Itog >= 0
			AND dolg > 0) AS t2)
	, 0)

END
go

