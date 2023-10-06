CREATE   PROCEDURE [dbo].[rep_ivc_value]
(
	  @fin_id SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @debug BIT = NULL
	, @format VARCHAR(10) = NULL
)
AS
/*
	
rep_ivc_value @tip_id=1,@fin_id=232,@build_id=6786,@debug=0,@format='xml'
rep_ivc_value @tip_id=1,@fin_id=232,@build_id=null, @sup_id=345
*/
	SET NOCOUNT ON;


	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL);

	IF @build_id = 0
		SET @build_id = NULL;

	SELECT --oh.occ AS 'LC_Nomer'
		dbo.Fun_GetFalseOccOut(oh.occ, oh.tip_id) AS LC_Nomer
	  , CAST('ЖКУ' AS VARCHAR(30)) AS 'Tip_nachisleniya'
	  , CAST(oh.start_date AS DATE) AS 'Period'
	  , SUM(oh.paid + oh.Paid_minus) + SUM(oh.Penalty_value) AS 'Nachisleno'
	  , SUM(oh.paid + oh.Paid_minus) AS 'Nachisleno_Uslugi'
	  , SUM(oh.Penalty_value) AS 'Nachisleno_Peni'
	INTO #t
	FROM dbo.View_occ_all AS oh 
	WHERE 
		oh.fin_id = @fin_id
		AND (@tip_id IS NULL OR oh.tip_id = @tip_id)
		AND (@build_id IS NULL OR oh.bldn_id = @build_id)
		AND (@sup_id IS NULL)
		AND oh.status_id <> 'закр'
		AND oh.total_sq > 0
		AND (oh.paid <> 0 OR oh.debt <> 0 OR oh.Penalty_old_new <> 0 OR oh.Penalty_value <> 0)
	GROUP BY oh.start_date
		   , oh.build_id
		   , oh.occ
		   , oh.tip_id
		   , oh.status_id;

	--////////  По поставщикам

	INSERT INTO #t
	SELECT os.occ_sup AS 'LC_Nomer'
		 , CASE
               WHEN sup.tip_occ = 3 THEN 'Кап. ремонт'
               ELSE 'ЖКУ'
        END AS Tip_nachisleniya
		 , CAST(oh.start_date AS DATE) AS 'Period'
		 , SUM(os.paid + os.Penalty_value) AS 'Nachisleno'
		 , SUM(os.paid) AS 'Nachisleno_Uslugi'
		 , SUM(os.Penalty_value) AS 'Nachisleno_Peni'
	FROM dbo.View_occ_all AS oh 
		JOIN dbo.Occ_Suppliers AS os ON 
			oh.fin_id = os.fin_id
			AND oh.occ = os.occ
		JOIN dbo.Suppliers_all sa ON 
			os.sup_id = sa.id
		LEFT JOIN dbo.Suppliers_all AS sup ON 
			os.sup_id = sup.id
	WHERE 
		oh.fin_id = @fin_id
		AND (@tip_id IS NULL OR oh.tip_id = @tip_id)
		AND (@build_id IS NULL OR oh.bldn_id = @build_id)
		AND (@sup_id IS NULL OR os.sup_id = @sup_id)
		AND oh.status_id <> 'закр'
		AND oh.total_sq > 0
		AND sup.tip_occ IN (1, 3)
	GROUP BY oh.start_date
		   , oh.occ
		   , oh.status_id
		   , os.occ_sup
		   , sup.tip_occ
		   , sa.name;


	IF @format IS NULL OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t

	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+ (
				SELECT *
				FROM #t
				FOR XML PATH ('nachislenie_LC'), ELEMENTS, ROOT ('nachisleniya')
			) AS result

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('nachisleniya')
			) AS result

DROP TABLE IF EXISTS #t;
go

