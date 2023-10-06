-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trBuilding_debugInsert] 
   ON  [Building_debug]
   FOR INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET createAt = CURRENT_TIMESTAMP
		,createUser = SYSTEM_USER
	FROM INSERTED AS i
    JOIN Building_debug AS t ON 
        t.id = i.id

END
go

