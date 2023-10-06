CREATE   TRIGGER [dbo].[tr_UpdateRATES_COUNTER]
   ON  [dbo].[Rates_counter] 
   FOR INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
		
	UPDATE t
	SET date_edit=CURRENT_TIMESTAMP
	FROM [dbo].RATES_COUNTER AS t 
	JOIN inserted AS i ON t.id=i.id

END
go

