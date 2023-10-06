CREATE   FUNCTION [dbo].[Fun_DolgMes] (@fin_id smallint,@occ int)  
RETURNS decimal(5,1)
AS 
 
--
-- Количество месяцев долга
--

BEGIN 
   declare @mes decimal(5,1), @Paid decimal(9,2)
   set @mes=0
   
   declare @fin_Current smallint
   select @fin_Current=fin_id from dbo.GLOBAL_VALUES where closed=0
   
	select @Paid=avg(oh.paid) --max(oh.paid) avg(oh.paid)
	from dbo.occ_history as oh 
	where oh.occ=@occ
		and oh.fin_id<@fin_id

	if @Paid=0 or @Paid is null return @mes

	if @fin_id=@fin_Current
	begin
		select @mes=(o.saldo-o.paymaccount)/@Paid
		from dbo.occupations as o 
		where o.occ=@occ
	end
	else
	begin
		select @mes=(o.saldo-o.paymaccount)/@Paid
		from dbo.occ_history as o 
		where o.occ=@occ
		and o.fin_id=@fin_id
	end

 if @mes is Null or @mes<0  set @mes=0
 if @mes>999 set @mes=999

return @mes

END
go

