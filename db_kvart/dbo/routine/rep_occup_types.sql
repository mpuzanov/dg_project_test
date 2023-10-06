CREATE   PROCEDURE [dbo].[rep_occup_types]
(
	@tip_id		SMALLINT	= NULL
	,@town_id	INT			= NULL
)
AS
/*
exec rep_occup_types
exec rep_occup_types @tip_id=4
exec rep_occup_types @town_id=1
*/
SET NOCOUNT ON

;with cte AS
(SELECT
	t.id
	,t.NAME
	,t.payms_value
	,t.fin_id
	,t.only_read
	,t.state_id
	,t.id_accounts
	,t.start_date		
	,t.StrMes AS FinName
	,t.StrMes
	,t.PaymClosed
	,COALESCE(t.email_subscribe,'') AS email_subscribe
	,ra.FileName AS Account_name
	,ra.NAME AS ReportName
	,t_build.cnt_paym AS kol_build
	,t_build.cnt AS build_cnt
	,t.logo
FROM dbo.VOcc_types AS t
LEFT JOIN dbo.Reports_account AS ra ON t.id_accounts = ra.id
CROSS APPLY (
	SELECT
		COUNT(id) as cnt
		,SUM(CASE WHEN is_paym_build = 1 THEN 1 ELSE 0 END) AS cnt_paym
	FROM dbo.Buildings AS B 
	WHERE B.tip_id = t.id
) as t_build
WHERE 
	(@tip_id IS NULL OR t.id = @tip_id)
	AND t.raschet_no = CAST(0 AS BIT)
)
SELECT * FROM cte WHERE build_cnt>0;
go

