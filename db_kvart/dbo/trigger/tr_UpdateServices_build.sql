-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_UpdateServices_build]
	ON [dbo].[Services_build]
	FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE p
	SET date_edit = current_timestamp
	  , user_edit = dbo.Fun_GetCurrentUserId()
	FROM dbo.Services_build AS p
		JOIN INSERTED AS i ON p.id = i.id

END
go

