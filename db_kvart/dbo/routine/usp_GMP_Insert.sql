CREATE       PROC [dbo].[usp_GMP_Insert]
	@N_EL_NUM		 VARCHAR(50)
   ,@N_TYPE_STR		 VARCHAR(50)
   ,@N_STATUS_STR	 VARCHAR(50)
   ,@N_SUMMA		 DECIMAL(10, 4)
   ,@ADDRESS		 VARCHAR(100)
   ,@N_PLAT_NAME	 VARCHAR(50)
   ,@N_SUMMA_DOLG	 DECIMAL(10, 4)
   ,@N_UIN			 VARCHAR(25)
   ,@FILE_NAME		 VARCHAR(50)
   ,@N_CUID			 VARCHAR(25)
   ,@N_DATE_PROVODKA SMALLDATETIME
   ,@N_DATE_PERIOD	 SMALLDATETIME
   ,@N_RDATE		 SMALLDATETIME
   ,@N_DATE_VVOD	 SMALLDATETIME

AS
	SET NOCOUNT ON


	DECLARE @user_edit VARCHAR(50)
		   ,@occ	   INT

	SELECT
		@user_edit = u.Initials
	FROM Users u
	WHERE u.login = system_user

	SELECT
		@occ = CAST(SUBSTRING(@N_EL_NUM, 1, 10) AS INT)

	-- заносим только последнии записи по N_EL_NUM, N_DATE_VVOD

	BEGIN TRAN

		IF EXISTS (SELECT
					1
				FROM dbo.GMP
				WHERE N_EL_NUM = @N_EL_NUM
				AND N_DATE_PERIOD < @N_DATE_PERIOD)

			UPDATE dbo.GMP
			SET N_TYPE_STR		= @N_TYPE_STR
			   ,N_STATUS_STR	= @N_STATUS_STR
			   ,N_SUMMA			= @N_SUMMA
			   ,ADDRESS			= @ADDRESS
			   ,N_PLAT_NAME		= @N_PLAT_NAME
			   ,N_SUMMA_DOLG	= @N_SUMMA_DOLG
			   ,N_UIN			= @N_UIN
			   ,FILE_NAME		= @FILE_NAME
			   ,N_CUID			= @N_CUID
			   ,N_DATE_PROVODKA = @N_DATE_PROVODKA
			   ,N_DATE_PERIOD   = @N_DATE_PERIOD
			   ,N_RDATE			= @N_RDATE
			   ,N_DATE_VVOD		= @N_DATE_VVOD
			   ,date_edit		= CURRENT_TIMESTAMP
			   ,user_edit		= @user_edit
			WHERE N_EL_NUM = @N_EL_NUM

		ELSE

			INSERT INTO dbo.GMP
			(N_EL_NUM
			,N_TYPE_STR
			,N_STATUS_STR
			,N_SUMMA
			,ADDRESS
			,N_PLAT_NAME
			,N_SUMMA_DOLG
			,N_UIN
			,FILE_NAME
			,N_CUID
			,N_DATE_PROVODKA
			,N_DATE_PERIOD
			,N_RDATE
			,N_DATE_VVOD
			,date_edit
			,user_edit
			,occ)
				SELECT
					@N_EL_NUM
				   ,@N_TYPE_STR
				   ,@N_STATUS_STR
				   ,@N_SUMMA
				   ,@ADDRESS
				   ,@N_PLAT_NAME
				   ,@N_SUMMA_DOLG
				   ,@N_UIN
				   ,@FILE_NAME
				   ,@N_CUID
				   ,@N_DATE_PROVODKA
				   ,@N_DATE_PERIOD
				   ,@N_RDATE
				   ,@N_DATE_VVOD
				   ,CURRENT_TIMESTAMP
				   ,@user_edit
				   ,@occ

		COMMIT
go

