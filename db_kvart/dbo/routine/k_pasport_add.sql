CREATE   PROCEDURE [dbo].[k_pasport_add]
/*
  Добавляем документ
*/
(
    @owner_id1 INT
, @doctype_id1 VARCHAR(10)
, @doc_no1 VARCHAR(12)
, @passser_no1 VARCHAR(12)
, @issued1 SMALLDATETIME
, @docorg1 VARCHAR(100)
, @kod_pvs1 VARCHAR(7) = NULL
)
AS
    SET NOCOUNT ON

    IF dbo.Fun_GetRejim() <> N'норм'
        BEGIN
            RAISERROR (N'База закрыта для редактирования!', 16, 1)
        END
    IF @issued1 IS NULL
        OR COALESCE(@docorg1,'')=''
        OR COALESCE(@passser_no1,'')=''
        OR COALESCE(@doc_no1,'')=''
        BEGIN
            RAISERROR (N'Установите полностью реквизиты документа!', 16, 1)
        END

DECLARE
    @user_id1     SMALLINT
    , @date_edit1 SMALLDATETIME
    , @birthdate  SMALLDATETIME
    , @Age        INT

    -- дата рождения должна быть меньше даты выдачи документа на 14 лет
    -- для паспорта
	SELECT @birthdate = p.Birthdate
		 , @Age = dbo.Fun_GetBetweenDateYear(p.Birthdate, @issued1)
	FROM dbo.People AS p 
	WHERE p.id = @owner_id1

    IF (@doctype_id1 = N'пасп')
        AND (@Age < 14)
        BEGIN
            DECLARE @s_tmp VARCHAR(1000)
            SET @s_tmp = CONCAT(N'Проверьте дату рождения <', CONVERT(VARCHAR(10), @birthdate, 104)
			,'> и дату выдачи ПАСПОРТА <', CONVERT(VARCHAR(10), @issued1, 104)
			,'>! (возраст ',@Age,' меньше 14 лет)')			
            RAISERROR (@s_tmp, 16, 1)
        END

	SELECT @date_edit1 = dbo.Fun_GetOnlyDate(current_timestamp)
     , @user_id1 = dbo.Fun_GetCurrentUserId()

    BEGIN TRAN

	UPDATE dbo.Iddoc
	SET active = 0
	WHERE owner_id = @owner_id1

    -- Добавляем
	INSERT INTO dbo.Iddoc
	( owner_id
	, active
	, DOCTYPE_ID
	, doc_no
	, PASSSER_NO
	, ISSUED
	, DOCORG
	, user_edit
	, date_edit
	, kod_pvs)
	VALUES ( @owner_id1
		   , 1
		   , LOWER(@doctype_id1)
		   , @doc_no1
		   , @passser_no1
		   , @issued1
		   , @docorg1
		   , @user_id1
		   , @date_edit1
		   , @kod_pvs1)

    COMMIT TRAN
go

