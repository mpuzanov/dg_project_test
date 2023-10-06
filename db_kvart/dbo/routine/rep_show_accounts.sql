-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Выдаем список квитанций и других отчётов для массовой печати
-- =============================================
CREATE     PROCEDURE [dbo].[rep_show_accounts]
(
	  @tip_id SMALLINT = NULL -- возможно будет использоваться для ограничения выбора квитанций 
	, @FileName VARCHAR(50) = NULL
)
AS
BEGIN
	/*
	rep_show_accounts @tip_id=1
	*/
	SET NOCOUNT ON;

	SELECT Id
		 , name
		 , FileName
		 , REPORT_BODY
		 , 'REPORTS_ACCOUNT' AS table_name
		 , ra.SIZE_REPORT_BODY
	FROM dbo.Reports_account AS ra
		LEFT JOIN dbo.Reports_account_types RAT ON ra.Id = RAT.id_account
	WHERE ra.visible = CAST(1 AS BIT)
		AND (@tip_id IS NULL OR (RAT.id_account IS NOT NULL AND RAT.tip_id = @tip_id))
	UNION ALL
	SELECT Id
		 , name
		 , FileName
		 , REPORT_BODY
		 , 'REPORTS' AS table_name
		 , r.SIZE_REPORT_BODY
	FROM dbo.Reports AS R 
	WHERE is_account = 1
		AND @tip_id IS NULL
		AND R.NO_VISIBLE = CAST(0 AS BIT)
	UNION
	SELECT ra.Id
		 , ra.name
		 , ra.FileName
		 , ra.REPORT_BODY
		 , 'REPORTS_ACCOUNT' AS table_name
		 , ra.SIZE_REPORT_BODY
	FROM dbo.Reports_account AS ra
	WHERE @FileName IS NOT NULL
		AND ra.FileName = @FileName
		AND ra.visible = CAST(1 AS BIT)
	ORDER BY SIZE_REPORT_BODY DESC

END
go

