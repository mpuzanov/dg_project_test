-- =============================================
-- Author:		Пузанов
-- Create date: 18.12.2011
-- Description:	Дата обновления отчёта
-- =============================================
CREATE   TRIGGER [dbo].[tr_UpdateReports]
   ON  [dbo].[Reports] 
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
		
	UPDATE t
	SET date_edit=CURRENT_TIMESTAMP
		,SIZE_REPORT_BODY = dbo.fsize(i.REPORT_BODY)
	FROM dbo.Reports AS t 
	JOIN inserted AS i ON 
		t.id=i.id

END
go

