CREATE   FUNCTION [dbo].[Fun_GetDOGFromSchetl]
(
    @Schetl INT
)
RETURNS INT
AS
BEGIN

	/*
-- Возвращаем код договора по из лицевого счета
-- select dbo.Fun_GetDOGFromSchetl(@schet1)
*/
RETURN (
    SELECT TOP (1) dog_int
	FROM dbo.OCC_SUPPLIERS AS os 
		JOIN dbo.OCCUPATIONS AS O 
			ON os.occ = O.occ AND O.fin_id = os.fin_id		
	WHERE occ_sup = @schetl
    )

END
go

