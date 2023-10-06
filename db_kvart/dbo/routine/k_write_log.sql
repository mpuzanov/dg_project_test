CREATE   PROCEDURE [dbo].[k_write_log]
(
	@occ1		INT
	,@oper1		VARCHAR(10)
	,@comments1	VARCHAR(100)	= NULL
)
AS
/*
	--  заносим в историю изменений
*/
	SET NOCOUNT ON;

	--IF (SYSTEM_USER = 'sa') AND (@oper1 = 'рдлс')
	--	RETURN -- не трогать

	IF NOT EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS 
			WHERE occ = @occ1)
		RETURN

	DECLARE	@user_id1	SMALLINT = dbo.Fun_GetCurrentUserId()
			,@date1		SMALLDATETIME = CAST(CURRENT_TIMESTAMP AS DATE)
	
	IF @user_id1 IS NULL AND @oper1 IN ('пере','прлс','рдлс')   -- значит это системный пользователь
		RETURN --set @user_id1=0

	IF NOT EXISTS (SELECT
				1
			FROM dbo.OP_LOG 
			WHERE [user_id] = @user_id1
			AND op_id = @oper1
			AND occ = @occ1
			AND done = @date1
			AND (comments=@comments1 OR (comments IS NULL AND @comments1 IS NULL) )
			)
	BEGIN
		INSERT INTO dbo.OP_LOG
		(	user_id
			,op_id
			,occ
			,done
			,comments
			,comp)
		VALUES (@user_id1
				,@oper1
				,@occ1
				,@date1
				,@comments1
				,HOST_NAME())

	END
go

