CREATE   PROCEDURE [dbo].[k_write_log_adm]
(
	@oper1		VARCHAR(10)
	,@comments1	VARCHAR(100)	= NULL
)
AS
	--
	--  заносим в историю глобальных изменений в базе (не по лицевым счетам)
	--
	SET NOCOUNT ON

	--if (SYSTEM_USER='dbo') and (@oper1='рдлс') return -- не трогать

	DECLARE	@user_id1	SMALLINT
			,@date1		SMALLDATETIME

	SET @date1 = current_timestamp -- надо со временем

	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()
	IF @user_id1 IS NULL
		SET @user_id1 = 0

	INSERT INTO dbo.OP_LOG_ADM
	(	done
		,user_id
		,op_id
		,comments)
	VALUES (@date1
			,@user_id1
			,@oper1
			,@comments1)
go

