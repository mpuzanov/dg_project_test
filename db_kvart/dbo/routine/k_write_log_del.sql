CREATE   PROCEDURE [dbo].[k_write_log_del]
(
	@occ1	INT
	,@oper1	VARCHAR(10)
)
AS
	--
	--  заносим в историю изменений
	--
	SET NOCOUNT ON

	DECLARE	@user_id1	SMALLINT
			,@date1		SMALLDATETIME

	SET @date1 = dbo.Fun_GetOnlyDate(current_timestamp)

	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()
	IF @user_id1 IS NULL
		SET @user_id1 = 0

	IF NOT EXISTS (SELECT
				[user_id]
			FROM dbo.OP_LOG_DEL 
			WHERE user_id = @user_id1
			AND op_id = @oper1
			AND occ = @occ1
			AND dbo.Fun_GetOnlyDate(done) = @date1)

	BEGIN
		INSERT INTO dbo.OP_LOG_DEL 
		(	user_id
			,op_id
			,occ
			,done)
		VALUES (@user_id1
				,@oper1
				,@occ1
				,@date1)
	END
go

