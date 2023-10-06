-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER  [dbo].[update_serv_vid]
   ON  [dbo].[Services]
AFTER INSERT, UPDATE
AS
BEGIN
	-- update services set serv_vid=serv_vid
	SET NOCOUNT ON;

	UPDATE s
	SET	date_edit = CAST(CURRENT_TIMESTAMP AS date),
	serv_vid	= CASE
                      WHEN i.serv_vid IS NULL OR s.serv_vid <> i.serv_vid THEN dbo.Fun_GetServVid(i.id)
                      ELSE s.serv_vid
        END
	FROM [dbo].[SERVICES] s 
	JOIN INSERTED i ON s.id = i.id

END
go

