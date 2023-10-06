CREATE   PROCEDURE [dbo].[ka_PeopleFinShow](@occ1 int,
                                          @fin_id1 int
)
AS
/*
  Выдаем список людей проживающих по заданному лиц. счету в заданном фин. периоде
  может отличаться с данными на данный момент

  ka_PeopleFinShow @occ1=680004014, @fin_id1=212

*/
    SET NOCOUNT ON

declare
    @p1 table
        (
            fin_id      smallint,
            occ         int,
            owner_id    int,
            people_uid  UNIQUEIDENTIFIER NOT NULL,
            lgota_id    smallint,
            status_id   tinyint,
            status2_id  VARCHAR(10),
            birthdate   smalldatetime,
            doxod       decimal(9, 2),
            koldaylgota tinyint,
            data1       smalldatetime,
            data2       smalldatetime,
            kolday      tinyint,
			DateEnd		SMALLDATETIME
        )
insert into @p1 exec k_PeopleFin @occ1, @fin_id1

SELECT CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.') as Initials,
       p1.kolday,
       p1.lgota_id,
       CONVERT(VARCHAR(10), p1.Birthdate, 104) as Birthdate,
       substring(st.name, 1, 15)                               as status_id,
       per.name                                                as status2_id,
       CONVERT(VARCHAR(10), p.DateReg, 104) as DateReg,
       CONVERT(VARCHAR(10), p.DateDel, 104) as DateDel,
       p1.koldaylgota                                          as koldaylgota,
       p1.owner_id                                             as owner_id,
       p.kol_day_add                                           as kol_day_add,
       p.kol_day_lgota                                         as kol_day_lgota
FROM dbo.people as p 
    JOIN @p1 as p1
        ON p.id = p1.owner_id
    JOIN dbo.person_statuses as per 
        ON p1.status2_id = per.id
    JOIN dbo.status as st 
        ON p1.status_id = st.id
WHERE p.occ = @occ1
go

