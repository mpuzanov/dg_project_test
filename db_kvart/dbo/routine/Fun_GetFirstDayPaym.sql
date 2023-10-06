CREATE   FUNCTION [dbo].[Fun_GetFirstDayPaym]
(
	@occ1		INT
	,@fin_id1	SMALLINT
)
RETURNS SMALLDATETIME
AS
BEGIN
	/*
	--  Возвращаем дату с первым днем оплаты в заданном месяце
	*/
	RETURN (	
		SELECT TOP 1
			p2.day
		FROM dbo.Payings AS p1 
		JOIN dbo.Paydoc_packs AS p2 
			ON p1.pack_id = p2.id
		WHERE p1.occ = @occ1
			AND p2.forwarded = cast(1 as bit)
			AND p2.fin_id = @fin_id1
		ORDER BY p2.day
	)
	
END
go

