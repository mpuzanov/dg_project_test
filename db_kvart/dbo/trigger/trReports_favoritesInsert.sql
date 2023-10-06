-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trReports_favoritesInsert]
   ON  [dbo].[Reports_favorites]
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE dbo.Reports_favorites 
	SET date_edit=current_timestamp
	, size_body = dbo.fsize(REPORT_BODY)
	WHERE id in (SELECT id FROM inserted)

END
go

