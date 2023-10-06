-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_UpdatePeny_added]
	ON [dbo].[Peny_added]
	FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET date_edit = current_timestamp
	  , user_edit = system_user
	FROM dbo.Peny_added AS t
		JOIN INSERTED AS i ON t.fin_id = i.fin_id
			AND t.occ = i.occ

END
go

