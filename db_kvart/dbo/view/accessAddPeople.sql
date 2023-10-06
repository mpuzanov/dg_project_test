-- dbo.accessAddPeople source

CREATE   VIEW [dbo].[accessAddPeople]
AS
	/*
	доступ к прописке-выписке граждан
	*/
	SELECT A.area_id
		 , A.group_id
	FROM dbo.Allowed_Areas AS A 
		INNER JOIN dbo.Users AS U ON A.user_id = U.id
		INNER JOIN dbo.Group_membership gm ON A.group_id = gm.group_id
			AND A.user_id = gm.user_id
	WHERE (U.login = system_user)
	AND (A.op_id = 'люди');
go

