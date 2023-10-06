CREATE   FUNCTION [dbo].[Fun_ProcentPenalty] (@occ1 int, @fin_id1 smallint)  
RETURNS DECIMAL(10, 4)
AS  
BEGIN 
--
-- Если квартира приватизирована или куплена
-- или непр и нет договора соц. найма  то  -  1%(0.01) 
-- Если квартира "непр" и есть договор соц.найма то  -    0,1%(0.001) 
--
 
declare @fin_current smallint, 
        @proptype_id1 VARCHAR(10), 
		@socnaim1 bit,
		@Proc1 DECIMAL(10, 4)
 
SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
 
if  @fin_current=@fin_id1
begin
   select @proptype_id1=proptype_id, @socnaim1=socnaim
   from dbo.occupations
   where occ=@occ1
end
else
begin
   select @proptype_id1=proptype_id, @socnaim1=socnaim
   from dbo.occ_history
   where fin_id=@fin_id1 and occ=@occ1
end
 
set @Proc1=case
  when (@proptype_id1='непр') and (@socnaim1=1) then 0.001
  else  0.01
end
 
return @Proc1
 
END
go

