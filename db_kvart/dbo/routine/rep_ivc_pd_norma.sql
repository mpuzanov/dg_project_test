-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[rep_ivc_pd_norma]
(
	  @fin_id SMALLINT
	, @build_id INT
	, @occ INT = NULL
	, @sup_id INT = NULL
	, @all BIT = 0
	, @debug BIT = NULL
)
AS
BEGIN
	/*
	exec rep_ivc_pd_norma @fin_id=230,@build_id=6785,@occ=null,@sup_id=null,@all=1,@debug=0
	*/
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #temp;
	CREATE TABLE #temp (
		  occ INT
		, serv_name VARCHAR(100) COLLATE database_default DEFAULT NULL
		, unit_id VARCHAR(10) COLLATE database_default DEFAULT NULL
		, kol_norma DECIMAL(12, 6) DEFAULT NULL
		, service_name_gis VARCHAR(100) COLLATE database_default DEFAULT NULL
	)

	INSERT INTO #temp
	EXEC dbo.k_intPrintNormaBuild @fin_id = @fin_id
								, @build_id = @build_id
								, @occ = @occ
								, @sup_id = @sup_id
								, @all = @all
								, @debug = @debug

	SELECT t.occ
		 , 'Норматив' AS type
		 , t.serv_name AS usluga
		 , t.unit_id AS ed
		 , t.kol_norma AS ind
	FROM #temp t
END
go

