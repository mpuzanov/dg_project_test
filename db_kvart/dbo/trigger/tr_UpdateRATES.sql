CREATE   TRIGGER [dbo].[tr_UpdateRATES]
   ON  [dbo].[Rates] 
   FOR INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
		
	UPDATE t
	SET date_edit=CURRENT_TIMESTAMP
	FROM [dbo].RATES AS t 
	JOIN inserted AS i ON t.id=i.id

END
go

