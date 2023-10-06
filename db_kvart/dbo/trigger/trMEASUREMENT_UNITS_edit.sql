-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[trMEASUREMENT_UNITS_edit]
ON [dbo].[Measurement_units]
FOR INSERT, UPDATE
AS
BEGIN
	--
	--  Протоколируем дату изменения и пользователя
	--
	SET NOCOUNT ON

	UPDATE t
	SET --date_edit = current_timestamp,
	user_edit = (SELECT
			id
		FROM dbo.USERS
		WHERE login = system_user)
	FROM INSERTED AS i
	JOIN dbo.MEASUREMENT_UNITS AS t
		ON t.id=i.id

END
go

