CREATE   PROCEDURE [dbo].[adm_edit_user_tip_from]
(
	@user_id_from	SMALLINT
	,@user_id_to	SMALLINT
)
AS
	/*
	 
	 копируем права доступа пользователя @user_id_from к типам фонда
	 adm_edit_user_tip_from @user_id_from, @user_id_to
	 
	*/
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @login_to NVARCHAR(30)

	SELECT
		@login_to = login
	FROM dbo.USERS
	WHERE id = @user_id_to


	BEGIN TRANSACTION

		DELETE pa
			FROM dbo.users_occ_types AS pa
		WHERE pa.SYSUSER = @login_to


		INSERT INTO dbo.users_occ_types
		(	SYSUSER
			,ONLY_TIP_ID
			,only_read
			,fin_id_start)
				SELECT
					@login_to
					,pa.ONLY_TIP_ID
					,pa.only_read
					,pa.fin_id_start
				FROM dbo.users_occ_types AS pa 
				JOIN dbo.users AS u
					ON pa.SYSUSER = u.login
				WHERE u.id = @user_id_from


	COMMIT TRANSACTION
go

