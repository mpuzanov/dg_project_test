CREATE   PROCEDURE [dbo].[rep_CounterHouse]
(
	  @fin_id SMALLINT
	, @tip_id SMALLINT
	, @build_id INT = NULL
	, @town_id SMALLINT = NULL
	, @service_id VARCHAR(10) = NULL
)
AS
	/*
	exec rep_CounterHouse 232, 4, null, null, 'хвод'
	*/

	SET NOCOUNT ON


	DECLARE @t TABLE (
		  tip_id SMALLINT
		, build_id INT
		, service_id VARCHAR(10)
		, short_name VARCHAR(20)
		, unit_id VARCHAR(10)
		, is_boiler BIT
		, V_start DECIMAL(15, 6) DEFAULT 0
		, V1 DECIMAL(15, 4) DEFAULT 0
		, V_arenda DECIMAL(15, 4) DEFAULT 0
		, V_norma DECIMAL(15, 4) DEFAULT 0
		, V_add DECIMAL(15, 4) DEFAULT 0
		, V2 DECIMAL(15, 4) DEFAULT 0
		, V3 DECIMAL(15, 4) DEFAULT 0
		, V_economy DECIMAL(15, 6) DEFAULT 0
		, block_paym_V BIT DEFAULT 0
		, v_itog DECIMAL(15, 6) DEFAULT 0
	)

	DECLARE cursor_name CURSOR FOR
		SELECT bldn_id
		FROM dbo.View_build_all vba
		WHERE vba.fin_id = @fin_id
			AND vba.tip_id = @tip_id
			AND (vba.bldn_id = @build_id OR @build_id IS NULL)
			AND (vba.town_id = @town_id OR @town_id IS NULL)

	OPEN cursor_name;
	FETCH NEXT FROM cursor_name INTO @build_id;
	WHILE @@fetch_status = 0
	BEGIN
		PRINT @build_id
		
		INSERT INTO @t(tip_id,build_id,service_id,short_name,unit_id,is_boiler,V_start,V1,V_arenda,V_norma,V_add,V2,V3,V_economy,block_paym_V,v_itog)
		EXEC k_intPrintCounterHouse @occ1 = NULL
								  , @fin_id = @fin_id
								  , @build_id = @build_id
		
		FETCH NEXT FROM cursor_name INTO @build_id;
	END
	CLOSE cursor_name;
	DEALLOCATE cursor_name;

	SELECT vb.street_name
		 , vb.nom_dom
		 , t.*
	FROM @t AS t
		JOIN dbo.View_buildings vb ON 
			t.build_id = vb.id
	WHERE 
		(t.service_id = @service_id OR @service_id IS NULL)
	ORDER BY vb.street_name
		   , vb.nom_dom_sort
go

