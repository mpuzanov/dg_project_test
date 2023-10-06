CREATE         PROC [dbo].[k_PEOPLE_TmpOutInsert] @occ INT
, @owner_id INT
, @data1 SMALLDATETIME
, @data2 SMALLDATETIME
, @doc VARCHAR(100)
, @add BIT = 0 -- 1- создать разовые 
, @debug BIT = 0
, @is_noliving BIT = 1 -- отсутсвие
AS
    SET NOCOUNT ON
    SET XACT_ABORT ON

	SET @is_noliving=COALESCE(@is_noliving, 1)

	DECLARE
		@sysuser       VARCHAR(30)   = system_user
		, @data_edit   SMALLDATETIME = current_timestamp
		, @fin_current SMALLINT

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

   
    IF EXISTS(SELECT 1
              FROM [dbo].[PEOPLE_TmpOut]
              WHERE occ = @occ
                AND owner_id = @owner_id
                AND data1 = @data1)
        BEGIN
            DECLARE @strerror VARCHAR(100);
            SELECT dbo.Fun_InitialsPeople(@owner_id)
            SET @strerror = N'У гражданина ' + dbo.Fun_InitialsPeople(@owner_id) + N'уже есть возврат с ' +
                            CONVERT(VARCHAR(15), @data1, 104)
            RAISERROR (@strerror, 16, 1);
        END

    BEGIN TRAN

INSERT INTO [dbo].[PEOPLE_TmpOut]
( [occ]
, [owner_id]
, [data1]
, [data2]
, [doc]
, [sysuser]
, [data_edit]
, fin_id
, is_noliving)
SELECT @occ
     , @owner_id
     , @data1
     , @data2
     , @doc
     , @sysuser
     , @data_edit
     , @fin_current
	 , @is_noliving

    -- Begin Return Select <- do not remove
SELECT [occ]
     , [owner_id]
     , [data1]
     , [data2]
     , [doc]
     , [sysuser]
     , [data_edit]
	 , is_noliving
FROM [dbo].[PEOPLE_TmpOut]
WHERE [occ] = @occ
  AND [owner_id] = @owner_id
  AND [data1] = @data1
    -- End Return Select <- do not remove

    COMMIT
    IF @add = 1
        EXEC [dbo].[ka_add_people_tmp_out] @owner_id = @owner_id
            , @data1 = @data1
            , @data2 = @data2
            , @doc = @doc
            , @debug = @debug
			, @is_noliving = @is_noliving
go

