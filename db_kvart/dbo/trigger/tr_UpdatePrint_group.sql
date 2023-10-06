-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE      TRIGGER [dbo].[tr_UpdatePrint_group]
	ON [dbo].[Print_group]
	FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE p
	SET date_edit = current_timestamp
	  , user_edit = dbo.Fun_GetCurrentUserId()
	FROM dbo.Print_group AS p
		JOIN INSERTED AS i ON p.id = i.id


END
go

