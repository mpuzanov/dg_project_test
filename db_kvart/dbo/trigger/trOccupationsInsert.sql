-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trOccupationsInsert] 
   ON [dbo].[Occupations]
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT
				1
			FROM INSERTED)
		RETURN;

	UPDATE t
	SET occ_uid = dbo.fn_newid()
	FROM INSERTED i
		JOIN Occupations AS t ON 
			t.Occ = i.Occ
	WHERE i.occ_uid IS NULL

END
go

