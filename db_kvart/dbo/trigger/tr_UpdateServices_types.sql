-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_UpdateServices_types]
	ON [dbo].[Services_types]
	FOR INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE p
	SET date_edit = current_timestamp
	  , user_edit = dbo.Fun_GetCurrentUserId()
	FROM dbo.Services_types AS p
		JOIN INSERTED AS i ON p.id = i.id

END
go

