-- =============================================
-- Author:		Пузанов
-- Create date: 13.03.2009
-- Description:	Ввод данных по использованию отчетов
-- =============================================
CREATE     PROCEDURE [dbo].[rep_log_reports]
	@ReportName	VARCHAR(50)
	,@KolSec	INT				= NULL
	,@query		VARCHAR(4000)	= NULL
	,@params	VARCHAR(1000)	= NULL
AS
BEGIN
	SET NOCOUNT ON;


	IF (COALESCE(@ReportName, '') <> '')
		INSERT dbo.REPORTS_LOG
		(	ReportName
			,date
			,UserName
			,KolSec
			,query
			,params)
		VALUES (@ReportName
				,current_timestamp
				,SUSER_NAME()
				,@KolSec
				,@query
				,@params)

END
go

