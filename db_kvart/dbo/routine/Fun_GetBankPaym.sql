CREATE   FUNCTION [dbo].[Fun_GetBankPaym]
(
	@source_id1 INT
)
RETURNS VARCHAR(50)
AS
/*
--  Возвращаем название банка и тип платежа по коду источника в PAYDOC_PACKS
*/
BEGIN
	RETURN COALESCE((SELECT TOP (1)
			CONCAT(b.short_name , '(' , RTRIM(p2.name) , ')')
		FROM dbo.Paycoll_orgs AS p
		JOIN dbo.Bank AS b 
			ON p.BANK = b.id
		JOIN dbo.Paying_types AS p2 
			ON p.vid_paym = p2.id
		WHERE p.id = @source_id1)
	, '')

END
go

