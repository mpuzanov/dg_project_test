-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[k_pid_form_show]
(
	@pid_tip SMALLINT = NULL
-- 1-Уведомление о задолженности
-- 2-Иски
-- 3-Соглашение о задолженности
-- 4-Претензия
-- 5-Судебный приказ
)
/*
k_pid_form_show 1
*/
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		ID
		,Name
		,[FileName]
		,REPORT_BODY
	FROM dbo.REPORTS AS RA 
	WHERE APP = 'PID'
	AND REPORT_BODY IS NOT NULL
	AND pid_tip = @pid_tip
--(pid_tip = coalesce(@pid_tip, pid_tip) OR pid_tip IS NULL)

END
go

