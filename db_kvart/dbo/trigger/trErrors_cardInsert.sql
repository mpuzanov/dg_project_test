-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trErrors_cardInsert]
   ON [dbo].[Errors_card]
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET size_file_error = dbo.fsize(i.file_error)
	FROM INSERTED i
		JOIN Errors_card AS t ON 
			t.id = i.id

END
go

