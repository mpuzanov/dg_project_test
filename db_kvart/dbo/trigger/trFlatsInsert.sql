-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trFlatsInsert] 
   ON [Flats]
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET flat_uid = dbo.fn_newid()
	FROM INSERTED i
		JOIN Flats AS t ON 
			t.id = i.id
	WHERE i.flat_uid IS NULL

END
go

