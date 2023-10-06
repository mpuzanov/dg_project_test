CREATE   FUNCTION [dbo].[Fun_GetOccEAN] (@occ1 int , @service_kod1 tinyint =0)   
RETURNS varchar(15) AS  
BEGIN 
--
-- Расчёт контрольной цифры для кода EAN-13
--	автор:		Антропов С.В.
--	дата создания:	10.08.04
--	дата изменеия:	
--	автор изменеия:	
--  
--
declare  @strResult varchar(15),@sumCHet smallint,@sumNEchet smallint
,@i smallint,@a smallint

set @strresult= CONCAT(@service_kod1, RIGHT('000000'+ cast(@occ1 AS VARCHAR), 6) )


set @i=len(@strresult)
set @sumCHet=0
set @sumNEchet=0
while @i>=1
begin
	if @i=1 
	begin
		set @sumCHet=@sumCHet+convert(int,substring(@strresult,@i,1))
	end
	else
	begin
		set @sumCHet=@sumCHet+convert(int,substring(@strresult,@i,1))
		set @sumNEchet=@sumNEchet+convert(int,substring(@strresult,@i-1,1))
	end
	set @i=@i-2
end


--break 
--continue
set @a=@sumCHet*3+@sumNEchet
set @i=((convert(int,substring(ltrim(str(@a)),1,len(@a)-1)))+1)*10
if (@i-@a)=10 
set @strresult=@strresult+'0'
else
set @strresult=@strresult+ltrim(str(@i-@a))

return convert(int,@strresult)
--return @strresult

END
go

