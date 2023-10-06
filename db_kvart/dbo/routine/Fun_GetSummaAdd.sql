CREATE   FUNCTION [dbo].[Fun_GetSummaAdd]
(  @occ1 int,
   @service_id1 VARCHAR(10),
   @day_count1 smallint,
   @people_count1 smallint,
   @Fin_id1 smallint
)
RETURNS decimal(8,2) AS  
BEGIN 
--
--  Получение суммы  суммы ввода разовых
--
declare @Start_date smalldatetime, @End_date smalldatetime, @summa decimal(8,2)
declare @day_diff smallint, @FinPeriodId smallint
declare   @mode1 int,       -- ключ режима потребления
          @source1 int,     -- ключ поставщика  
          @tar1  DECIMAL(10, 4)
 
select @FinPeriodId=fin_Id, @Start_date=start_date, @End_date=End_date from GLOBAL_VALUES where fin_Id=@fin_Id1
if @FinPeriodId is Null  -- не найден заданный фин. период, поэтому делаем по текущему
begin
   SELECT @FinPeriodId = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
   select @FinPeriodId=fin_Id, @Start_date=start_date, @End_date=End_date 
   from dbo.GLOBAL_VALUES where fin_id=@FinPeriodId
end
 
 
SELECT  @day_diff=datediff(day,@START_DATE, @END_DATE ) + 1 
 
select @mode1=mode_id, @source1=source_id  
from dbo.consmodes_list 
where (occ=@occ1) and (service_id=@service_id1)
 
select  @tar1=value
from dbo.rates
where (FinPeriod=@FinPeriodId) and 
	(service_id=@service_id1) and 
	(mode_id=@mode1) and 
	(source_id=@source1) and 
	(status_id='откр')
 
SELECT  @summa= round(  @tar1 / @day_diff * @day_count1 * @people_count1 ,2)
 
return(@summa)
 
END
go

