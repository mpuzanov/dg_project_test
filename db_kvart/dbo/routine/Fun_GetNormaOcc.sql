-- =============================================
-- Author:		Пузанов
-- Create date: 08.08.16
-- Description:	Получить норму по лиц.счёту
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetNormaOcc]
(
	@occ			INT
	,@service_id	VARCHAR(10)
	,@fin_id		SMALLINT
)
RETURNS DECIMAL(12, 6)
/*

select [dbo].[Fun_GetNormaOcc](45321,'хвод',173)
select [dbo].[Fun_GetNormaOcc](680004323,'хвод',173)
select [dbo].[Fun_GetNormaOcc](45321,'элек',174)
select [dbo].[Fun_GetNormaOcc](910001676,'хвод',175)

*/
AS
BEGIN
	DECLARE @NormaSingle DECIMAL(12, 6) = 0

	IF @service_id IN ('элек')
		SELECT
			@NormaSingle = (SELECT
					kol_watt
				FROM dbo.MEASUREMENT_EE 
				WHERE mode_id = cl.mode_id
				AND rooms =
					CASE
						WHEN o.rooms = 0 THEN 1
						WHEN o.rooms > 4 THEN 4
						ELSE o.rooms
					END
				AND kol_people =
					CASE
						WHEN o.kol_people = 0 THEN 1
						WHEN o.kol_people > 5 THEN 5
						ELSE o.kol_people
					END
				AND fin_id = @fin_id)
		FROM dbo.OCCUPATIONS o 
		JOIN dbo.CONSMODES_LIST cl
			ON o.occ = cl.occ
		WHERE o.occ = @occ
		AND cl.service_id = @service_id

	ELSE
	BEGIN
		DECLARE @t_serv TABLE
			(
				service_id VARCHAR(10)
			)
		INSERT INTO @t_serv
		(service_id)
		VALUES (@service_id)

		IF (@service_id = 'хвод')
			INSERT INTO @t_serv
			(service_id)
			VALUES ('хвпк')
		IF (@service_id = 'гвод')
			INSERT INTO @t_serv
			(service_id)
			VALUES ('гвпк')

		SELECT
			@NormaSingle = SUM(q_single)
		FROM dbo.OCCUPATIONS o 
		JOIN dbo.CONSMODES_LIST cl 
			ON o.occ = cl.occ
		JOIN @t_serv s
			ON s.service_id=cl.service_id 	
		JOIN dbo.service_units su 
			ON s.service_id=su.service_id
			AND su.roomtype_id=o.ROOMTYPE_ID
			AND su.tip_id=o.tip_id
		JOIN dbo.MEASUREMENT_UNITS AS mu 
			ON mu.unit_id = su.unit_id
			AND mu.mode_id = cl.mode_id
			AND mu.is_counter = 0
			AND mu.tip_id = o.tip_id			
			AND mu.fin_id =  @fin_id
		WHERE su.fin_id = @fin_id
		AND o.occ = @occ
		AND ((cl.mode_id % 1000)<>0 OR (cl.source_id % 1000)<>0)

	END
	RETURN COALESCE(@NormaSingle, 0)

END
go

