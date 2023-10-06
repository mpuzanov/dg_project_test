CREATE   TRIGGER [dbo].[trACCOUNT_ORG_EDIT]
ON [dbo].[Account_org]
FOR INSERT, UPDATE
AS
	--
	--  Протоколируем дату изменения и пользователя
	--
	SET NOCOUNT ON

	UPDATE t
	SET date_edit = current_timestamp
	   ,user_edit = (SELECT
				Initials
			FROM dbo.USERS
			WHERE login = system_user)
	FROM INSERTED AS i
	JOIN dbo.ACCOUNT_ORG AS t
		ON t.id = i.id
go

