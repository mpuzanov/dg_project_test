-- =============================================
-- Author:		Пузанов
-- Create date: 22.04.2017
-- Description:	
-- =============================================
CREATE     FUNCTION [dbo].[Fun_Tbl_DolgMesCalSup]
(
	@fin_id		SMALLINT
	,@occ		INT
	,@sup_id INT = NULL
)
RETURNS TABLE
/*
select * FROM [dbo].[Fun_Tbl_DolgMesCalSup](182,680000008,323)
OUTER APPLY [dbo].Fun_Tbl_DolgMesCalSup(182,680000008) AS sup_dolg
*/
AS
RETURN (
	SELECT
		sup_id
		,CAST(kol_month AS SMALLINT) + CAST((Itog / CASE
                                                        WHEN t2.paid = 0 THEN 1
                                                        ELSE t2.paid
        END) AS SMALLINT) AS kol_mes
		FROM (SELECT sup_id,
				COUNT(*) AS kol_month
				,MIN(t2.Itog) AS Itog
				,MAX(t2.paid) AS paid
			FROM (SELECT
					sup_id
					,fin_id
					,paid
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
					AND	occ = @occ
					AND (sup_id=@sup_id OR @sup_id IS NULL)
					) AS t) AS t2
			WHERE t2.Itog > 0 
			GROUP BY sup_id ) AS t2
)
go

