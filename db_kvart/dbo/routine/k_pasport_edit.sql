CREATE   PROCEDURE [dbo].[k_pasport_edit]
/*
  изменяем документ
*/
(
	  @id1 INT
	, @doctype_id1 VARCHAR(10)
	, @doc_no1 VARCHAR(12)
	, @passser_no1 VARCHAR(12)
	, @issued1 SMALLDATETIME
	, @docorg1 VARCHAR(100)
	, @kod_pvs1 VARCHAR(7) = NULL
)
AS
	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	SET NOCOUNT ON

	DECLARE @user_id1 SMALLINT
		  , @date_edit1 SMALLDATETIME
		  , @birthdate SMALLDATETIME
		  , @Age INT

	-- дата рождения должна быть меньше даты выдачи документа на 14 лет
	-- для паспорта
	SELECT TOP 1 @birthdate = p.Birthdate
			   , @Age = dbo.Fun_GetBetweenDateYear(p.Birthdate, @issued1)
	FROM dbo.Iddoc AS i 
		JOIN dbo.People AS p ON p.id = i.owner_id
	WHERE i.id = @id1

	IF (@doctype_id1 = 'пасп')
		AND (@Age < 14)
	BEGIN
		DECLARE @s_tmp VARCHAR(1000)
		SET @s_tmp = CONCAT('Проверьте дату рождения <', CONVERT(VARCHAR(10), @birthdate, 104)
			,'> и дату выдачи документа <', CONVERT(VARCHAR(10), @issued1, 104)
			,'>! (возраст ', @Age,' меньше 14 лет)')
		RAISERROR (@s_tmp, 11, 1)
		RETURN 1
	END

	SELECT @user_id1 = dbo.Fun_GetCurrentUserId()
		 , @date_edit1 = dbo.Fun_GetOnlyDate(current_timestamp)

	BEGIN TRAN

		UPDATE dbo.Iddoc 
		SET DOCTYPE_ID = LOWER(@doctype_id1)
		  , doc_no = @doc_no1
		  , PASSSER_NO = @passser_no1
		  , ISSUED = @issued1
		  , DOCORG = @docorg1
		  , user_edit = @user_id1
		  , date_edit = @date_edit1
		  , kod_pvs = @kod_pvs1
		WHERE id = @id1

	COMMIT TRAN
go

