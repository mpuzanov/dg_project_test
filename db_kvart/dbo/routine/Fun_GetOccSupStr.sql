-- =============================================
-- Author:		Пузанов
-- Create date: 03.09.2013
-- Description:	Получаем строку лиц.счетов поставщиков
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetOccSupStr]
(
	@occ1		INT
	,@fin_id1	SMALLINT
	,@sup_id	INT = NULL
)
RETURNS VARCHAR(100)
/*

select [dbo].[Fun_GetOccSupStr](315246,138,null)
select [dbo].[Fun_GetOccSupStr](680000572,180,null)
select [dbo].[Fun_GetOccSupStr](680000572,180,347)

*/
AS
BEGIN
	RETURN COALESCE((SELECT
			STUFF((SELECT
					',' + LTRIM(STR([occ_sup]))
				FROM dbo.occ_suppliers os
				WHERE OS.occ = @occ1 
				AND OS.fin_id = @fin_id1
				AND (os.sup_id=@sup_id OR @sup_id IS NULL)
				GROUP BY occ_sup
				FOR XML PATH (''))
			, 1, 1, '')),'')

END
go

