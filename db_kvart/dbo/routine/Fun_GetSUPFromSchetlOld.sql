CREATE   FUNCTION [dbo].[Fun_GetSUPFromSchetlOld]
(
	  @Schetl VARCHAR(10)
)
RETURNS INT
AS
BEGIN

	/*
-- Возвращаем код поставщика по из лицевого счета
 select dbo.Fun_GetSUPFromSchetlOld(@schet1)
 select dbo.Fun_GetSUPFromSchetlOld(560291983)
 select dbo.Fun_GetSUPFromSchetlOld(776055383)
 								 
*/
	RETURN COALESCE(
	(
	-- Поставщик должен быть на лицевом в текущем или предыдущем месяце
	SELECT TOP 1 sup_id
	FROM dbo.Occ_Suppliers AS os 
		JOIN dbo.Occupations AS O 
		ON os.Occ = O.Occ 
		AND (O.fin_id = os.fin_id OR (O.fin_id - 1 = os.fin_id))			
	WHERE occ_sup = CAST(@Schetl AS INT)

	), 0)
END
go

