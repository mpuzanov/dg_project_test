-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[k_pid_add3]
(
	@fin_id			SMALLINT		= NULL
	,@occ			INT
	,@sup_id		INT				= NULL
	,@Summa			DECIMAL(9, 2)
	,@pid_tip		SMALLINT			= 3 -- 3 - соглашение о рассрочке
	,@occ_sup		INT				= NULL
	,@data_create	SMALLDATETIME	= NULL
	,@kol_mes		SMALLINT
	,@owner_id		INT				= NULL
	,@str_sum		XML
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	DECLARE	@dog_int	INT	= NULL
			,@pid_id	INT	= NULL
			,@hXml		INT
			,@tmp_sum	DECIMAL(9, 2)
			,@tmp_sum2	DECIMAL(9, 2)
			,@data_end	SMALLDATETIME

	IF @pid_tip IS NULL
		SET @pid_tip = 3

	IF @data_create IS NULL
		SELECT
			@data_create = dbo.Fun_GetOnlyDate(current_timestamp)
	ELSE
		SELECT
			@data_create = dbo.Fun_GetOnlyDate(@data_create)

	SELECT
		@data_end = DATEADD(MONTH, @kol_mes, @data_create) - 1

	IF @fin_id IS NULL
		SELECT
			@fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	IF @occ_sup IS NULL
		AND COALESCE(@sup_id,0)<>0
		SELECT TOP 1
			@occ_sup = occ_sup
			,@dog_int = dog_int
		FROM dbo.OCC_SUPPLIERS 
		WHERE Occ = @occ
		AND fin_id = @fin_id
		AND sup_id = @sup_id

	SELECT
		@pid_id = id
	FROM dbo.PID 
	WHERE Occ = @occ
	AND [data_create] = @data_create
	AND pid_tip = @pid_tip
	AND sup_id=COALESCE(@sup_id,sup_id)
	
	BEGIN TRAN

		IF @pid_id IS NOT NULL
		BEGIN
			UPDATE dbo.PID
			SET	fin_id		= @fin_id
				,Summa		= COALESCE(@Summa, 0)
				,occ_sup	= @occ_sup
				,dog_int	= @dog_int
				,kol_mes	= @kol_mes
				,data_end	= @data_end
				,owner_id	= @owner_id
			WHERE id = @pid_id
		END
		ELSE
		BEGIN
			INSERT
			INTO [dbo].[PID]
			(	fin_id
				,[Occ]
				,[data_create]
				,[sup_id]
				,[Summa]
				,[pid_tip]
				,occ_sup
				,dog_int
				,kol_mes
				,owner_id
				,data_end)
			VALUES (@fin_id
					,@occ
					,@data_create
					,COALESCE(@sup_id,0)
					,COALESCE(@Summa, 0)
					,@pid_tip
					,@occ_sup
					,@dog_int
					,@kol_mes
					,@owner_id
					,@data_end)

			SELECT
				@pid_id = SCOPE_IDENTITY()
		END

		IF @pid_id IS NULL
		BEGIN
			ROLLBACK
			RAISERROR ('Документ не создали!', 16, 1)
			RETURN -1
		END

		IF EXISTS (SELECT
					*
				FROM dbo.InstallmentPlan
				WHERE pid_id = @pid_id)
			DELETE FROM dbo.InstallmentPlan
			WHERE pid_id = @pid_id

		--SET @str_sum = '<?xml version="1.0"?> <root> <row date_payment="20120901" summa1="123.45"/> </root>'
		EXEC sp_xml_preparedocument	@hXml OUTPUT
									,@str_sum

		INSERT
		INTO dbo.InstallmentPlan
		(	pid_id
			,date_payment
			,Summa)
			SELECT
				@pid_id
				,date_payment
				,Summa1
			FROM OPENXML(@hXml, '/root/row', 1) WITH (date_payment SMALLDATETIME, summa1 DECIMAL(9, 2))
		EXEC sp_xml_removedocument @hXml

		-- проверяем
		SELECT
			@tmp_sum = SUM(Summa)
		FROM dbo.InstallmentPlan AS ip
		WHERE pid_id = @pid_id
		SELECT
			@tmp_sum2 = SUM(Summa)
		FROM dbo.PID AS P
		WHERE id = @pid_id

		IF (@tmp_sum <> @Summa)
			AND (@Summa <> @tmp_sum2)
		BEGIN
			ROLLBACK TRAN
			RAISERROR ('Ошибка в создании документа! Сумма не сходиться!', 16, 1)
			RETURN -1
		END

	COMMIT TRAN

END
go

