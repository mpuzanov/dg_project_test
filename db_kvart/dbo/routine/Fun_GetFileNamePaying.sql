-- =============================================
-- Author:		Пузанов
-- Create date: 13.06.2012
-- Description:	Возвращает наименование файла платежа по коду платежа
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetFileNamePaying]
(
	@paying_id INT
)
RETURNS VARCHAR(100)
AS
BEGIN
	RETURN COALESCE((SELECT
			bs.filenamedbf
		FROM dbo.Payings AS p
		JOIN dbo.Bank_tbl_spisok AS bs
			ON p.filedbf_id = bs.filedbf_id
		WHERE p.id = @paying_id)
	, '')

END
go

exec sp_addextendedproperty 'MS_Description', N'Возвращает наименование файла платежа по коду платежа', 'SCHEMA', 'dbo',
     'FUNCTION', 'Fun_GetFileNamePaying'
go

