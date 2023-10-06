CREATE   PROCEDURE [dbo].[adm_show_user_prog]
(
	@user_id1 SMALLINT
   ,@access1  BIT = 1
)
AS
	--
	--  Показываем список доступных програм пользователю @access1 =1
	--
	SET NOCOUNT ON

	IF @access1 = 1
	BEGIN
		SELECT
			p.name AS [program_name]
		   ,pa.[user_id]
		FROM dbo.PROGRAM_ACCESS AS pa 
		JOIN dbo.PROGRAMS AS p 
			ON pa.program_id = p.id
		WHERE user_id = @user_id1
	END
	ELSE
	BEGIN --  Показываем список не доступных програм пользователю @access1 = 0
		SELECT
			p.name
		FROM dbo.PROGRAMS AS p 
		WHERE NOT EXISTS (SELECT
				*
			FROM dbo.PROGRAM_ACCESS AS pa 
			WHERE user_id = @user_id1
			AND pa.program_id = p.id)
	END
go

