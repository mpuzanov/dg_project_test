CREATE   PROCEDURE [dbo].[k_bankcount_edit]
(
	@id1		 INT
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
--  изменяем банковский счет
--
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

	DECLARE @occ1 INT

	SELECT
		@occ1 = occ
	FROM dbo.PEOPLE AS p
	JOIN dbo.BANK_COUNTS AS bc 
		ON p.id = bc.owner_id
	WHERE bc.id = @id1

	IF dbo.Fun_AccessSubsidLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с банковскими счетами запрещена', 16, 1)
		RETURN
	END

	DECLARE @user_id1 SMALLINT

	SELECT
		@user_id1 = id
	FROM dbo.USERS 
	WHERE login = system_user

	BEGIN TRAN

		UPDATE dbo.BANK_COUNTS 
		SET bank_id	   = @bank_id1
		   ,name	   = @name1
		   ,number	   = @number1
		   ,number2	   = @number2
		   ,data_open  = @data_open1
		   ,data_close = @data_close1
		   ,user_edit  = @user_id1
		   ,date_edit  = CAST(CAST(current_timestamp AS DATE) AS SMALLDATETIME)
		   ,otd		   = @otd
		   ,fil		   = @fil
		   ,tnomer	   = @tnomer
		   ,KODI	   = @kodi
		WHERE id = @id1


	COMMIT TRAN
go

