CREATE   FUNCTION [dbo].[Fun_GetSUPFromSchetl]
(
	  @Schetl INT
)
RETURNS INT
AS
BEGIN
/*
 Возвращаем код поставщика по из лицевого счета

 select dbo.Fun_GetSUPFromSchetl(@schet1)
 select dbo.Fun_GetSUPFromSchetl(560291983)
 select dbo.Fun_GetSUPFromSchetl(776055383)
 								 
*/
	RETURN COALESCE(
	(
	-- Поставщик должен быть на лицевом в текущем или предыдущем месяце
	SELECT TOP (1) sup_id
	FROM dbo.Occ_Suppliers AS os
		JOIN dbo.Occupations AS O 
		ON os.occ = O.occ 
		AND (O.fin_id = os.fin_id OR (os.fin_id = O.fin_id - 1))		
	WHERE occ_sup = @Schetl

	), 0)
END
go

