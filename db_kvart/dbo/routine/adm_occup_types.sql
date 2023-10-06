CREATE   PROCEDURE [dbo].[adm_occup_types]
(
	  @tip_id SMALLINT = NULL
	, @raschet_no BIT = NULL
)
AS
	/*
		exec adm_occup_types
		exec adm_occup_types NULL,0
		exec adm_occup_types 28
	*/
	SET NOCOUNT ON

	SELECT t.*
		 , cp.StrFinPeriod AS FinName
		 , ra.FileName AS Account_name
		 , ra.name AS ReportName
		 , b.kol_build AS kol_build
	FROM dbo.VOcc_types AS t 
		INNER JOIN dbo.Calendar_period cp 
			ON cp.fin_id = t.fin_id
		LEFT JOIN dbo.Reports_account AS ra 
			ON t.id_accounts = ra.id
		CROSS APPLY (
			SELECT COUNT(id) AS kol_build
			FROM dbo.Buildings AS B
			WHERE B.tip_id = t.id
				AND B.is_paym_build = cast(1 as bit)
		) AS b
	WHERE (t.id = @tip_id OR @tip_id IS NULL)
		AND (t.raschet_no = @raschet_no OR @raschet_no IS NULL)
	ORDER BY t.id
go

