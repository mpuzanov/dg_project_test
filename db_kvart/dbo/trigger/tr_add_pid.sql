-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       TRIGGER [dbo].[tr_add_pid]
ON [dbo].[Pid]
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET	user_edit	= system_user
		,date_edit	= current_timestamp
	FROM dbo.PID AS t
	JOIN INSERTED AS i
		ON t.id = i.id

END
go

