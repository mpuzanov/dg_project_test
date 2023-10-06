CREATE   TRIGGER [dbo].[tr_Counter_format_update]
   ON  [dbo].[Counter_format]
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET date_edit = current_timestamp
	FROM dbo.Counter_format AS t
	JOIN INSERTED AS i
		ON t.id = i.id

END
go

