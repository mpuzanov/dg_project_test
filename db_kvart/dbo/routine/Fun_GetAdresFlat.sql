-- =============================================
-- Author:		Пузанов
-- Create date: 25.08.2008
-- Description:	Возвращает адрес квартиры по коду
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetAdresFlat]
(
	@flat_id INT
)
RETURNS VARCHAR(60)
AS
BEGIN
	declare @adres VARCHAR(60)
	
	SELECT @adres= (SELECT TOP 1
			o.address
		FROM dbo.Occupations AS o 
		WHERE o.flat_id = @flat_id)

	IF @adres is NULL
		select @adres = dbo.Fun_GetAdres(NULL,@flat_id,NULL)

	RETURN @adres

END
go

