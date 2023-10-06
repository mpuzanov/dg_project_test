CREATE   FUNCTION [dbo].[Fun_GetPaymAccountStorno]
(
	  @fin_id SMALLINT
	, @occ INT
	, @sup_id INT
)
RETURNS DECIMAL(9, 2)
AS
/*
Возвращаем сумму сторнированных платежей по лицевому
  
SELECT dbo.Fun_GetPaymAccountStorno (238,100011,345)
SELECT dbo.Fun_GetPaymAccountStorno (238,100011,0)

*/

BEGIN

	RETURN COALESCE(

	(SELECT SUM(p.value)
	FROM dbo.Payings AS p
		JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
		JOIN dbo.Paycoll_orgs po ON pd.source_id = po.id
		JOIN dbo.Paying_types pt ON po.vid_paym = pt.id
	WHERE p.occ = @occ
		AND pd.fin_id = @fin_id
		AND pd.sup_id = @sup_id
		AND pt.is_storno = cast(1 as bit)
		AND (p.value < 0)

	), 0)

END
go

