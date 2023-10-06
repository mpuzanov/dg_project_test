CREATE   PROCEDURE [dbo].[ka_show_services]
(
	@occ1			INT
	,@serv_people1	BIT	= 0
	,@is_counter1	BIT	= 0
)
AS
	/*
		Выдаем список услуг для разовых по людям
		
		ka_show_services 170004858,0,0
		ka_show_services 680003383,0,1
		
	*/
	SET NOCOUNT ON

	IF @is_counter1 = 0
		SET @is_counter1 = NULL

	IF @serv_people1 = 1
	BEGIN
		SELECT
			ROW_NUMBER() OVER (ORDER BY s.name) AS ROW_NUM
			,s.*
			,cl.sup_id
			,sa.name AS sup_name
			,CONCAT(s.name , ' (' , sa.name , ')') AS name2
		FROM dbo.OCCUPATIONS AS o 
		JOIN OCCUPATION_TYPES ot 
			ON o.tip_id = ot.id
		JOIN dbo.CONSMODES_LIST AS cl 
			ON o.occ = cl.occ
		JOIN dbo.View_SERVICES AS s 
			ON cl.service_id = s.id
		JOIN dbo.SERVICE_UNITS AS su 
			ON o.roomtype_id = su.roomtype_id
			AND s.id = su.service_id
			AND su.fin_id = o.fin_id
			AND su.tip_id = o.tip_id
		JOIN dbo.SUPPLIERS_ALL sa
			ON cl.sup_id = sa.id
		WHERE o.occ = @occ1
		AND (
		(cl.mode_id % 1000) != 0
		OR (cl.source_id % 1000) != 0
		)
		AND su.unit_id = 'люди'
		AND (s.is_counter = @is_counter1
		OR @is_counter1 IS NULL)
		ORDER BY s.name
	END
	ELSE
	BEGIN
		SELECT
			ROW_NUMBER() OVER (ORDER BY s.name) AS ROW_NUM
			,s.*
			,cl.sup_id
			,sa.name AS sup_name
			,CONCAT(s.name , ' (' , sa.name , ')') AS name2
		FROM dbo.OCCUPATIONS AS o 
		JOIN dbo.CONSMODES_LIST AS cl 
			ON o.occ = cl.occ
		JOIN dbo.View_SERVICES AS s 
			ON cl.service_id = s.id
		JOIN dbo.SUPPLIERS_ALL sa
			ON cl.sup_id = sa.id
		WHERE o.occ = @occ1
		AND (
		(cl.mode_id % 1000) != 0
		OR (cl.source_id % 1000) != 0
		)
		AND (s.is_counter = @is_counter1
		OR @is_counter1 IS NULL)
		ORDER BY s.name
	END
go

