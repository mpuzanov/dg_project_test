CREATE   PROCEDURE [dbo].[k_showkomp_tmp]
( @occ1  int
)
AS
--
--  
--
set nocount on
 
select *, 
'Doxod_People'=convert(decimal(9,2),doxod/realy_people),
--'standart_tarif'=sumnorm/realy_people,
'SocOplata'=SumNorm-SumKomp
from compensac_tmp 
where occ=@occ1
go

