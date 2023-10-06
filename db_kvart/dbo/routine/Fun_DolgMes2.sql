CREATE   FUNCTION [dbo].[Fun_DolgMes2] (@fin_id smallint,@occ int)  
RETURNS smallint
AS 
 
--
-- Количество месяцев долга
--

BEGIN 
   declare 
   @mes decimal(5,1), 
   @mes2 decimal(5,1), -- кол-во месяцев когда начисление = 0
   @Paid decimal(9,2), -- начисление на лицевом
   @last_paid_fin smalldatetime, -- Дата последнего фин.периода на котором есть начисление
   @start_date smalldatetime  -- Дата начала фин.периода на который ищем долг
   
   set @mes=0

   
   declare @fin_Current smallint
   select @fin_Current=fin_id from dbo.GLOBAL_VALUES  where closed=0 ORDER BY fin_id DESC
   
   -- 
   select @start_date=start_date from dbo.GLOBAL_VALUES where fin_id=@fin_id
   
	select @Paid=avg(oh.paid) --max(oh.paid)
	from dbo.occ_history as oh 
	where oh.occ=@occ
		and oh.fin_id<@fin_id

	select top 1 @last_paid_fin=gb.start_date
	from dbo.occ_history as oh 
	JOIN dbo.global_values as gb ON oh.fin_id=gb.fin_id
	where oh.occ=@occ
		and oh.fin_id<@fin_id
		and oh.value>0
	order by gb.fin_id desc

	set @mes2=DATEDIFF ( month , @last_paid_fin , @start_date )-1

	if @Paid=0 or @Paid is null return @mes

	if @fin_id=@fin_Current
	begin
		select @mes=round((o.saldo-o.paymaccount)/@Paid,0)
		from dbo.occupations as o 
		where o.occ=@occ
	end
	else
	begin
		select @mes=round((o.saldo-o.paymaccount)/@Paid,0)
		from dbo.occ_history as o 
		where o.occ=@occ
		and o.fin_id=@fin_id
	end

	set @mes=@mes+@mes2
	
	if @mes is Null or @mes<0  set @mes=0
	if @mes>999 set @mes=999

return @mes

END
go

