-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[tr_BANK_FORMAT_OUT_update]
   ON  [dbo].[Bank_format_out]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE t
	SET date_edit = current_timestamp
	FROM dbo.BANK_FORMAT_OUT AS t
	JOIN INSERTED AS i
		ON t.id = i.id

END
go

