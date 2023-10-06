CREATE   PROCEDURE [dbo].[adm_group_member_user]
(
	@user_id1 INT  -- код пользователя
   ,@group1	  SMALLINT  -- 0 - не входит в группы, 1 - входит
)
AS
/*
 Показать группы куда пользователь входит или нет

 exec dbo.adm_group_member_user 2, 1
 exec dbo.adm_group_member_user 2, 0
*/
	SET NOCOUNT ON

	IF @group1 = 1
	BEGIN -- Список групп в которые пользователь входит
		SELECT
			us.name
		   ,us.group_id
		FROM dbo.User_groups AS us
		WHERE EXISTS (SELECT
				1
			FROM dbo.Group_membership AS gr 
			WHERE gr.user_id = @user_id1
			AND gr.group_id = us.group_id);
	END
	
	IF @group1 = 0
	BEGIN -- Список групп в которые пользователь не входит
		SELECT
			us.name
		   ,us.group_id
		FROM dbo.User_groups AS us
		WHERE NOT EXISTS (SELECT
				1
			FROM dbo.Group_membership AS gr
			WHERE gr.user_id = @user_id1
			AND gr.group_id = us.group_id);
	END
go

