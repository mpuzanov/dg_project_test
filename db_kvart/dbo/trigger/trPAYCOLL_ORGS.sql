CREATE   TRIGGER [dbo].[trPAYCOLL_ORGS]
ON [dbo].[Paycoll_orgs]
FOR INSERT, UPDATE
AS
/*
  Протоколируем дату изменения и пользователя
*/
SET NOCOUNT ON

UPDATE t
SET data_edit = current_timestamp
	,[user_id] = dbo.Fun_GetCurrentUserId()
	,paycoll_uid = CASE WHEN i.paycoll_uid IS NULL THEN dbo.fn_newid() ELSE i.paycoll_uid END
FROM INSERTED AS i
JOIN Paycoll_orgs AS t
	ON i.id = t.id
go

