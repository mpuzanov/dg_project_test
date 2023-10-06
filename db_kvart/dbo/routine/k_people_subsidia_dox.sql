CREATE   PROCEDURE [dbo].[k_people_subsidia_dox]
(
@occ1 int,
@fin_id1 smallint,
@people_subs smallint = null OUTPUT,
@sum_pm decimal(9, 2) = 0 OUTPUT, -- средний прожиточный минимум
@doxod_avg decimal(9, 2) = 0 OUTPUT -- среднемесячный доход семьи кому положена субсидия
)
AS
/*  
Показаваем список людей с доходом для расчета субсидии
*/
set nocount on

create table #p1
(
    fin_id     smallint,
    occ        int,
    owner_id   int,
    people_uid UNIQUEIDENTIFIER,
    lgota_id   smallint,
    status_id  tinyint,
    status2_id VARCHAR(10) COLLATE database_default,
    birthdate  smalldatetime,
    doxod      decimal(9, 2),
    dop_norma  tinyint,
    data1      smalldatetime,
    data2      smalldatetime,
    kolday     tinyint,
	DateEnd	   SMALLDATETIME
)
insert into #p1 exec k_PeopleFin @occ1, @fin_id1

declare @start_date1 smalldatetime

select @start_date1 = start_date from dbo.GLOBAL_VALUES where fin_id = @fin_id1

select p.id,
       p.FIO as last_name,
       p.doxod,
       p.KolMesDoxoda,
       dbo.Fun_GetDoxodAvg(p.id) AS doxod_avg,
       p2.kolday,
       p.Del,
       p2.lgota_id,
       p.status_id, -- p2.status_id,
       ps.is_subs,
       dbo.Fun_GetSumPM(p2.status_id, @start_date1) AS sum_pm
from dbo.vpeople as p
	JOIN #p1 as p2 ON p.id = p2.owner_id
	JOIN dbo.person_statuses as ps ON p2.status2_id = ps.id


-- Выдаем количество людей которые участвуют в расчете субсидии

select @people_subs = count(p.id),
       @sum_pm = sum(dbo.Fun_GetSumPM(p2.status_id, @start_date1)) / Count(*),
       @doxod_avg = sum(dbo.Fun_GetDoxodAvg(p.id))
from people as p
	JOIN #p1 as p2 ON p.id = p2.owner_id
	JOIN dbo.person_statuses as ps ON p2.status2_id = ps.id
Where ps.is_subs = 1
  and p.Del = 0

if @people_subs is null set @people_subs = 0
go

