-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE                   PROCEDURE [dbo].[k_intPrintCounterHouse2]
(
	@build_id	INT
	,@fin_id	SMALLINT	= NULL
	,@debug		BIT			= 0
)
AS
/*
exec k_intPrintCounterHouse2 700204978, 128
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE	@tip_id					SMALLINT
			,@is_ValueBuildMinus	BIT
			,@fin_current			SMALLINT = dbo.Fun_GetFinCurrent(NULL, @build_id, NULL, NULL)

	SELECT
		@tip_id = tip_id
		,@is_ValueBuildMinus = COALESCE(OT.is_ValueBuildMinus, 0)
	FROM dbo.View_BUILD_ALL AS vba 
	JOIN dbo.OCCUPATION_TYPES OT
		ON vba.tip_id = OT.id
	WHERE vba.fin_id = @fin_id
	AND vba.bldn_id = @build_id

	IF @fin_id IS NULL
		SELECT
			@fin_id = @fin_current

	DELETE bsv
		FROM [dbo].[BUILD_SOURCE_VALUE] AS bsv
	WHERE bsv.build_id = @build_id
		AND bsv.fin_id > 128
		AND NOT EXISTS (SELECT
				1
			FROM [dbo].[PAYM_OCC_BUILD] AS t2
			JOIN dbo.View_OCC_ALL AS voa
				ON t2.occ = voa.occ
				AND t2.fin_id = voa.fin_id
			WHERE t2.service_in = bsv.service_id
			AND t2.fin_id = bsv.fin_id
			AND voa.bldn_id = bsv.build_id)

	DECLARE @t TABLE
		(
			tip_id		SMALLINT
			,build_id	INT
			,service_id	VARCHAR(10)
			,short_name	VARCHAR(50)
			,unit_id	VARCHAR(10)
			,is_boiler	BIT
			,V_start	DECIMAL(15, 6)	DEFAULT 0
			,V1			DECIMAL(15, 6)	DEFAULT 0
			,V_arenda	DECIMAL(15, 6)	DEFAULT 0
			,V_norma	DECIMAL(15, 6)	DEFAULT 0
			,V_add		DECIMAL(15, 6)	DEFAULT 0
			,V_load_odn DECIMAL(15, 6) DEFAULT 0
			,V2			DECIMAL(15, 6)	DEFAULT 0
			,V3			DECIMAL(15, 6)	DEFAULT 0
			,V_economy	DECIMAL(15, 6)	DEFAULT 0
		)

	INSERT INTO @t
	(	tip_id
		,build_id
		,service_id
		,short_name
		,unit_id
		,is_boiler
		,V_start
		,V1
		,V_arenda
		,V_norma
		,V_add
		,V_load_odn
		,V2
		,V3)
			SELECT
				@tip_id
				,bsv.build_id
				,bsv.service_id
				,S.short_name AS short_name
				,U.short_id
				,B.is_boiler
				,bsv.value_start
				,value_source
				,value_arenda
				,value_norma + value_ipu +
					CASE
						WHEN B.is_boiler = 1 THEN coalesce(value_gvs, 0)
						ELSE 0
					END
				,value_add
				,bsv.value_odn
				,0
				,0
			FROM dbo.BUILD_SOURCE_VALUE bsv 
			JOIN dbo.SERVICES AS S 
				ON bsv.service_id = S.id
			JOIN dbo.UNITS AS U 
				ON bsv.unit_id = U.id
			JOIN dbo.BUILDINGS AS B 
				ON bsv.build_id = B.id
			WHERE bsv.fin_id = @fin_id
				AND bsv.build_id = @build_id

	DELETE FROM @t WHERE V_norma <= 0

	--IF @debug = 1
	--	SELECT *
	--	FROM @t

	-- Изменяем если есть названия услуг по разным типам фонда
	UPDATE t
	SET short_name = st.service_name
	FROM @t AS t
	JOIN dbo.services_types AS st 
		ON t.tip_id = st.tip_id
		AND t.service_id = st.service_id

	UPDATE t
	SET short_name = sb.service_name
	FROM @t AS t
	JOIN dbo.Services_build AS sb ON sb.build_id=t.build_id AND sb.service_id=t.service_id		

	UPDATE t
	SET	V2	= V_arenda + V_norma --+ V_add
		,V3	= V1 - (V_arenda + V_norma) -- + V_add)
	FROM @t AS t

	UPDATE t
	SET V3 = 0
	FROM @t AS t
	WHERE (V3 < 0
	AND @is_ValueBuildMinus = 0)
	OR V2 = 0

	SELECT
		tip_id
		 , build_id
		 , service_id
		 , short_name
		 , u.short_id2 AS unit_id
		 , is_boiler		 
		 , V_start AS V_start
		 , V1 AS V1
		 , V_arenda AS V_arenda
		 , V_norma AS V_norma
		 , V_add AS V_add
		 , V_load_odn AS V_load_odn
		 , V2 AS V2
		 , V3 AS V3
		 , V_economy AS V_economy 
	FROM @t t
	JOIN dbo.UNITS AS U ON t.unit_id = U.id
END
go

