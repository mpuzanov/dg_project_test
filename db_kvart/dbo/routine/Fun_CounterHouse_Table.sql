-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE           FUNCTION [dbo].[Fun_CounterHouse_Table]
(
	  @build_id INT
	, @fin_id SMALLINT = NULL
	, @debug BIT = 0
)
/*
SELECT * FROM [dbo].[Fun_CounterHouse_Table](6922, 250,0)
*/
RETURNS @t TABLE (
	  tip_id SMALLINT
	, build_id INT
	, service_id VARCHAR(10)
	, short_name VARCHAR(50)
	, unit_id VARCHAR(10) DEFAULT NULL
	, short_id VARCHAR(10) DEFAULT NULL
	, is_boiler BIT
	, V_start DECIMAL(15, 6) DEFAULT 0
	, V1 DECIMAL(15, 6) DEFAULT 0
	, V_arenda DECIMAL(15, 6) DEFAULT 0
	, V_norma DECIMAL(15, 6) DEFAULT 0
	, V_add DECIMAL(15, 6) DEFAULT 0
	, V_load_odn DECIMAL(15, 6) DEFAULT 0	
	, V2 DECIMAL(15, 6) DEFAULT 0
	, V3 DECIMAL(15, 6) DEFAULT 0
	, block_paym_V BIT DEFAULT 0
	, V_itog DECIMAL(15, 6) DEFAULT 0
	, V_economy DECIMAL(15, 6) DEFAULT 0
)
AS
BEGIN
	DECLARE @tip_id SMALLINT
		  , @is_ValueBuildMinus BIT
		  , @fin_current SMALLINT = dbo.Fun_GetFinCurrent(NULL, @build_id, NULL, NULL)

	SELECT @tip_id = vba.tip_id
		 , @is_ValueBuildMinus = COALESCE(OT.is_ValueBuildMinus, 0)
	FROM dbo.View_build_all AS vba 
		JOIN dbo.Occupation_Types OT ON vba.tip_id = OT.id
	WHERE vba.fin_id = @fin_id
		AND vba.bldn_id = @build_id

	IF @fin_id IS NULL
		SELECT @fin_id = @fin_current

	INSERT INTO @t
		(tip_id
	   , build_id
	   , service_id
	   , short_name
	   , unit_id
	   , short_id
	   , is_boiler
	   , V_start
	   , V1
	   , V_arenda
	   , V_norma
	   , V_add
	   , V_load_odn
	   , V2
	   , V3
	   , V_itog
	   , V_economy)
	SELECT @tip_id
		 , bsv.build_id
		 , bsv.service_id
		 , CASE
               WHEN sb.service_name IS NOT NULL THEN substring(sb.service_name, 1, 30)
               ELSE S.short_name
        END AS short_name
		 , bsv.unit_id
		   --,U.short_id
		 , (
			   SELECT TOP 1              -- 01.04.2019
				   u.short_id
			   FROM dbo.Service_units AS su 
				   JOIN dbo.Units u ON su.unit_id = u.id
			   WHERE fin_id = bsv.fin_id
				   AND service_id = S.id
				   AND tip_id = b.tip_id
		   ) AS short_id
		 , COALESCE(B.is_boiler,0) AS is_boiler
		 , bsv.value_start
		 , bsv.value_source
		 , bsv.value_arenda
		 , bsv.value_norma + bsv.value_ipu +
									CASE
										WHEN B.is_boiler = 1 THEN COALESCE(bsv.value_gvs, 0)
										ELSE 0
									END AS V_norma
		 , bsv.value_add
		 , bsv.value_odn
		 , 0 AS V2
		 , 0 AS V3
		 , bsv.v_itog
		 , CASE
               WHEN bsv.v_itog < 0 THEN bsv.v_itog
               ELSE 0
        END -- V_economy
	FROM dbo.Build_source_value bsv 
		JOIN dbo.Services AS S ON bsv.service_id = S.id
		JOIN dbo.Units AS U ON bsv.unit_id = U.id
		JOIN dbo.Buildings AS B ON bsv.build_id = B.id
		LEFT JOIN dbo.Services_build as sb ON sb.build_id=b.id AND sb.service_id=bsv.service_id
	WHERE bsv.fin_id = @fin_id
		AND bsv.build_id = @build_id

	DELETE FROM @t
	WHERE V_norma <= 0
	AND V_itog=0

	--IF @debug = 1
	--	SELECT *
	--	FROM @t

	---- Изменяем если есть названия услуг по разным типам фонда
	--UPDATE t
	--SET short_name = st.service_name
	--FROM @t AS t
	--JOIN dbo.SERVICES_TYPES AS st
	--	ON t.tip_id = st.tip_id AND t.service_id = st.service_id

	UPDATE t
	SET V2 = V_arenda + V_norma --+ V_add
	  , V3 = V1 - (V_arenda + V_norma) -- + V_add)
	FROM @t AS t

	UPDATE t
	SET V3 = 0
	FROM @t AS t
	WHERE (V3 < 0 AND @is_ValueBuildMinus = 0)
		OR V2 = 0

	--UPDATE t
	--SET V3 = v_itog
	--FROM @t AS t
	--WHERE v_itog>0
	
	RETURN
END
go

