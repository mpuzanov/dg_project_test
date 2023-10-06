-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE           TRIGGER [dbo].[tr_BANK_FORMAT_update]
   ON  [dbo].[Bank_format]
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET date_edit = current_timestamp
	FROM dbo.BANK_FORMAT AS t
	JOIN INSERTED AS i
		ON t.id = i.id

END
go

