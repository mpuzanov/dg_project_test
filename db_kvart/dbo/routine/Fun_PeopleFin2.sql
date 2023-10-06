CREATE   FUNCTION [dbo].[Fun_PeopleFin2]   
(@occ1 int,  @fin_id1 int, @data1 datetime=null, @data2 datetime=null)  
RETURNS  @TablePeopleFin Table
       (owner_id int,  
       lgota_id smallint, 
       status2_id VARCHAR(10), 
       birthdate smalldatetime, 
       dop_norma tinyint, 
       KolDay smallint)

AS  
BEGIN 
--
-- Выдаем информацию по людям зарегистрированным в заданном фин.периоде
-- для других хранимых процедур
--
/*  Вставляйте блок
declare @p1 table(owner_id  int, lgota_id smallint, status2_id VARCHAR(10), birthdate  smalldatetime, dop_norma  tinyint, kolday int)
insert into @p1
select *
from Fun_PeopleFin(@occ1,@fin_id1)
*/


declare @start_date smalldatetime, @end_date smalldatetime
select @start_date=start_date, @end_date=end_date from global_values where fin_id=@fin_id1

declare @TableVar Table(owner_id int, 
       dateReg smalldatetime, 
       DateDel smalldatetime,  
       DateEnd smalldatetime,  
       lgota_id smallint, 
       status2_id VARCHAR(10), 
       birthdate smalldatetime, 
       dop_norma tinyint, 
       KolDay smallint)

insert into @TableVar
select 'owner_id'=id, dateReg, DateDel, DateEnd, lgota_id, status2_id, birthdate, dop_norma, 'KolDay'=0
from people where occ=@occ1 and 
     (dateDel>=@start_date or DateDel is Null) and 
     (DateReg<=@end_date or DateReg is Null)

if @data1 between @start_date and @end_date
set @start_date=@data1

if @data2 between @start_date and @end_date
set @end_date=@data2

update @TableVar
set dateReg=@start_date
where dateReg is Null or DateReg<@start_date

update @TableVar
set dateDel=@end_date
where dateDel is Null or dateDel>@end_date

update @TableVar
set dateDel=DateEnd
where DateEnd is not Null and DateEnd<@end_date and status2_id='врем'

update @TableVar
set KolDay=datediff(day,dateReg, DateDel)+1
where dateReg<DateDel

INSERT INTO @TablePeopleFin
select owner_id,  
           lgota_id, 
           status2_id, 
           birthdate, 
           dop_norma,
           kolday  from @TableVar
RETURN

END
go

