CREATE       PROC [dbo].[k_FileFTPInsert]
	@occ		INT
   ,@FileName   VARCHAR(250)
   ,@FileSizeKb SMALLINT = NULL
   ,@file_edit  SMALLDATETIME = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	-- проверяем есть ли такой файл на лицевом
	IF EXISTS (SELECT
				*
			FROM [dbo].[FileFTP]
			WHERE occ = @occ
			AND [FileName] = @FileName)
	BEGIN
		RAISERROR ('Файл %s уже есть на лицевом счету %i', 16, 1, @FileName, @occ)
		RETURN -1
	END

	BEGIN TRAN

		--DECLARE @date_load SMALLDATETIME = current_timestamp
		--	   ,@user_load VARCHAR(30)	 = system_user


		INSERT
		INTO [dbo].[FileFTP]
		([occ]
		,[FileName]
		,[date_load]
		,[user_load]
		,FileSizeKb
		,file_edit)
			SELECT
				@occ
			   ,@FileName
			   ,current_timestamp
			   ,system_user
			   ,@FileSizeKb
			   ,@file_edit

		-- Begin Return Select <- do not remove
		SELECT
			[id]
		   ,[occ]
		   ,[FileName]
		   ,[date_load]
		   ,[user_load]
		   ,FileSizeKb
		   ,file_edit
		FROM [dbo].[FileFTP]
		WHERE [id] = SCOPE_IDENTITY()
		-- End Return Select <- do not remove

	COMMIT
go

