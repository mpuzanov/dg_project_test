-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_add_dog_account]
(
	@build_id	INT
	,@dog_id	VARCHAR(20)
	,@dog_date	SMALLDATETIME
	,@tip_id	SMALLINT
	,@sup_id	INT
	,@name_str1	VARCHAR(100)	= ''
	,@bank		VARCHAR(50)		= ''
	,@bik		VARCHAR(9)		= ''
	,@rasschet	VARCHAR(20)		= ''
	,@korschet	VARCHAR(20)		= ''
	,@inn		VARCHAR(12)		= ''
	,@name_str2	VARCHAR(100)	= ''
	,@kpp		VARCHAR(9)		= ''
	,@first_occ	INT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@bank_account	INT
			,@dog_int		INT
			,@fin_id		SMALLINT


	BEGIN TRANSACTION

		IF EXISTS (SELECT
					*
				FROM [dbo].[ACCOUNT_ORG]
				WHERE [rasschet] = @rasschet
				AND [bik] = @bik)
		BEGIN
			SELECT
				@bank_account = id
			FROM [dbo].[ACCOUNT_ORG]
			WHERE [rasschet] = @rasschet
			AND [bik] = @bik
		END
		ELSE
		BEGIN
			INSERT
			INTO [dbo].[ACCOUNT_ORG]
			(	[rasschet]
				,[bik]
				,licbank
				,[name_str1]
				,[bank]
				,[korschet]
				,[inn]
				,[comments]
				,[tip]
				,[name_str2]
				,[kpp])
				SELECT
					@rasschet
					,@bik
					,0
					,@name_str1
					,@bank
					,@korschet
					,@inn
					,[comments] = ''
					,[tip] = 6
					,@name_str2
					,@kpp

			SELECT
				@bank_account = SCOPE_IDENTITY()
		END

		IF EXISTS (SELECT
					*
				FROM [dbo].[DOG_SUP]
				WHERE [dog_id] = @dog_id)
		BEGIN	
			update [dbo].[DOG_SUP]
			SET bank_account=@bank_account, @dog_int = id
			WHERE [dog_id] = @dog_id
		END
		ELSE
		BEGIN
			INSERT
			INTO [dbo].[DOG_SUP]
			(	[dog_id]
				,[dog_date]
				,[sup_id]
				,[tip_id]
				,bank_account
				,first_occ)
				SELECT
					@dog_id
					,@dog_date
					,@sup_id
					,@tip_id
					,@bank_account
					,@first_occ
			SELECT
				@dog_int = SCOPE_IDENTITY()
		END

		SELECT
			@fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

		IF NOT EXISTS (SELECT
					*
				FROM [dbo].[DOG_BUILD]
				WHERE [dog_int] = @dog_int
				AND [fin_id] = @fin_id
				AND [build_id] = @build_id)
			INSERT
			INTO [dbo].[DOG_BUILD]
			(	[dog_int]
				,[fin_id]
				,[build_id])
			VALUES (@dog_int
					,@fin_id
					,@build_id)

	COMMIT TRAN


END
go

