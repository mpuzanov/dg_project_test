CREATE       PROC [dbo].[k_PEOPLE_TmpOutUpdate]
	@occ	  INT
   ,@owner_id INT
   ,@data1	  SMALLDATETIME
   ,@data2	  SMALLDATETIME
   ,@doc	  VARCHAR(100)
   ,@add	  BIT = 0 -- 1- создать разовые,  0-убрать
   ,@debug	  BIT = 0
   ,@is_noliving BIT = 1
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @sysuser   VARCHAR(30)	 = system_user
		   ,@data_edit SMALLDATETIME = current_timestamp

	BEGIN TRAN

		UPDATE [dbo].[PEOPLE_TmpOut]
		SET [data2]		= @data2
		   ,[doc]		= @doc
		   ,[sysuser]   = @sysuser
		   ,[data_edit] = @data_edit
		   ,is_noliving = @is_noliving
		WHERE [occ] = @occ
		AND [owner_id] = @owner_id
		AND [data1] = @data1

		-- Begin Return Select <- do not remove
		SELECT
			[occ]
		   ,[owner_id]
		   ,[data1]
		   ,[data2]
		   ,[doc]
		   ,[sysuser]
		   ,[data_edit]
		   ,is_noliving
		FROM [dbo].[PEOPLE_TmpOut] 
		WHERE [occ] = @occ
		AND [owner_id] = @owner_id
		AND [data1] = @data1
		-- End Return Select <- do not remove

		COMMIT

		IF @add = 1
			EXEC [dbo].[ka_add_people_tmp_out] @owner_id = @owner_id
											  ,@data1 = @data1
											  ,@data2 = @data2
											  ,@doc = @doc
											  ,@debug = @debug
											  ,@is_noliving = @is_noliving
go

