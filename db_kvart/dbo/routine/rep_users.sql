-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Список пользователей с условиями
-- =============================================
CREATE PROCEDURE [dbo].[rep_users]
(
    @tip_id     SMALLINT = NULL,  -- тип фонда
    @program_id INT      = NULL   -- код программы
)
AS
/*
rep_users @tip_id=null,@program_id=null
rep_users @tip_id=2,@program_id=null
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @users TABLE(
		[id] INT PRIMARY KEY
	)

	INSERT INTO @users
	SELECT u.id
	FROM
		[dbo].[USERS] AS u


	IF @tip_id IS NOT NULL
		DELETE u
		FROM
			@users u
		WHERE
			NOT EXISTS (SELECT DISTINCT U2.id
						   FROM
							   [dbo].[USERS_OCC_TYPES] AS uot
							   JOIN dbo.USERS U2
								   ON U2.login = uot.SYSUSER
						   WHERE
							   [ONLY_TIP_ID] = @tip_id
							   AND U2.id=u.[id])

	IF @program_id IS NOT NULL
		DELETE u
		FROM
			@users u
		WHERE
			 NOT EXISTS (SELECT DISTINCT pa.[user_id]
						   FROM
							   [dbo].PROGRAM_ACCESS AS pa
						   WHERE
							   program_id = @program_id
							   AND pa.[user_id]=u.[id])

	SELECT u.*
	FROM
		[dbo].[USERS] AS U
		JOIN @users AS u2
			ON U.id = u2.id
	ORDER BY
		Initials


END
go

