CREATE   FUNCTION [dbo].[Fun_DolgMesServ] (@fin_id smallint,@occ int, @service_id VARCHAR(10))  
RETURNS int
AS 
 
--
-- Количество месяцев долга
-- Только у услуг которым начисляем отдельно
-- 
BEGIN 
   declare @mes int, @Paid decimal(9,2), @fin_top smallint
   set @mes=0
   set @fin_top=@fin_id-36 
   
   declare @fin_Current smallint
   select @fin_Current=fin_id from dbo.GLOBAL_VALUES where closed=0
   
	select @Paid=avg(paid) --max(paid)
	from dbo.paym_history 
	where occ=@occ
		and fin_id between @fin_top and @fin_id
		and service_id=@service_id
		and account_one=1

	if @Paid=0 or @Paid is null return @mes

	if @fin_id=@fin_Current
	begin
		select @mes=(saldo-paid)/@Paid
		from dbo.paym_list 
		where occ=@occ 
			and service_id=@service_id
			and account_one=1
	end
	else
	begin
		select @mes=(saldo-paid)/@Paid
		from dbo.paym_history 
		where occ=@occ
			and fin_id=@fin_id
			and service_id=@service_id
			and account_one=1
	end

 if @mes is Null  set @mes=0
 if @mes>999 set @mes=999

return @mes

END
go

