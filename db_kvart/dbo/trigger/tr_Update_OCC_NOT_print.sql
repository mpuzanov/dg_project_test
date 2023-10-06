-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[tr_Update_OCC_NOT_print]
   ON  [dbo].[Occ_not_print]
   FOR INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET date_edit=CURRENT_TIMESTAMP,	
		user_edit=dbo.Fun_GetCurrentUserId()
	FROM [dbo].OCC_NOT_print AS t 
	JOIN inserted AS i ON t.occ=i.occ AND t.flag = i.flag

END
go

