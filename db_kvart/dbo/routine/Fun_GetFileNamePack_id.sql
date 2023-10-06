-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Возвращает список реестров платежей в пачке
-- =============================================
CREATE         FUNCTION [dbo].[Fun_GetFileNamePack_id]
(
	@pack_id INT
)
RETURNS VARCHAR(1000)
AS
/*
select dbo.Fun_GetFileNamePack_id(49725)
*/
BEGIN
	RETURN LTRIM(COALESCE(
	    STUFF(
		(SELECT ', ' + bs.filenamedbf
		FROM dbo.Payings AS p
		JOIN dbo.Bank_tbl_spisok AS bs
			ON p.filedbf_id = bs.filedbf_id
		WHERE p.pack_id = @pack_id
		GROUP BY bs.filenamedbf
		FOR XML PATH (''))
	   ,1, 1, '')
	, ''))

END
go

