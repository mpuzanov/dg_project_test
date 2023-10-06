-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trCESSIA] ON [dbo].[Cessia] FOR INSERT, UPDATE AS
BEGIN
	--
	--  Протоколируем дату изменения и пользователя
	--
	SET NOCOUNT ON

	UPDATE ces
	SET
		data_edit = current_timestamp, SYSUSER = system_user
	FROM
		inserted AS i
		JOIN dbo.CESSIA AS ces
			ON i.occ_sup = ces.occ_sup

END
go

