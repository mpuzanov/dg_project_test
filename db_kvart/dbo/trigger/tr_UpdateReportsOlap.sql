-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[tr_UpdateReportsOlap]
   ON  [dbo].[Reports_olap] 
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET date_edit=CURRENT_TIMESTAMP
		,size_body= dbo.fsize(i.slice_body)
	FROM dbo.Reports_olap AS t 
	JOIN inserted AS i ON 
		t.id=i.id
END
go

