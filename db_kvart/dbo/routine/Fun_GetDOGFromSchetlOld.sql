CREATE   FUNCTION [dbo].[Fun_GetDOGFromSchetlOld]
(
	  @Schetl VARCHAR(10)
)
RETURNS INT
AS
BEGIN

	/*
-- Возвращаем код договора по из лицевого счета
-- select dbo.Fun_GetDOGFromSchetl(@schet1)
*/
RETURN (SELECT TOP (1) dog_int
        FROM dbo.Occ_Suppliers AS os
                 JOIN dbo.Occupations AS O ON os.Occ = O.Occ AND O.fin_id = os.fin_id
        WHERE occ_sup = CAST(@Schetl AS INT)
)
END
go

