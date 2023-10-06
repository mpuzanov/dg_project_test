CREATE   FUNCTION [dbo].[Fun_GetNumUV_NAIM]
(
	@occ INT
)
RETURNS VARCHAR(16)
AS
BEGIN
	/*
	
	Функция формирования уникального начисления для базы найм
	
	select dbo.Fun_GetNumUV_NAIM(45321)    -- 0000045321171101	
	select dbo.Fun_GetNumUV_NAIM(85607809) -- 0085607809171101
	*/

	RETURN (SELECT
			--('%010i171101', @occ)
			CONCAT(dbo.Fun_AddLeftZero(@occ,10), '171101')
			)

END
go

