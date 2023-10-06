-- =============================================
-- Author:		Пузанов
-- Create date: 10.09.2011
-- Description:	Дата обновления отчёта
-- =============================================
CREATE       TRIGGER [dbo].[tr_UpdateReportsAccount]
   ON  [dbo].[Reports_account] 
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	
	UPDATE dbo.Reports_account 
	SET date_edit=current_timestamp
		, SIZE_REPORT_BODY = dbo.fsize(REPORT_BODY)
	WHERE id in (SELECT id FROM inserted)

END
go

