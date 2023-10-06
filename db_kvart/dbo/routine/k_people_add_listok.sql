CREATE   PROCEDURE [dbo].[k_people_add_listok](
    @occ1 INT -- код лицевого
, @list_id1 INT-- код листка прибытия
)
AS
    --
    --  Добавление человека из листка прибытия
    --  

    IF dbo.Fun_GetRejimOcc(@occ1) <> N'норм'
        BEGIN
            RAISERROR (N'База закрыта для редактирования!', 16, 1)
        END

    SET NOCOUNT ON
    SET XACT_ABORT ON

DECLARE
    @trancount INT,
    @tran_name varchar(50) = 'k_people_add_listok'
    SET @trancount = @@trancount;

DECLARE
    @id1       INT
    , @DateReg SMALLDATETIME
    , @Fam_id1 VARCHAR(10)

BEGIN TRY

    IF EXISTS(SELECT 1
              FROM dbo.PEOPLE 
              WHERE occ = @occ1
                AND DateDel IS NULL)
        -- Если уже существуют люди на этом лицевом счете
        SET @Fam_id1 = '????'
    ELSE
        -- то первый прописанный является ответств. квартиросъемщиком
        SET @Fam_id1 = N'отвл'

    SET @DateReg = DATEADD(dd, DATEDIFF(dd, '', current_timestamp), '')

    --=============================================
    DECLARE @Last_name1 VARCHAR(50)
        ,@First_name1 VARCHAR(30)
        ,@Second_name1 VARCHAR(30)
        ,@Status_id1 TINYINT
        ,@Status2_id1 VARCHAR(10)
        ,@Birthdate1 SMALLDATETIME
        ,@sex1 TINYINT

    SELECT @Status_id1 = 0
         , @Status2_id1 = '????'

    DECLARE @DOCTYPE_ID1 VARCHAR(10)
        ,@PASSSER_NO1 VARCHAR(12)
        ,@DOC_NO1 VARCHAR(12)
        ,@ISSUED1 SMALLDATETIME
        ,@DOCORG1 VARCHAR(50)

    DECLARE @KraiBirth1 VARCHAR(50)
        ,@RaionBirth1 VARCHAR(30)
        ,@TownBirth1 VARCHAR(30)
        ,@VillageBirth1 VARCHAR(30)
        ,@KraiOld1 VARCHAR(50)
        ,@TownOld1 VARCHAR(30)
        ,@StreetOld1 VARCHAR(30)
        ,@Nom_domOld1 VARCHAR(12)
        ,@Nom_kvrOld1 VARCHAR(20)

    SELECT @Last_name1 = last_name
         , @First_name1 = first_name
         , @Second_name1 = second_name
         , @Birthdate1 = birthdate
         , @sex1 = sex
         , @DOCTYPE_ID1 = DOCTYPE_ID
         , @PASSSER_NO1 = PASSSER_NO
         , @DOC_NO1 = DOC_NO
         , @ISSUED1 = ISSUED
         , @DOCORG1 = DOCORG
         , @KraiBirth1 = KraiBirth
         , @RaionBirth1 = RaionBirth
         , @TownBirth1 = TownBirth
         , @VillageBirth1 = VillageBirth
         , @KraiOld1 = KraiOld
         , @TownOld1 = TownOld
         , @StreetOld1 = StreetOld
         , @Nom_domOld1 = Nom_domOld
         , @Nom_kvrOld1 = Nom_kvrOld
    FROM dbo.PEOPLE_LISTOK AS p 
    WHERE id = @list_id1

    --=============================================
    IF @trancount = 0
        BEGIN TRANSACTION
    ELSE
        SAVE TRANSACTION @tran_name;

    --EXEC @id1 = dbo.k_people_next -- новое значение ключа
    SET @id1 = NEXT VALUE FOR dbo.GeneratePeolpleSequence;

    INSERT
    INTO dbo.PEOPLE
    ( id
    , occ
    , last_name
    , first_name
    , second_name
    , Fam_id
    , DateReg
    , status_id
    , status2_id
    , birthdate
    , sex)
    VALUES ( @id1
           , @occ1
           , @Last_name1
           , @First_name1
           , @Second_name1
           , @Fam_id1
           , @DateReg
           , @Status_id1
           , @Status2_id1
           , @Birthdate1
           , @sex1)

    -- добавляем паспортные дынные
    IF @DOCTYPE_ID1 IS NOT NULL
        EXEC dbo.k_pasport_add @id1
            , @DOCTYPE_ID1
            , @DOC_NO1
            , @PASSSER_NO1
            , @ISSUED1
            , @DOCORG1

    -- Добавляем историю проживания
    INSERT
    INTO dbo.PEOPLE_2
    ( owner_id
    , KraiBirth
    , RaionBirth
    , TownBirth
    , VillageBirth
    , KraiOld
    , TownOld
    , StreetOld
    , Nom_domOld
    , Nom_kvrOld)
    VALUES ( @id1
           , @KraiBirth1
           , @RaionBirth1
           , @TownBirth1
           , @VillageBirth1
           , @KraiOld1
           , @TownOld1
           , @StreetOld1
           , @Nom_domOld1
           , @Nom_kvrOld1)

    IF @trancount = 0
        COMMIT TRANSACTION;

    -- обновляем статус лицевого(открыт, свободен, закрыт)
    EXEC k_occ_status @occ1

    -- сохраняем в историю изменений
    DECLARE @comments VARCHAR(30)
    SET @comments = N'из базы: ' + @Last_name1 + ' ' + SUBSTRING(@First_name1, 1, 1) + '. ' +
                    SUBSTRING(@Second_name1, 1, 1) + '.'
    EXEC k_write_log @occ1
        , N'прчл'
        , @comments

    SELECT @id1 as id

END TRY
BEGIN CATCH
    DECLARE @xstate INT;
    SELECT @xstate = XACT_STATE();
    IF @xstate = -1
        ROLLBACK;
    IF @xstate = 1
        AND @trancount = 0
        ROLLBACK;
    IF @xstate = 1
        AND @trancount > 0
        ROLLBACK TRANSACTION @tran_name;

    DECLARE @strerror VARCHAR(4000) = ''
    EXECUTE k_GetErrorInfo @visible = 0
        , @strerror = @strerror OUT
    RAISERROR (@strerror, 16, 1)
END CATCH
go

