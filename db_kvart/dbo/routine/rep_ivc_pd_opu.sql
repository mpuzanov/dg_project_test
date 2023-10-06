-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[rep_ivc_pd_opu]
(
	  @fin_id SMALLINT
	, @occ INT = NULL
	, @sup_id INT = NULL
	, @build_id INT = NULL
	, @all BIT = NULL
	, @debug BIT = 0
	, @tip_id SMALLINT = NULL
)
AS
/*
EXEC rep_ivc_pd_opu @fin_id=228, @build_id=null, @sup_id=null, @occ=31001, @all=1
EXEC rep_ivc_pd_opu @fin_id=232,@occ=31001,@build_id=6785,@all=1
EXEC rep_ivc_pd_opu @fin_id=232,@occ=null,@build_id=6785,@all=1
EXEC rep_ivc_pd_opu @fin_id=232,@occ=null,@build_id=null, @tip_id=1, @all=1
*/
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #temp;
	CREATE TABLE #temp (
		  serv_name VARCHAR(100) COLLATE database_default
		, serial_number VARCHAR(20) COLLATE database_default DEFAULT NULL
		, unit_id VARCHAR(10) COLLATE database_default DEFAULT NULL
		, pred_value DECIMAL(14, 6) DEFAULT NULL
		, pred_date DATE DEFAULT NULL
		, inspector_value DECIMAL(14, 6) DEFAULT NULL
		, inspector_date DATE DEFAULT NULL
		, actual_value DECIMAL(14, 6) DEFAULT NULL
		, service_id VARCHAR(10) COLLATE database_default DEFAULT NULL
		, sup_id INT DEFAULT NULL
		, koef DECIMAL(9, 4) DEFAULT NULL
		, build_id INT DEFAULT NULL
	)

	INSERT INTO #temp
	EXEC dbo.k_intPrintCounterOpu @fin_id = @fin_id
								, @occ = @occ
								, @sup_id = @sup_id
								, @build_id = @build_id
								, @all = @all
								, @debug = @debug

	SELECT 'ОДН' AS type
		 , 'Общедомовой' AS [name]
		 , t.serv_name AS usluga
		 , t.serial_number AS number
		 , t.unit_id AS ed
		 , t.pred_value AS last_value
		 , t.pred_date AS last_date
		 , t.inspector_value AS current_value
		 , t.inspector_date AS [current_date]
		 , t.actual_value AS rashod
		 , t.koef AS coef
		 , t.build_id AS build_id
	FROM #temp t
END
go

