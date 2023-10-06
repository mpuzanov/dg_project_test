-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[tr_Paym_occ_build]
   ON  [Paym_occ_build]
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE t
	SET
		[data] = current_timestamp
		, user_login = system_user
	FROM
		inserted AS i
		JOIN Paym_occ_build AS t ON 
			i.fin_id = t.fin_id
			AND i.occ = t.occ
			AND i.service_id = t.service_id

END
go

