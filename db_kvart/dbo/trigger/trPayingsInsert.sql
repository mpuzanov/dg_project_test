-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE    TRIGGER [dbo].[trPayingsInsert]
ON [dbo].[Payings]
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET paying_uid = dbo.fn_newid()
	FROM INSERTED i
	JOIN Payings AS t ON 
		t.id = i.id
	WHERE i.paying_uid IS NULL

END
go

