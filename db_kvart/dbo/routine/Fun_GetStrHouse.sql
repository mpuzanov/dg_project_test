-- =============================================
-- Author:		Пузанов
-- Create date: 24.01.08
-- Description:	Функция возвращает строку дома по его коду
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetStrHouse]
(
	@build_id int
)
RETURNS varchar(50)
AS
BEGIN
/*
select [dbo].[Fun_GetStrHouse](1031)
*/

	RETURN CAST((SELECT CONCAT(rtrim(s.full_name),' д.', nom_dom)
	FROM dbo.Buildings as b
         JOIN dbo.Streets as s ON b.street_id=s.id
    where b.id=@build_id) AS varchar(50) )

END
go

