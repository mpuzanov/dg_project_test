-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE           PROCEDURE [dbo].[rep_ivc_pd_house]
(
	  @occ INT = NULL
	, @fin_id SMALLINT = NULL
	, @debug BIT = 0
	, @time SMALLINT = 2
	, @build_id INT = NULL
)
AS
/*
exec rep_ivc_pd_house @occ=910010016, @fin_id=243, @debug=0, @time=0, @build_id=NULL
exec rep_ivc_pd_house @fin_id=243, @debug=0, @time=0, @build_id=6901
*/
BEGIN
	SET NOCOUNT ON

	DROP TABLE IF EXISTS #temp;
	CREATE TABLE #temp
	(
		tip_id			SMALLINT
		,build_id		INT
		,service_id		VARCHAR(10) COLLATE database_default
		,short_name		VARCHAR(50) COLLATE database_default
		,unit_id		VARCHAR(10) COLLATE database_default
		,is_boiler		BIT
		,V_start		DECIMAL(15, 6)	DEFAULT 0
		,V1				DECIMAL(15, 6)	DEFAULT 0
		,V_arenda		DECIMAL(15, 6)	DEFAULT 0
		,V_norma		DECIMAL(15, 6)	DEFAULT 0
		,V_add			DECIMAL(15, 6)	DEFAULT 0
		,V2				DECIMAL(15, 6)	DEFAULT 0
		,V3				DECIMAL(15, 6)	DEFAULT 0
		,V_economy		DECIMAL(15, 6)	DEFAULT 0
		,block_paym_V	BIT				DEFAULT 0
		,v_itog			DECIMAL(15, 6)	DEFAULT 0
	)
	INSERT INTO #temp
	EXEC dbo.k_intPrintCounterHouse @occ1 = @occ
								  , @fin_id = @fin_id
								  , @debug = @debug
								  , @time = @time
								  , @build_id = @build_id

	SELECT 'Общие по дому' AS [type]
		 , t.short_name AS usluga
		 , t.unit_id AS ed
		 , t.V1 AS value_odpu  --Объём коммунальных услуг по ОДПУ
		-- , t.V_arenda
		-- , t.V_norma
		-- , t.V_add
		 , t.V2  AS value_build --Суммарный объём коммун. услуг в помещении дома
		 , t.V3  AS value_odn --Суммарный объём коммун. услуг на общедомовые нужды
	FROM #temp t
END
go

