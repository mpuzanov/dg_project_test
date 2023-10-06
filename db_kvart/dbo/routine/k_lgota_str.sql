CREATE   PROCEDURE [dbo].[k_lgota_str] 
( @occ1 int
)
AS
set nocount on
 
declare @StrLgota varchar(20), @StrR1 char(1),@StrR2 char(1)
 
select @StrLgota=''
select @StrR1='-'
select @StrR2=' '
 
select @StrLgota=@StrLgota+LTrim(str(lgota_id))+@StrR1+Ltrim(str(count(*)))+@StrR2
from people
where occ=@occ1 and lgota_id>0
group by lgota_id
 
if  @StrLgota ='' select @StrLgota='Нет'
 
select @StrLgota
go

