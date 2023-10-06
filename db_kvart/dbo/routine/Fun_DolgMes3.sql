CREATE   FUNCTION [dbo].[Fun_DolgMes3] (@fin_id smallint,@occ int)  
RETURNS smallint
AS 
 
--
-- Количество месяцев долга от последнего начисления на лицевом счете
--

BEGIN 
   declare 
   @mes decimal(5,1), -- кол-во месяцев когда начисление = 0
   @last_paid_fin smalldatetime, -- Дата последнего фин.периода на котором есть начисление
   @start_date smalldatetime  -- Дата начала фин.периода на который ищем долг
   
   set @mes=0
  
   -- 
   select @start_date=start_date from dbo.GLOBAL_VALUES where fin_id=@fin_id
   
	select top 1 @last_paid_fin=gb.start_date
	from dbo.occ_history as oh 
		JOIN dbo.global_values as gb  ON oh.fin_id=gb.fin_id
	where oh.occ=@occ
		and oh.fin_id<@fin_id
		and oh.value>0
	order by gb.fin_id desc

	set @mes=DATEDIFF ( month , @last_paid_fin , @start_date )-1
	
	if @mes is Null or @mes<0  set @mes=0
	if @mes>999 set @mes=999

return @mes

END
go

