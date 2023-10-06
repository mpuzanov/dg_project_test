-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trPeopleInsert]
   ON [People]
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET people_uid = dbo.fn_newid()
	FROM INSERTED i
		JOIN People AS t ON 
			t.id = i.id
	WHERE i.people_uid IS NULL

END
go

