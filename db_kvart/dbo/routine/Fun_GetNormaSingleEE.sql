-- =============================================
-- Author:		Пузанов
-- Create date: 11.11.11
-- Description:	Получить норму по режиму
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetNormaSingleEE]
(
    @occ             INT,
    @fin_id          SMALLINT,
    @mode_id         INT,
    @kol_rooms       SMALLINT = 0,
    @Total_people_ee SMALLINT = 0
)
/*
SELECT [dbo].[Fun_GetNormaSingleEE](313376, 138, 11001, O.rooms, O.kol_people)
*/
RETURNS DECIMAL(9, 4)
AS
BEGIN
	RETURN coalesce(
	(SELECT kol_watt
	FROM
		dbo.measurement_EE
	WHERE
		mode_id = @mode_id
		AND rooms = CASE WHEN @kol_rooms > 4 THEN
				4 ELSE
				@kol_rooms
		END
		AND kol_people = CASE WHEN @Total_people_ee > 5 THEN
				5 ELSE
				@Total_people_ee
		END
		AND fin_id = @fin_id

	),0)

END
go

