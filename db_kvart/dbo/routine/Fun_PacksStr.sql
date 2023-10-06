CREATE   FUNCTION [dbo].[Fun_PacksStr]
(
	@occ1		INT
	,@fin_id1	SMALLINT
)
RETURNS VARCHAR(50)
AS
BEGIN
	/*	
	  Выдаем строку номера пачек по лицевому  и фин. периоду
	  для оборотно-сальдовой ведомости по лицевым
	  
	  select dbo.Fun_PacksStr(680000013,172)
	  
	*/
	RETURN COALESCE((SELECT
			STUFF((SELECT
					',' + LTRIM(STR(p1.pack_id))
				FROM dbo.PAYINGS AS p1 
				JOIN dbo.PAYDOC_PACKS AS p2 
					ON p1.pack_id = p2.id
				WHERE p1.occ = @occ1
				AND p2.fin_id = @fin_id1
				FOR XML PATH (''))
			, 1, 1, ''))
	, '')

END
go

