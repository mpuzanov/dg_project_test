-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE      PROCEDURE [dbo].[rep_favorites_click_show]
(
	@user_id1 SMALLINT = NULL
)
/*
exec rep_favorites_click_show 2
*/
AS
BEGIN
	SET NOCOUNT ON;

	SELECT rf.*
	FROM dbo.Reports_favorites rf
	WHERE (rf.user_id = @user_id1
	    or rf.is_for_all = 1)
		and rf.rep_type in ('CLICKHOUSE')
	ORDER BY rf.name

END
go

