CREATE   PROCEDURE [dbo].[adm_user_groups]
AS

	SET NOCOUNT ON

	SELECT
		group_id
	   ,name
	   ,group_no
	   ,max_access
	FROM USER_GROUPS
go

