CREATE   PROCEDURE [dbo].[k_dsc_delete](
    @id1 INT
, @del BIT = 0-- 1 -Удалить на совсем
)
AS
    --
    --  Процедура удаления льготы
    --  В льготе проставляем дату удаления льготы
    --  запись не удаляем
    --
    SET NOCOUNT ON
    
    IF dbo.Fun_GetRejim() <> N'норм'
        BEGIN
            RAISERROR (N'База закрыта для редактирования!', 16, 1)
        END

    SET NOCOUNT ON

DECLARE
    @owner_id1       INT
    , @id2           INT
    , @active1       BIT
    , @occ1          INT
    , @Datedel       SMALLDATETIME
    , @DelDateLgota1 SMALLDATETIME

SELECT @owner_id1 = do.owner_id
     , @active1 = do.active
     , @occ1 = p.occ
     , @Datedel = p.DateDel
     , @DelDateLgota1 = do.DelDateLgota
FROM DSC_OWNERS AS do 
   , PEOPLE AS p 
WHERE do.id = @id1
  AND p.id = do.owner_id

    -- Льгота уже удалена
    IF @DelDateLgota1 IS NOT NULL
        RETURN

DECLARE @user_id1 SMALLINT
SELECT @user_id1 = id
FROM USERS 
WHERE login = system_user

    BEGIN TRAN
    IF @del = 0
        UPDATE DSC_OWNERS 
        SET DelDateLgota = current_timestamp
          , active       = 0
          , user_id      = @user_id1
        WHERE id = @id1
    ELSE
        BEGIN
            --  Удаляем на совсем
            --       if not exists(select * from PAYM_LGOTA_HISTORY where owner_id=@owner_id1 and owner_lgota=@owner_id1) 
            IF NOT EXISTS(SELECT *
                          FROM PEOPLE_HISTORY 
                          WHERE occ = @occ1
                            AND owner_id = @owner_id1
                            AND lgota_kod = @id1)
                DELETE
                FROM DSC_OWNERS 
                WHERE id = @id1
            ELSE
                RAISERROR (N'Удалить на совсем НЕЛЬЗЯ!', 16, 1)
        END

    -- Если льгота была активная и человека не удаляем
    IF @active1 = 1 AND @Datedel IS NULL
        BEGIN
            -- Выбираем новую активную льготу
            SET @id2 = 0
            SELECT TOP 1 @id2 = id
            FROM DSC_OWNERS ow
               , dbo.Fun_SpisokLgotaActive(@owner_id1) AS ow2
            WHERE ow.id = ow2.id1

            IF @id2 <> 0
                EXEC dbo.k_dsc_active @id2
            ELSE
                UPDATE PEOPLE 
                SET lgota_id  = 0
                  , lgota_kod = 0
                WHERE id = @owner_id1
                  AND Del = 0
        END

    COMMIT TRAN
go

