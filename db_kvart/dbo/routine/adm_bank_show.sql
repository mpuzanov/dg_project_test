-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_bank_show]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT b.id
		 , b.short_name
		 , b.is_bank
		 , CAST(b.bank_uid AS VARCHAR(36)) AS bank_uid
		 , b.name
		 , b.bank
		 , b.rasscht
		 , b.korscht
		 , b.bik
		 , b.inn
		 , b.comments
		 , b.data_edit
		 , b.user_id
		 , b.visible
		 , u.Initials AS user_edit
	FROM dbo.bank AS b
		LEFT JOIN dbo.Users AS u ON b.user_id = u.id
	ORDER BY b.visible DESC
		   , b.short_name

END
go

