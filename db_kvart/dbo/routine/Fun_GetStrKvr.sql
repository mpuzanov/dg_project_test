-- =============================================
-- Author:		Пузанов
-- Create date: 24.01.08
-- Description:	Функция возвращает Адрес квартиры по её коду
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetStrKvr]
(
	@flat_id INT
)
RETURNS VARCHAR(60)
AS
BEGIN

	RETURN
	CAST((SELECT
			RTRIM(s.name) + ' д.' + nom_dom + ' кв.' + f.nom_kvr
		FROM dbo.BUILDINGS AS b 
		JOIN dbo.VSTREETS AS s
			ON b.street_id = s.id
		JOIN dbo.FLATS AS f
			ON f.bldn_id = b.id
		WHERE f.id = @flat_id)
	AS VARCHAR(60)
	)


END
go

