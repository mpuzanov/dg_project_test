CREATE FUNCTION [dbo].[Fun_SubsidStr] (@occ1 int)  
RETURNS varchar(10) AS  
BEGIN 

declare @subsid varchar(10), @fin_current smallint

SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

if exists(select occ from dbo.View_COMPENSAC where occ=@occ1 and fin_id=@fin_current)
    set  @subsid='Есть'
else
    set  @subsid='-'
 
return @subsid
 
END
go

