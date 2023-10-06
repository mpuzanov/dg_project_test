
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[k_email_acc_del]
(
	@occ		INT
	,@fin_id	SMALLINT
	,@fileName	VARCHAR(50)
	,@res		BIT	= 0
)
AS
/*

exec k_email_acc_del 680000210,182,'20170301_680000210_42.PDF'

*/
BEGIN
	SET NOCOUNT ON;

	DELETE FROM [dbo].[ACCOUNT_EMAIL]
	WHERE fin_id = @fin_id
		AND occ = @occ
		AND [fileName] = @fileName
	SET @res = @@rowcount

END
go

