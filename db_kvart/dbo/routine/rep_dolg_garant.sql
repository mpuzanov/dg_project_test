CREATE   PROCEDURE [dbo].[rep_dolg_garant]
(
@service_id1 VARCHAR(10)= null,    -- услуга
@source_id1 int = null -- поставщик
)        
AS
--
--  Список должников по услугам по гаранту(или другие поставщики)
--
/*

дата создания: 26.04.2005
автор: Кривобоков А.В.

дата последней модификации: 
автор изменений:  
*/ 

SET NOCOUNT ON


declare @s1 int, @s2 int
if (@source_id1 is null or @source_id1=1)
begin
   set @s1=0
   set @s2=100000
end
else
begin
  set @s1=@source_id1
  set @s2=@source_id1
end


declare @fin_current smallint, @fin_pred smallint
SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)
set @fin_pred=@fin_current-1

select
	 dbo.Fun_Initials(o.occ) as Initials,
	 o.address,
	 o.jeu,
	  case 
		 when pl.paid>0 then convert(int,(pl.saldo-pl.paymaccount)/pl.paid)
		 else convert(int,(pl.saldo-pl.paymaccount)/(ph.value+1))
	   end as kol_mes,
	 pl.saldo-pl.paymaccount as dolg,
	 s.id,
	 sp.name,
	 cm.name
from dbo.VOCC as o,
     dbo.paym_list as pl,
     dbo.View_PAYM as ph,
     dbo.View_SERVICES as s,
     dbo.cons_modes as cm,
     dbo.consmodes_list as cl,
     dbo.View_SUPPLIERS as sp
where
	ph.occ=o.occ
	and  ph.fin_id=@fin_pred
	and o.occ=pl.occ
	and s.id=pl.service_id
	and s.id=ph.service_id
	and o.status_id<>'закр'
	and (pl.saldo-pl.paymaccount)>0 
	and s.id=@service_id1
	and convert(int,((pl.saldo-pl.paymaccount)/(ph.value+1)))>1
	and s.id=cl.service_id
	and cl.occ=o.occ
	and cm.id=cl.mode_id
	and sp.id=cl.source_id
	and sp.id between @s1 and @s2

order by sp.name,o.jeu,o.address
go

