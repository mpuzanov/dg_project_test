-- =============================================
-- Author:		Пузанов
-- Create date: 15.10.2015
-- Description:	Возвращает расчётный счёт по файлу по коду платежа
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetRaschetPaying]
(
	@paying_id INT
)
RETURNS VARCHAR(20)
AS
BEGIN
	RETURN COALESCE((SELECT
			bs.rasschet
		FROM dbo.Payings AS p 
		JOIN dbo.Bank_tbl_spisok AS bs 
			ON p.filedbf_id = bs.filedbf_id
		WHERE p.id = @paying_id)
	, '')

END
go

