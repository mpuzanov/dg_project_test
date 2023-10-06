CREATE   PROCEDURE [dbo].[k_bankcount_add]
(
	@owner_id1	 INT
   ,@bank_id1	 INT
   ,@name1		 VARCHAR(30)
   ,@number1	 VARCHAR(20)
   ,@number2	 VARCHAR(2)	   = NULL
   ,@data_open1	 SMALLDATETIME = NULL
   ,@data_close1 SMALLDATETIME = NULL
   ,@otd		 VARCHAR(4)	   = NULL
   ,@fil		 VARCHAR(4)	   = NULL
   ,@tnomer		 VARCHAR(7)	   = NULL
   ,@kodi		 VARCHAR(2)	   = NULL
)
/*
--
--  Добавляем банковский счет

Пузанов
26.08.2005
*/
AS

	SET NOCOUNT ON

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE @occ1		 INT
		   ,@fin_current SMALLINT
	SELECT
		@occ1 = occ
	FROM dbo.PEOPLE 
	WHERE id = @owner_id1

	IF dbo.Fun_AccessSubsidLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с банковскими счетами запрещена', 16, 1)
		RETURN
	END

	DECLARE @user_id1 SMALLINT
		   ,@date1	  SMALLDATETIME

	SET @date1 = dbo.Fun_GetOnlyDate(current_timestamp)
	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

BEGIN TRY 

	BEGIN TRAN

		UPDATE dbo.Bank_Counts 
		SET active = 0
		WHERE owner_id = @owner_id1

		-- Добавляем
		INSERT INTO dbo.Bank_Counts 
		(owner_id
		,active
		,bank_id
		,name
		,number
		,number2
		,data_open
		,data_close
		,user_edit
		,date_edit
		,otd
		,fil
		,tnomer
		,kodi)
		VALUES (@owner_id1
			   ,1
			   ,@bank_id1
			   ,@name1
			   ,@number1
			   ,@number2
			   ,@data_open1
			   ,@data_close1
			   ,@user_id1
			   ,@date1
			   ,@otd
			   ,@fil
			   ,@tnomer
			   ,@kodi)

		UPDATE dbo.Compensac_all
		SET transfer_bank = 1
		WHERE occ = @occ1
		AND fin_id = @fin_current

	COMMIT TRAN

END TRY
BEGIN CATCH
	
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
	
	THROW;
END CATCH
go

