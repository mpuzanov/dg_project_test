CREATE   PROCEDURE [dbo].[k_counter_write_log]
(
	  @counter_id1 INT
	, @oper1 VARCHAR(10)
	, @comments1 VARCHAR(100) = NULL
)
AS
	/*
		заносим в историю изменений
	*/
	SET NOCOUNT ON

	--if (SYSTEM_USER='dbo')  return -- не трогать

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Counters 
			WHERE id = @counter_id1
		)
		RETURN

	DECLARE @user_id1 SMALLINT
		  , @date1 SMALLDATETIME

	SELECT @user_id1 = dbo.Fun_GetCurrentUserId()
		 , @date1 = dbo.Fun_GetOnlyDate(current_timestamp)

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Counter_log 
			WHERE user_id = @user_id1
				AND op_id = @oper1
				AND counter_id = @counter_id1
				AND date_edit = @date1
				AND COALESCE(comments, '') = COALESCE(@comments1, '')
		)
	BEGIN

		INSERT INTO dbo.Counter_log (user_id
									, op_id
									, counter_id
									, date_edit
									, comments)
		VALUES(@user_id1
			 , @oper1
			 , @counter_id1
			 , @date1
			 , @comments1)

	END
go

