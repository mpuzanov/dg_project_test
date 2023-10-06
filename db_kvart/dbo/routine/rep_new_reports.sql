-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[rep_new_reports]
(
	@LastExecute SMALLDATETIME = NULL --  последний запуск программы
)
AS
BEGIN
	SET NOCOUNT ON;
	
	IF @LastExecute IS NULL 
		SET @LastExecute=CURRENT_TIMESTAMP
		
	SELECT
		concat(LTRIM(STR(Level1)) , '. ' , LTRIM(STR(Level2)) , '. ' , Name) as Name
		,Name as RepName
		,FileName
		,id
		,FileDateEdit
		,'DREP' as tip_rep
	FROM dbo.View_REPORTS
	WHERE NO_VISIBLE = 0
		AND APP = 'DREP'
		AND REPORT_BODY IS NOT NULL
		AND FileDateEdit > @LastExecute
	UNION ALL
	SELECT
		concat('OLAP ' , Name) as Name
		,RepName = Name
		,[FileName]
		,id
		,FileDateEdit
		,'OLAP' as tip_rep
	FROM dbo.REPORTS_OLAP
	WHERE slice_body IS NOT NULL
	AND FileDateEdit > @LastExecute


END
go

