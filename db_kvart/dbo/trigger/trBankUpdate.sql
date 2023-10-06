CREATE   TRIGGER [dbo].[trBankUpdate]
ON [dbo].[Bank]
AFTER INSERT, UPDATE
AS
/*
	Протоколируем дату изменения и пользователя
*/
	SET NOCOUNT ON

	UPDATE b
	SET data_edit = current_timestamp
	   ,[user_id] = (SELECT id FROM dbo.USERS WHERE login = system_user)
	FROM INSERTED AS i
	JOIN dbo.bank AS b ON 
		i.id = b.id
go

