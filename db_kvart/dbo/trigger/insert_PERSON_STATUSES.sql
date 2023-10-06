-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[insert_PERSON_STATUSES] ON [dbo].[Person_statuses]
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @id VARCHAR(10)
	SELECT @id=id FROM inserted
	
	
	UPDATE dbo.PERSON_STATUSES
	SET id_no=COALESCE((SELECT MAX(id_no) FROM dbo.PERSON_STATUSES),1)+1
	WHERE id=@id

END
go

