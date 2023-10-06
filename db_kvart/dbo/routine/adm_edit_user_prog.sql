CREATE   PROCEDURE [dbo].[adm_edit_user_prog]
(
	@user_id1 SMALLINT
   ,@program1 VARCHAR(25)
   ,@add1	  BIT = 1 --добавить             0-убрать доступ
)
AS
	--
	--  Добавляем или убираем доступ пользователей к определенным программам  
	--
	SET NOCOUNT ON

	IF @program1 = ''
		RETURN 0

	DECLARE @program_id INT
	SELECT
		@program_id = Id
	FROM dbo.PROGRAMS
	WHERE name = @program1

	IF @add1 = 1
	BEGIN
		IF NOT EXISTS (SELECT
					*
				FROM dbo.PROGRAM_ACCESS 
				WHERE [user_id] = @user_id1
				AND program_id = @program_id)
			INSERT INTO dbo.PROGRAM_ACCESS
			([user_id]
			,program_id)
			VALUES (@user_id1
				   ,@program_id)
	END
	ELSE
	BEGIN
		DELETE FROM dbo.PROGRAM_ACCESS
		WHERE user_id = @user_id1
			AND program_id = @program_id
	END
go

