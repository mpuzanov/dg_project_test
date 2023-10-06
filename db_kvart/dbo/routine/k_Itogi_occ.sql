CREATE   PROCEDURE [dbo].[k_Itogi_occ]
/*
  Выдаем итоговые значения по заданному лицевому счету
  
  exec k_Itogi_occ 680003604, 172
*/
(
    @occ1 INT
, @fin_id1 INT
)
AS
    SET NOCOUNT ON

DECLARE
    @total_people       SMALLINT
    , @people_finperiod SMALLINT
    , @CountCounter     SMALLINT
    , @doxod            DECIMAL(9, 2) = 0
    , @lgota            VARCHAR(20)   = '-'
    , @subsid           VARCHAR(10)   = '-'
    , @StrStatus        VARCHAR(50)   = ''

CREATE TABLE #p1
(
    fin_id      SMALLINT,
    occ         INT,
    owner_id    INT,
    people_uid  UNIQUEIDENTIFIER,
    lgota_id    SMALLINT,
    status_id   SMALLINT,
    status2_id  VARCHAR(10) COLLATE database_default,
    birthdate   SMALLDATETIME,
    doxod       DECIMAL(9, 2),
    koldaylgota SMALLINT,
    data1       SMALLDATETIME,
    data2       SMALLDATETIME,
    kolday      SMALLINT,
	DateEnd		SMALLDATETIME
)

INSERT INTO #p1 EXEC k_PeopleFin @occ1, @fin_id1

SELECT @total_people = COUNT(id)
FROM dbo.People 
WHERE occ = @occ1
  AND Del = CAST(0 AS BIT)

SELECT @people_finperiod = COUNT(owner_id)
FROM #p1

IF @people_finperiod > 0
SELECT @StrStatus =
        SUBSTRING((SELECT ';' + LTRIM(ps.short_name) + ':' + LTRIM(STR(COUNT(owner_id)))
                    FROM #p1 AS p
                    JOIN dbo.Person_statuses AS ps ON 
					p.status2_id = ps.id
                    GROUP BY ps.id_no
                            , ps.short_name
                    ORDER BY ps.id_no
                    FOR XML PATH (''))
            , 2, 50)

SELECT @CountCounter = COUNT(counter_id)
FROM dbo.Counter_list_all AS CLA 
WHERE occ = @occ1
  AND fin_id = @fin_id1

SELECT @total_people AS total_people
     , @people_finperiod AS people_finperiod
     , @doxod AS doxod
     , @lgota AS lgota
     , @subsid AS subsid
     , @StrStatus AS StrStatus
     , CAST(1 AS BIT) AS SubsidiaBank
     , @CountCounter AS CountCounter
go

