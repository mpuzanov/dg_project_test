CREATE   PROCEDURE [dbo].[k_dsc_edit]
--
--  Редактируем льготу
--
(
	@id1			INT
	,@doc1			VARCHAR(50)
	,@issued1		DATETIME
	,@issued2		DATETIME
	,@expire_date1	SMALLDATETIME
	,@doc_no1		VARCHAR(10)	= NULL
	,@doc_seria1	VARCHAR(10)	= NULL
	,@doc_org1		VARCHAR(30)	= NULL

)
AS
	SET NOCOUNT ON
    
	IF dbo.Fun_GetRejim() <> N'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	DECLARE	@owner_id1	INT
			,@active1	BIT
	SELECT
		@owner_id1 = owner_id
		,@active1 = active
	FROM DSC_OWNERS 
	WHERE id = @id1


	DECLARE @start_date SMALLDATETIME
	SELECT
		@start_date = CONVERT(CHAR(8), current_timestamp, 112)
	SELECT
		@start_date = DATEADD(DAY, 1 - DAY(@start_date), @start_date) -- первый день тек. месяца

	IF @expire_date1 < current_timestamp
	BEGIN
		RAISERROR (N'Ошибка ввода! Действие льготы истекло!', 16, 1)
	END

	DECLARE @user_id1 SMALLINT
	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()

	BEGIN TRAN

		-- Изменяем
		UPDATE DSC_OWNERS 
		SET	doc				= @doc1
			,ISSUED			= @issued1
			,issued2		= @issued2
			,expire_date	= @expire_date1
			,user_id		= @user_id1
			,doc_no			= @doc_no1
			,doc_seria		= @doc_seria1
			,doc_org		= @doc_org1
		WHERE id = @id1

	COMMIT TRAN
go

